const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const AnalyticsService = require('../src/services/analytics.service');

describe('ENX Money — Personal vs Business Analytics Isolation & Health Score Tests', () => {
  let authToken;

  beforeAll(async () => {
    authToken = TokenService.signAccessToken({ id: 99999, email: 'analytics.test@enxmoney.com' });
  });

  describe('KPI Endpoint Isolation (/api/v1/analytics/kpi)', () => {
    it('GET /api/v1/analytics/kpi?profile_type=personal should isolate personal metrics and zero out business KPIs', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/kpi?profile_type=personal')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      const data = res.body.data;

      // Business receivables, payables, GST, and loan EMIs must strictly be 0 for personal profiles
      expect(data.outstandingReceivables).toBe(0);
      expect(data.outstandingPayables).toBe(0);
      expect(data.gstPayable).toBe(0);
      expect(data.emiDueThisMonth).toBe(0);
      expect(data.totalPurchases).toBe(0);
      expect(data.collectionRate).toBe(0);
    });

    it('GET /api/v1/analytics/kpi?profile_type=business should calculate business metrics', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/kpi?profile_type=business')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      const data = res.body.data;
      expect(data).toHaveProperty('totalRevenue');
      expect(data).toHaveProperty('totalExpense');
      expect(data).toHaveProperty('netProfit');
      expect(data).toHaveProperty('outstandingReceivables');
      expect(data).toHaveProperty('outstandingPayables');
      expect(data).toHaveProperty('gstPayable');
      expect(data).toHaveProperty('emiDueThisMonth');
    });
  });

  describe('Business Health Score Algorithm Guard', () => {
    it('should return INSUFFICIENT DATA and score 0 when operational revenue and expense are 0', async () => {
      // User 99999 has no operational revenue or expense
      const result = await AnalyticsService.calculateBusinessHealthScore(99999);

      expect(result.score).toBe(0);
      expect(result.status).toBe('INSUFFICIENT DATA');
      expect(result.hasSufficientData).toBe(false);
      expect(result.breakdown.profitability.score).toBe(0);
      expect(result.breakdown.collections.score).toBe(0);
      expect(result.breakdown.expenseControl.score).toBe(0);
      expect(result.actionableTips).toBeInstanceOf(Array);
      expect(result.actionableTips.length).toBeGreaterThan(0);
    });

    it('GET /api/v1/analytics/health-score endpoint should return valid health score payload with INSUFFICIENT DATA for inactive accounts', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/health-score')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('score');
      expect(res.body.data).toHaveProperty('status');
      expect(res.body.data).toHaveProperty('breakdown');
      expect(res.body.data.status).toBe('INSUFFICIENT DATA');
      expect(res.body.data.score).toBe(0);
    });
  });
});
