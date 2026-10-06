const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');

describe('Full Loan EMI Management Backend APIs', () => {
  const userA = 'user-owner-a-111';
  const userB = 'user-intruder-b-222';
  let tokenA = '';
  let tokenB = '';

  let createdLoanId = '';
  let firstScheduleId = '';
  let recordedPaymentId = '';

  beforeAll(() => {
    tokenA = TokenService.signAccessToken({
      id: userA,
      email: 'userA@enxmoney.com',
      name: 'User A',
      status: 'ACTIVE',
    });

    tokenB = TokenService.signAccessToken({
      id: userB,
      email: 'userB@enxmoney.com',
      name: 'User B',
      status: 'ACTIVE',
    });
  });

  describe('1. Loan CRUD APIs', () => {
    it('POST /api/loans should create a new loan with full schedule for User A', async () => {
      const res = await request(app)
        .post('/api/loans')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          loanType: 'Vehicle',
          principalAmount: 300000,
          interestRate: 9.0,
          tenureMonths: 12,
          startDate: '2026-09-01',
          interestType: 'Reducing',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loan.principalAmount).toBe(300000);
      expect(res.body.data.loan.loanType).toBe('Vehicle');
      expect(res.body.data.schedule.length).toBe(12);

      createdLoanId = res.body.data.loan.id;
      firstScheduleId = res.body.data.schedule[0].id;
    });

    it('GET /api/loans should list all loans for User A with analytics', async () => {
      const res = await request(app)
        .get('/api/loans')
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.loans.length).toBe(1);
      expect(res.body.data.analytics.totalActivePrincipal).toBe(300000);
    });

    it('GET /api/loans should return empty list for User B (Ownership isolation)', async () => {
      const res = await request(app)
        .get('/api/loans')
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.loans.length).toBe(0);
    });

    it('GET /api/loans/:id should retrieve complete loan details for owner', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.loan.id).toBe(createdLoanId);
      expect(res.body.data.schedule.length).toBe(12);
      expect(res.body.data.stats.totalInstallments).toBe(12);
      expect(res.body.data.stats.pendingInstallmentsCount).toBe(12);
    });

    it('GET /api/loans/:id should return 404/denied for User B accessing User A loan', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('PUT /api/loans/:id should update loan attributes', async () => {
      const res = await request(app)
        .put(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          loanType: 'Personal',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.loan.loanType).toBe('Personal');
    });
  });

  describe('2. EMI Schedule APIs', () => {
    it('GET /api/loans/:id/schedule should retrieve full amortization schedule', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}/schedule`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.schedule.length).toBe(12);
      expect(res.body.data.schedule[0].installmentNumber).toBe(1);
      expect(res.body.data.schedule[11].closingBalance).toBe(0.00);
    });

    it('GET /api/loans/schedules/upcoming should get user-wide upcoming EMIs', async () => {
      const res = await request(app)
        .get('/api/loans/schedules/upcoming?days=60')
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.upcomingEmis).toBeDefined();
      expect(res.body.data.count).toBeGreaterThanOrEqual(1);
    });

    it('GET /api/loans/:id/schedules/upcoming should get loan-specific upcoming EMIs', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}/schedules/upcoming`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.loanId).toBe(createdLoanId);
      expect(res.body.data.upcomingEmis).toBeDefined();
    });

    it('GET /api/loans/schedules/overdue should get overdue EMIs', async () => {
      const res = await request(app)
        .get('/api/loans/schedules/overdue')
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.overdueEmis).toBeDefined();
    });
  });

  describe('3. Payment APIs', () => {
    it('POST /api/loans/:id/payments should mark an EMI installment as paid and log payment', async () => {
      const res = await request(app)
        .post(`/api/loans/${createdLoanId}/payments`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          scheduleId: firstScheduleId,
          amount: 26235.39,
          lateFee: 0,
          notes: 'September 2026 EMI payment',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.payment).toBeDefined();
      expect(res.body.data.payment.amount).toBe(26235.39);
      expect(res.body.data.scheduleItem.status).toBe('Paid');
      expect(res.body.data.loanSummary.numberPaidEmis).toBe(1);
      expect(res.body.data.loanSummary.numberPendingEmis).toBe(11);

      recordedPaymentId = res.body.data.payment.id;
    });

    it('PUT /api/loans/payments/:paymentId should update an existing payment', async () => {
      const res = await request(app)
        .put(`/api/loans/payments/${recordedPaymentId}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          notes: 'Updated: Paid via ENX UPI Auto-Debit',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.notes).toBe('Updated: Paid via ENX UPI Auto-Debit');
    });

    it('PUT /api/loans/payments/:paymentId should fail if User B tries to update User A payment', async () => {
      const res = await request(app)
        .put(`/api/loans/payments/${recordedPaymentId}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({
          notes: 'Hacked note',
        });

      expect(res.statusCode).toBe(403);
    });

    it('GET /api/loans/:id/payments should return payment ledger', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}/payments`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.payments.length).toBe(1);
      expect(res.body.data.totalAmountPaid).toBe(26235.39);
    });
  });

  describe('4. Loan Summary API', () => {
    it('GET /api/loans/:id/summary must return all required metrics', async () => {
      const res = await request(app)
        .get(`/api/loans/${createdLoanId}/summary`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);

      const summary = res.body.data;
      expect(summary.principalAmount).toBe(300000);
      expect(summary.emi).toBeDefined();
      expect(summary.outstandingBalance).toBeLessThan(300000);
      expect(summary.totalInterest).toBeDefined();
      expect(summary.interestPaid).toBeGreaterThan(0);
      expect(summary.principalPaid).toBeGreaterThan(0);
      expect(summary.nextEmi).toBeDefined();
      expect(summary.nextEmi.installmentNumber).toBe(2);
      expect(summary.numberPaidEmis).toBe(1);
      expect(summary.numberPendingEmis).toBe(11);
      expect(summary.numberOverdueEmis).toBe(0);
      expect(summary.completionPercentage).toBeGreaterThan(0);
    });
  });

  describe('5. Loan Deletion API', () => {
    it('DELETE /api/loans/:id should delete loan and clean up schedule', async () => {
      const res = await request(app)
        .delete(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);

      const verifyRes = await request(app)
        .get(`/api/loans/${createdLoanId}`)
        .set('Authorization', `Bearer ${tokenA}`);

      expect(verifyRes.statusCode).toBe(404);
    });
  });
});
