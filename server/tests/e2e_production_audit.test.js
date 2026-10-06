const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db.config');
const OtpModel = require('../src/models/otp.model');

describe('E2E Production Audit: Flow, Persistence, Isolation & Exact Math', () => {
  const userA = {
    email: `audit_user_a_${Date.now()}@enxmoney.com`,
    password: 'SecurePassword123!',
    name: 'Audit User A',
    phone: '9876543210',
  };

  const userB = {
    email: `audit_user_b_${Date.now()}@enxmoney.com`,
    password: 'SecurePassword456!',
    name: 'Audit User B',
    phone: '9876543211',
  };

  let tokenA = '';
  let tokenB = '';
  let customerAId = '';
  let supplierAId = '';
  let productAId = '';
  let otpA = '';
  let otpB = '';

  beforeAll(async () => {
    const randA = Math.floor(10000000 + Math.random() * 90000000);
    const randB = Math.floor(10000000 + Math.random() * 90000000);
    userA.email = `audit_user_a_${Date.now()}_${randA}@enxmoney.com`;
    userA.phone = `91${randA}`;
    userB.email = `audit_user_b_${Date.now()}_${randB}@enxmoney.com`;
    userB.phone = `91${randB}`;
    await db.initDb();
  });

  test('Step 1: User A requests dynamic registration OTP', async () => {
    const res = await request(app)
      .post('/api/auth/send-otp')
      .send({
        email: userA.email,
        phone: userA.phone,
        name: userA.name,
        password: userA.password,
        purpose: 'REGISTRATION',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const bcrypt = require('bcryptjs');
    otpA = '849201';
    await OtpModel.createOtp({
      email: userA.email.toLowerCase().trim(),
      otpHash: await bcrypt.hash(otpA, 10),
      purpose: 'REGISTRATION',
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });
  });

  test('Step 2: User A verifies registration OTP and receives JWT', async () => {
    const res = await request(app)
      .post('/api/auth/verify-otp')
      .send({
        email: userA.email,
        otp: otpA,
        password: userA.password,
        name: userA.name,
        phone: userA.phone,
        purpose: 'REGISTRATION',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    tokenA = res.body.data.token;
  });

  test('Step 3: User A signs out and logs in via Password Login flow', async () => {
    // Logout
    const logoutRes = await request(app)
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(logoutRes.status).toBe(200);

    // Password login
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({
        email: userA.email,
        password: userA.password,
      });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.success).toBe(true);
    expect(loginRes.body.data.token).toBeDefined();
    tokenA = loginRes.body.data.token; // refreshed token
  });

  test('Step 4: User A creates a real customer with address & credit limit', async () => {
    const res = await request(app)
      .post('/api/customers')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        name: 'Sharma Textiles',
        phone: '9848011223',
        companyName: 'Sharma Fabrics LLP',
        email: 'billing@sharmatextiles.in',
        country: 'India',
        countryCode: 'IN',
        state: 'Telangana',
        district: 'Hyderabad',
        pincode: '500001',
        addressLine: 'Shop 12, Pathergatti',
        gstin: '36AAAFS1234F1Z1',
        openingBalance: 2000.00,
        creditLimit: 50000.00,
        blockOnCreditBreach: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBeDefined();
    expect(res.body.data.name).toBe('Sharma Textiles');
    customerAId = res.body.data.id;
  });

  test('Step 5: User A retrieves customer list and sees newly created customer', async () => {
    const res = await request(app)
      .get('/api/customers')
      .set('Authorization', `Bearer ${tokenA}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const customers = res.body.data.customers;
    expect(customers.length).toBeGreaterThanOrEqual(1);
    const created = customers.find(c => c.id === customerAId);
    expect(created).toBeDefined();
    expect(created.name).toBe('Sharma Textiles');
    expect(created.currentBalance).toBe(2000.00);
  });

  test('Step 6: User B registers and MUST NOT see User A customers (Data Isolation)', async () => {
    // Send OTP for User B
    const sendRes = await request(app)
      .post('/api/auth/send-otp')
      .send({
        email: userB.email,
        phone: userB.phone,
        name: userB.name,
        password: userB.password,
        purpose: 'REGISTRATION',
      });

    expect(sendRes.status).toBe(200);
    expect(sendRes.body.success).toBe(true);

    const bcrypt = require('bcryptjs');
    otpB = '928410';
    await OtpModel.createOtp({
      email: userB.email.toLowerCase().trim(),
      otpHash: await bcrypt.hash(otpB, 10),
      purpose: 'REGISTRATION',
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    // Verify OTP for User B
    const verifyRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({
        email: userB.email,
        otp: otpB,
        password: userB.password,
        name: userB.name,
        phone: userB.phone,
        purpose: 'REGISTRATION',
      });

    tokenB = verifyRes.body.data.token;

    // User B fetches customers
    const res = await request(app)
      .get('/api/customers')
      .set('Authorization', `Bearer ${tokenB}`);

    expect(res.status).toBe(200);
    const customers = res.body.data.customers;
    const leakedCustomer = customers.find(c => c.id === customerAId);
    expect(leakedCustomer).toBeUndefined();
  });

  test('Step 7: User A creates a Supplier and Product', async () => {
    // Supplier
    const suppRes = await request(app)
      .post('/api/suppliers')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        name: 'Venkateshwara Yarn Mills',
        contactNumber: '9123450000',
        companyName: 'VY Mills Ltd',
        gstin: '36AAACV9876E1Z5',
        openingBalance: 0,
      });

    expect(suppRes.status).toBe(201);
    supplierAId = suppRes.body.data.id;

    // Product
    const prodRes = await request(app)
      .post('/api/inventory/products')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        name: 'Pure Silk Sarees (Pack of 5)',
        sku: `SKU-SILK-${Date.now().toString().slice(-4)}`,
        category: 'Apparel',
        unit: 'Packs',
        costPrice: 4000.00,
        sellingPrice: 7000.00,
        gstRate: 12,
        stockQuantity: 20,
      });

    expect(prodRes.status).toBe(201);
    expect(prodRes.body.data.currentStock).toBe(20);
    productAId = prodRes.body.data.id;
  });

  test('Step 8: User A generates a GST Sales Invoice -> Verifies Math, Stock Deduction & Khata', async () => {
    const res = await request(app)
      .post('/api/invoices')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        customerId: customerAId,
        customerName: 'Sharma Textiles',
        customerGstin: '36AAAFS1234F1Z1',
        merchantStateCode: '36', // Telangana -> Intra-State
        customerStateCode: '36', // Telangana -> Intra-State
        invoiceType: 'GST',
        items: [
          {
            productId: productAId,
            description: 'Pure Silk Sarees (Pack of 5)',
            hsnCode: '5007',
            quantity: 3,
            unitPrice: 7000.00,
            discount: 1000.00,
            gstRate: 12,
          }
        ],
        amountPaid: 5000.00,
      });

    expect(res.status).toBe(201);
    const inv = res.body.data;

    // Math Verification:
    // Taxable: (3 * 7000) - 1000 = 20000.00
    // CGST 6%: 1200.00
    // SGST 6%: 1200.00
    // Total: 20000 + 1200 + 1200 = 22400.00
    // Balance Due: 22400 - 5000 = 17400.00
    expect(inv.taxableTotal).toBe(20000.00);
    expect(inv.cgstTotal).toBe(1200.00);
    expect(inv.sgstTotal).toBe(1200.00);
    expect(inv.igstTotal).toBe(0.00);
    expect(inv.grandTotal).toBe(22400.00);
    expect(inv.amountPaid).toBe(5000.00);
    expect(inv.balanceDue).toBe(17400.00);

    // Verify Stock Deduction:
    // Started at 20, sold 3 -> 17 remaining
    const prodCheck = await request(app)
      .get(`/api/inventory/products/${productAId}`)
      .set('Authorization', `Bearer ${tokenA}`);
    expect(prodCheck.body.data.currentStock).toBe(17);

    // Verify Customer Balance Update:
    // Previous balance 2000 + newly due 17400 = 19400
    const custCheck = await request(app)
      .get(`/api/customers/${customerAId}`)
      .set('Authorization', `Bearer ${tokenA}`);
    expect(custCheck.body.data.currentBalance).toBe(19400.00);
  });

  test('Step 9: User A records a customer payment -> Verifies Customer Balance decreases', async () => {
    const res = await request(app)
      .post(`/api/customers/${customerAId}/ledger`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        entryType: 'GOT',
        amount: 9400.00,
        paymentMode: 'UPI',
        description: 'UPI Payment received from Sharma Textiles',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    // Verify balance: 19400 - 9400 = 10000.00
    const custCheck = await request(app)
      .get(`/api/customers/${customerAId}`)
      .set('Authorization', `Bearer ${tokenA}`);
    expect(custCheck.body.data.currentBalance).toBe(10000.00);
  });

  test('Step 10: User A checks Analytics Dashboard KPIs and verifies real database figures', async () => {
    const res = await request(app)
      .get('/api/analytics/kpi?profile_type=business')
      .set('Authorization', `Bearer ${tokenA}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const kpi = res.body.data;

    // User A's outstanding receivables equals customer dues (10000.00)
    expect(kpi.outstandingReceivables).toBe(10000.00);
  });

  test('Step 11: Disk Resilience Test - Simulating server restart and verifying zero data loss', async () => {
    // Clear in-memory maps to simulate container termination
    db.inMemoryStore.customers.clear();
    db.inMemoryStore.products.clear();
    db.inMemoryStore.invoices.clear();

    // Re-initialize from disk
    db.loadResilienceStore();

    // Verify Customer A was restored
    const restoredCust = db.inMemoryStore.customers.get(customerAId);
    expect(restoredCust).toBeDefined();
    expect(restoredCust.name).toBe('Sharma Textiles');
    expect(restoredCust.currentBalance).toBe(10000.00);

    // Verify Product A was restored with accurate stock
    const restoredProd = db.inMemoryStore.products.get(productAId);
    expect(restoredProd).toBeDefined();
    expect(restoredProd.currentStock).toBe(17);
  });
});
