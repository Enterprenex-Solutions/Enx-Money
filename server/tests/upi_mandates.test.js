const request = require('supertest');
const app = require('../src/app');

describe('UPI Bank Account Linking & AutoPay Mandates API Suite', () => {
  let challengeId;
  let testAccountId;
  let createdMandateId;

  describe('Step 1: 2-Factor OTP SMS Verification & SIM Binding Flow', () => {
    it('Initiates UPI Bank Linking and dispatches OTP SMS challenge', async () => {
      const res = await request(app)
        .post('/api/finance/upi/initiate-link')
        .send({
          bankName: 'HDFC Bank',
          mobileNumber: '+919876543210',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.challengeId).toBeDefined();
      expect(res.body.data.bankName).toBe('HDFC Bank');
      expect(res.body.data.mobileNumber).toBe('+919876543210');

      challengeId = res.body.data.challengeId;
    });

    it('Rejects invalid OTP during verification with descriptive message', async () => {
      const res = await request(app)
        .post('/api/finance/upi/verify-otp')
        .send({
          challengeId,
          otp: '000000',
          bankName: 'HDFC Bank',
          mobileNumber: '+919876543210',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid OTP code entered');
    });

    it('Fails verification when challenge session is nonexistent', async () => {
      const res = await request(app)
        .post('/api/finance/upi/verify-otp')
        .send({
          challengeId: 'nonexistent_session',
          otp: '123456',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Verification session expired');
    });

    it('Confirms UPI bank account linking and creates default VPA', async () => {
      const res = await request(app)
        .post('/api/finance/upi/confirm-link')
        .send({
          bankName: 'HDFC Bank',
          accountNumber: 'XXXXXXXXXXXX3210',
          accountNumberLast4: '3210',
          ifsc: 'HDFC0003210',
          accountType: 'Savings',
          accountHolderName: 'Revanth V',
          vpa: '9876543210@hdfcbank',
          isDefault: true,
          balance: 68500.0,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBeDefined();
      expect(res.body.data.bankName).toBe('HDFC Bank');
      expect(res.body.data.isUpiLinked).toBe(true);
      expect(res.body.data.vpa).toBe('9876543210@hdfcbank');

      testAccountId = res.body.data.id;
    });

    it('Configures native UPI PIN with debit card validation', async () => {
      const res = await request(app)
        .post('/api/finance/upi/setup-pin')
        .send({
          accountId: testAccountId,
          cardLast6: '654321',
          expiryMonth: '08',
          expiryYear: '29',
          upiPin: '4826',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.hasUpiPin).toBe(true);
      expect(res.body.data.message).toContain('UPI PIN configured successfully');
    });

    it('Rejects invalid debit card details during UPI PIN setup', async () => {
      const res = await request(app)
        .post('/api/finance/upi/setup-pin')
        .send({
          accountId: testAccountId,
          cardLast6: '12', // invalid length
          expiryMonth: '08',
          expiryYear: '29',
          upiPin: '1234',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('last 6 digits');
    });
  });

  describe('Step 2: UPI AutoPay & Recurring Mandate System', () => {
    it('Fetches active and existing mandates', async () => {
      const res = await request(app)
        .get('/api/finance/mandates');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].name).toBeDefined();
    });

    it('Registers a new AutoPay recurring mandate', async () => {
      const res = await request(app)
        .post('/api/finance/mandates')
        .send({
          name: 'Monthly Office Cloud Server',
          frequency: 'Monthly',
          maxLimit: 3500.0,
          startDate: '2026-10-01',
          endDate: '2028-10-01',
          isUntilCancelled: true,
          sourceAccountId: testAccountId,
          sourceBankName: 'HDFC Bank',
          vpa: 'enxmoney@bank',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBeDefined();
      expect(res.body.data.name).toBe('Monthly Office Cloud Server');
      expect(res.body.data.status).toBe('Active');
      expect(res.body.data.maxLimit).toBe(3500.0);

      createdMandateId = res.body.data.id;
    });

    it('Pauses an active mandate with 1-tap status update', async () => {
      const res = await request(app)
        .patch(`/api/finance/mandates/${createdMandateId}/status`)
        .send({ status: 'Paused' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('Paused');
    });

    it('Resumes a paused mandate back to Active status', async () => {
      const res = await request(app)
        .patch(`/api/finance/mandates/${createdMandateId}/status`)
        .send({ status: 'Active' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('Active');
    });

    it('Revokes / cancels an active AutoPay mandate', async () => {
      const res = await request(app)
        .delete(`/api/finance/mandates/${createdMandateId}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('revoked successfully');
    });
  });
});
