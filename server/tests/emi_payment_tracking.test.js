const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');

describe('EMI Payment Tracking and Duplicate Prevention Tests', () => {
  const userId = 'user-payment-tracking-test-123';
  let token = '';
  let loanId = '';
  let firstScheduleId = '';
  let secondScheduleId = '';

  beforeAll(() => {
    token = TokenService.signAccessToken({
      id: userId,
      email: 'tracker@enxmoney.com',
      name: 'EMI Tracker User',
      status: 'ACTIVE',
    });
  });

  it('Step 1: Create a test loan with 6 installments', async () => {
    const res = await request(app)
      .post('/api/loans')
      .set('Authorization', `Bearer ${token}`)
      .send({
        loanType: 'Personal',
        principalAmount: 60000,
        interestRate: 12.0,
        tenureMonths: 6,
        startDate: '2026-08-01',
        interestType: 'Reducing',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);

    loanId = res.body.data.loan.id;
    firstScheduleId = res.body.data.schedule[0].id;
    secondScheduleId = res.body.data.schedule[1].id;
  });

  it('Step 2: Mark Installment #1 as paid and verify tracking', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/payments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        scheduleId: firstScheduleId,
        amount: 10355.20,
        paymentDate: '2026-08-05',
        lateFee: 0,
        notes: 'Paid via ENX Auto-Debit',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.payment.amount).toBe(10355.20);
    expect(res.body.data.scheduleItem.status).toBe('Paid');
    expect(res.body.data.scheduleItem.paidDate).toBeDefined();

    // Verify loan summary reflects payment
    const summary = res.body.data.loanSummary;
    expect(summary.numberPaidEmis).toBe(1);
    expect(summary.numberPendingEmis + (summary.numberOverdueEmis || 0)).toBe(5);
    expect(summary.principalPaid).toBeGreaterThan(9000);
    expect(summary.interestPaid).toBeGreaterThan(500);
    expect(summary.outstandingBalance).toBeLessThan(60000);
  });

  it('Step 3: Reject duplicate payment attempt on Installment #1 with HTTP 400', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/payments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        scheduleId: firstScheduleId,
        amount: 10355.20,
      });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Duplicate payment rejected');
  });

  it('Step 4: Mark Installment #2 as paid and verify updated outstanding balance', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/payments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        scheduleId: secondScheduleId,
        amount: 10355.20,
        paymentDate: '2026-09-01',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);

    const summary = res.body.data.loanSummary;
    expect(summary.numberPaidEmis).toBe(2);
    expect(summary.numberPendingEmis + (summary.numberOverdueEmis || 0)).toBe(4);
    expect(summary.outstandingBalance).toBeLessThan(42000);
  });
});
