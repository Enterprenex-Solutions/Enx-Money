const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const InventoryModel = require('../src/models/inventory.model');

describe('ENX Money — Total Inventory Valuation API & Calculations Suite', () => {
  let tokenBusinessA;
  let tokenBusinessB;
  let userAId = 77701;
  let userBId = 77702;

  let productAId;
  let productBId;

  beforeAll(async () => {
    tokenBusinessA = TokenService.signAccessToken({ id: userAId, email: 'biz_a@enxmoney.com' });
    tokenBusinessB = TokenService.signAccessToken({ id: userBId, email: 'biz_b@enxmoney.com' });
  });

  describe('1. Initial State & Empty Valuation Handling', () => {
    it('GET /api/inventory/valuation should return 0.00 valuation when business has no inventory', async () => {
      const res = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.total_inventory_valuation).toBe(0);
      expect(res.body.data.currency).toBe('INR');
      expect(res.body.data.total_stock_quantity).toBe(0);
      expect(res.body.data.totalProducts).toBe(0);
    });

    it('GET /api/inventory/summary should also return 0.00 valuation for empty inventory', async () => {
      const res = await request(app)
        .get('/api/inventory/summary')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.total_inventory_valuation).toBe(0);
      expect(res.body.data.totalCostValuation).toBe(0);
      expect(res.body.data.currency).toBe('INR');
      expect(res.body.data.totalProducts).toBe(0);
    });
  });

  describe('2. Adding Products & Exact Inventory Valuation Math', () => {
    it('POST /api/inventory/products adds Product A (10 units @ ₹100 cost) -> Valuation = ₹1,000.00', async () => {
      const res = await request(app)
        .post('/api/inventory/products')
        .set('Authorization', `Bearer ${tokenBusinessA}`)
        .send({
          name: 'Product A',
          sku: `SKU-A-${Date.now()}`,
          category: 'Hardware',
          unit: 'Pcs',
          costPrice: 100.00,
          sellingPrice: 150.00,
          currentStock: 10,
        });

      expect([200, 201]).toContain(res.statusCode);
      expect(res.body.success).toBe(true);
      productAId = res.body.data.id;
      expect(res.body.data.currentStock).toBe(10);
      expect(res.body.data.costPrice).toBe(100.00);

      // Verify valuation
      const valRes = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(valRes.statusCode).toBe(200);
      expect(valRes.body.data.total_inventory_valuation).toBe(1000.00);
      expect(valRes.body.data.total_stock_quantity).toBe(10);
      expect(valRes.body.data.currency).toBe('INR');
    });

    it('POST /api/inventory/products adds Product B (20 units @ ₹50 cost) -> Total Valuation = ₹2,000.00', async () => {
      const res = await request(app)
        .post('/api/inventory/products')
        .set('Authorization', `Bearer ${tokenBusinessA}`)
        .send({
          name: 'Product B',
          sku: `SKU-B-${Date.now()}`,
          category: 'Accessories',
          unit: 'Pcs',
          costPrice: 50.00,
          sellingPrice: 80.00,
          currentStock: 20,
        });

      expect([200, 201]).toContain(res.statusCode);
      expect(res.body.success).toBe(true);
      productBId = res.body.data.id;
      expect(res.body.data.currentStock).toBe(20);
      expect(res.body.data.costPrice).toBe(50.00);

      // Verify combined valuation: (10 * 100) + (20 * 50) = 1,000 + 1,000 = 2,000.00
      const valRes = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(valRes.statusCode).toBe(200);
      expect(valRes.body.data.total_inventory_valuation).toBe(2000.00);
      expect(valRes.body.data.total_stock_quantity).toBe(30);
      expect(valRes.body.data.totalProducts).toBe(2);
    });
  });

  describe('3. Dynamic Stock Movements & Immediate Valuation Updates', () => {
    it('POST /api/inventory/stock-out reduces 5 units of Product A -> Valuation = ₹1,500.00', async () => {
      const res = await request(app)
        .post('/api/inventory/stock-out')
        .set('Authorization', `Bearer ${tokenBusinessA}`)
        .send({
          productId: productAId,
          quantity: 5,
          reason: 'Direct Counter Sale',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.product.currentStock).toBe(5);

      // Remaining: Product A: 5 * 100 = 500; Product B: 20 * 50 = 1000 -> Total: 1500.00
      const valRes = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(valRes.body.data.total_inventory_valuation).toBe(1500.00);
      expect(valRes.body.data.total_stock_quantity).toBe(25);
    });

    it('POST /api/inventory/stock-in adds 10 units to Product B -> Valuation = ₹2,000.00', async () => {
      const res = await request(app)
        .post('/api/inventory/stock-in')
        .set('Authorization', `Bearer ${tokenBusinessA}`)
        .send({
          productId: productBId,
          quantity: 10,
          unitCost: 50.00,
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.product.currentStock).toBe(30);

      // New: Product A: 5 * 100 = 500; Product B: 30 * 50 = 1500 -> Total: 2000.00
      const valRes = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(valRes.body.data.total_inventory_valuation).toBe(2000.00);
      expect(valRes.body.data.total_stock_quantity).toBe(35);
    });

    it('PUT /api/inventory/products/:id updates Product A cost price from 100 to 120 -> Valuation = ₹2,100.00', async () => {
      const res = await request(app)
        .put(`/api/inventory/products/${productAId}`)
        .set('Authorization', `Bearer ${tokenBusinessA}`)
        .send({
          costPrice: 120.00,
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.costPrice).toBe(120.00);

      // New: Product A: 5 * 120 = 600; Product B: 30 * 50 = 1500 -> Total: 2100.00
      const valRes = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(valRes.body.data.total_inventory_valuation).toBe(2100.00);
    });

    it('DELETE /api/inventory/products/:id deletes Product B -> Valuation = ₹600.00', async () => {
      const res = await request(app)
        .delete(`/api/inventory/products/${productBId}`)
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);

      // Remaining: Only Product A (5 units @ ₹120) = ₹600.00
      const valRes = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(valRes.body.data.total_inventory_valuation).toBe(600.00);
      expect(valRes.body.data.total_stock_quantity).toBe(5);
      expect(valRes.body.data.totalProducts).toBe(1);
    });
  });

  describe('4. Strict Multi-Tenant Business Isolation', () => {
    it('GET /api/inventory/valuation for Business B should return ₹0.00 valuation and zero products', async () => {
      const res = await request(app)
        .get('/api/inventory/valuation')
        .set('Authorization', `Bearer ${tokenBusinessB}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.total_inventory_valuation).toBe(0);
      expect(res.body.data.total_stock_quantity).toBe(0);
      expect(res.body.data.totalProducts).toBe(0);
    });

    it('Business B should not be able to update or delete Business A product', async () => {
      const res = await request(app)
        .delete(`/api/inventory/products/${productAId}`)
        .set('Authorization', `Bearer ${tokenBusinessB}`);

      expect(res.statusCode).toBe(404);
    });
  });

  describe('5. Analytics Dashboard KPI Integration', () => {
    it('GET /api/v1/analytics/kpi?profile_type=business returns inventory valuation for Business A', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/kpi?profile_type=business')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.inventoryValue).toBe(600.00);
      expect(res.body.data.total_inventory_valuation).toBe(600.00);
    });

    it('GET /api/v1/analytics/kpi?profile_type=personal zeros out inventory valuation', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/kpi?profile_type=personal')
        .set('Authorization', `Bearer ${tokenBusinessA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.inventoryValue).toBe(0);
      expect(res.body.data.total_inventory_valuation).toBe(0);
    });
  });
});
