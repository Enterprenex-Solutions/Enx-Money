/**
 * Enterprenex Company Management Portal — Phase 1 RBAC & Security Test Suite
 * 
 * Verifies:
 * 1. Single Unified Login (Email + Password only, no role pre-selection)
 * 2. Automatic Role & Permission resolution
 * 3. Strict 403 Forbidden enforcement on unauthorized cross-role API calls
 * 4. Data scoping (Employees cannot access confidential executive/financial data)
 * 5. Full Security Audit logging
 */

const request = require('supertest');
const app = require('../src/app');
const { PortalModel, ROLES, PERMISSIONS } = require('../src/models/portal.model');

describe('Enterprenex Company Management Portal — RBAC & Security Suite', () => {
  let ceoToken = '';
  let ctoToken = '';
  let cfoToken = '';
  let hrToken = '';
  let employeeToken = '';
  let internToken = '';

  beforeAll(() => {
    PortalModel._resetForTesting();
  });

  // ─── 1. UNIFIED LOGIN & ROLE RESOLUTION ──────────────
  it('1. CEO Unified Login: returns JWT, CEO role, permissions, and /portal/ceo redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'rohit@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.CEO);
    expect(res.body.data.redirectUrl).toBe('/portal/ceo');
    expect(res.body.data.user.permissions).toContain(PERMISSIONS.VIEW_ANALYTICS);
    expect(res.body.data.token).toBeDefined();
    ceoToken = res.body.data.token;
  });

  it('2. CTO Unified Login: returns JWT, CTO role, and /portal/cto redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'revanth.reddy@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.CTO);
    expect(res.body.data.redirectUrl).toBe('/portal/cto');
    expect(res.body.data.user.permissions).toContain(PERMISSIONS.VIEW_TECH_SYSTEMS);
    ctoToken = res.body.data.token;
  });

  it('3. CFO Unified Login: returns JWT, CFO role, and /portal/cfo redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'aniket@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.CFO);
    expect(res.body.data.redirectUrl).toBe('/portal/cfo');
    expect(res.body.data.user.permissions).toContain(PERMISSIONS.VIEW_FINANCE);
    cfoToken = res.body.data.token;
  });

  it('4. HR Unified Login: returns JWT, HR role, and /portal/hr redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'jyothi@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.HR);
    expect(res.body.data.redirectUrl).toBe('/portal/hr');
    expect(res.body.data.user.permissions).toContain(PERMISSIONS.CREATE_EMPLOYEE);
    hrToken = res.body.data.token;
  });

  it('5. Regular Employee Unified Login: returns JWT, EMPLOYEE role, and /portal/employee redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'kishore@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.EMPLOYEE);
    expect(res.body.data.redirectUrl).toBe('/portal/employee');
    employeeToken = res.body.data.token;
  });

  it('6. Intern Unified Login: returns JWT, INTERN role, and /portal/intern redirect', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'sneha.intern@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(ROLES.INTERN);
    expect(res.body.data.redirectUrl).toBe('/portal/intern');
    internToken = res.body.data.token;
  });

  it('7. Login rejects invalid password with 401 Unauthorized', async () => {
    const res = await request(app)
      .post('/api/v1/portal/auth/login')
      .send({
        email: 'rohit@enterprenex.solutions',
        password: 'WrongPasswordXYZ'
      });

    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // ─── 2. STRICT 403 FORBIDDEN CROSS-ROLE ATTACK TESTS ─
  it('8. SECURITY TEST: Employee attempting to access CEO Overview must return 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/ceo')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Forbidden');
  });

  it('9. SECURITY TEST: Employee attempting to access CFO Financial Overview must return 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/cfo')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Forbidden');
  });

  it('10. SECURITY TEST: Employee attempting to create a new Employee must return 403 Forbidden', async () => {
    const res = await request(app)
      .post('/api/v1/portal/employees')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({
        name: 'Hacker User',
        email: 'hacker@enterprenex.solutions',
        role: 'CEO'
      });

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('11. SECURITY TEST: HR attempting to access CTO Technical Systems must return 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/cto')
      .set('Authorization', `Bearer ${hrToken}`);

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('12. SECURITY TEST: CFO attempting to access CTO Technical Systems must return 403 Forbidden', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/cto')
      .set('Authorization', `Bearer ${cfoToken}`);

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('13. SECURITY TEST: Intern attempting to delete/terminate an employee must return 403 Forbidden', async () => {
    const res = await request(app)
      .delete('/api/v1/portal/employees/EMP-001')
      .set('Authorization', `Bearer ${internToken}`);

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
  });

  // ─── 3. AUTHORIZED ACCESS VERIFICATION ───────────────
  it('14. AUTHORIZED: CEO can access executive cockpit overview', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/ceo')
      .set('Authorization', `Bearer ${ceoToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalEmployees).toBeDefined();
    expect(res.body.data.activeProjects).toBeDefined();
  });

  it('15. AUTHORIZED: CTO can access technical command overview', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/cto')
      .set('Authorization', `Bearer ${ctoToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.productionHealth).toBeDefined();
    expect(res.body.data.techTeamSize).toBeGreaterThan(0);
  });

  it('16. AUTHORIZED: CFO can access financial overview', async () => {
    const res = await request(app)
      .get('/api/v1/portal/executive/cfo')
      .set('Authorization', `Bearer ${cfoToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.monthlyPayrollLiability).toBeGreaterThan(0);
    expect(res.body.data.financialAudits).toBeDefined();
  });

  it('17. AUTHORIZED: HR can create a new employee', async () => {
    const res = await request(app)
      .post('/api/v1/portal/employees')
      .set('Authorization', `Bearer ${hrToken}`)
      .send({
        name: 'Vikas Deshmukh',
        email: 'vikas.deshmukh@enterprenex.solutions',
        role: ROLES.EMPLOYEE,
        department: 'OPERATIONS',
        designation: 'Operations Specialist',
        phone: '+91-9123456789',
        salaryAmount: 60000
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.employee.email).toBe('vikas.deshmukh@enterprenex.solutions');
  });

  it('18. AUTHORIZED: Employee can Punch In and Punch Out (Clock In/Out)', async () => {
    // Clock In
    const inRes = await request(app)
      .post('/api/v1/portal/attendance/clock-in')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ notes: 'Starting morning sprint' });

    expect(inRes.statusCode).toBe(200);
    expect(inRes.body.data.status).toBe('PRESENT');

    // Clock Out
    const outRes = await request(app)
      .post('/api/v1/portal/attendance/clock-out')
      .set('Authorization', `Bearer ${employeeToken}`);

    expect(outRes.statusCode).toBe(200);
    expect(outRes.body.data.status).toBe('COMPLETED');
  });

  it('19. SECURITY AUDIT: Security audit trail records violations and logins', async () => {
    const res = await request(app)
      .get('/api/v1/portal/audit-logs')
      .set('Authorization', `Bearer ${ceoToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);

    const deniedLogs = res.body.data.filter(l => l.action.includes('DENIED'));
    expect(deniedLogs.length).toBeGreaterThan(0);
  });

  // ─── 4. UNIFIED PORTAL UI & SUBDOMAIN ROUTING ─────────
  it('20. Should render Unified Company Management Portal Web UI on /portal', async () => {
    const res = await request(app).get('/portal');
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toContain('text/html');
    expect(res.text).toContain('Enterprenex Solutions');
    expect(res.text).toContain('Company Management Portal');
    expect(res.text).toContain('Company Email');
    expect(res.text).toContain('Sign In to Portal');
  });

  it('21. Should render Unified Portal when accessing via Host: portal.enterprenex.solutions', async () => {
    const res = await request(app)
      .get('/')
      .set('Host', 'portal.enterprenex.solutions');

    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toContain('text/html');
    expect(res.text).toContain('portal.enterprenex.solutions');
    expect(res.text).toContain('Company Management Portal');
  });
});
