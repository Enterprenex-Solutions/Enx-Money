/**
 * ZeroCarbonix EWMS — Domain Rules, Logic and Calculations (CommonJS)
 */

const { TaskStatus, WorkloadBand } = require('../enums');

/**
 * Valid Task Status Transitions Map
 * BACKLOG → ASSIGNED → IN_PROGRESS → BLOCKED → IN_REVIEW → CHANGES_REQUIRED → APPROVED → COMPLETED → CANCELLED
 */
const ALLOWED_TASK_TRANSITIONS = {
  [TaskStatus.BACKLOG]: [TaskStatus.ASSIGNED, TaskStatus.CANCELLED],
  [TaskStatus.ASSIGNED]: [TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
  [TaskStatus.IN_PROGRESS]: [TaskStatus.BLOCKED, TaskStatus.IN_REVIEW, TaskStatus.CANCELLED],
  [TaskStatus.BLOCKED]: [TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
  [TaskStatus.IN_REVIEW]: [TaskStatus.CHANGES_REQUIRED, TaskStatus.APPROVED, TaskStatus.CANCELLED],
  [TaskStatus.CHANGES_REQUIRED]: [TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
  [TaskStatus.APPROVED]: [TaskStatus.COMPLETED, TaskStatus.CANCELLED],
  [TaskStatus.COMPLETED]: [], // Terminal state
  [TaskStatus.CANCELLED]: [], // Terminal state
};

/**
 * Validates whether a requested task status transition is permitted.
 */
function isValidTaskStatusTransition(current, target) {
  if (current === target) return true;
  const allowed = ALLOWED_TASK_TRANSITIONS[current] || [];
  return allowed.includes(target);
}

/**
 * Task Dependency Rule:
 * A task cannot start (move to IN_PROGRESS) until all its dependent tasks are COMPLETED.
 */
function canStartTask(dependencies = []) {
  const unresolved = dependencies
    .filter(d => d.status !== TaskStatus.COMPLETED)
    .map(d => d.title || 'Uncompleted prerequisite');

  return {
    canStart: unresolved.length === 0,
    unresolvedDependencies: unresolved,
  };
}

/**
 * Workload Calculation:
 * Weekly capacity vs assigned estimated hours.
 * e.g. 45h assigned on a 40h week = 112.5% = OVERLOADED.
 */
function calculateWorkload(assignedHours, capacityHours = 40) {
  const capacity = capacityHours > 0 ? capacityHours : 40;
  const rawPercentage = (assignedHours / capacity) * 100;
  const percentage = Math.round(rawPercentage * 10) / 10;

  let band = WorkloadBand.AVAILABLE;
  if (percentage > 100) {
    band = WorkloadBand.OVERLOADED;
  } else if (percentage >= 91) {
    band = WorkloadBand.HIGH;
  } else if (percentage >= 70) {
    band = WorkloadBand.HEALTHY;
  } else {
    band = WorkloadBand.AVAILABLE;
  }

  return {
    assignedHours,
    capacityHours: capacity,
    percentage,
    band,
  };
}

/**
 * Task & Work Session Time Totals:
 * Aggregates work time, break time, and total office time.
 */
function calculateTimeSessionTotals(sessions = []) {
  let taskWorkSeconds = 0;
  let breakSeconds = 0;

  for (const s of sessions) {
    if (s.sessionType === 'WORK') {
      taskWorkSeconds += s.durationSeconds;
    } else if (s.sessionType === 'BREAK') {
      breakSeconds += s.durationSeconds;
    }
  }

  const totalOfficeSeconds = taskWorkSeconds + breakSeconds;

  const formatHrsMins = (secs) => {
    const hrs = Math.floor(secs / 3600);
    const mins = Math.floor((secs % 3600) / 60);
    return `${hrs}h ${mins}m`;
  };

  return {
    taskWorkSeconds,
    breakSeconds,
    totalOfficeSeconds,
    formattedWorkHours: formatHrsMins(taskWorkSeconds),
    formattedBreakHours: formatHrsMins(breakSeconds),
    formattedTotalHours: formatHrsMins(totalOfficeSeconds),
  };
}

/**
 * KPI Weighted Scoring Formula:
 * Final KPI = Σ (KPI score × weight).
 * Weights must total 100%.
 * Example: weights 25/25/20/10/10/10 with scores 92/88/92/85/90/95 = 90.3
 */
function calculateKpiScore(metrics = []) {
  let totalWeight = 0;
  let weightedSum = 0;

  for (const m of metrics) {
    totalWeight += m.weight;
    weightedSum += (m.score * (m.weight / 100));
  }

  const isWeightValid = Math.round(totalWeight) === 100;
  const totalScore = Math.round(weightedSum * 10) / 10;

  return {
    totalScore,
    totalWeight,
    isWeightValid,
  };
}

/**
 * Role KPI Template Specifications
 */
const ROLE_KPI_TEMPLATES = {
  DEVELOPER: [
    { metric: 'Delivery', weight: 25 },
    { metric: 'Code Quality', weight: 25 },
    { metric: 'Bug Rate', weight: 15 },
    { metric: 'Technical Contribution', weight: 15 },
    { metric: 'Documentation', weight: 10 },
    { metric: 'Team Collaboration', weight: 10 },
  ],
  QA: [
    { metric: 'Test Coverage', weight: 25 },
    { metric: 'Defect Detection', weight: 25 },
    { metric: 'Defect Escape Rate', weight: 20 },
    { metric: 'Automation', weight: 15 },
    { metric: 'Delivery', weight: 10 },
    { metric: 'Documentation', weight: 5 },
  ],
  DESIGNER: [
    { metric: 'Visual Quality', weight: 30 },
    { metric: 'User Research', weight: 20 },
    { metric: 'Design System', weight: 20 },
    { metric: 'Delivery', weight: 15 },
    { metric: 'Cross-Functional Collab', weight: 15 },
  ],
  DEVOPS: [
    { metric: 'Uptime & Reliability', weight: 30 },
    { metric: 'CI/CD Pipeline', weight: 25 },
    { metric: 'Security & Compliance', weight: 20 },
    { metric: 'Incident MTTR', weight: 15 },
    { metric: 'Automation', weight: 10 },
  ],
  INTERN: [
    { metric: 'Learning Velocity', weight: 30 },
    { metric: 'Task Execution', weight: 25 },
    { metric: 'Code Quality', weight: 20 },
    { metric: 'Curiosity & Initiative', weight: 15 },
    { metric: 'Communication', weight: 10 },
  ],
};

/**
 * Leave Balance Calculation:
 * Deducts approved and pending leave days from allocation.
 */
function calculateLeaveBalance(allocation = 24, leaves = []) {
  const approvedDays = leaves
    .filter(l => l.status === 'APPROVED')
    .reduce((sum, l) => sum + (l.days || 1), 0);

  const pendingDays = leaves
    .filter(l => l.status === 'PENDING')
    .reduce((sum, l) => sum + (l.days || 1), 0);

  const remainingDays = Math.max(0, allocation - approvedDays);

  return {
    allocation,
    approvedDays,
    pendingDays,
    remainingDays,
  };
}

/**
 * OKR Objective Progress Roll-up:
 * Calculates objective progress as the average of its key results.
 */
function calculateOkrProgress(keyResults = []) {
  if (!keyResults || keyResults.length === 0) return 0;
  const total = keyResults.reduce((acc, kr) => {
    const cur = kr.currentValue ?? 0;
    const tgt = kr.targetValue > 0 ? kr.targetValue : 100;
    const pct = Math.min(100, Math.max(0, (cur / tgt) * 100));
    return acc + pct;
  }, 0);
  return Math.round((total / keyResults.length) * 10) / 10;
}

/**
 * Project Health Score Calculation:
 * Factors: Completion rate (60%), Overdue penalty (20%), Open risks penalty (20%).
 */
function calculateProjectHealthScore({ totalTasks = 0, completedTasks = 0, overdueTasks = 0, openRisks = 0 }) {
  if (totalTasks === 0) return 100;
  const completionRate = (completedTasks / totalTasks) * 60;
  const overduePenalty = Math.min(25, (overdueTasks / totalTasks) * 25);
  const riskPenalty = Math.min(20, openRisks * 5);
  const score = Math.max(0, Math.min(100, Math.round(completionRate + (40 - overduePenalty - riskPenalty))));
  return score;
}

/**
 * Workflow Automation Rule Evaluation:
 * Checks trigger conditions (TASK_OVERDUE, WORKLOAD_EXCEEDED) and returns actions.
 */
function evaluateAutomationRule(trigger, context = {}) {
  const actions = [];
  if (trigger === 'TASK_OVERDUE' && context.isOverdue) {
    actions.push({ type: 'NOTIFY_EMPLOYEE', message: `Task "${context.taskTitle}" is overdue` });
    actions.push({ type: 'NOTIFY_LEAD', message: `Task "${context.taskTitle}" assigned to ${context.assigneeName} is overdue` });
    actions.push({ type: 'ESCALATE_TO_MANAGER', severity: 'HIGH' });
  }

  if (trigger === 'WORKLOAD_EXCEEDED' && context.workloadPercentage > 100) {
    actions.push({ type: 'FLAG_OVERLOADED', employeeId: context.employeeId, workload: context.workloadPercentage });
    actions.push({ type: 'NOTIFY_MANAGER', message: `${context.employeeName} is overloaded (${context.workloadPercentage}%)` });
  }

  return {
    triggered: actions.length > 0,
    actions,
  };
}

module.exports = {
  ALLOWED_TASK_TRANSITIONS,
  isValidTaskStatusTransition,
  canStartTask,
  calculateWorkload,
  calculateTimeSessionTotals,
  calculateKpiScore,
  ROLE_KPI_TEMPLATES,
  calculateLeaveBalance,
  calculateOkrProgress,
  calculateProjectHealthScore,
  evaluateAutomationRule,
};
