const request = require('supertest');
const app = require('../src/app');

describe('Setu Account Aggregator Pre-built Webview Flow', () => {
  it('1. POST /api/v1/bank/initiate-consent should return redirectUrl and consentId', async () => {
    const res = await request(app)
      .post('/api/v1/bank/initiate-consent')
      .send({
        phone: '9876543210',
        redirectUrl: 'enxmoney://bank-success',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeDefined();
    expect(res.body.data.consentId).toBeDefined();
    expect(res.body.data.redirectUrl).toBeDefined();
    expect(res.body.data.redirectUrl).toContain('/api/v1/bank/setu-webview');
  });

  it('2. GET /api/v1/bank/setu-webview should render the automated Setu AA Webview page', async () => {
    const res = await request(app)
      .get('/api/v1/bank/setu-webview?consentId=test_cst_123&phone=9876543210&redirectUrl=enxmoney://bank-success');

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('text/html');
    expect(res.text).toContain('Setu AA Gateway');
    expect(res.text).toContain('State Bank of India');
    expect(res.text).toContain('enxmoney://bank-success');
  });

  it('3. POST /api/v1/bank/complete-consent should link the bank account and sync state', async () => {
    const res = await request(app)
      .post('/api/v1/bank/complete-consent')
      .send({
        consentId: 'test_cst_123',
        bankName: 'HDFC Bank',
        accountNumber: 'XXXXXX5892',
        ifsc: 'HDFC0000456',
        mode: 'BUSINESS',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeDefined();
    expect(res.body.data.bankName).toBe('HDFC Bank');
  });
});
