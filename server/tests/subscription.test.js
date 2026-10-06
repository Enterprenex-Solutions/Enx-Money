/**
 * ENX Money — Subscription & Billing Automated Tests
 * Tests plan seeding, entitlement engine, merchant settlement configuration,
 * order routing, instant subscription webhook activation, and GST PDF generation.
 */
const request = require('supertest');
const app = require('../src/app');
const subscriptionModel = require('../src/models/subscription.model');
const paymentModel = require('../src/models/payment.model');
const invoiceModel = require('../src/models/subscriptionInvoice.model');
const entitlementService = require('../src/services/entitlement.service');
const razorpayService = require('../src/services/razorpay.service');
const { SETTLEMENT_CONFIG } = require('../src/config/settlement.config');

describe('Subscription & Billing Integration Tests', () => {
  beforeAll(async () => {
    await subscriptionModel.seedDefaultPlans();
  });

  test('1. Plan Seeding includes all required tiers with exact prices', async () => {
    const plans = await subscriptionModel.getPlans();
    expect(plans.length).toBe(5);

    const basic = plans.find(p => p.name === 'BASIC');
    expect(basic).toBeDefined();
    expect(basic.price_monthly).toBe(199);

    const pro = plans.find(p => p.name === 'PRO');
    expect(pro).toBeDefined();
    expect(pro.price_monthly).toBe(499);

    const advanced = plans.find(p => p.name === 'ADVANCED');
    expect(advanced).toBeDefined();
    expect(advanced.price_monthly).toBe(999);

    const business = plans.find(p => p.name === 'BUSINESS');
    expect(business).toBeDefined();
    expect(business.price_monthly).toBe(1999);
  });

  test('2. Merchant Settlement Configuration matches exact payout destination', () => {
    expect(SETTLEMENT_CONFIG.BENEFICIARY_NAME).toBe('Rohit Samadhan Pawar');
    expect(SETTLEMENT_CONFIG.BANK_NAME).toBe('Jio Payments Bank');
    expect(SETTLEMENT_CONFIG.ACCOUNT_NUMBER).toBe('002021712159733');
    expect(SETTLEMENT_CONFIG.IFSC_CODE).toBe('JIOP0000001');
    expect(SETTLEMENT_CONFIG.URN_NUMBER).toBe('92603438');
  });

  test('3. Razorpay order creation routes with settlement metadata notes', async () => {
    const order = await razorpayService.createOrder(499 * 100, 'INR', 'receipt-settle-001', {
      user_id: 'test-user-rohit',
      plan_name: 'PRO',
    });
    expect(order.id).toBeDefined();
    expect(order.amount).toBe(49900);
    expect(order.notes.beneficiary_name).toBe('Rohit Samadhan Pawar');
    expect(order.notes.bank_name).toBe('Jio Payments Bank');
    expect(order.notes.account_number).toBe('002021712159733');
    expect(order.notes.ifsc_code).toBe('JIOP0000001');
    expect(order.notes.urn_number).toBe('92603438');
    expect(order.notes.settlement_destination).toBe('MERCHANT_DIRECT_SETTLEMENT');
  });

  test('4. Free Tier Entitlements restrict premium features correctly', async () => {
    const testUserId = 'test-free-user-jest';
    const expEntitlement = await entitlementService.checkEntitlement(testUserId, 'EXPENSE_TRACKING');
    expect(expEntitlement.allowed).toBe(true);

    const waEntitlement = await entitlementService.checkEntitlement(testUserId, 'WHATSAPP_CHATBOT');
    expect(waEntitlement.allowed).toBe(false);

    const bankLimit = await entitlementService.checkLimit(testUserId, 'BANK_ACCOUNT');
    expect(bankLimit).toBe(1);
  });

  test('5. Instant Subscription Activation via Webhook (POST /api/v1/subscription/webhook)', async () => {
    const testUserId = 'user-auto-activate-99';
    const orderId = `order_sim_webhook_${Date.now()}`;
    const paymentId = `pay_sim_webhook_${Date.now()}`;

    // Create an initial order
    await paymentModel.createPaymentOrder({
      user_id: testUserId,
      plan_id: 'plan-pro',
      order_id: orderId,
      amount: 499,
      billing_cycle: 'MONTHLY',
    });

    // Send Webhook payload to activate
    const res = await request(app)
      .post('/api/v1/subscription/webhook')
      .send({
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: paymentId,
              order_id: orderId,
              amount: 49900,
              currency: 'INR',
              status: 'captured',
              method: 'upi',
              notes: {
                user_id: testUserId,
                plan_id: 'plan-pro',
                billing_cycle: 'MONTHLY',
              },
            },
          },
        },
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.activated).toBe(true);
    expect(res.body.data.plan_tier).toBe('PRO');
    expect(res.body.data.merchant_name).toBe('ENX Money');
    expect(res.body.data.settlement_destination).toBeUndefined();

    // Verify entitlements unlocked
    const waAccess = await entitlementService.checkEntitlement(testUserId, 'WHATSAPP_CHATBOT');
    expect(waAccess.allowed).toBe(true);

    const bankLimit = await entitlementService.checkLimit(testUserId, 'BANK_ACCOUNT');
    expect(bankLimit).toBe(10);
  });

  test('6. PDF Invoice Generation Stream (GET /api/v1/subscription/invoices/:id/pdf)', async () => {
    // Generate an invoice
    const inv = await invoiceModel.createInvoice({
      user_id: 'user-invoice-test',
      plan_name: 'Business Suite',
      billing_cycle: 'MONTHLY',
      subtotal: 1999,
      billing_name: 'Rohit Business Enterprise',
      billing_email: 'rohit@enxmoney.com',
    });

    const res = await request(app)
      .get(`/api/v1/subscription/invoices/${inv.id}/pdf`);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toBe('application/pdf');
    expect(res.body.length).toBeGreaterThan(500); // PDF binary data returned
  });

  test('7. Payment Gateway Order Creation API (POST /api/v1/payment/create-order)', async () => {
    // Advanced/Business plan ₹1,999 + 18% GST (₹359.82) = ₹2,358.82
    const res = await request(app)
      .post('/api/v1/payment/create-order')
      .send({
        plan_id: 'plan-business',
        billing_cycle: 'MONTHLY',
        user_id: 'usr_business_test_01',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.order_id).toBeDefined();
    expect(res.body.data.base_amount).toBe(1999);
    expect(res.body.data.gst_amount).toBe(359.82);
    expect(res.body.data.total_amount).toBe(2358.82);
    expect(res.body.data.amount).toBe(235882); // amount in paise
    expect(res.body.data.merchant_name).toBe('ENX Money');
    expect(res.body.data.business_name).toBe('ENX Money');
    expect(res.body.data.settlement_destination).toBeUndefined();
  });

  test('8. Payment Verification & Real Receipt ID (POST /api/v1/payment/verify)', async () => {
    const testUserId = 'usr_verified_test_02';
    const orderId = `order_sim_${Date.now()}`;
    const paymentId = `pay_sim_${Date.now()}`;

    // Seed order first
    await paymentModel.createPaymentOrder({
      user_id: testUserId,
      plan_id: 'plan-business',
      order_id: orderId,
      amount: 2358.82,
      billing_cycle: 'MONTHLY',
    });

    const res = await request(app)
      .post('/api/v1/payment/verify')
      .send({
        order_id: orderId,
        payment_id: paymentId,
        signature: 'sim_sig_verified_hash',
        plan_id: 'plan-business',
        billing_cycle: 'MONTHLY',
        user_id: testUserId,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.verified).toBe(true);
    expect(res.body.data.receipt_id).toMatch(/^ENXI-/);
    expect(res.body.data.subscription.status).toBe('ACTIVE');
    expect(res.body.data.entitlements).toBeDefined();
  });
});
