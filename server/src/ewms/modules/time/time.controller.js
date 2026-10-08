/**
 * ZeroCarbonix EWMS — Time Tracking Controller
 * Supports: Start, Pause, Resume, Stop work sessions
 * Computes: Task hours, break time, total office time
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');
const { calculateTimeSessionTotals } = require('../../../../../packages/shared/src/dto');

class TimeController {
  startSession(req, res) {
    const { taskId, sessionType = 'WORK', notes } = req.body;
    const employeeId = req.user.employeeId;

    if (!employeeId) {
      return res.status(400).json({ success: false, error: 'User does not have an associated employee profile' });
    }

    // Stop any active open session for this employee
    const active = repository.workSessions.find(s => s.employeeId === employeeId && !s.stoppedAt);
    if (active) {
      active.stoppedAt = new Date();
      active.durationSeconds = Math.max(0, Math.floor((active.stoppedAt.getTime() - active.startedAt.getTime()) / 1000));
    }

    const sessionId = `ws-${Date.now()}`;
    const session = {
      id: sessionId,
      organizationId: req.organizationId,
      employeeId,
      taskId: taskId || null,
      sessionType,
      startedAt: new Date(),
      stoppedAt: null,
      durationSeconds: 0,
      notes: notes || null,
      createdAt: new Date(),
    };

    repository.workSessions.push(session);

    return res.status(201).json({
      success: true,
      message: `Started ${sessionType.toLowerCase()} session`,
      data: session,
    });
  }

  stopSession(req, res) {
    const employeeId = req.user.employeeId;
    const active = repository.workSessions.find(s => s.employeeId === employeeId && !s.stoppedAt);

    if (!active) {
      return res.status(400).json({ success: false, error: 'No active session running to stop' });
    }

    active.stoppedAt = new Date();
    active.durationSeconds = Math.max(0, Math.floor((active.stoppedAt.getTime() - active.startedAt.getTime()) / 1000));

    // If linked to a task, increment task actualHours
    if (active.taskId && active.sessionType === 'WORK') {
      const task = repository.tasks.find(t => t.id === active.taskId);
      if (task) {
        const addedHours = Math.round((active.durationSeconds / 3600) * 10) / 10;
        task.actualHours = (parseFloat(task.actualHours) || 0) + addedHours;
        task.updatedAt = new Date();
      }
    }

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'TIME_SESSION_STOP',
      entityName: 'work_sessions',
      entityId: active.id,
      afterState: { durationSeconds: active.durationSeconds, taskId: active.taskId },
      ipAddress: req.ip,
    });

    return res.json({
      success: true,
      message: 'Work session stopped and saved',
      data: active,
    });
  }

  getActiveSession(req, res) {
    const employeeId = req.user.employeeId;
    const active = repository.workSessions.find(s => s.employeeId === employeeId && !s.stoppedAt);
    return res.json({
      success: true,
      data: active || null,
    });
  }

  getSummary(req, res) {
    const employeeId = req.query.employeeId || req.user.employeeId;
    const sessions = repository.workSessions.filter(s => s.employeeId === employeeId);

    const totals = calculateTimeSessionTotals(sessions.map(s => ({
      sessionType: s.sessionType,
      durationSeconds: s.stoppedAt
        ? s.durationSeconds
        : Math.max(0, Math.floor((Date.now() - s.startedAt.getTime()) / 1000)),
    })));

    return res.json({
      success: true,
      data: {
        employeeId,
        sessionsCount: sessions.length,
        ...totals,
      },
    });
  }
}

module.exports = new TimeController();
