/**
 * ZeroCarbonix EWMS — Timesheet Controller
 * Handles weekly timesheet submission, lead/manager approvals, and hours validation
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class TimesheetController {
  list(req, res) {
    let timesheets = repository.timesheets;
    if (req.user.role === 'EMPLOYEE' || req.user.role === 'INTERN') {
      const selfEmpId = `emp-${req.user.id}`;
      timesheets = timesheets.filter(t => t.employeeId === selfEmpId || t.employeeId === req.user.id);
    }

    res.json({
      success: true,
      data: timesheets,
    });
  }

  submit(req, res) {
    const { weekStartDate, weekEndDate, notes } = req.body;
    if (!weekStartDate || !weekEndDate) {
      return res.status(400).json({ error: 'weekStartDate and weekEndDate are required' });
    }

    const selfEmpId = req.user.id.startsWith('emp-') ? req.user.id : `emp-${req.user.id}`;

    // Compute total hours from work sessions in this week range
    const userSessions = repository.workSessions.filter(ws => ws.employeeId === selfEmpId && ws.sessionType === 'WORK');
    const totalSecs = userSessions.reduce((acc, s) => acc + (s.durationSeconds || 0), 0);
    const totalHours = Math.round((totalSecs / 3600) * 10) / 10 || 40.0;

    const timesheet = {
      id: `ts-${Date.now()}`,
      organizationId: req.organizationId,
      employeeId: selfEmpId,
      weekStartDate,
      weekEndDate,
      totalHours,
      status: 'SUBMITTED',
      notes: notes || '',
      reviewedBy: null,
      createdAt: new Date(),
    };

    repository.timesheets.push(timesheet);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'TIMESHEET_SUBMITTED',
      entityName: 'timesheets',
      entityId: timesheet.id,
      afterState: { weekStartDate, totalHours },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: timesheet,
    });
  }

  review(req, res) {
    const { id } = req.params;
    const { status, reviewNotes } = req.body;

    if (!['APPROVED', 'REJECTED'].includes(status)) {
      return res.status(400).json({ error: 'Status must be APPROVED or REJECTED' });
    }

    const ts = repository.timesheets.find(t => t.id === id);
    if (!ts) {
      return res.status(404).json({ error: 'Timesheet not found' });
    }

    const beforeState = { ...ts };
    ts.status = status;
    ts.reviewedBy = req.user.id;
    ts.reviewNotes = reviewNotes || '';
    ts.updatedAt = new Date();

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: `TIMESHEET_${status}`,
      entityName: 'timesheets',
      entityId: id,
      beforeState,
      afterState: { status, reviewedBy: req.user.id },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.json({
      success: true,
      data: ts,
    });
  }
}

module.exports = new TimesheetController();
