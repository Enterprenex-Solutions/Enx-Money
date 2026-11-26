const request = require('supertest');
const app = require('../src/app');
const OtpService = require('../src/services/otp.service');

describe('ENX Money and EWMS Authentication Isolation', () => {
  let enxToken;
  let ewmsToken;

  const email = `isolation_${Date.now()}@example.com`;

  beforeAll(async () => {
    const register = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Isolation Test User',
        email,
        password: 'TestPassword123!',
        businessName: 'QA Business'
      });

    expect(register.body.success).toBe(true);

    const { rawOtp } = await OtpService.createAndStoreOtp(
      email, 'AUTH'
    );

    const verified = await request(app)
      .post('/api/v1/auth/verify-otp')
      .send({ email, otp: rawOtp });

    expect(verified.statusCode).toBe(200);
    expect(verified.body.data.accessToken).toBeTruthy();

    enxToken = verified.body.data.accessToken;

    const jwt = require('jsonwebtoken');
    const config = require('../src/ewms/config');
    const { repository } = require(
      '../src/ewms/database/ewms_repository'
    );

    const user = repository.users.find(
      u => u.status === 'ACTIVE'
    );

    expect(user).toBeDefined();

    ewmsToken = jwt.sign({
      sub: user.id,
      email: user.email,
      role: user.role,
      org: user.organizationId
    }, config.JWT_ACCESS_SECRET, {
      expiresIn: '5m'
    });
  });

  test('ENX Money accepts its own JWT', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${enxToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data.email).toBe(email);
  });

  test('EWMS accepts its own JWT', async () => {
    const res = await request(app)
      .get('/api/v1/ewms/auth/me')
      .set('Authorization', `Bearer ${ewmsToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('EWMS rejects ENX Money JWT', async () => {
    const res = await request(app)
      .get('/api/v1/ewms/auth/me')
      .set('Authorization', `Bearer ${enxToken}`);

    expect(res.statusCode).toBe(401);
  });

  test('ENX Money rejects EWMS JWT', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${ewmsToken}`);

    expect(res.statusCode).toBe(401);
  });

  test.each([
    '/api/v1/auth/me',
    '/api/v1/ewms/auth/me'
  ])('Rejects missing JWT on %s', async (endpoint) => {
    const res = await request(app).get(endpoint);
    expect(res.statusCode).toBe(401);
  });

  test.each([
    '/api/v1/auth/me',
    '/api/v1/ewms/auth/me'
  ])('Rejects malformed JWT on %s', async (endpoint) => {
    const res = await request(app)
      .get(endpoint)
      .set('Authorization', 'Bearer invalid_token');

    expect(res.statusCode).toBe(401);
  });
});
