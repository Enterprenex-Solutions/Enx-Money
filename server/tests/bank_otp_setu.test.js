const request = require('supertest');
const app = require('../src/app');

describe('Bank Security Verification & Setu AA OTP Suite', () => {
  let transactionId;

  describe('POST /api/v1/bank/send-otp', () => {
    it('Fails with 400 when account details are missing', async () => {
      const res = await request(app)
        .post('/api/v1/bank/send-otp')
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Failed to send SMS OTP. Please check your registered phone number.');
    });

    it('Fails with 400 when account number is fewer than 9 digits', async () => {
      const res = await request(app)
        .post('/api/v1/bank/send-otp')
        .send({
          accountNumber: '12345',
          ifsc: 'HDFC0001234',
          bankName: 'HDFC Bank',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Failed to send SMS OTP. Please check your registered phone number.');
    });

    it('Dispatches 6-digit SMS OTP challenge and returns transactionId and 60s cooldown', async () => {
      const res = await request(app)
        .post('/api/v1/bank/send-otp')
        .send({
          accountNumber: '50200012345678',
          ifsc: 'HDFC0001234',
          bankName: 'HDFC Bank',
          mobileNumber: '+919876543210',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.transactionId).toBeDefined();
      expect(res.body.data.consentHandle).toBeDefined();
      expect(res.body.data.expiresInSeconds).toBe(60);
      expect(res.body.data.phone).toBe('+91 98****3210');
      expect(res.body.data.isSandbox).toBe(true);

      transactionId = res.body.data.transactionId;
    });

    it('Formats dynamic masked phone correctly for different numbers', async () => {
      const res = await request(app)
        .post('/api/v1/bank/send-otp')
        .send({
          accountNumber: '50200012345678',
          ifsc: 'HDFC0001234',
          bankName: 'HDFC Bank',
          mobileNumber: '9123456789',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.phone).toBe('+91 91****6789');
    });
  });

  describe('POST /api/v1/bank/verify-otp', () => {
    it('Fails with 400 when transactionId is missing', async () => {
      const res = await request(app)
        .post('/api/v1/bank/verify-otp')
        .send({
          otp: '123456',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid OTP entered. Please try again.');
    });

    it('Fails with 400 when OTP is not 6 digits', async () => {
      const res = await request(app)
        .post('/api/v1/bank/verify-otp')
        .send({
          transactionId,
          otp: '123',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid OTP entered. Please try again.');
    });

    it('Fails with 400 when invalid OTP is submitted', async () => {
      const res = await request(app)
        .post('/api/v1/bank/verify-otp')
        .send({
          transactionId,
          otp: '000000',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid OTP entered. Please try again.');
    });

    it('Strictly rejects dummy OTP 123456 in production mode unless challenge OTP matches', async () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const res = await request(app)
        .post('/api/v1/bank/verify-otp')
        .send({
          transactionId: 'invalid_prod_tx',
          otp: '123456',
          bankName: 'HDFC Bank',
          accountNumber: '50200012345678',
          ifsc: 'HDFC0001234',
        });

      process.env.NODE_ENV = originalEnv;

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid OTP entered. Please try again.');
    });

    it('Successfully verifies valid OTP and returns linked bank account data', async () => {
      const res = await request(app)
        .post('/api/v1/bank/verify-otp')
        .send({
          transactionId,
          otp: '123456',
          bankName: 'HDFC Bank',
          accountNumber: '50200012345678',
          ifsc: 'HDFC0001234',
          accountType: 'Savings',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.status).toBe('ACTIVE');
      expect(res.body.message).toBe('Bank Account Linked Successfully');
      expect(res.body.data).toBeDefined();
      expect(res.body.data.status).toBe('ACTIVE');
      expect(res.body.data.bankName).toBe('HDFC Bank');
    });
  });
});
