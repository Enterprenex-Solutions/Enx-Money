const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');

describe('EMI Due Reminder & Notification System Tests', () => {
  const userId = 'user-emi-reminders-test-456';
  let token = '';
  let loanId = '';

  beforeAll(async () => {
    token = TokenService.signAccessToken({
      id: userId,
      email: 'reminderuser@enxmoney.com',
      name: 'Reminder Test User',
      status: 'ACTIVE',
    });

    // Create an active loan starting 2026-06-01 (Jul 1 & Aug 1 overdue on Aug 26)
    const res = await request(app)
      .post('/api/loans')
      .set('Authorization', `Bearer ${token}`)
      .send({
        loanType: 'Vehicle',
        principalAmount: 120000,
        interestRate: 10.0,
        tenureMonths: 12,
        startDate: '2026-06-01',
        interestType: 'Reducing',
      });

    loanId = res.body.data.loan.id;
  });

  it('Step 1: Get and update reminder timing configuration', async () => {
    const getRes = await request(app)
      .get('/api/loans/reminders/config')
      .set('Authorization', `Bearer ${token}`);

    expect(getRes.statusCode).toBe(200);
    expect(getRes.body.data.advanceDays).toEqual([7, 3, 1, 0]);

    const updateRes = await request(app)
      .put('/api/loans/reminders/config')
      .set('Authorization', `Bearer ${token}`)
      .send({
        advanceDays: [14, 7, 3, 1, 0],
        sendOverdueAlerts: true,
      });

    expect(updateRes.statusCode).toBe(200);
    expect(updateRes.body.data.advanceDays).toContain(14);
  });

  it('Step 2: Scan pending reminders for an overdue installment', async () => {
    const res = await request(app)
      .get('/api/loans/reminders/pending?asOfDate=2026-08-26')
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.count).toBeGreaterThan(0);

    const reminder = res.body.data.reminders[0];
    expect(reminder.loanId).toBe(loanId);
    expect(reminder.isOverdue).toBe(true);
    expect(reminder.reminderType).toBe('OVERDUE_ALERT');
    expect(reminder.lateFee).toBeGreaterThan(0);
    expect(reminder.totalPayable).toBeGreaterThan(reminder.emiAmount);
  });

  it('Step 3: Trigger reminder check & dispatch for the first time', async () => {
    const res = await request(app)
      .post('/api/loans/reminders/trigger-check')
      .set('Authorization', `Bearer ${token}`)
      .send({
        asOfDate: '2026-08-26',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.dispatchedCount).toBeGreaterThan(0);
    expect(res.body.data.skippedDuplicatesCount).toBe(0);
  });

  it('Step 4: Strict Deduplication - Repeated check on same day must NOT send duplicates', async () => {
    const res = await request(app)
      .post('/api/loans/reminders/trigger-check')
      .set('Authorization', `Bearer ${token}`)
      .send({
        asOfDate: '2026-08-26',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.dispatchedCount).toBe(0);
    expect(res.body.data.totalEligible).toBe(0); // Scanned and detected as already recorded
  });

  it('Step 5: Verify reminder audit history is logged', async () => {
    const res = await request(app)
      .get('/api/loans/reminders/history')
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data.count).toBeGreaterThan(0);
    expect(res.body.data.history[0].loanId).toBe(loanId);
    expect(res.body.data.history[0].status).toBe('SENT');
  });
});
