const request = require('supertest');
const app = require('../src/app');

describe('Multi-Device Login & Approval API', () => {
  const testUser = {
    name: 'Device Test User',
    email: 'devicetest@enxmoney.com',
    phoneNumber: '919876543210',
    password: 'Password@123',
    role: 'USER',
  };

  let primaryToken = '';
  let userId = '';

  beforeAll(async () => {
    // Register test user
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send(testUser);
    expect(res.statusCode).toBe(201);
    userId = res.body.data.user.id;
  });

  test('Primary device logs in and is auto-approved', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: testUser.email,
        password: testUser.password,
        deviceId: 'device-primary-1',
        deviceName: 'Pixel 8 Pro',
        devicePlatform: 'android',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    primaryToken = res.body.data.accessToken || res.body.data.token;
    expect(primaryToken).toBeDefined();
    expect(res.body.data.requiresDeviceApproval).toBeUndefined();
  });

  test('Primary device lists its active devices', async () => {
    const res = await request(app)
      .get('/api/v1/auth/devices')
      .set('Authorization', `Bearer ${primaryToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data.devices.length).toBe(1);
    expect(res.body.data.devices[0].deviceId).toBe('device-primary-1');
    expect(['APPROVED', 'ACTIVE']).toContain(res.body.data.devices[0].status);
  });

  test('Second device attempts login and requires approval', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: testUser.email,
        password: testUser.password,
        deviceId: 'device-secondary-2',
        deviceName: 'iPhone 15',
        devicePlatform: 'ios',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.requiresDeviceApproval).toBe(true);
    expect(res.body.data.approvalRequestId).toBeDefined();
    expect(res.body.data.verificationCode).toBeDefined();
    const requestId = res.body.data.approvalRequestId;

    // Check polling status before approval
    const statusRes = await request(app)
      .get(`/api/v1/auth/device-approval-status/${requestId}`);

    expect(statusRes.statusCode).toBe(200);
    expect(statusRes.body.data.status).toBe('PENDING');

    // Primary device checks pending approvals
    const pendingRes = await request(app)
      .get('/api/v1/auth/pending-device-approvals')
      .set('Authorization', `Bearer ${primaryToken}`);

    expect(pendingRes.statusCode).toBe(200);
    expect(pendingRes.body.data.pendingApprovals.length).toBeGreaterThanOrEqual(1);
    const pendingItem = pendingRes.body.data.pendingApprovals.find(p => p.id === requestId);
    expect(pendingItem).toBeDefined();
    expect(pendingItem.deviceName).toBe('iPhone 15');

    // Primary device approves the request
    const approveRes = await request(app)
      .post('/api/v1/auth/approve-device')
      .set('Authorization', `Bearer ${primaryToken}`)
      .send({ requestId });

    expect(approveRes.statusCode).toBe(200);
    expect(approveRes.body.data.status).toBe('APPROVED');

    // Second device polls again and receives access token
    const pollAfterApproval = await request(app)
      .get(`/api/v1/auth/device-approval-status/${requestId}`);

    expect(pollAfterApproval.statusCode).toBe(200);
    expect(pollAfterApproval.body.data.status).toBe('APPROVED');
    expect(pollAfterApproval.body.data.accessToken).toBeDefined();
    expect(pollAfterApproval.body.data.user.email).toBe(testUser.email);
  });

  test('Primary device sees both devices and can revoke second device', async () => {
    const res = await request(app)
      .get('/api/v1/auth/devices')
      .set('Authorization', `Bearer ${primaryToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data.devices.length).toBe(2);

    // Revoke second device
    const revokeRes = await request(app)
      .delete('/api/v1/auth/devices/device-secondary-2')
      .set('Authorization', `Bearer ${primaryToken}`);

    expect(revokeRes.statusCode).toBe(200);

    const checkRes = await request(app)
      .get('/api/v1/auth/devices')
      .set('Authorization', `Bearer ${primaryToken}`);

    expect(checkRes.statusCode).toBe(200);
    const secondary = checkRes.body.data.devices.find(d => d.deviceId === 'device-secondary-2');
    expect(!secondary || secondary.status === 'REVOKED').toBe(true);
  });

  test('Third device rejected by primary device', async () => {
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: testUser.email,
        password: testUser.password,
        deviceId: 'device-third-3',
        deviceName: 'Windows Laptop',
        devicePlatform: 'windows',
      });

    expect(loginRes.statusCode).toBe(200);
    expect(loginRes.body.data.requiresDeviceApproval).toBe(true);
    const requestId = loginRes.body.data.approvalRequestId;

    // Primary rejects it
    const rejectRes = await request(app)
      .post('/api/v1/auth/reject-device')
      .set('Authorization', `Bearer ${primaryToken}`)
      .send({ requestId });

    expect(rejectRes.statusCode).toBe(200);
    expect(rejectRes.body.data.status).toBe('REJECTED');

    // Third device polls and sees rejected
    const pollRes = await request(app)
      .get(`/api/v1/auth/device-approval-status/${requestId}`);

    expect(pollRes.statusCode).toBe(200);
    expect(pollRes.body.data.status).toBe('REJECTED');
    expect(pollRes.body.data.accessToken).toBeUndefined();
  });
});
