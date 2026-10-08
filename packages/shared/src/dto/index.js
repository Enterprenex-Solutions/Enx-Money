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

module.exports = {
  ALLOWED_TASK_TRANSITIONS,
  isValidTaskStatusTransition,
  canStartTask,
  calculateWorkload,
  calculateTimeSessionTotals,
  calculateKpiScore,
};
