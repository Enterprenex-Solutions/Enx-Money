/**
 * Automated Test Suite: Enterprenex Workforce & Task Management System
 * Tests employee role-based authentication, punch clock-in/out,
 * task assignments, HR live attendance roster, and portal rendering.
 */

const request = require('supertest');
const app = require('../src/app');
const WorkforceModel = require('../src/models/workforce.model');

describe('Enterprenex Workforce & Task Management API', () => {
  let ceoToken = '';
  let ctoToken = '';
  let employeeToken = '';

  beforeAll(() => {
    WorkforceModel._resetForTesting();
  });

  it('1. Should render the HTML Workforce web portal on /workforce', async () => {
    const res = await request(app).get('/workforce');
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toContain('text/html');
    expect(res.text).toContain('ENTERPRENEX WORKFORCE');
    expect(res.text).toContain('DAILY ATTENDANCE');
    expect(res.text).toContain('Tasks Assigned to You');
  });

  it('2. Should log in CEO (Rohit Pawar) and return JWT with CEO role', async () => {
    const res = await request(app)
      .post('/api/v1/workforce/login')
      .send({
        email: 'rohit@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.employee.role).toBe('CEO');
    expect(res.body.data.employee.name).toBe('Rohit Pawar');
    expect(res.body.data.token).toBeDefined();
    ceoToken = res.body.data.token;
  });

  it('3. Should log in CTO (Revanth Reddy) and return JWT with CTO role', async () => {
    const res = await request(app)
      .post('/api/v1/workforce/login')
      .send({
        email: 'revanth.reddy@enterprenex.solutions',
        password: 'Admin@123'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.employee.role).toBe('CTO');
    expect(res.body.data.token).toBeDefined();
    ctoToken = res.body.data.token;
  });

  it('4. Should reject login with invalid password', async () => {
    const res = await request(app)
      .post('/api/v1/workforce/login')
      .send({
        email: 'rohit@enterprenex.solutions',
        password: 'WrongPassword999'
      });

    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('5. Should allow an employee to Clock-In (Punch In)', async () => {
    const res = await request(app)
      .post('/api/v1/workforce/attendance/clock-in')
      .set('Authorization', `Bearer ${ctoToken}`)
      .send({ notes: 'Morning check-in from Hyderabad office' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.clockInTime).toBeDefined();
    expect(res.body.data.status).toBe('PRESENT');
  });

  it('6. Should return active status in live attendance roster for HR and CEO', async () => {
    const res = await request(app)
      .get('/api/v1/workforce/attendance/live')
      .set('Authorization', `Bearer ${ceoToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);

    const cto = res.body.data.find(e => e.email === 'revanth.reddy@enterprenex.solutions');
    expect(cto).toBeDefined();
    expect(cto.workStatus).toBe('WORKING');
  });

  it('7. Should allow an employee to Clock-Out (Punch Out) and calculate hours', async () => {
    const res = await request(app)
      .post('/api/v1/workforce/attendance/clock-out')
      .set('Authorization', `Bearer ${ctoToken}`)
      .send({ notes: 'End of shift work completed' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.clockOutTime).toBeDefined();
    expect(res.body.data.totalMinutes).toBeGreaterThanOrEqual(0);
  });

  it('8. Should allow leadership (CTO) to create and assign a new work task', async () => {
    const res = await request(app)
      .post('/api/v1/workforce/tasks')
      .set('Authorization', `Bearer ${ctoToken}`)
      .send({
        title: 'Deploy Payment Gateway Verification Fixes',
        description: 'Verify webhook signature verification and zero-latency transaction capture.',
        assignedTo: 'EMP-005', // Piyush
        priority: 'URGENT',
        dueDate: '2026-10-12'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBeDefined();
    expect(res.body.data.priority).toBe('URGENT');
    expect(res.body.data.status).toBe('TODO');
  });

  it('9. Should allow assignee to update task status to IN_PROGRESS and DONE', async () => {
    // List tasks
    const listRes = await request(app).get('/api/v1/workforce/tasks');
    const task = listRes.body.data[0];

    // Update to IN_PROGRESS
    const updateRes = await request(app)
      .patch(`/api/v1/workforce/tasks/${task.id}/status`)
      .send({
        status: 'IN_PROGRESS',
        workNotes: 'Started implementation on branch feature/payment-fix'
      });

    expect(updateRes.statusCode).toBe(200);
    expect(updateRes.body.data.status).toBe('IN_PROGRESS');

    // Update to DONE
    const doneRes = await request(app)
      .patch(`/api/v1/workforce/tasks/${task.id}/status`)
      .send({
        status: 'DONE',
        workNotes: 'PR merged and unit tests passing 100%'
      });

    expect(doneRes.statusCode).toBe(200);
    expect(doneRes.body.data.status).toBe('DONE');
    expect(doneRes.body.data.completedAt).toBeDefined();
  });

  it('10. Should return company productivity overview and department roster', async () => {
    const res = await request(app)
      .get('/api/v1/workforce/overview')
      .set('Authorization', `Bearer ${ceoToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalStaff).toBeGreaterThanOrEqual(6);
    expect(res.body.data.totalTasks).toBeGreaterThanOrEqual(1);
    expect(res.body.data.productivityPercentage).toBeDefined();
  });
});
