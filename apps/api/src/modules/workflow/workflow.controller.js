/**
 * ZeroCarbonix EWMS — Workflow Automation Controller
 * Rule-based automation engine:
 * - IF task overdue -> notify employee -> notify team lead -> flag on manager dashboard
 * - IF workload > 100% -> flag overloaded -> notify manager
 */

const { repository } = require('../../database/ewms_repository');
const { evaluateAutomationRule } = require('../../../../../packages/shared/src/dto');
const auditService = require('../audit/audit.service');

class WorkflowController {
  getRules(req, res) {
    res.json({
      success: true,
      data: repository.automationRules,
    });
  }

  /**
   * Run Automation Cycle:
   * Inspects all active tasks and employee workloads, triggering rules
   */
  runAutomationScan(req, res) {
    const executedActions = [];
    const now = new Date();

    // 1. Scan for Overdue Tasks
    repository.tasks.forEach(t => {
      if (t.status !== 'COMPLETED' && t.status !== 'CANCELLED' && t.deadline && new Date(t.deadline) < now) {
        const assigneeLink = repository.taskAssignees.find(ta => ta.taskId === t.id);
        const emp = assigneeLink ? repository.employees.find(e => e.id === assigneeLink.employeeId) : null;

        const evalResult = evaluateAutomationRule('TASK_OVERDUE', {
          isOverdue: true,
          taskTitle: t.title,
          assigneeName: emp ? `${emp.firstName} ${emp.lastName}` : 'Unassigned',
        });

        if (evalResult.triggered) {
          evalResult.actions.forEach(act => {
            executedActions.push({ taskId: t.id, ...act });
            // Queue in-app notification
            repository.notifications.push({
              id: `notif-auto-${Date.now()}-${Math.random()}`,
              organizationId: req.organizationId,
              recipientId: emp ? emp.userId : 'usr-projmgr',
              title: 'Automated Overdue Escalation',
              message: act.message || `Task ${t.title} is overdue.`,
              read: false,
              createdAt: new Date(),
            });
          });
        }
      }
    });

    // 2. Scan for Overloaded Employees (>100% capacity)
    repository.employees.forEach(emp => {
      const assignedTasks = repository.taskAssignees
        .filter(ta => ta.employeeId === emp.id)
        .map(ta => repository.tasks.find(t => t.id === ta.taskId && t.status !== 'COMPLETED'))
        .filter(Boolean);

      const totalHours = assignedTasks.reduce((sum, t) => sum + (t.estimatedHours || 0), 0);
      const workloadPct = Math.round((totalHours / emp.weeklyCapacityHours) * 100);

      if (workloadPct > 100) {
        const evalResult = evaluateAutomationRule('WORKLOAD_EXCEEDED', {
          workloadPercentage: workloadPct,
          employeeId: emp.id,
          employeeName: `${emp.firstName} ${emp.lastName}`,
        });

        if (evalResult.triggered) {
          evalResult.actions.forEach(act => {
            executedActions.push({ employeeId: emp.id, ...act });
            repository.notifications.push({
              id: `notif-auto-${Date.now()}-${Math.random()}`,
              organizationId: req.organizationId,
              recipientId: 'usr-projmgr',
              title: 'Protective Workload Overload Flag',
              message: act.message || `${emp.firstName} is overloaded at ${workloadPct}%.`,
              read: false,
              createdAt: new Date(),
            });
          });
        }
      }
    });

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user ? req.user.id : 'system-worker',
      action: 'WORKFLOW_AUTOMATION_CYCLE_EXECUTED',
      entityName: 'automation_rules',
      entityId: 'scan-cycle',
      afterState: { actionsCount: executedActions.length },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.json({
      success: true,
      scannedAt: new Date().toISOString(),
      triggeredActionsCount: executedActions.length,
      actions: executedActions,
    });
  }
}

module.exports = new WorkflowController();
