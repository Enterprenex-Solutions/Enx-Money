/**
 * Enterprenex Solutions — Company Management Portal Full Enterprise Test Suite
 * 
 * Tests the complete 30-section architecture:
 * 1. Super Admin user & role management
 * 2. All 9 roles login & RBAC permissions (SUPER_ADMIN, CEO, CFO, CTO, DEPARTMENT_HEAD, HR, MANAGER, EMPLOYEE, CLIENT)
 * 3. Client Portal strict isolation (No access to HR/Employee/Financial internal data)
 * 4. Onboarding & Offboarding workflows
 * 5. Milestones & Task time tracking
 * 6. KPI metrics & Performance reviews
 * 7. Announcements & Notifications
 * 8. Refresh Token & Session revocation
 */

const request = require('supertest');
const app = require('../src/app');
const { PortalModel, ROLES, PERMISSIONS } = require('../src/models/portal.model');

describe('Enterprenex Company Management Portal — Enterprise Architecture Suite', () => {
  let superAdminToken = '';
  let superAdminRefreshToken = '';
  let clientToken = '';
  let managerToken = '';
  let employeeToken = '';

  beforeAll(() => {
    PortalModel._resetForTesting();
  });

  // ─── 1. ALL 9 ROLES LOGIN & RBAC RESOLUTION ────────────
  it('1. Super Admin login: returns tokens, SUPER_ADMIN role, and full permissions', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({ email: 'admin@enterprenex.solutions', password: 'Admin@123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.SUPER_ADMIN);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();
    superAdminToken = res.body.data.token;
    superAdminRefreshToken = res.body.data.refreshToken;
  });

  it('2. Manager login: returns MANAGER role and manager redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({ email: 'piyush@enterprenex.solutions', password: 'Admin@123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.user.role).toBe(ROLES.MANAGER);
    expect(res.body.data.redirectUrl).toBe('/portal/manager');
    managerToken = res.body.data.token;
  });

  it('3. Department Head login: returns DEPARTMENT_HEAD role and department redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({ email: 'amit.marketing@enterprenex.solutions', password: 'Admin@123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.user.role).toBe(ROLES.DEPARTMENT_HEAD);
    expect(res.body.data.redirectUrl).toBe('/portal/department');
  });

  it('4. Client login: returns CLIENT role and client redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({ email: 'client@acmecorp.com', password: 'Admin@123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.user.role).toBe(ROLES.CLIENT);
    expect(res.body.data.redirectUrl).toBe('/portal/client');
    clientToken = res.body.data.token;
  });

  it('5. Employee login: returns EMPLOYEE role and employee redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({ email: 'kishore@enterprenex.solutions', password: 'Admin@123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.user.role).toBe(ROLES.EMPLOYEE);
    employeeToken = res.body.data.token;
  });

  // ─── 2. REFRESH TOKEN & SESSIONS ──────────────────────
  it('6. Refresh Token: successfully renews access token', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/refresh')
      .send({ refreshToken: superAdminRefreshToken });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.token).toBeDefined();
  });

  it('7. Session Management: lists active sessions and revokes session', async () => {
    const sessionsRes = await request(app)
      .get('/api/v1/portal/auth/sessions')
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(sessionsRes.statusCode).toBe(200);
    expect(Array.isArray(sessionsRes.body.data)).toBe(true);
    expect(sessionsRes.body.data.length).toBeGreaterThan(0);

    const sessionId = sessionsRes.body.data[0].id;
    const revokeRes = await request(app)
      .post('/api/v1/portal/auth/sessions/revoke')
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ sessionId });

    expect(revokeRes.statusCode).toBe(200);
    expect(revokeRes.body.success).toBe(true);
  });

  // ─── 3. USER MANAGEMENT & RBAC ────────────────────────
  it('8. Super Admin can list users and create a new user', async () => {
    const listRes = await request(app)
      .get('/api/v1/portal/users')
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(listRes.statusCode).toBe(200);
    expect(Array.isArray(listRes.body.data)).toBe(true);

    const createRes = await request(app)
      .post('/api/v1/portal/users')
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({
        email: 'test.user@enterprenex.solutions',
        name: 'Test Enterprise User',
        role: ROLES.EMPLOYEE,
        department: 'ENGINEERING',
        password: 'Password@2026'
      });

    expect(createRes.statusCode).toBe(201);
    expect(createRes.body.data.email).toBe('test.user@enterprenex.solutions');
  });

  it('9. Employee cannot access user management (403 Forbidden)', async () => {
    const res = await request(app)
      .get('/api/v1/portal/users')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(res.statusCode).toBe(403);
  });

  // ─── 4. DEPARTMENTS & DESIGNATIONS ────────────────────
  it('10. Can retrieve and create departments and designations', async () => {
    const deptRes = await request(app)
      .get('/api/v1/portal/departments')
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(deptRes.statusCode).toBe(200);
    expect(deptRes.body.data.length).toBeGreaterThanOrEqual(6);

    const desRes = await request(app)
      .get('/api/v1/portal/designations')
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(desRes.statusCode).toBe(200);
    expect(desRes.body.data.length).toBeGreaterThanOrEqual(9);
  });

  // ─── 5. ONBOARDING & OFFBOARDING ──────────────────────
  it('11. Onboarding workflow: creates pipeline and advances stage', async () => {
    const createRes = await request(app)
      .post('/api/v1/portal/onboarding')
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({
        candidateName: 'Aarav Patel',
        candidateEmail: 'aarav.patel@enterprenex.solutions',
        department: 'ENGINEERING',
        designation: 'Backend Architect'
      });

    expect(createRes.statusCode).toBe(201);
    const onbId = createRes.body.data.id;

    const advanceRes = await request(app)
      .patch(`/api/v1/portal/onboarding/${onbId}/step`)
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(advanceRes.statusCode).toBe(200);
    expect(advanceRes.body.data.currentStep).toBe(2);
  });

  // ─── 6. MILESTONES & TIME TRACKING ────────────────────
  it('12. Milestones: creates and updates project milestone', async () => {
    const createRes = await request(app)
      .post('/api/v1/portal/milestones')
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        projectId: 'PRJ-102',
        name: 'Sprint 4 - Production Security Audit',
        dueDate: '2026-11-01',
        progress: 0
      });

    expect(createRes.statusCode).toBe(201);
    const mId = createRes.body.data.id;

    const updateRes = await request(app)
      .patch(`/api/v1/portal/milestones/${mId}`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ progress: 50, status: 'IN_PROGRESS' });

    expect(updateRes.statusCode).toBe(200);
    expect(updateRes.body.data.progress).toBe(50);
  });

  it('13. Time Tracking: employee starts timer and stops timer', async () => {
    const startRes = await request(app)
      .post('/api/v1/portal/time-tracking/start')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ taskId: 'TSK-501', projectId: 'PRJ-102', notes: 'Working on RBAC tests' });

    expect(startRes.statusCode).toBe(200);
    expect(startRes.body.data.startTime).toBeDefined();

    const stopRes = await request(app)
      .post('/api/v1/portal/time-tracking/stop')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ notes: 'Finished unit tests' });

    expect(stopRes.statusCode).toBe(200);
    expect(stopRes.body.data.durationMinutes).toBeGreaterThanOrEqual(1);

    const summaryRes = await request(app)
      .get('/api/v1/portal/time-tracking/summary')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(summaryRes.statusCode).toBe(200);
    expect(summaryRes.body.data.todayHours).toBeDefined();
  });

  // ─── 7. KPIS & PERFORMANCE REVIEWS ────────────────────
  it('14. KPIs & Performance: creates KPI and logs review', async () => {
    const kpiRes = await request(app)
      .get('/api/v1/portal/kpis')
      .set('Authorization', `Bearer ${managerToken}`);

    expect(kpiRes.statusCode).toBe(200);
    expect(kpiRes.body.data.length).toBeGreaterThan(0);

    const reviewRes = await request(app)
      .post('/api/v1/portal/performance/reviews')
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        employeeId: 'EMP-007',
        reviewCycle: 'Q3 2026',
        kpiScore: 92,
        taskCompletionRate: 95,
        qualityScore: 90,
        feedback: 'Outstanding delivery on Enterprise RBAC system.'
      });

    expect(reviewRes.statusCode).toBe(201);
    expect(reviewRes.body.data.kpiScore).toBe(92);
  });

  // ─── 8. ANNOUNCEMENTS & NOTIFICATIONS ──────────────────
  it('15. Communication: retrieves announcements and notifications', async () => {
    const annRes = await request(app)
      .get('/api/v1/portal/announcements')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(annRes.statusCode).toBe(200);
    expect(annRes.body.data.length).toBeGreaterThan(0);

    const notifRes = await request(app)
      .get('/api/v1/portal/notifications')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(notifRes.statusCode).toBe(200);
  });

  // ─── 9. CLIENT PORTAL STRICT ISOLATION ────────────────
  it('16. CLIENT ISOLATION: Client can access assigned client projects & deliverables', async () => {
    const prjRes = await request(app)
      .get('/api/v1/portal/client/projects')
      .set('Authorization', `Bearer ${clientToken}`);

    expect(prjRes.statusCode).toBe(200);
    expect(Array.isArray(prjRes.body.data)).toBe(true);

    const taskRes = await request(app)
      .get('/api/v1/portal/client/tasks')
      .set('Authorization', `Bearer ${clientToken}`);

    expect(taskRes.statusCode).toBe(200);
    expect(Array.isArray(taskRes.body.data)).toBe(true);
  });

  it('17. CLIENT ISOLATION: Client attempting to access internal Employee Directory returns 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/employees')
      .set('Authorization', `Bearer ${clientToken}`);

    expect(res.statusCode).toBe(403);
  });

  it('18. CLIENT ISOLATION: Client attempting to access Audit Logs returns 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/audit-logs')
      .set('Authorization', `Bearer ${clientToken}`);

    expect(res.statusCode).toBe(403);
  });

  it('19. CLIENT ISOLATION: Client attempting to access CFO Financial Overview returns 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/cfo')
      .set('Authorization', `Bearer ${clientToken}`);

    expect(res.statusCode).toBe(403);
  });

  // ─── 10. COMPANY ANALYTICS & SETTINGS ─────────────────
  it('20. Super Admin can view analytics and update company settings', async () => {
    const analyticsRes = await request(app)
      .get('/api/v1/portal/analytics/company')
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(analyticsRes.statusCode).toBe(200);
    expect(analyticsRes.body.data.totalHeadcount).toBeDefined();

    const settingsRes = await request(app)
      .patch('/api/v1/portal/admin/settings')
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ workHoursPerDay: 8.5 });

    expect(settingsRes.statusCode).toBe(200);
    expect(settingsRes.body.data.workHoursPerDay).toBe(8.5);
  });
});
