/**
 * ZeroCarbonix EWMS — Meetings & Action Items Controller
 * Manages meetings, participants, and converts meeting action items into real Tasks
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class MeetingsController {
  list(req, res) {
    const meetings = repository.meetings.filter(m => m.organizationId === req.organizationId);
    const enriched = meetings.map(m => {
      const items = repository.meetingActionItems.filter(act => act.meetingId === m.id);
      return {
        ...m,
        actionItems: items,
      };
    });

    res.json({
      success: true,
      data: enriched,
    });
  }

  create(req, res) {
    const { title, agenda, startTime, endTime, projectId, participantIds = [] } = req.body;
    if (!title || !startTime) {
      return res.status(400).json({ error: 'Title and startTime are required' });
    }

    const meeting = {
      id: `mtg-${Date.now()}`,
      organizationId: req.organizationId,
      title,
      agenda: agenda || '',
      startTime: new Date(startTime),
      endTime: endTime ? new Date(endTime) : new Date(new Date(startTime).getTime() + 3600000),
      projectId: projectId || null,
      organizerId: req.user.id,
      status: 'SCHEDULED',
      participantIds,
      createdAt: new Date(),
    };

    repository.meetings.push(meeting);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'MEETING_SCHEDULED',
      entityName: 'meetings',
      entityId: meeting.id,
      afterState: { title, startTime },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: meeting,
    });
  }

  addActionItem(req, res) {
    const { id } = req.params;
    const { description, assigneeId, dueDate } = req.body;
    if (!description) {
      return res.status(400).json({ error: 'Description is required' });
    }

    const actionItem = {
      id: `act-${Date.now()}`,
      meetingId: id,
      description,
      assigneeId: assigneeId || null,
      dueDate: dueDate || null,
      isConvertedToTask: false,
      taskId: null,
    };

    repository.meetingActionItems.push(actionItem);

    res.status(201).json({
      success: true,
      data: actionItem,
    });
  }

  /**
   * Action Item Conversion:
   * Converts a meeting action item directly into a real project task
   */
  convertActionItemToTask(req, res) {
    const { id, itemId } = req.params;
    const { projectId, priority = 'MEDIUM', estimatedHours = 8 } = req.body;

    const actionItem = repository.meetingActionItems.find(a => a.id === itemId && a.meetingId === id);
    if (!actionItem) {
      return res.status(404).json({ error: 'Action item not found for this meeting' });
    }

    if (actionItem.isConvertedToTask) {
      return res.status(400).json({ error: 'Action item has already been converted to a task', taskId: actionItem.taskId });
    }

    const targetProjectId = projectId || 'prj-cloud-core';
    const taskId = `tsk-${Date.now()}`;

    const newTask = {
      id: taskId,
      organizationId: req.organizationId,
      projectId: targetProjectId,
      code: `TSK-${Math.floor(100 + Math.random() * 900)}`,
      title: actionItem.description,
      description: `Converted from Meeting Action Item (Meeting: ${id})`,
      status: 'ASSIGNED',
      priority,
      estimatedHours: Number(estimatedHours),
      actualHours: 0,
      deadline: actionItem.dueDate ? new Date(actionItem.dueDate) : new Date(Date.now() + 7 * 86400000),
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    repository.tasks.push(newTask);

    if (actionItem.assigneeId) {
      repository.taskAssignees.push({
        id: `ta-${Date.now()}`,
        taskId,
        employeeId: actionItem.assigneeId,
        assignedAt: new Date(),
        acceptedAt: null,
      });
    }

    // Mark action item as converted
    actionItem.isConvertedToTask = true;
    actionItem.taskId = taskId;

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'ACTION_ITEM_CONVERTED_TO_TASK',
      entityName: 'tasks',
      entityId: taskId,
      afterState: { actionItemId: itemId, title: newTask.title },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: {
        actionItem,
        task: newTask,
      },
    });
  }
}

module.exports = new MeetingsController();
