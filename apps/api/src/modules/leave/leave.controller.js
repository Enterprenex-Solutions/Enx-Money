/**
 * ZeroCarbonix EWMS — Leave Management Controller
 * Manages leave allowances, requests, approvals, and balance calculations
 */

const { repository } = require('../../database/ewms_repository');
const { calculateLeaveBalance } = require('../../../../../packages/shared/src/dto');
const auditService = require('../audit/audit.service');

class LeaveController {
  getBalance(req, res) {
    const employeeId = req.params.employeeId || req.user.id;
    const resolvedEmpId = employeeId.startsWith('emp-') ? employeeId : `emp-${employeeId}`;

    const balanceRecord = repository.leaveBalances.find(b => b.employeeId === resolvedEmpId) || {
      casualAllocation: 12,
      sickAllocation: 10,
      earnedAllocation: 15,
      casualUsed: 0,
      sickUsed: 0,
      earnedUsed: 0,
    };

    const userLeaves = repository.leaveRequests.filter(l => l.employeeId === resolvedEmpId);

    const casualCalc = calculateLeaveBalance(balanceRecord.casualAllocation, userLeaves.filter(l => l.leaveType === 'CASUAL'));
    const sickCalc = calculateLeaveBalance(balanceRecord.sickAllocation, userLeaves.filter(l => l.leaveType === 'SICK'));
    const earnedCalc = calculateLeaveBalance(balanceRecord.earnedAllocation, userLeaves.filter(l => l.leaveType === 'EARNED'));

    res.json({
      success: true,
      data: {
        employeeId: resolvedEmpId,
        year: 2026,
        balances: {
          casual: casualCalc,
          sick: sickCalc,
          earned: earnedCalc,
        },
        totalRemainingDays: casualCalc.remainingDays + sickCalc.remainingDays + earnedCalc.remainingDays,
      },
    });
  }

  list(req, res) {
    // Managers/HR see all or team leaves; Employees see their own
    let requests = repository.leaveRequests;
    if (req.user.role === 'EMPLOYEE' || req.user.role === 'INTERN') {
      const selfEmpId = `emp-${req.user.id}`;
      requests = requests.filter(l => l.employeeId === selfEmpId || l.employeeId === req.user.id);
    }

    res.json({
      success: true,
      data: requests,
    });
  }

  apply(req, res) {
    const { leaveType, startDate, endDate, days = 1, reason } = req.body;
    if (!leaveType || !startDate || !endDate || !reason) {
      return res.status(400).json({ error: 'Missing required leave application fields' });
    }

    const selfEmpId = req.user.id.startsWith('emp-') ? req.user.id : `emp-${req.user.id}`;

    const newRequest = {
      id: `lr-${Date.now()}`,
      organizationId: req.organizationId,
      employeeId: selfEmpId,
      leaveType,
      startDate,
      endDate,
      days: Number(days),
      reason,
      status: 'PENDING',
      reviewedBy: null,
      reviewNote: null,
      createdAt: new Date(),
    };

    repository.leaveRequests.push(newRequest);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'LEAVE_REQUESTED',
      entityName: 'leave_requests',
      entityId: newRequest.id,
      afterState: { leaveType, days, startDate },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: newRequest,
    });
  }

  review(req, res) {
    const { id } = req.params;
    const { status, reviewNote } = req.body;

    if (!['APPROVED', 'REJECTED', 'CLARIFICATION_REQUESTED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid leave review status' });
    }

    const request = repository.leaveRequests.find(l => l.id === id);
    if (!request) {
      return res.status(404).json({ error: 'Leave request not found' });
    }

    const beforeState = { ...request };
    request.status = status;
    request.reviewNote = reviewNote || '';
    request.reviewedBy = req.user.id;
    request.updatedAt = new Date();

    // If approved, deduct from balance
    if (status === 'APPROVED') {
      const balance = repository.leaveBalances.find(b => b.employeeId === request.employeeId);
      if (balance) {
        if (request.leaveType === 'CASUAL') balance.casualUsed += request.days;
        if (request.leaveType === 'SICK') balance.sickUsed += request.days;
        if (request.leaveType === 'EARNED') balance.earnedUsed += request.days;
      }
    }

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: `LEAVE_${status}`,
      entityName: 'leave_requests',
      entityId: id,
      beforeState,
      afterState: { status, reviewedBy: req.user.id },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.json({
      success: true,
      data: request,
    });
  }
}

module.exports = new LeaveController();
