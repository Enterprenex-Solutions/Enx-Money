const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const LateFeeCalculatorService = require('../src/services/lateFeeCalculator.service');

describe('Late Fee Calculation System Tests', () => {
  describe('1. LateFeeCalculatorService Rule Engine Unit Tests', () => {
    it('should return ₹0 late fee if installment is already paid', () => {
      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 10000,
        dueDate: '2026-08-01',
        status: 'Paid',
      });

      expect(result.lateFee).toBe(0.0);
      expect(result.isOverdue).toBe(false);
      expect(result.totalPayable).toBe(10000);
    });

    it('should return ₹0 late fee if due date has not passed', () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 10);

      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 15000,
        dueDate: futureDate.toISOString().split('T')[0],
        status: 'Pending',
      });

      expect(result.lateFee).toBe(0.0);
      expect(result.isOverdue).toBe(false);
      expect(result.totalPayable).toBe(15000);
    });

    it('should waive late fee if within grace period (e.g. 2 days overdue with 3 days grace)', () => {
      const asOf = new Date('2026-08-10');
      const due = '2026-08-08'; // 2 days overdue

      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 20000,
        dueDate: due,
        status: 'Pending',
        asOfDate: asOf,
        customConfig: { gracePeriodDays: 3 },
      });

      expect(result.inGracePeriod).toBe(true);
      expect(result.lateFee).toBe(0.0);
      expect(result.totalPayable).toBe(20000);
    });

    it('should calculate FIXED late fee correctly past grace period', () => {
      const asOf = new Date('2026-08-15');
      const due = '2026-08-01'; // 14 days overdue

      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 25000,
        dueDate: due,
        status: 'Pending',
        asOfDate: asOf,
        customConfig: {
          strategy: 'FIXED',
          fixedFee: 500.0,
          gracePeriodDays: 3,
        },
      });

      expect(result.lateFee).toBe(500.0);
      expect(result.totalPayable).toBe(25500.0);
    });

    it('should calculate PERCENTAGE-BASED late fee correctly', () => {
      const asOf = new Date('2026-08-15');
      const due = '2026-08-01'; // 14 days overdue

      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 30000,
        dueDate: due,
        status: 'Pending',
        asOfDate: asOf,
        customConfig: {
          strategy: 'PERCENTAGE',
          percentageRate: 3.5, // 3.5% of 30,000 = 1,050
          gracePeriodDays: 3,
        },
      });

      expect(result.percentageLateFee).toBe(1050.0);
      expect(result.lateFee).toBe(1050.0);
      expect(result.totalPayable).toBe(31050.0);
    });

    it('should calculate DAILY penalty correctly (10 billable days * ₹50/day = ₹500)', () => {
      const asOf = new Date('2026-08-15');
      const due = '2026-08-02'; // 13 days overdue - 3 days grace = 10 billable days

      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 10000,
        dueDate: due,
        status: 'Pending',
        asOfDate: asOf,
        customConfig: {
          strategy: 'DAILY',
          dailyPenaltyAmount: 50.0,
          gracePeriodDays: 3,
        },
      });

      expect(result.billableDays).toBe(10);
      expect(result.dailyPenalty).toBe(500.0);
      expect(result.lateFee).toBe(500.0);
      expect(result.totalPayable).toBe(10500.0);
    });

    it('should enforce maximum penalty cap', () => {
      const asOf = new Date('2026-12-01');
      const due = '2026-01-01'; // ~330 days overdue

      const result = LateFeeCalculatorService.calculateLateFee({
        emiAmount: 10000,
        dueDate: due,
        status: 'Pending',
        asOfDate: asOf,
        customConfig: {
          strategy: 'DAILY',
          dailyPenaltyAmount: 100.0,
          maxCapAmount: 1500.0,
        },
      });

      expect(result.lateFee).toBe(1500.0);
      expect(result.totalPayable).toBe(11500.0);
    });
  });

  describe('2. Late Fee API Integration Tests', () => {
    const userId = 'user-late-fee-api-test';
    let token = '';
    let loanId = '';
    let scheduleId = '';

    beforeAll(async () => {
      token = TokenService.signAccessToken({
        id: userId,
        email: 'latefee@enxmoney.com',
        name: 'Late Fee Test User',
        status: 'ACTIVE',
      });

      const res = await request(app)
        .post('/api/loans')
        .set('Authorization', `Bearer ${token}`)
        .send({
          loanType: 'Vehicle',
          principalAmount: 100000,
          interestRate: 10.0,
          tenureMonths: 6,
          startDate: '2026-07-01', // Due dates in July, August, September
          interestType: 'Reducing',
        });

      loanId = res.body.data.loan.id;
      scheduleId = res.body.data.schedule[0].id; // July installment (overdue)
    });

    it('GET /api/loans/:id/schedules/:scheduleId/late-fee should return exact breakdown', async () => {
      const res = await request(app)
        .get(`/api/loans/${loanId}/schedules/${scheduleId}/late-fee?asOfDate=2026-08-26`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.originalEmi).toBeGreaterThan(16000);
      expect(res.body.data.daysOverdue).toBe(25);
      expect(res.body.data.lateFee).toBeGreaterThan(0);
      expect(res.body.data.totalPayable).toBe(res.body.data.originalEmi + res.body.data.lateFee);
      expect(res.body.data.ruleApplied).toBeDefined();
    });

    it('GET /api/loans/:id/schedules/overdue should attach lateFeeBreakdown to overdue EMIs', async () => {
      const res = await request(app)
        .get(`/api/loans/${loanId}/schedules/overdue`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.overdueEmis.length).toBeGreaterThan(0);
      expect(res.body.data.totalLateFees).toBeGreaterThan(0);
      expect(res.body.data.totalPayableAmount).toBeGreaterThan(0);
      expect(res.body.data.overdueEmis[0].lateFeeBreakdown).toBeDefined();
    });
  });
});
