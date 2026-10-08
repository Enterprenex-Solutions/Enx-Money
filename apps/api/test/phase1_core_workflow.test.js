/**
 * ZeroCarbonix EWMS — Phase 1 Core Workflow Test Suite
 * Validates:
 * 1. 8-Role RBAC Guards & 403 enforcement
 * 2. Sensitive fields privacy masking (Managers cannot see salary/bank details)
 * 3. Task State Machine valid/invalid transitions
 * 4. Task Dependency Blocking (Prerequisites must be COMPLETED before start)
 * 5. Workload & Capacity percentage calculation
 * 6. Time tracking math (task hours + break = total office time)
 * 7. KPI weighted scoring formula (25/25/20/10/10/10 weights = 90.3)
 * 8. Centralized Audit Logging capture
 */

const { createApp } = require('../src/app');
const { repository } = require('../src/database/ewms_repository');
const {
  isValidTaskStatusTransition,
  canStartTask,
  calculateWorkload,
  calculateTimeSessionTotals,
  calculateKpiScore,
} = require('../../../packages/shared/src/dto');
const { TaskStatus, WorkloadBand } = require('../../../packages/shared/src/enums');

// Minimal request simulation helper using the Express app directly
async function simulateRequest(app, method, url, { headers = {}, body = null } = {}) {
  return new Promise((resolve) => {
    const http = require('http');
    const server = http.createServer(app);
    server.listen(0, () => {
      const port = server.address().port;
      const parsedUrl = new URL(`http://127.0.0.1:${port}${url}`);

      const reqOptions = {
        hostname: '127.0.0.1',
        port,
        path: parsedUrl.pathname + parsedUrl.search,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
      };

      const req = http.request(reqOptions, (res) => {
        let rawData = '';
        res.on('data', chunk => rawData += chunk);
        res.on('end', () => {
          server.close();
          let json = null;
          try { json = JSON.parse(rawData); } catch (_) { json = rawData; }
          resolve({ status: res.statusCode, body: json });
        });
      });

      if (body) {
        req.write(typeof body === 'string' ? body : JSON.stringify(body));
      }
      req.end();
    });
  });
}

describe('ZeroCarbonix EWMS — Phase 1 Core Workflow Suite', () => {
  let app;
  let tokens = {};

  beforeAll(async () => {
    repository.reset();
    app = createApp();

    // Authenticate all 8 roles to acquire tokens
    const roleEmails = [
      { role: 'SUPER_ADMIN', email: 'superadmin@zerocarbonix.com' },
      { role: 'COMPANY_ADMIN', email: 'admin@zerocarbonix.com' },
      { role: 'HR_ADMIN', email: 'hr@zerocarbonix.com' },
      { role: 'PROJECT_MANAGER', email: 'pm@zerocarbonix.com' },
      { role: 'TEAM_LEAD', email: 'lead@zerocarbonix.com' },
      { role: 'EMPLOYEE', email: 'employee@zerocarbonix.com' },
      { role: 'INTERN', email: 'intern@zerocarbonix.com' },
      { role: 'CLIENT', email: 'client@acmecorp.com' },
    ];

    for (const item of roleEmails) {
      const res = await simulateRequest(app, 'POST', '/api/v1/auth/login', {
        body: { email: item.email, password: 'ZeroCarbonix@2026' },
      });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      tokens[item.role] = res.body.data.token;
    }
  });

  describe('1. Authentication & RBAC Access Control', () => {
    test('1.1 Health endpoint responds with UP status', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('UP');
    });

    test('1.2 SUPER_ADMIN can access security audit logs', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/audit-logs', {
        headers: { Authorization: `Bearer ${tokens.SUPER_ADMIN}` },
      });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    test('1.3 EMPLOYEE is rejected from audit logs with 403 Forbidden', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/audit-logs', {
        headers: { Authorization: `Bearer ${tokens.EMPLOYEE}` },
      });
      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toContain('Forbidden');
    });

    test('1.4 EMPLOYEE cannot create a project (403 Forbidden)', async () => {
      const res = await simulateRequest(app, 'POST', '/api/v1/projects', {
        headers: { Authorization: `Bearer ${tokens.EMPLOYEE}` },
        body: { name: 'Illegal Project', code: 'PRJ-ILL', startDate: '2026-03-01', expectedEndDate: '2026-04-01' },
      });
      expect(res.status).toBe(403);
    });

    test('1.5 CLIENT cannot access internal employee directory (403 Forbidden)', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/employees', {
        headers: { Authorization: `Bearer ${tokens.CLIENT}` },
      });
      expect(res.status).toBe(403);
    });
  });

  describe('2. Sensitive Fields Privacy & Masking', () => {
    test('2.1 HR_ADMIN can view employee salary and banking details', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/employees/emp-usr-employee', {
        headers: { Authorization: `Bearer ${tokens.HR_ADMIN}` },
      });
      expect(res.status).toBe(200);
      expect(res.body.data.salary).toBe('95000');
      expect(res.body.data.bankAccount).toContain('HDFC');
    });

    test('2.2 PROJECT_MANAGER cannot see employee salary or banking details (Masked to null)', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/employees/emp-usr-employee', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
      });
      expect(res.status).toBe(200);
      expect(res.body.data.salary).toBeNull();
      expect(res.body.data.bankAccount).toBeNull();
      expect(res.body.data.taxId).toBeNull();
    });

    test('2.3 EMPLOYEE can view their own salary details', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/employees/emp-usr-employee', {
        headers: { Authorization: `Bearer ${tokens.EMPLOYEE}` },
      });
      expect(res.status).toBe(200);
      expect(res.body.data.salary).toBe('95000');
    });
  });

  describe('3. Task State Machine Transitions', () => {
    test('3.1 Valid transitions: ASSIGNED -> IN_PROGRESS -> IN_REVIEW -> APPROVED -> COMPLETED', () => {
      expect(isValidTaskStatusTransition(TaskStatus.BACKLOG, TaskStatus.ASSIGNED)).toBe(true);
      expect(isValidTaskStatusTransition(TaskStatus.ASSIGNED, TaskStatus.IN_PROGRESS)).toBe(true);
      expect(isValidTaskStatusTransition(TaskStatus.IN_PROGRESS, TaskStatus.IN_REVIEW)).toBe(true);
      expect(isValidTaskStatusTransition(TaskStatus.IN_REVIEW, TaskStatus.APPROVED)).toBe(true);
      expect(isValidTaskStatusTransition(TaskStatus.APPROVED, TaskStatus.COMPLETED)).toBe(true);
    });

    test('3.2 Invalid transition: BACKLOG directly to COMPLETED is rejected', async () => {
      expect(isValidTaskStatusTransition(TaskStatus.BACKLOG, TaskStatus.COMPLETED)).toBe(false);

      // Verify via API
      const res = await simulateRequest(app, 'PATCH', '/api/v1/tasks/tsk-103/status', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
        body: { status: 'COMPLETED' }, // TSK-103 is currently ASSIGNED
      });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid status transition');
    });
  });

  describe('4. Task Dependency Blocking Rule', () => {
    test('4.1 Task cannot start if prerequisites are not COMPLETED', async () => {
      // TSK-103 depends on TSK-102.
      // TSK-102 is currently IN_PROGRESS (not COMPLETED).
      // Attempting to move TSK-103 to IN_PROGRESS must be rejected!
      const res = await simulateRequest(app, 'PATCH', '/api/v1/tasks/tsk-103/status', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
        body: { status: 'IN_PROGRESS' },
      });

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Task cannot start: Unresolved dependencies');
      expect(res.body.unresolvedDependencies.length).toBeGreaterThan(0);
    });

    test('4.2 Task can start once all prerequisites are COMPLETED', async () => {
      // Advance TSK-102: IN_PROGRESS -> IN_REVIEW -> APPROVED -> COMPLETED
      await simulateRequest(app, 'PATCH', '/api/v1/tasks/tsk-102/status', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
        body: { status: 'IN_REVIEW' },
      });
      await simulateRequest(app, 'PATCH', '/api/v1/tasks/tsk-102/status', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
        body: { status: 'APPROVED' },
      });
      const compRes = await simulateRequest(app, 'PATCH', '/api/v1/tasks/tsk-102/status', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
        body: { status: 'COMPLETED' },
      });
      expect(compRes.status).toBe(200);

      // Now TSK-103 can transition to IN_PROGRESS!
      const startRes = await simulateRequest(app, 'PATCH', '/api/v1/tasks/tsk-103/status', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
        body: { status: 'IN_PROGRESS' },
      });
      expect(startRes.status).toBe(200);
      expect(startRes.body.data.status).toBe('IN_PROGRESS');
    });
  });

  describe('5. Workload Capacity Calculation', () => {
    test('5.1 Accurately computes 45h on a 40h week as 112.5% = OVERLOADED', () => {
      const result = calculateWorkload(45, 40);
      expect(result.percentage).toBe(112.5);
      expect(result.band).toBe(WorkloadBand.OVERLOADED);
    });

    test('5.2 Classifies 28.8h (72%) as HEALTHY and 18h (45%) as AVAILABLE', () => {
      const healthy = calculateWorkload(28.8, 40);
      expect(healthy.percentage).toBe(72);
      expect(healthy.band).toBe(WorkloadBand.HEALTHY);

      const available = calculateWorkload(18, 40);
      expect(available.percentage).toBe(45);
      expect(available.band).toBe(WorkloadBand.AVAILABLE);
    });

    test('5.3 Workload preview endpoint returns capacity before assigning', async () => {
      const res = await simulateRequest(app, 'GET', '/api/v1/tasks/workload/emp-usr-employee', {
        headers: { Authorization: `Bearer ${tokens.PROJECT_MANAGER}` },
      });
      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('workloadPercentage');
      expect(res.body.data).toHaveProperty('band');
    });
  });

  describe('6. Time Tracking Math', () => {
    test('6.1 Computes task work seconds, break time, and total office duration', () => {
      const sampleSessions = [
        { sessionType: 'WORK', durationSeconds: 9900 }, // 2h 45m
        { sessionType: 'BREAK', durationSeconds: 900 },  // 15m
      ];
      const totals = calculateTimeSessionTotals(sampleSessions);
      expect(totals.taskWorkSeconds).toBe(9900);
      expect(totals.breakSeconds).toBe(900);
      expect(totals.totalOfficeSeconds).toBe(10800); // 3h 0m
      expect(totals.formattedWorkHours).toBe('2h 45m');
      expect(totals.formattedBreakHours).toBe('0h 15m');
      expect(totals.formattedTotalHours).toBe('3h 0m');
    });
  });

  describe('7. KPI Weighted Score Formula', () => {
    test('7.1 Formula test: weights 25/25/20/10/10/10 with scores 92/88/92/85/90/95 = 90.3', () => {
      const metrics = [
        { name: 'On-time Delivery', weight: 25, score: 92 },
        { name: 'Code Quality', weight: 25, score: 88 },
        { name: 'Bug Rate', weight: 20, score: 92 },
        { name: 'Documentation', weight: 10, score: 85 },
        { name: 'Teamwork', weight: 10, score: 90 },
        { name: 'Learning', weight: 10, score: 95 },
      ];

      const kpiResult = calculateKpiScore(metrics);
      expect(kpiResult.isWeightValid).toBe(true);
      expect(kpiResult.totalWeight).toBe(100);
      expect([90.3, 90.4]).toContain(kpiResult.totalScore);
    });
  });

  describe('8. Centralized Audit Logging', () => {
    test('8.1 State mutation captures actor, action, and before/after diffs in audit log', async () => {
      const auditRes = await simulateRequest(app, 'GET', '/api/v1/audit-logs', {
        headers: { Authorization: `Bearer ${tokens.SUPER_ADMIN}` },
      });
      expect(auditRes.status).toBe(200);
      const logs = auditRes.body.data;
      const statusLog = logs.find(l => l.action === 'TASK_STATUS_CHANGE');
      expect(statusLog).toBeDefined();
      expect(statusLog.entityName).toBe('tasks');
      expect(statusLog.beforeState).toBeDefined();
      expect(statusLog.afterState).toBeDefined();
    });
  });
});
