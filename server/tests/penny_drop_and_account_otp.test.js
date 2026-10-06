const request = require('supertest');
const app = require('../src/app');

describe('Penny-Drop & Account Linking OTP Integration Suite', () => {
  let challengeId;

  describe('Real-Time Penny Drop / Account Verification', () => {
    it('Validates account and returns verified status with Account Holder Name', async () => {
      const res = await request(app)
        .post('/api/finance/bank-account/verify')
        .send({
          accountNumber: '50200012345678',
          ifsc: 'HDFC0001234',
          bankName: 'HDFC Bank',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.accountExists).toBe(true);
      expect(res.body.data.accountHolderName).toBeDefined();
      expect(res.body.data.accountHolderName).toContain('Revanth');
      expect(res.body.data.bankName).toBe('HDFC Bank');
      expect(res.body.data.ifsc).toBe('HDFC0001234');
      expect(res.body.data.accountNumberLast4).toBe('5678');
      expect(res.body.data.status).toBe('VERIFIED');
      expect(res.body.data.referenceId).toMatch(/^pny_/);
    });

    it('Rejects invalid account number with fewer than 9 digits', async () => {
      const res = await request(app)
        .post('/api/finance/bank-account/verify')
        .send({
          accountNumber: '12345',
          ifsc: 'HDFC0001234',
          bankName: 'HDFC Bank',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid account number');
    });

    it('Rejects invalid IFSC code format', async () => {
      const res = await request(app)
        .post('/api/finance/bank-account/verify')
        .send({
          accountNumber: '50200012345678',
          ifsc: 'INVALID_IFSC',
          bankName: 'HDFC Bank',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid IFSC code');
    });
  });

  describe('SMS / Mobile OTP Linking Flow', () => {
    it('Dispatches 6-digit linking OTP challenge to mobile', async () => {
      const res = await request(app)
        .post('/api/finance/bank-account/send-otp')
        .send({
          accountNumber: '50200012345678',
          ifsc: 'HDFC0001234',
          bankName: 'HDFC Bank',
          mobileNumber: '+919876543210',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.challengeId).toBeDefined();
      expect(res.body.data.expiresInSeconds).toBe(30);
      expect(res.body.data.message).toContain('6-digit verification code sent');

      challengeId = res.body.data.challengeId;
    });

    it('Rejects invalid OTP code during account linking', async () => {
      const res = await request(app)
        .post('/api/finance/bank-account/verify-and-link')
        .send({
          challengeId,
          otp: '000000',
          accountData: {
            bankName: 'HDFC Bank',
            accountNumber: '50200012345678',
            ifsc: 'HDFC0001234',
            accountType: 'Savings',
          },
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid OTP code');
    });

    it('Successfully links account upon valid OTP verification', async () => {
      const res = await request(app)
        .post('/api/finance/bank-account/verify-and-link')
        .send({
          challengeId,
          otp: '123456',
          accountData: {
            bankName: 'HDFC Bank',
            accountNumber: '50200012345678',
            ifsc: 'HDFC0001234',
            accountType: 'Savings',
            accountName: 'HDFC Salary Account',
            accountHolderName: 'P. Revanth Reddy',
          },
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBeDefined();
      expect(res.body.data.bankName).toBe('HDFC Bank');
      expect(res.body.data.accountNumber).toBe('50200012345678');
      expect(res.body.data.ifsc).toBe('HDFC0001234');
    });
  });

  describe('Real-Time IFSC Lookup & Branch Details', () => {
    it('Returns bank name, branch, city, and status for valid 11-digit IFSC code', async () => {
      const res = await request(app).get('/api/finance/bank-account/ifsc/HDFC0001234');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.bank).toBe('HDFC Bank');
      expect(res.body.data.branch).toBe('Koramangala 5th Block');
      expect(res.body.data.city).toBe('Bengaluru');
      expect(res.body.data.status).toBe('ACTIVE_BRANCH');
      expect(res.body.data.upi).toBe(true);
    });

    it('Rejects invalid IFSC format', async () => {
      const res = await request(app).get('/api/finance/bank-account/ifsc/INVALID123');

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid IFSC format');
    });
  });

  describe('Business Expense Double-Entry Settlement', () => {
    it('Deducts expense amount from source account and records status as SETTLED', async () => {
      // First, create or retrieve an account
      const createRes = await request(app).post('/api/finance/accounts').send({
        mode: 'BUSINESS',
        accountName: 'HDFC Corporate Current',
        bankName: 'HDFC Bank',
        accountNumber: '502000998877',
        ifsc: 'HDFC0001234',
        balance: 50000,
      });
      expect(createRes.status).toBe(201);
      const acc = createRes.body.data;
      const initialBalance = acc.balance;

      const expenseRes = await request(app)
        .post('/api/expenses')
        .send({
          title: 'AWS Cloud Hosting',
          amount: 2500,
          category: 'Software & Tech Subscriptions',
          accountId: acc.id,
          paymentMode: 'BANK_TRANSFER',
          status: 'PAID',
        });

      expect(expenseRes.status).toBe(201);
      expect(expenseRes.body.success).toBe(true);
      expect(expenseRes.body.data.status).toBe('SETTLED');
      expect(expenseRes.body.data.updatedAccount).toBeDefined();
      expect(expenseRes.body.data.updatedAccount.balance).toBe(Number((initialBalance - 2500).toFixed(2)));
    });
  });
});
