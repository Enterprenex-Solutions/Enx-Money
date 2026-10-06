const request = require('supertest');
const app = require('../src/app');
const { initDb } = require('../src/config/db.config');

describe('ENX Money — Comprehensive Production API & Auth Verification', () => {
  let authToken;
  let testEmail = `verify_${Date.now()}@enxmoney.com`;
  let testCustomerId;
  let testSupplierId;

  beforeAll(async () => {
    await initDb();

    // Register a test user for the suite
    const regRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Verification Lead',
        email: testEmail,
        password: 'StrongPassword123!',
        businessName: 'ENX Global Enterprises',
      });

    if (regRes.body.data && regRes.body.data.accessToken) {
      authToken = regRes.body.data.accessToken;
    }
  });

  // 1. Health Check Suite
  describe('1. Health Check Endpoints', () => {
    test('GET /health returns 200 HEALTHY without leaking secrets', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('HEALTHY');
      expect(res.body.service).toContain('ENX Money');
      expect(res.body).not.toHaveProperty('JWT_SECRET');
      expect(res.body).not.toHaveProperty('DB_PASSWORD');
    });

    test('GET /api/health returns 200 HEALTHY', async () => {
      const res = await request(app).get('/api/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('HEALTHY');
    });

    test('GET /api/v1/health returns 200 HEALTHY', async () => {
      const res = await request(app).get('/api/v1/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('HEALTHY');
    });

    test('GET /api returns welcome documentation', async () => {
      const res = await request(app).get('/api');
      expect(res.status).toBe(200);
      expect(res.body.endpoints).toBeDefined();
    });
  });

  // 2. CORS Verification
  describe('2. CORS Policy & Security Headers', () => {
    test('Allows requests without origin (native mobile apps)', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
    });

    test('Handles OPTIONS preflight gracefully', async () => {
      const res = await request(app)
        .options('/api/v1/auth/login')
        .set('Origin', 'http://localhost:3000')
        .set('Access-Control-Request-Method', 'POST');
      expect(res.status).toBe(204);
    });
  });

  // 3. Authentication & JWT Pipeline
  describe('3. Authentication Flow', () => {
    test('POST /api/v1/auth/login with valid credentials returns JWT token', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: testEmail,
          password: 'StrongPassword123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      if (res.body.data.accessToken) {
        authToken = res.body.data.accessToken;
        expect(res.body.data.accessToken).toBeDefined();
      }
    });

    test('POST /api/v1/auth/login with wrong password returns 401', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: testEmail,
          password: 'IncorrectPassword!',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    test('GET /api/v1/auth/me with valid JWT returns current user profile', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.email).toBe(testEmail);
    });

    test('GET /api/v1/auth/me with missing token returns 401 Unauthorized', async () => {
      const res = await request(app).get('/api/v1/auth/me');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    test('GET /api/v1/auth/me with malformed token returns 401 Unauthorized', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid_garbage_token');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  // 4. Customer & Khata Ledger API Suite
  describe('4. Customer & Ledger APIs', () => {
    test('POST /api/v1/customers creates a new customer', async () => {
      const res = await request(app)
        .post('/api/v1/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Rajesh Sharma',
          phone: '9876543210',
          email: 'rajesh.sharma@example.com',
          creditLimit: 50000,
        });

      expect([200, 201]).toContain(res.status);
      expect(res.body.data).toBeDefined();
      testCustomerId = res.body.data.id;
    });

    test('GET /api/v1/customers lists customers', async () => {
      const res = await request(app)
        .get('/api/v1/customers')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      const customersList = Array.isArray(res.body.data) ? res.body.data : res.body.data.customers;
      expect(Array.isArray(customersList)).toBe(true);
    });

    test('GET /api/v1/customers/:id/ledger returns ledger statements', async () => {
      if (!testCustomerId) return;
      const res = await request(app)
        .get(`/api/v1/customers/${testCustomerId}/ledger`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
    });
  });

  // 5. Supplier API Suite
  describe('5. Supplier APIs', () => {
    test('POST /api/v1/suppliers creates a new supplier', async () => {
      const res = await request(app)
        .post('/api/v1/suppliers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Supreme Textiles Ltd',
          companyName: 'Supreme Textiles Wholesalers',
          phone: '9123456780',
          email: 'sales@supremetextiles.com',
          gstin: '29ABCDE1234F1Z5',
        });

      expect([200, 201]).toContain(res.status);
      expect(res.body.data).toBeDefined();
      testSupplierId = res.body.data.id;
    });

    test('GET /api/v1/suppliers lists suppliers', async () => {
      const res = await request(app)
        .get('/api/v1/suppliers')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  // 6. Inventory & Stock Management API Suite
  describe('6. Inventory & Product APIs', () => {
    test('POST /api/v1/inventory creates a new inventory product', async () => {
      const res = await request(app)
        .post('/api/v1/inventory')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Cotton Fabric Rolls',
          sku: `SKU-${Date.now()}`,
          category: 'Textiles',
          currentStock: 100,
          minStockLevel: 10,
          purchasePrice: 250,
          sellingPrice: 450,
          hsnCode: '5208',
          gstRate: 5,
        });

      expect([200, 201]).toContain(res.status);
      expect(res.body.data).toBeDefined();
    });

    test('GET /api/v1/inventory retrieves current stock list', async () => {
      const res = await request(app)
        .get('/api/v1/inventory')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  // 7. Invoices & GST Invoicing API Suite
  describe('7. Invoices & GST Billing APIs', () => {
    test('POST /api/v1/invoices creates a new GST invoice with line items', async () => {
      const res = await request(app)
        .post('/api/v1/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerName: 'Rajesh Sharma',
          customerId: testCustomerId,
          customerGstin: '27AABCU9603R1ZM',
          items: [
            {
              productName: 'Cotton Fabric Rolls',
              quantity: 2,
              unitPrice: 450,
              gstRate: 5,
            },
          ],
        });

      expect([200, 201]).toContain(res.status);
      expect(res.body.data).toBeDefined();
    });

    test('GET /api/v1/invoices lists invoice records', async () => {
      const res = await request(app)
        .get('/api/v1/invoices')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  // 8. Finance & Analytics APIs
  describe('8. Business Finance & Analytics APIs', () => {
    test('GET /api/v1/finance/net-worth calculates business net worth', async () => {
      const res = await request(app)
        .get('/api/v1/finance/net-worth')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
    });

    test('GET /api/v1/analytics/overview returns analytics summary', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/overview')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
    });
  });
});
