const request = require('supertest');
const app = require('../src/app');
const OtpModel = require('../src/models/otp.model');
const { generateSixDigitOtp } = require('../src/utils/crypto.util');

describe('ENX Money — Authentication & Security API Integration Tests', () => {
  jest.setTimeout(30000);
  const testEmail = 'alex.morgan@enxmoney.com';
  let issuedToken = '';

  describe('Health Check Endpoints', () => {
    it('GET /health should return 200 OK', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('HEALTHY');
    });

    it('GET /api should list available auth endpoints', async () => {
      const res = await request(app).get('/api');
      expect(res.statusCode).toBe(200);
      expect(res.body.endpoints.auth).toBeDefined();
    });
  });

  describe('POST /api/auth/send-otp', () => {
    it('should fail with 400 when email is missing or invalid', async () => {
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({ email: 'invalid-email-format' });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errors).toBeDefined();
    });

    it('should generate and send OTP for valid email', async () => {
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({ email: testEmail });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.email).toBe(testEmail);
      expect(res.body.data.expiryMinutes).toBe(5);
    });

    it('POST /api/auth/resend-otp should enforce 60s cooldown rate limiting', async () => {
      const res = await request(app)
        .post('/api/auth/resend-otp')
        .send({ email: testEmail });

      expect(res.statusCode).toBe(429);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Please wait');
    });
  });

  describe('POST /api/auth/verify-otp', () => {
    it('should fail with 400 for incorrect 6-digit OTP code', async () => {
      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ email: testEmail, otp: '000000' });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid verification code');
    });

    it('should fail with 400 when OTP is not 6 digits', async () => {
      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ email: testEmail, otp: '123' });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should successfully verify OTP and return JWT access token', async () => {
      // Find the active OTP generated in model
      const activeOtp = await OtpModel.getLatestActiveOtp(testEmail, 'AUTH');
      expect(activeOtp).toBeDefined();

      // In tests, we can test with a fresh OTP
      const bcrypt = require('bcryptjs');
      const testCode = '889900';
      const hash = await bcrypt.hash(testCode, 10);
      await OtpModel.createOtp({
        email: testEmail,
        otpHash: hash,
        purpose: 'AUTH',
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      });

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ email: testEmail, otp: testCode });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.accessToken).toBeDefined();
      expect(res.body.data.user.email).toBe(testEmail);

      issuedToken = res.body.data.accessToken;
    });

    it('should prevent reuse of already verified OTP (single-use check)', async () => {
      const testCode = '889900';
      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ email: testEmail, otp: testCode });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/auth/me (Protected Route)', () => {
    it('should reject requests without authorization token with 401', async () => {
      const res = await request(app).get('/api/auth/me');
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should return user profile when provided valid Bearer token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${issuedToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.email).toBe(testEmail);
    });
  });

  describe('POST /api/auth/register', () => {
    const newRegUser = {
      name: 'Sarah Connor',
      email: 'sarah.connor@enxmoney.com',
      phone: '+1 234 567 8900',
      password: 'StrongPassword123!',
      isBiometricEnabled: true,
    };

    it('should fail with 400 when required fields are missing', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ name: '', email: 'not-an-email', password: '123' });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should register a new user, hash password and return JWT accessToken', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(newRegUser);

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.email).toBe(newRegUser.email);
      expect(res.body.data.user.name).toBe(newRegUser.name);
      expect(res.body.data.accessToken).toBeDefined();
    });

    it('should fail with 409 Conflict when attempting to register an already registered email', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          ...newRegUser,
          phoneNumber: '+919999900001',
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('This account is already registered.');
      expect(res.body.error).toBe('ALREADY_REGISTERED');
    });

    it('should fail with 409 Conflict when attempting to register an already registered phone', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          ...newRegUser,
          email: 'brandnewunique@enxmoney.com',
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('This account is already registered.');
    });
  });

  describe('POST /api/auth/check-registered', () => {
    it('should return 200 when email and phone are available for registration', async () => {
      const res = await request(app)
        .post('/api/auth/check-registered')
        .send({
          email: 'completely_available_user@enxmoney.com',
          phone: '+919111122222',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isRegistered).toBe(false);
    });

    it('should return 409 Conflict when checking an already registered email', async () => {
      const res = await request(app)
        .post('/api/auth/check-registered')
        .send({
          email: 'alex.morgan@enxmoney.com',
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('This account is already registered.');
      expect(res.body.data.isRegistered).toBe(true);
      expect(res.body.data.field).toBe('email');
    });

    it('should return 409 Conflict and prevent OTP when send-otp has purpose REGISTRATION for existing account', async () => {
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({
          email: 'alex.morgan@enxmoney.com',
          purpose: 'REGISTRATION',
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('This account is already registered.');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should fail with 401 for incorrect password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          identifier: 'sarah.connor@enxmoney.com',
          password: 'WrongPassword!',
        });

      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should successfully log in with email and password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          identifier: 'sarah.connor@enxmoney.com',
          password: 'StrongPassword123!',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.email).toBe('sarah.connor@enxmoney.com');
      expect(res.body.data.accessToken).toBeDefined();
    });

    it('should successfully log in with phone and password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          identifier: '+1 234 567 8900',
          password: 'StrongPassword123!',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.email).toBe('sarah.connor@enxmoney.com');
    });
  });

  describe('POST /api/auth/logout (Protected Route)', () => {
    it('should successfully logout and blacklist token', async () => {
      const res = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${issuedToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('should reject subsequent requests with revoked/blacklisted token with 401', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${issuedToken}`);

      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('Forgot Password Flow Integration Tests', () => {
    const resetUserEmail = 'reset.user@enxmoney.com';
    let activeResetToken = '';

    beforeAll(async () => {
      // Register a user for the reset flow
      await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Reset Test User',
          email: resetUserEmail,
          password: 'InitialPassword123!',
          phone: '+1 999 888 7777',
        });
    });

    describe('POST /api/auth/forgot-password', () => {
      it('should fail with 400 for invalid email format', async () => {
        const res = await request(app)
          .post('/api/auth/forgot-password')
          .send({ email: 'not-a-valid-email' });

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
      });

      it('should fail with 404 for non-existent user email', async () => {
        const res = await request(app)
          .post('/api/auth/forgot-password')
          .send({ email: 'nonexistent.ghost@enxmoney.com' });

        expect(res.statusCode).toBe(404);
        expect(res.body.success).toBe(false);
        expect(res.body.message).toContain('No registered account found');
      });

      it('should successfully send reset OTP for registered email', async () => {
        const res = await request(app)
          .post('/api/auth/forgot-password')
          .send({ email: resetUserEmail });

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.data.email).toBe(resetUserEmail);
        expect(res.body.data.expiryMinutes).toBe(5);
      });

      it('should enforce cooldown on repeated forgot-password requests', async () => {
        const res = await request(app)
          .post('/api/auth/forgot-password')
          .send({ email: resetUserEmail });

        expect(res.statusCode).toBe(429);
        expect(res.body.success).toBe(false);
        expect(res.body.message).toContain('Please wait');
      });
    });

    describe('POST /api/auth/verify-reset-otp', () => {
      it('should fail with 400 for wrong OTP', async () => {
        const res = await request(app)
          .post('/api/auth/verify-reset-otp')
          .send({ email: resetUserEmail, otp: '112233' });

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
      });

      it('should successfully verify reset OTP and return a 15-min resetToken', async () => {
        const bcrypt = require('bcryptjs');
        const resetOtpCode = '654321';
        const hash = await bcrypt.hash(resetOtpCode, 10);
        await OtpModel.createOtp({
          email: resetUserEmail,
          otpHash: hash,
          purpose: 'RESET_PASSWORD',
          expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        });

        const res = await request(app)
          .post('/api/auth/verify-reset-otp')
          .send({ email: resetUserEmail, otp: resetOtpCode });

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.data.resetToken).toBeDefined();
        expect(res.body.data.email).toBe(resetUserEmail);

        activeResetToken = res.body.data.resetToken;
      });
    });

    describe('POST /api/auth/reset-password', () => {
      it('should fail with 400 when password is under 8 characters', async () => {
        const res = await request(app)
          .post('/api/auth/reset-password')
          .send({
            email: resetUserEmail,
            resetToken: activeResetToken,
            newPassword: '123',
          });

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
      });

      it('should fail with 400 for invalid/forged resetToken', async () => {
        const res = await request(app)
          .post('/api/auth/reset-password')
          .send({
            email: resetUserEmail,
            resetToken: 'invalid.jwt.token',
            newPassword: 'BrandNewSecurePassword1!',
          });

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
      });

      it('should successfully reset password with valid resetToken', async () => {
        const res = await request(app)
          .post('/api/auth/reset-password')
          .send({
            email: resetUserEmail,
            resetToken: activeResetToken,
            newPassword: 'BrandNewSecurePassword1!',
          });

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.message).toContain('Password has been updated');
      });

      it('should prevent replay/reuse of already consumed resetToken', async () => {
        const res = await request(app)
          .post('/api/auth/reset-password')
          .send({
            email: resetUserEmail,
            resetToken: activeResetToken,
            newPassword: 'AnotherPassword2@',
          });

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
      });

      it('should reject login with old password and accept login with new password', async () => {
        // 1. Old password must fail
        const oldLoginRes = await request(app)
          .post('/api/auth/login')
          .send({
            identifier: resetUserEmail,
            password: 'InitialPassword123!',
          });

        expect(oldLoginRes.statusCode).toBe(401);

        // 2. New password must succeed
        const newLoginRes = await request(app)
          .post('/api/auth/login')
          .send({
            identifier: resetUserEmail,
            password: 'BrandNewSecurePassword1!',
          });

        expect(newLoginRes.statusCode).toBe(200);
        expect(newLoginRes.body.success).toBe(true);
        expect(newLoginRes.body.data.accessToken).toBeDefined();
      });
    });
  });
});
