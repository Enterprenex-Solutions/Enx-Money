const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db.config');

describe('Security Questions & Password Recovery Flow', () => {
  let userToken = '';
  const testEmail = `sq_test_${Date.now()}@enxmoney.com`;
  const initialPassword = 'OldPassword@123';
  const updatedPassword = 'NewPassword@456';

  beforeAll(async () => {
    await db.initDb();

    // Register test user
    await request(app)
      .post('/api/auth/register')
      .send({
        email: testEmail,
        fullName: 'Security Question User',
        password: initialPassword,
        phone: '+919876543210',
      });

    // Create known OTP for test user
    const OtpModel = require('../src/models/otp.model');
    const bcrypt = require('bcryptjs');
    const testCode = '889900';
    const hash = await bcrypt.hash(testCode, 10);
    await OtpModel.createOtp({
      email: testEmail,
      otpHash: hash,
      purpose: 'AUTH',
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    // Verify OTP to obtain accessToken
    const otpRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({
        email: testEmail,
        otp: testCode,
      });

    if (otpRes.body && otpRes.body.data && otpRes.body.data.accessToken) {
      userToken = otpRes.body.data.accessToken;
    } else {
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({
          identifier: testEmail,
          password: initialPassword,
        });
      userToken = loginRes.body && loginRes.body.data ? loginRes.body.data.accessToken : '';
    }
  });

  describe('1. Standard Catalog Retrieval', () => {
    it('GET /api/auth/security-questions returns list of standard questions', async () => {
      const res = await request(app)
        .get('/api/auth/security-questions')
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.questions)).toBe(true);
      expect(res.body.data.questions.length).toBeGreaterThanOrEqual(3);
      expect(res.body.data.questions[0]).toHaveProperty('id');
      expect(res.body.data.questions[0]).toHaveProperty('text');
    });
  });

  describe('2. Security Questions Setup', () => {
    it('should reject setup without authentication', async () => {
      await request(app)
        .post('/api/auth/security-questions/setup')
        .send({ questions: [] })
        .expect(401);
    });

    it('should reject setup with fewer than 3 questions', async () => {
      await request(app)
        .post('/api/auth/security-questions/setup')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          questions: [
            { questionId: 'q1', answer: 'Alice' },
          ],
        })
        .expect(400);
    });

    it('should reject setup with duplicate questions', async () => {
      await request(app)
        .post('/api/auth/security-questions/setup')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          questions: [
            { questionId: 'q1', answer: 'Alice' },
            { questionId: 'q1', answer: 'Bob' },
            { questionId: 'q2', answer: 'Blue' },
          ],
        })
        .expect(400);
    });

    it('should reject setup with empty answer', async () => {
      await request(app)
        .post('/api/auth/security-questions/setup')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          questions: [
            { questionId: 'q1', answer: 'Alice' },
            { questionId: 'q2', answer: '   ' },
            { questionId: 'q3', answer: 'Oxford' },
          ],
        })
        .expect(400);
    });

    it('should successfully configure 3 questions and securely hash answers', async () => {
      const res = await request(app)
        .post('/api/auth/security-questions/setup')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          questions: [
            { questionId: 'q1', answer: 'Alice' },
            { questionId: 'q2', answer: 'Blue' },
            { questionId: 'q3', answer: 'St. Mary High' },
          ],
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.configuredCount).toBe(3);
    });
  });

  describe('3. Fetch User Questions for Password Recovery', () => {
    it('should retrieve configured questions without revealing answers or hashes', async () => {
      const res = await request(app)
        .post('/api/auth/security-questions/get-for-user')
        .send({ identifier: testEmail })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.questions.length).toBe(3);
      // Ensure zero answers or hashes are leaked
      for (const q of res.body.data.questions) {
        expect(q).not.toHaveProperty('answer');
        expect(q).not.toHaveProperty('answerHash');
        expect(q).toHaveProperty('questionId');
        expect(q).toHaveProperty('questionText');
      }
    });

    it('should return 404 for non-existent identifier', async () => {
      await request(app)
        .post('/api/auth/security-questions/get-for-user')
        .send({ identifier: 'does_not_exist_99@enxmoney.com' })
        .expect(404);
    });
  });

  describe('4. Answer Verification & Rate Limiting', () => {
    it('should reject incorrect answers with remaining attempt count', async () => {
      const res = await request(app)
        .post('/api/auth/security-questions/verify')
        .send({
          identifier: testEmail,
          answers: [
            { questionId: 'q1', answer: 'WrongAnswer1' },
            { questionId: 'q2', answer: 'Blue' },
            { questionId: 'q3', answer: 'St. Mary High' },
          ],
        })
        .expect(400);

      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('remaining');
    });

    it('should verify correct answers (case-insensitive and trimmed) and return resetToken', async () => {
      const res = await request(app)
        .post('/api/auth/security-questions/verify')
        .send({
          identifier: testEmail,
          answers: [
            { questionId: 'q1', answer: '  aLiCe  ' },
            { questionId: 'q2', answer: 'BLUE' },
            { questionId: 'q3', answer: 'st. mary high' },
          ],
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.verified).toBe(true);
      expect(res.body.data).toHaveProperty('resetToken');
      expect(typeof res.body.data.resetToken).toBe('string');
    });
  });

  describe('5. Password Reset & Session Invalidation', () => {
    let validResetToken = '';

    beforeAll(async () => {
      const verifyRes = await request(app)
        .post('/api/auth/security-questions/verify')
        .send({
          identifier: testEmail,
          answers: [
            { questionId: 'q1', answer: 'alice' },
            { questionId: 'q2', answer: 'blue' },
            { questionId: 'q3', answer: 'st. mary high' },
          ],
        });
      validResetToken = verifyRes.body.data.resetToken;
    });

    it('should reset password with verified resetToken', async () => {
      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({
          email: testEmail,
          resetToken: validResetToken,
          newPassword: updatedPassword,
        })
        .expect(200);

      expect(res.body.success).toBe(true);
    });

    it('should allow login with new password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          identifier: testEmail,
          password: updatedPassword,
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
    });

    it('should reject login with old password', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          identifier: testEmail,
          password: initialPassword,
        })
        .expect(401);
    });
  });
});
