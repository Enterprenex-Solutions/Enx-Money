/**
 * ZeroCarbonix EWMS — Attendance Controller
 * Handles daily shifts, punch clock-in/out, late arrivals, and live roster
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class AttendanceController {
  clockIn(req, res) {
    const employeeId = req.user.employeeId;
    if (!employeeId) return res.status(400).json({ success: false, error: 'No employee profile' });

    const todayStr = new Date().toISOString().split('T')[0];
    let record = repository.attendanceRecords.find(a => a.employeeId === employeeId && a.workDate === todayStr);

    if (record && record.clockIn && !record.clockOut) {
      return res.status(400).json({ success: false, error: 'Already clocked in for today' });
    }

    if (!record) {
      record = {
        id: `att-${Date.now()}`,
        organizationId: req.organizationId,
        employeeId,
        workDate: todayStr,
        clockIn: new Date(),
        clockOut: null,
        totalHours: 0,
        status: 'PRESENT',
        notes: req.body.notes || 'Office shift started',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      repository.attendanceRecords.push(record);
    } else {
      record.clockIn = new Date();
      record.clockOut = null;
      record.status = 'PRESENT';
      record.updatedAt = new Date();
    }

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'CLOCK_IN',
      entityName: 'attendance',
      entityId: record.id,
      ipAddress: req.ip,
    });

    return res.json({
      success: true,
      message: 'Clocked in successfully',
      data: record,
    });
  }

  clockOut(req, res) {
    const employeeId = req.user.employeeId;
    const todayStr = new Date().toISOString().split('T')[0];
    const record = repository.attendanceRecords.find(a => a.employeeId === employeeId && a.workDate === todayStr);

    if (!record || !record.clockIn || record.clockOut) {
      return res.status(400).json({ success: false, error: 'No active shift found to clock out from' });
    }

    record.clockOut = new Date();
    const hours = Math.max(0, (record.clockOut.getTime() - new Date(record.clockIn).getTime()) / (3600 * 1000));
    record.totalHours = Math.round(hours * 10) / 10;
    record.updatedAt = new Date();

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'CLOCK_OUT',
      entityName: 'attendance',
      entityId: record.id,
      afterState: { totalHours: record.totalHours },
      ipAddress: req.ip,
    });

    return res.json({
      success: true,
      message: 'Clocked out successfully',
      data: record,
    });
  }

  getToday(req, res) {
    const employeeId = req.user.employeeId;
    const todayStr = new Date().toISOString().split('T')[0];
    const record = repository.attendanceRecords.find(a => a.employeeId === employeeId && a.workDate === todayStr);

    return res.json({
      success: true,
      data: record || { status: 'NOT_CLOCKED_IN', totalHours: 0 },
    });
  }

  getRoster(req, res) {
    const todayStr = new Date().toISOString().split('T')[0];
    const roster = repository.employees.map(emp => {
      const att = repository.attendanceRecords.find(a => a.employeeId === emp.id && a.workDate === todayStr);
      const isWorking = att && att.clockIn && !att.clockOut;

      return {
        employeeId: emp.id,
        name: `${emp.firstName} ${emp.lastName}`,
        email: emp.email,
        designation: emp.designation,
        clockIn: att ? att.clockIn : null,
        clockOut: att ? att.clockOut : null,
        status: isWorking ? 'WORKING' : (att && att.clockOut ? 'COMPLETED' : 'OFFLINE'),
        totalHours: att ? att.totalHours : 0,
      };
    });

    return res.json({
      success: true,
      data: roster,
    });
  }
}

module.exports = new AttendanceController();
