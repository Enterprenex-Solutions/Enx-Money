/**
 * ZeroCarbonix EWMS — Reporting Controller
 * Generates Employee & Manager Dashboards with Workload & Capacity signals
 */

const { repository } = require('../../database/ewms_repository');
const { calculateWorkload } = require('../../shared/dto');

class ReportingController {
  getEmployeeDashboard(req, res) {
    const employeeId = req.user.employeeId;
    const todayStr = new Date().toISOString().split('T')[0];

    // Attendance
    const att = repository.attendanceRecords.find(a => a.employeeId === employeeId && a.workDate === todayStr);

    // Tasks
    const assignedTaskIds = repository.taskAssignees.filter(ta => ta.employeeId === employeeId).map(ta => ta.taskId);
    const myTasks = repository.tasks.filter(t => assignedTaskIds.includes(t.id));

    const totalTasks = myTasks.length;
    const completedTasks = myTasks.filter(t => t.status === 'COMPLETED').length;
    const pendingTasks = myTasks.filter(t => !['COMPLETED', 'CANCELLED'].includes(t.status)).length;
    const blockedTasks = myTasks.filter(t => t.status === 'BLOCKED').length;

    // Time Today
    const todaySessions = repository.workSessions.filter(s => s.employeeId === employeeId && s.createdAt >= new Date(todayStr));
    const workSeconds = todaySessions.filter(s => s.sessionType === 'WORK').reduce((sum, s) => sum + (s.durationSeconds || 0), 0);

    const hrs = Math.floor(workSeconds / 3600);
    const mins = Math.floor((workSeconds % 3600) / 60);

    return res.json({
      success: true,
      data: {
        workingTimeToday: `${hrs}h ${mins}m`,
        attendance: {
          status: att ? att.status : 'NOT_CLOCKED_IN',
          clockIn: att ? att.clockIn : null,
          isClockedIn: !!(att && att.clockIn && !att.clockOut),
        },
        tasks: {
          total: totalTasks,
          completed: completedTasks,
          pending: pendingTasks,
          blocked: blockedTasks,
        },
        kpiSignal: {
          score: 88,
          taskCompletionRate: totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 100,
          qualityScore: 92,
          notice: 'Management signal only; human review applies.',
        },
      },
    });
  }

  getManagerDashboard(req, res) {
    const teamMembers = repository.employees.filter(e => e.organizationId === req.organizationId);
    const todayStr = new Date().toISOString().split('T')[0];

    // Attendance breakdown
    let activeToday = 0;
    let onLeave = 0;
    let offline = 0;

    teamMembers.forEach(m => {
      const att = repository.attendanceRecords.find(a => a.employeeId === m.id && a.workDate === todayStr);
      if (att && att.clockIn && !att.clockOut) {
        activeToday++;
      } else if (att && att.status === 'ON_LEAVE') {
        onLeave++;
      } else {
        offline++;
      }
    });

    // Tasks breakdown
    const allTasks = repository.tasks.filter(t => t.organizationId === req.organizationId);
    const completed = allTasks.filter(t => t.status === 'COMPLETED').length;
    const inProgress = allTasks.filter(t => t.status === 'IN_PROGRESS').length;
    const blocked = allTasks.filter(t => t.status === 'BLOCKED').length;
    const now = new Date();
    const overdue = allTasks.filter(t => t.status !== 'COMPLETED' && new Date(t.dueDate) < now).length;

    // Workload breakdown per employee
    const workloadDistribution = teamMembers.map(emp => {
      const empTaskIds = repository.taskAssignees.filter(ta => ta.employeeId === emp.id).map(ta => ta.taskId);
      const openTasks = repository.tasks.filter(t => empTaskIds.includes(t.id) && t.status !== 'COMPLETED');
      const estimatedHours = openTasks.reduce((sum, t) => sum + (parseFloat(t.estimatedHours) || 0), 0);
      const calc = calculateWorkload(estimatedHours, 40.0);

      return {
        employeeId: emp.id,
        name: `${emp.firstName} ${emp.lastName}`,
        designation: emp.designation,
        assignedHours: calc.assignedHours,
        workloadPercentage: calc.percentage,
        statusBand: calc.band,
      };
    });

    const bandCounts = {
      AVAILABLE: workloadDistribution.filter(w => w.statusBand === 'AVAILABLE').length,
      HEALTHY: workloadDistribution.filter(w => w.statusBand === 'HEALTHY').length,
      HIGH: workloadDistribution.filter(w => w.statusBand === 'HIGH').length,
      OVERLOADED: workloadDistribution.filter(w => w.statusBand === 'OVERLOADED').length,
    };

    return res.json({
      success: true,
      data: {
        teamSize: teamMembers.length,
        attendance: {
          activeToday,
          onLeave,
          offline,
        },
        tasks: {
          completed,
          inProgress,
          overdue,
          blocked,
          total: allTasks.length,
        },
        averageKpi: 89.4,
        workloadSummary: bandCounts,
        workloadDetails: workloadDistribution,
      },
    });
  }
}

module.exports = new ReportingController();
