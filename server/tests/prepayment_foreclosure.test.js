const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');

describe('Prepayment & Foreclosure Calculator API Tests', () => {
  const userId = 'user-prepay-foreclose-test-123';
  let token = '';
  let loanId = '';

  beforeAll(async () => {
    token = TokenService.signAccessToken({
      id: userId,
      email: 'prepay@enxmoney.com',
      name: 'Prepay Foreclose User',
      status: 'ACTIVE',
    });

    const res = await request(app)
      .post('/api/loans')
      .set('Authorization', `Bearer ${token}`)
      .send({
        loanType: 'Personal',
        principalAmount: 500000,
        interestRate: 12.0,
        tenureMonths: 36,
        startDate: '2026-08-01',
        interestType: 'Reducing',
      });

    loanId = res.body.data.loan.id;
  });

  it('Step 1: Simulate Part-Prepayment with REDUCE_TENURE scenario', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/prepayment/simulate`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        prepaymentAmount: 100000,
        strategy: 'REDUCE_TENURE',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);

    const data = res.body.data;
    expect(data.currentOutstandingPrincipal).toBe(500000);
    expect(data.prepaymentAmount).toBe(100000);
    expect(data.revisedPrincipal).toBe(400000);
    expect(data.strategy).toBe('REDUCE_TENURE');
    expect(data.revisedTenureMonths).toBeLessThan(36);
    expect(data.monthsSaved).toBeGreaterThan(5);
    expect(data.interestSaved).toBeGreaterThan(20000);
  });

  it('Step 2: Simulate Part-Prepayment with REDUCE_EMI scenario', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/prepayment/simulate`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        prepaymentAmount: 100000,
        strategy: 'REDUCE_EMI',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);

    const data = res.body.data;
    expect(data.currentOutstandingPrincipal).toBe(500000);
    expect(data.prepaymentAmount).toBe(100000);
    expect(data.revisedPrincipal).toBe(400000);
    expect(data.strategy).toBe('REDUCE_EMI');
    expect(data.revisedTenureMonths).toBe(36);
    expect(data.monthlyEmiSaved).toBeGreaterThan(2500);
    expect(data.interestSaved).toBeGreaterThan(15000);
  });

  it('Step 3: Simulate Full Foreclosure calculation', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/foreclosure/simulate`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        foreclosureChargeRate: 2.0, // 2% foreclosure charge
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);

    const data = res.body.data;
    expect(data.currentOutstandingPrincipal).toBe(500000);
    expect(data.foreclosureChargeRate).toBe(2.0);
    expect(data.foreclosureChargeAmount).toBe(10000); // 2% of 500k
    expect(data.gstOnCharges).toBe(1800); // 18% GST on 10k
    expect(data.totalCharges).toBe(11800 + data.unpaidLateFees);
    expect(data.totalForeclosureAmount).toBe(500000 + data.totalCharges);
    expect(data.totalFutureInterestSaved).toBeGreaterThan(80000);
    expect(data.netSavings).toBeGreaterThan(70000);
  });

  it('Step 4: Apply Part-Prepayment to the loan', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/prepayment/apply`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        prepaymentAmount: 50000,
        strategy: 'REDUCE_TENURE',
        notes: 'Bonus payment prepay',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.prepayment.amount).toBe(50000);
    expect(res.body.data.loanSummary.outstandingBalance).toBeLessThan(460000);
  });

  it('Step 5: Apply Full Foreclosure and close the loan', async () => {
    const res = await request(app)
      .post(`/api/loans/${loanId}/foreclosure/apply`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        foreclosureChargeRate: 0.0,
        notes: 'Final settlement closure',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.loan.status).toBe('Closed');
    expect(res.body.data.loanSummary.status).toBe('Closed');
    expect(res.body.data.loanSummary.outstandingBalance).toBe(0);
  });
});
