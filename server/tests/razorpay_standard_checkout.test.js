const request = require('supertest');
const crypto = require('crypto');
const app = require('../src/app');

describe('Razorpay Standard Web Checkout Integration', () => {
  const testKeySecret = process.env.RAZORPAY_KEY_SECRET || 'qO8RdiLp42oez5ZF6O5XvF3w';

  describe('STEP 1: POST /api/create-order', () => {
    test('Rejects request if amount is missing or invalid', async () => {
      const res = await request(app)
        .post('/api/create-order')
        .send({});
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toMatch(/amount is required/i);
    });

    test('Rejects request if amount is less than 100 paise (min ₹1)', async () => {
      const res = await request(app)
        .post('/api/create-order')
        .send({ amount: 50 });
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toMatch(/at least 100 paise/i);
    });

    test('Successfully creates order for amount >= 100 paise', async () => {
      const res = await request(app)
        .post('/api/create-order')
        .send({
          amount: 50000, // ₹500
          currency: 'INR',
          receipt: 'receipt_test_101',
        });
      expect([200, 201]).toContain(res.status);
      expect(res.body.success).toBe(true);
      expect(res.body.order_id).toBeDefined();
      expect(res.body.amount).toBe(50000);
      expect(res.body.currency).toBe('INR');
      expect(res.body.key_id).toBeDefined();
    });
  });

  describe('STEP 3: POST /api/verify-payment', () => {
    test('Rejects payment verification if required fields are missing', async () => {
      const res = await request(app)
        .post('/api/verify-payment')
        .send({ order_id: 'order_123' });
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toMatch(/Missing required payment verification fields/i);
    });

    test('Rejects verification on signature mismatch', async () => {
      const res = await request(app)
        .post('/api/verify-payment')
        .send({
          order_id: 'order_test_999',
          payment_id: 'pay_test_888',
          razorpay_signature: 'invalid_signature_hex_1234567890abcdef',
        });
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toMatch(/signature verification failed|signature mismatch/i);
    });

    test('Successfully verifies payment when HMAC-SHA256 signature matches', async () => {
      const orderId = 'order_valid_12345';
      const paymentId = 'pay_valid_67890';
      const validSignature = crypto
        .createHmac('sha256', testKeySecret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

      const res = await request(app)
        .post('/api/verify-payment')
        .send({
          order_id: orderId,
          payment_id: paymentId,
          razorpay_signature: validSignature,
        });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toMatch(/verified successfully/i);
      expect(res.body.status).toBe('PAID');
    });
  });

  describe('STEP 2: Web Checkout Page (GET /checkout and GET /pay)', () => {
    test('Serves Razorpay Standard Web Checkout HTML at /checkout', async () => {
      const res = await request(app).get('/checkout');
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toMatch(/html/);
      expect(res.text).toContain('https://checkout.razorpay.com/v1/checkout.js');
      expect(res.text).toContain('startRazorpayCheckout');
      expect(res.text).toContain('/api/create-order');
      expect(res.text).toContain('/api/verify-payment');
    });

    test('Serves Razorpay Standard Web Checkout HTML at /pay', async () => {
      const res = await request(app).get('/pay');
      expect(res.status).toBe(200);
      expect(res.text).toContain('https://checkout.razorpay.com/v1/checkout.js');
    });
  });
});
