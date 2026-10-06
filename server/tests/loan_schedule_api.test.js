const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const LoanModel = require('../src/models/loan.model');

describe('Loan EMI & Automatic Amortization Schedule API Integration Tests', () => {
  const testUserId = 'user-test-amort-100';
  let userToken = '';
  let createdLoanId = '';

  beforeAll(async () => {
    // Generate valid JWT token for test user
    userToken = TokenService.signAccessToken({
      id: testUserId,
      email: 'alex.morgan@enxmoney.com',
      name: 'Alex Morgan',
      status: 'ACTIVE',
    });
  });

  describe('POST /api/loans/calculate (Public Calculation Utility)', () => {
    it('should calculate reducing balance EMI accurately', async () => {
      const res = await request(app)
        .post('/api/loans/calculate')
        .send({
          principalAmount: 1000000,
          interestRate: 10.5,
          tenureMonths: 36,
          interestType: 'Reducing',
          compareWithFlat: true,
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.calculation.emiAmount).toBe(32502.44);
      expect(res.body.data.calculation.totalPayable).toBe(1170087.84);
      expect(res.body.data.comparison).toBeDefined();
      expect(res.body.data.comparison.difference.interestDifference).toBeGreaterThan(0);
    });

    it('should fail with 400 when parameters are invalid', async () => {
      const res = await request(app)
        .post('/api/loans/calculate')
        .send({
          principalAmount: -500,
          interestRate: 15,
          tenureMonths: 0,
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errors).toBeDefined();
    });
  });

  describe('POST /api/loans/preview-schedule', () => {
    it('should generate preview schedule without persisting to database', async () => {
      const res = await request(app)
        .post('/api/loans/preview-schedule')
        .send({
          principalAmount: 500000,
          interestRate: 9.5,
          tenureMonths: 24,
          startDate: '2026-09-15',
          interestType: 'Reducing',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.schedule.length).toBe(24);
      expect(res.body.data.schedule[0].dueDate).toBe('2026-10-15');
      expect(res.body.data.schedule[23].closingBalance).toBe(0.00);
    });
  });

  describe('POST /api/loans (Create Loan & Auto Generate Schedule)', () => {
    it('should fail when authentication header is missing', async () => {
      const res = await request(app)
        .post('/api/loans')
        .send({
          loanType: 'Personal',
          principalAmount: 300000,
          interestRate: 11.5,
          tenureMonths: 24,
          startDate: '2026-09-01',
        });

      expect(res.statusCode).toBe(401);
    });

    it('should create loan, calculate EMI, and auto-generate & store 12 monthly installments with 0 ending balance', async () => {
      const res = await request(app)
        .post('/api/loans')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          loanType: 'Personal',
          principalAmount: 200000,
          interestRate: 12.0,
          tenureMonths: 12,
          startDate: '2026-09-01',
          interestType: 'Reducing',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loan).toBeDefined();
      expect(res.body.data.loan.id).toBeDefined();
      expect(res.body.data.loan.userId).toBe(testUserId);
      expect(res.body.data.loan.emiAmount).toBe(17769.76);
      expect(res.body.data.loan.status).toBe('Active');

      expect(res.body.data.schedule).toBeDefined();
      expect(res.body.data.schedule.length).toBe(12);

      // Verify Month 1
      expect(res.body.data.schedule[0].installmentNumber).toBe(1);
      expect(res.body.data.schedule[0].openingBalance).toBe(200000);
      expect(res.body.data.schedule[0].interestAmount).toBe(2000);
      expect(res.body.data.schedule[0].status).toBe('Pending');

      // Verify Final Month closes at exact 0.00
      const last = res.body.data.schedule[11];
      expect(last.installmentNumber).toBe(12);
      expect(last.closingBalance).toBe(0.00);

      createdLoanId = res.body.data.loan.id;
    });
  });

  describe('GET /api/loans (List Loans with Analytics)', () => {
    it('should retrieve list of loans and user analytics', async () => {
      const res = await request(app)
        .get('/api/loans')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loans.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.analytics.totalActivePrincipal).toBeGreaterThan(0);
      expect(res.body.data.analytics.totalMonthlyEmiBurden).toBeGreaterThan(0);
    });
  });

  describe('GET /api/loans/:id & GET /api/loans/:id/schedule', () => {
    it('should retrieve loan details with stats', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loan.id).toBe(createdLoanId);
      expect(res.body.data.stats.totalInstallments).toBe(12);
      expect(res.body.data.stats.pendingInstallmentsCount).toBe(12);
      expect(res.body.data.stats.remainingPrincipal).toBe(200000);
    });

    it('should retrieve amortization schedule specifically', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}/schedule`)
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loanId).toBe(createdLoanId);
      expect(res.body.data.schedule.length).toBe(12);
      expect(res.body.data.schedule[11].closingBalance).toBe(0.00);
    });
  });

  describe('POST /api/loans/:id/regenerate-schedule', () => {
    it('should regenerate amortization schedule when tenure or rate is updated', async () => {
      const res = await request(app)
        .post(`/api/loans/${createdLoanId}/regenerate-schedule`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          tenureMonths: 6,
          interestRate: 10.0,
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loan.tenureMonths).toBe(6);
      expect(res.body.data.loan.interestRate).toBe(10.0);
      expect(res.body.data.schedule.length).toBe(6);
      expect(res.body.data.schedule[5].installmentNumber).toBe(6);
      expect(res.body.data.schedule[5].closingBalance).toBe(0.00);
    });
  });

  describe('DELETE /api/loans/:id', () => {
    it('should delete loan and its amortization schedule', async () => {
      const res = await request(app)
        .delete(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);

      const checkRes = await request(app)
        .get(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${userToken}`);

      expect(checkRes.statusCode).toBe(404);
    });
  });
});
