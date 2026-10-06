const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');

describe('ENX Money — Data Analysis, Compliance (Section 21) & Power BI Integration Tests', () => {
  let authToken;

  beforeAll(async () => {
    authToken = TokenService.signAccessToken({ id: 1, email: 'compliance.test@enxmoney.com' });
  });

  describe('Compliance API (/api/compliance & /api/v1/compliance)', () => {
    it('GET /api/compliance/overview should return active compliance status & workflow steps', async () => {
      const res = await request(app).get('/api/compliance/overview');
      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.complianceStatus).toBe('Active & Enforced');
      expect(res.body.data.workflowSteps).toBeInstanceOf(Array);
      expect(res.body.data.workflowSteps.length).toBeGreaterThan(0);
    });

    it('GET /api/compliance/lineage should return source-to-KPI data lineage', async () => {
      const res = await request(app)
        .get('/api/compliance/lineage')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeInstanceOf(Array);
      expect(res.body.data[0]).toHaveProperty('analyticsField');
      expect(res.body.data[0]).toHaveProperty('source');
      expect(res.body.data[0]).toHaveProperty('transformation');
    });

    it('GET /api/compliance/access-matrix should return role-based access control matrix', async () => {
      const res = await request(app)
        .get('/api/compliance/access-matrix')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeInstanceOf(Array);
      expect(res.body.data.some(r => r.role === 'Admin')).toBe(true);
    });

    it('POST /api/compliance/events should log an analytics event', async () => {
      const res = await request(app)
        .post('/api/compliance/events')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          event_name: 'test_kpi_analysis_viewed',
          purpose: 'Test validation of compliance logger',
          metadata: { screen: 'DashboardView' },
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.event_name).toBe('test_kpi_analysis_viewed');
    });

    it('GET /api/compliance/events should list logged analytics events', async () => {
      const res = await request(app)
        .get('/api/compliance/events')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
    });

    it('GET /api/compliance/model-governance should return AI/ML model registry', async () => {
      const res = await request(app)
        .get('/api/compliance/model-governance')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data[0].modelName).toContain('ENX');
    });

    it('GET /api/compliance/signoff should return signed-off checklist', async () => {
      const res = await request(app)
        .get('/api/compliance/signoff')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.signedOff).toBe(true);
    });
  });

  describe('Power BI API (/api/powerbi & /api/v1/powerbi)', () => {
    it('GET /api/powerbi/schema should return push dataset schema', async () => {
      const res = await request(app).get('/api/powerbi/schema');
      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.schema.name).toBe('ENX_Money_Financial_Warehouse');
      expect(res.body.schema.tables).toBeInstanceOf(Array);
    });

    it('GET /api/powerbi/payload should return calculated KPIs and rows', async () => {
      const res = await request(app)
        .get('/api/powerbi/payload')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.dataset).toBe('ENX_Money_Financial_Warehouse');
      expect(res.body.data.kpiSummary).toBeDefined();
      expect(res.body.data.kpiSummary).toHaveProperty('TotalRevenue');
      expect(res.body.data.kpiSummary).toHaveProperty('NetProfit');
    });

    it('GET /api/powerbi/status should return sync engine status', async () => {
      const res = await request(app).get('/api/powerbi/status');
      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.backendEngine).toContain('Power BI');
    });

    it('POST /api/powerbi/sync should acknowledge push synchronization', async () => {
      const res = await request(app)
        .post('/api/powerbi/sync')
        .set('Authorization', `Bearer ${authToken}`)
        .send({});

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Power BI backend dataset');
    });
  });
});
