/**
 * ZeroCarbonix EWMS — Tasks Controller
 * Enforces:
 * - Valid State Transitions (BACKLOG → ASSIGNED → IN_PROGRESS → BLOCKED → IN_REVIEW → CHANGES_REQUIRED → APPROVED → COMPLETED → CANCELLED)
 * - Task Dependency Blocking (Prerequisites must be COMPLETED before moving to IN_PROGRESS)
 * - Capacity preview before assignment (Workload calculation)
 * - Full audit logging of state changes with before/after state capture
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');
const {
  ALLOWED_TASK_TRANSITIONS,
  isValidTaskStatusTransition,
  canStartTask,
  calculateWorkload,
} = require('../../shared/dto');

class TasksController {
  list(req, res) {
    const { projectId, status, assignedToId } = req.query;
    let list = repository.tasks.filter(t => t.organizationId === req.organizationId);

    // If client, ensure they can only view tasks of their assigned projects
    if (req.user.role === 'CLIENT') {
      const clientProjects = repository.projects.filter(p => p.clientId === req.user.id).map(p => p.id);
      list = list.filter(t => clientProjects.includes(t.projectId));
    }

    if (projectId) list = list.filter(t => t.projectId === projectId);
    if (status) list = list.filter(t => t.status === status);

    if (assignedToId) {
      const taskIds = repository.taskAssignees.filter(ta => ta.employeeId === assignedToId).map(ta => ta.taskId);
      list = list.filter(t => taskIds.includes(t.id));
    }

    const tasksWithDetails = list.map(t => {
      const project = repository.projects.find(p => p.id === t.projectId);
      const assignees = repository.taskAssignees
        .filter(ta => ta.taskId === t.id)
        .map(ta => {
          const emp = repository.employees.find(e => e.id === ta.employeeId);
          return {
            employeeId: ta.employeeId,
            name: emp ? `${emp.firstName} ${emp.lastName}` : 'Unassigned',
            assignedAt: ta.assignedAt,
            acceptedAt: ta.acceptedAt,
          };
        });

      const deps = repository.taskDependencies
        .filter(td => td.taskId === t.id)
        .map(td => {
          const parent = repository.tasks.find(pt => pt.id === td.dependsOnTaskId);
          return {
            dependsOnTaskId: td.dependsOnTaskId,
            title: parent ? parent.title : 'Dependency',
            status: parent ? parent.status : 'UNKNOWN',
          };
        });

      return {
        ...t,
        projectName: project ? project.name : 'Unknown',
        assignees,
        dependencies: deps,
      };
    });

    return res.json({
      success: true,
      data: tasksWithDetails,
    });
  }

  getById(req, res) {
    const { id } = req.params;
    const task = repository.tasks.find(t => t.id === id && t.organizationId === req.organizationId);

    if (!task) {
      return res.status(404).json({ success: false, error: 'Task not found' });
    }

    const project = repository.projects.find(p => p.id === task.projectId);
    if (req.user.role === 'CLIENT' && project && project.clientId !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Forbidden: Access to this task is restricted' });
    }

    const assignees = repository.taskAssignees
      .filter(ta => ta.taskId === task.id)
      .map(ta => {
        const emp = repository.employees.find(e => e.id === ta.employeeId);
        return {
          employeeId: ta.employeeId,
          name: emp ? `${emp.firstName} ${emp.lastName}` : 'Unassigned',
          acceptedAt: ta.acceptedAt,
        };
      });

    const deps = repository.taskDependencies
      .filter(td => td.taskId === task.id)
      .map(td => {
        const parent = repository.tasks.find(pt => pt.id === td.dependsOnTaskId);
        return {
          dependsOnTaskId: td.dependsOnTaskId,
          title: parent ? parent.title : 'Dependency',
          status: parent ? parent.status : 'UNKNOWN',
        };
      });

    return res.json({
      success: true,
      data: {
        ...task,
        projectName: project ? project.name : 'Unknown',
        assignees,
        dependencies: deps,
      },
    });
  }

  create(req, res) {
    const {
      projectId,
      title,
      description,
      priority = 'MEDIUM',
      estimatedHours = 8.0,
      dueDate,
      assignedToId,
      reviewerId,
      dependencies = [],
      acceptanceCriteria,
    } = req.body;

    if (!projectId || !title || !dueDate) {
      return res.status(400).json({
        success: false,
        error: 'Project ID, title, and due date are required',
      });
    }

    const project = repository.projects.find(p => p.id === projectId && p.organizationId === req.organizationId);
    if (!project) {
      return res.status(404).json({ success: false, error: 'Project not found' });
    }

    const taskId = `tsk-${Date.now()}`;
    const taskNumber = `TSK-${Math.floor(100 + Math.random() * 900)}`;

    const task = {
      id: taskId,
      organizationId: req.organizationId,
      projectId,
      taskNumber,
      title,
      description: description || null,
      priority,
      status: assignedToId ? 'ASSIGNED' : 'BACKLOG',
      createdById: req.user.employeeId,
      reviewerId: reviewerId || null,
      startDate: new Date(),
      dueDate: new Date(dueDate),
      estimatedHours: parseFloat(estimatedHours),
      actualHours: 0.0,
      acceptanceCriteria: acceptanceCriteria || null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    repository.tasks.push(task);

    if (assignedToId) {
      repository.taskAssignees.push({
        id: `ta-${Date.now()}`,
        taskId,
        employeeId: assignedToId,
        assignedAt: new Date(),
        acceptedAt: null,
      });
    }

    if (Array.isArray(dependencies)) {
      dependencies.forEach((depId, idx) => {
        repository.taskDependencies.push({
          id: `td-${Date.now()}-${idx}`,
          taskId,
          dependsOnTaskId: depId,
          dependencyType: 'BLOCKS',
        });
      });
    }

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'TASK_CREATE',
      entityName: 'tasks',
      entityId: taskId,
      afterState: { taskNumber, title, status: task.status, assignedToId },
      ipAddress: req.ip,
    });

    return res.status(201).json({
      success: true,
      message: 'Task created successfully',
      data: task,
    });
  }

  assign(req, res) {
    const { id } = req.params;
    const { employeeId } = req.body;

    const task = repository.tasks.find(t => t.id === id && t.organizationId === req.organizationId);
    if (!task) return res.status(404).json({ success: false, error: 'Task not found' });

    const employee = repository.employees.find(e => e.id === employeeId && e.organizationId === req.organizationId);
    if (!employee) return res.status(404).json({ success: false, error: 'Employee not found' });

    // Check if already assigned
    const existing = repository.taskAssignees.find(ta => ta.taskId === id && ta.employeeId === employeeId);
    if (!existing) {
      repository.taskAssignees.push({
        id: `ta-${Date.now()}`,
        taskId: id,
        employeeId,
        assignedAt: new Date(),
        acceptedAt: null,
      });
    }

    const previousStatus = task.status;
    if (task.status === 'BACKLOG') {
      task.status = 'ASSIGNED';
      task.updatedAt = new Date();
    }

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'TASK_ASSIGN',
      entityName: 'tasks',
      entityId: id,
      beforeState: { status: previousStatus },
      afterState: { status: task.status, employeeId },
      ipAddress: req.ip,
    });

    return res.json({
      success: true,
      message: `Task assigned to ${employee.firstName} ${employee.lastName}`,
      data: task,
    });
  }

  accept(req, res) {
    const { id } = req.params;
    const assignment = repository.taskAssignees.find(ta => ta.taskId === id && ta.employeeId === req.user.employeeId);
    if (!assignment) {
      return res.status(404).json({ success: false, error: 'No active task assignment found for your user' });
    }

    assignment.acceptedAt = new Date();
    return res.json({
      success: true,
      message: 'Task assignment accepted',
      data: assignment,
    });
  }

  updateStatus(req, res) {
    const { id } = req.params;
    const { status: targetStatus, comment } = req.body;

    const task = repository.tasks.find(t => t.id === id && t.organizationId === req.organizationId);
    if (!task) return res.status(404).json({ success: false, error: 'Task not found' });

    const currentStatus = task.status;

    // 1. Strict State Transition Validation
    if (!isValidTaskStatusTransition(currentStatus, targetStatus)) {
      return res.status(400).json({
        success: false,
        error: `Invalid status transition: Cannot transition from '${currentStatus}' to '${targetStatus}'`,
        allowedTransitions: ALLOWED_TASK_TRANSITIONS[currentStatus] || [],
      });
    }

    // 2. Strict Dependency Blocking Rule
    // A task cannot transition to IN_PROGRESS until all dependent tasks are COMPLETED
    if (targetStatus === 'IN_PROGRESS') {
      const deps = repository.taskDependencies.filter(td => td.taskId === id);
      const parentTasks = deps.map(d => {
        const pt = repository.tasks.find(t => t.id === d.dependsOnTaskId);
        return {
          status: pt ? pt.status : 'UNKNOWN',
          title: pt ? pt.title : 'Prerequisite Task',
        };
      });

      const depCheck = canStartTask(parentTasks);
      if (!depCheck.canStart) {
        return res.status(400).json({
          success: false,
          error: `Task cannot start: Unresolved dependencies must be COMPLETED first.`,
          unresolvedDependencies: depCheck.unresolvedDependencies,
        });
      }
    }

    task.status = targetStatus;
    task.updatedAt = new Date();

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'TASK_STATUS_CHANGE',
      entityName: 'tasks',
      entityId: id,
      beforeState: { status: currentStatus },
      afterState: { status: targetStatus, comment: comment || null },
      ipAddress: req.ip,
    });

    return res.json({
      success: true,
      message: `Task status updated from '${currentStatus}' to '${targetStatus}'`,
      data: task,
    });
  }

  checkWorkload(req, res) {
    const { employeeId } = req.params;
    const assignedTasks = repository.taskAssignees
      .filter(ta => ta.employeeId === employeeId)
      .map(ta => repository.tasks.find(t => t.id === ta.taskId))
      .filter(t => t && t.status !== 'COMPLETED' && t.status !== 'CANCELLED');

    const totalEstimatedHours = assignedTasks.reduce((sum, t) => sum + (parseFloat(t.estimatedHours) || 0), 0);
    const capacityHours = 40.0;
    const workloadResult = calculateWorkload(totalEstimatedHours, capacityHours);

    return res.json({
      success: true,
      data: {
        employeeId,
        openTasksCount: assignedTasks.length,
        workloadPercentage: workloadResult.percentage,
        ...workloadResult,
      },
    });
  }
}

module.exports = new TasksController();
