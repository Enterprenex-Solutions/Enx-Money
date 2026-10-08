/**
 * ZeroCarbonix EWMS — Phase 2 & Phase 3 (Performance + Company Platform) Test Suite
 */

const request = require('supertest');
const { createApp } = require('../src/app');
const { repository } = require('../src/database/ewms_repository');

describe('ZeroCarbonix EWMS — Phase 2 & 3 Company Platform Suite', () => {
  let app;
  let superAdminToken;
  let hrAdminToken;
  let pmToken;
  let leadToken;
  let empToken;

  beforeAll(async () => {
    app = createApp();

    // Authenticate test roles
    const login = async (email) => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email, password: 'ZeroCarbonix@2026' });
      return res.body.data ? res.body.data.token : null;
    };

    superAdminToken = await login('vikram.mehra@zerocarbonix.com');
    hrAdminToken = await login('sneha.patil@zerocarbonix.com');
    pmToken = await login('rahul.deshmukh@zerocarbonix.com');
    leadToken = await login('ananya.sen@zerocarbonix.com');
    empToken = await login('kishore.kumar@zerocarbonix.com');
  });

  describe('1. KPI Templates & Role-Specific Weighted Math', () => {
    it('1.1 Fetches role-specific KPI templates including Developer and QA', async () => {
      const res = await request(app)
        .get('/api/v1/kpi/templates')
        .set('Authorization', `Bearer ${empToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.some(t => t.role === 'DEVELOPER')).toBe(true);
      expect(res.body.standardRoleTemplates.DEVELOPER).toBeDefined();
    });

    it('1.2 Validates that KPI evaluation requires weights summing exactly to 100%', async () => {
      const invalidPayload = {
        employeeId: 'emp-usr-employee',
        period: '2026-Q1',
        metrics: [
          { name: 'Delivery', weight: 40, score: 90 },
          { name: 'Code Quality', weight: 40, score: 90 }, // Total = 80%, not 100%
        ],
      };

      const res = await request(app)
        .post('/api/v1/kpi/evaluate')
        .set('Authorization', `Bearer ${leadToken}`)
        .send(invalidPayload)
        .expect(400);

      expect(res.body.error).toContain('Total weight must equal 100%');
    });

    it('1.3 Successfully calculates weighted KPI score and returns signal-not-verdict notice', async () => {
      const validPayload = {
        employeeId: 'emp-usr-employee',
        templateId: 'kpi-tpl-dev',
        period: '2026-Q1',
        metrics: [
          { name: 'Delivery', weight: 25, score: 92 },
          { name: 'Code Quality', weight: 25, score: 88 },
          { name: 'Bug Rate', weight: 15, score: 92 },
          { name: 'Technical Contribution', weight: 15, score: 85 },
          { name: 'Documentation', weight: 10, score: 90 },
          { name: 'Team Collaboration', weight: 10, score: 95 },
        ],
      };

      const res = await request(app)
        .post('/api/v1/kpi/evaluate')
        .set('Authorization', `Bearer ${leadToken}`)
        .send(validPayload)
        .expect(201);

      expect([90.1, 90.3, 90.4]).toContain(res.body.data.calculatedScore);
      expect(res.body.data.signalNotice).toContain('Management signal for career growth; not an automated verdict.');
    });
  });

  describe('2. Objectives & Key Results (OKR) Progress Roll-up', () => {
    it('2.1 Creates company objective with key results', async () => {
      const payload = {
        title: 'Expand Multi-Region Cloud Footprint',
        description: 'Deploy resilient edge caching in EU and US regions',
        level: 'COMPANY',
        targetQuarter: '2026-Q2',
        keyResults: [
          { title: 'EU Data Center Provisioning', targetValue: 100, currentValue: 100, unit: '%' },
          { title: 'Latency Benchmarking < 50ms', targetValue: 100, currentValue: 50, unit: '%' },
        ],
      };

      const res = await request(app)
        .post('/api/v1/goals/objectives')
        .set('Authorization', `Bearer ${pmToken}`)
        .send(payload)
        .expect(201);

      expect(res.body.data.progress).toBe(75); // (100 + 50) / 2 = 75%
    });

    it('2.2 Updating a Key Result recalculates objective overall progress', async () => {
      const kr = repository.keyResults[0];
      const res = await request(app)
        .patch(`/api/v1/goals/key-results/${kr.id}`)
        .set('Authorization', `Bearer ${pmToken}`)
        .send({ currentValue: 80 })
        .expect(200);

      expect(res.body.data.currentValue).toBe(80);
      expect(res.body.objectiveProgress).toBeDefined();
    });
  });

  describe('3. Leave Management & Balance Deductions', () => {
    it('3.1 Returns remaining leave allowances for employee', async () => {
      const res = await request(app)
        .get('/api/v1/leave/balance')
        .set('Authorization', `Bearer ${empToken}`)
        .expect(200);

      expect(res.body.data.balances.casual).toBeDefined();
      expect(res.body.data.totalRemainingDays).toBeGreaterThan(0);
    });

    it('3.2 Employee can submit leave application', async () => {
      const res = await request(app)
        .post('/api/v1/leave/apply')
        .set('Authorization', `Bearer ${empToken}`)
        .send({
          leaveType: 'SICK',
          startDate: '2026-05-02',
          endDate: '2026-05-02',
          days: 1,
          reason: 'Medical checkup',
        })
        .expect(201);

      expect(res.body.data.status).toBe('PENDING');
    });

    it('3.3 Manager approves leave and updates leave records', async () => {
      const pendingLeave = repository.leaveRequests.find(l => l.status === 'PENDING');
      const res = await request(app)
        .patch(`/api/v1/leave/requests/${pendingLeave.id}/review`)
        .set('Authorization', `Bearer ${leadToken}`)
        .send({ status: 'APPROVED', reviewNote: 'Approved. Get well soon!' })
        .expect(200);

      expect(res.body.data.status).toBe('APPROVED');
    });
  });

  describe('4. Weekly Timesheet Submission & Approval', () => {
    it('4.1 Employee submits weekly timesheet for review', async () => {
      const res = await request(app)
        .post('/api/v1/timesheets/submit')
        .set('Authorization', `Bearer ${empToken}`)
        .send({
          weekStartDate: '2026-03-02',
          weekEndDate: '2026-03-08',
          notes: 'Finished task state machines and meeting action items conversion',
        })
        .expect(201);

      expect(res.body.data.status).toBe('SUBMITTED');
    });

    it('4.2 Team Lead approves timesheet', async () => {
      const submitted = repository.timesheets.find(t => t.status === 'SUBMITTED');
      const res = await request(app)
        .patch(`/api/v1/timesheets/${submitted.id}/review`)
        .set('Authorization', `Bearer ${leadToken}`)
        .send({ status: 'APPROVED', reviewNotes: 'Great work this week.' })
        .expect(200);

      expect(res.body.data.status).toBe('APPROVED');
    });
  });

  describe('5. Meetings & Converting Action Items to Tasks', () => {
    let meetingId;
    let actionItemId;

    it('5.1 Schedules meeting with participants', async () => {
      const res = await request(app)
        .post('/api/v1/meetings/schedule')
        .set('Authorization', `Bearer ${pmToken}`)
        .send({
          title: 'Sprint 5 Planning & Architecture Sync',
          agenda: 'Review BullMQ worker automation & S3 storage hooks',
          startTime: '2026-03-10T09:00:00Z',
          endTime: '2026-03-10T10:00:00Z',
          projectId: 'prj-cloud-core',
          participantIds: ['emp-usr-employee', 'emp-usr-teamlead'],
        })
        .expect(201);

      meetingId = res.body.data.id;
      expect(meetingId).toBeDefined();
    });

    it('5.2 Adds action item to meeting', async () => {
      const res = await request(app)
        .post(`/api/v1/meetings/${meetingId}/action-items`)
        .set('Authorization', `Bearer ${pmToken}`)
        .send({
          description: 'Implement S3 presigned URL generator for secure uploads',
          assigneeId: 'emp-usr-employee',
          dueDate: '2026-03-20',
        })
        .expect(201);

      actionItemId = res.body.data.id;
      expect(actionItemId).toBeDefined();
    });

    it('5.3 Converts meeting action item into a real project task on task board', async () => {
      const res = await request(app)
        .post(`/api/v1/meetings/${meetingId}/action-items/${actionItemId}/convert-to-task`)
        .set('Authorization', `Bearer ${pmToken}`)
        .send({
          projectId: 'prj-cloud-core',
          priority: 'HIGH',
          estimatedHours: 12,
        })
        .expect(201);

      expect(res.body.data.actionItem.isConvertedToTask).toBe(true);
      expect(res.body.data.task.id).toBeDefined();
      expect(res.body.data.task.title).toBe('Implement S3 presigned URL generator for secure uploads');

      // Verify task exists in repository
      const createdTask = repository.tasks.find(t => t.id === res.body.data.task.id);
      expect(createdTask).toBeDefined();
    });
  });

  describe('6. Document Access Control & Confidentiality', () => {
    it('6.1 Regular employee can view INTERNAL documents but NOT CONFIDENTIAL documents', async () => {
      const res = await request(app)
        .get('/api/v1/documents')
        .set('Authorization', `Bearer ${empToken}`)
        .expect(200);

      expect(res.body.data.some(d => d.accessLevel === 'INTERNAL')).toBe(true);
      expect(res.body.data.some(d => d.accessLevel === 'CONFIDENTIAL')).toBe(false);
    });

    it('6.2 HR Admin CAN view CONFIDENTIAL documents', async () => {
      const res = await request(app)
        .get('/api/v1/documents')
        .set('Authorization', `Bearer ${hrAdminToken}`)
        .expect(200);

      expect(res.body.data.some(d => d.accessLevel === 'CONFIDENTIAL')).toBe(true);
    });
  });

  describe('7. Workflow Automation Rule Engine', () => {
    it('7.1 Scans rules and executes automated actions for overdue tasks and overload flags', async () => {
      // Simulate an overdue task
      repository.tasks.push({
        id: 'tsk-overdue-sample',
        organizationId: 'org-zc-001',
        projectId: 'prj-cloud-core',
        title: 'Legacy Database Vacuuming',
        status: 'IN_PROGRESS',
        deadline: new Date('2026-01-01'), // past date
        estimatedHours: 8,
      });

      const res = await request(app)
        .post('/api/v1/workflow/scan')
        .set('Authorization', `Bearer ${pmToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.triggeredActionsCount).toBeGreaterThan(0);
    });
  });

  describe('8. Project Risks Register & Health Scoring', () => {
    it('8.1 Registers a project risk and returns health score computation', async () => {
      const res = await request(app)
        .post('/api/v1/risks')
        .set('Authorization', `Bearer ${pmToken}`)
        .send({
          projectId: 'prj-cloud-core',
          title: 'Third-party OAuth identity provider intermittent timeout',
          severity: 'HIGH',
          probability: 'LOW',
          mitigationPlan: 'Maintain local JWT session fallback',
        })
        .expect(201);

      expect(res.body.data.severity).toBe('HIGH');

      // Fetch risks and health scores
      const listRes = await request(app)
        .get('/api/v1/risks')
        .set('Authorization', `Bearer ${pmToken}`)
        .expect(200);

      expect(listRes.body.projectHealthScores.length).toBeGreaterThan(0);
      const prjHealth = listRes.body.projectHealthScores.find(p => p.projectId === 'prj-cloud-core');
      expect(prjHealth.healthScore).toBeGreaterThanOrEqual(0);
      expect(prjHealth.healthScore).toBeLessThanOrEqual(100);
    });
  });
});
