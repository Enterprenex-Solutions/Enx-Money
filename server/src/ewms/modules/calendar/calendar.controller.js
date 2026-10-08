/**
 * ZeroCarbonix EWMS — Calendar Controller
 * Aggregates unified company schedule: task deadlines, meetings, approved leaves, and project milestones
 */

const { repository } = require('../../database/ewms_repository');

class CalendarController {
  getEvents(req, res) {
    const events = [];

    // 1. Task Deadlines
    repository.tasks.forEach(t => {
      if (t.deadline) {
        events.push({
          id: `cal-tsk-${t.id}`,
          type: 'TASK_DEADLINE',
          title: `Task Deadline: ${t.title}`,
          date: new Date(t.deadline).toISOString(),
          status: t.status,
          priority: t.priority,
          entityId: t.id,
        });
      }
    });

    // 2. Scheduled Meetings
    repository.meetings.forEach(m => {
      events.push({
        id: `cal-mtg-${m.id}`,
        type: 'MEETING',
        title: `Meeting: ${m.title}`,
        date: new Date(m.startTime).toISOString(),
        endDate: new Date(m.endTime).toISOString(),
        entityId: m.id,
      });
    });

    // 3. Approved Leaves
    repository.leaveRequests.filter(l => l.status === 'APPROVED').forEach(l => {
      events.push({
        id: `cal-lv-${l.id}`,
        type: 'LEAVE',
        title: `On Leave: ${l.leaveType} (${l.days} days)`,
        date: new Date(l.startDate).toISOString(),
        endDate: new Date(l.endDate).toISOString(),
        entityId: l.id,
      });
    });

    res.json({
      success: true,
      data: events,
    });
  }
}

module.exports = new CalendarController();
