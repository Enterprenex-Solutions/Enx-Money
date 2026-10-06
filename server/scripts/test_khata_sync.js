/**
 * test_khata_sync.js
 * Comprehensive automated verification script for ENX Money:
 * 1. User A registration & login
 * 2. Customer "Ravi Kumar" creation
 * 3. Initial state verification (Revenue = 0, Receivables = 0, Ravi balance = 0)
 * 4. Sale ₹1,500 ("Gave ₹ (Sale)")
 * 5. Verify: Ravi balance = ₹1,500, Receivables = ₹1,500, Revenue = ₹1,500
 * 6. Payment ₹500 ("Got ₹ (Payment)")
 * 7. Verify: Ravi balance = ₹1,000, Receivables = ₹1,000, Revenue = ₹1,500 (not double counted!)
 * 8. Sale ₹2,000 ("Gave ₹ (Sale)")
 * 9. Verify: Ravi balance = ₹3,000, Receivables = ₹3,000, Revenue = ₹3,500
 * 10. User B registration & login
 * 11. Cross-account isolation check: User B sees 0 customers, 0 transactions, 0 revenue, 0 receivables
 * 12. Dynamic Search check: search by Name ("Ravi"), Mobile ("9876543210"), and Email ("ravi.test@example.com")
 */

const http = require('http');

const BASE_URL = 'http://localhost:5000';

function makeRequest(path, method = 'GET', body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(
      url,
      {
        method,
        headers,
      },
      (res) => {
        let raw = '';
        res.on('data', (chunk) => (raw += chunk));
        res.on('end', () => {
          let data = null;
          try {
            data = JSON.parse(raw);
          } catch (_) {
            data = raw;
          }
          resolve({ status: res.statusCode, body: data });
        });
      }
    );

    req.on('error', (err) => reject(err));
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ ASSERTION FAILED: ${message}`);
    process.exit(1);
  } else {
    console.log(`✅ ${message}`);
  }
}

async function runTests() {
  console.log('========================================================');
  console.log('🚀 RUNNING ENX MONEY KHATA & LIVE SYNC VERIFICATION SUITE');
  console.log('========================================================\n');

  const timestamp = Date.now();
  const userAEmail = `usera_${timestamp}@enxmoney.test`;
  const userBEmail = `userb_${timestamp}@enxmoney.test`;

  // 1. Register User A
  console.log('--- STEP 1: Register User A ---');
  const regARes = await makeRequest('/api/auth/register', 'POST', {
    name: 'Alice Sharma',
    email: userAEmail,
    password: 'Password123!',
    phone: '9123456780',
    businessName: 'Sharma Enterprises',
  });
  assert(regARes.status === 200 || regARes.status === 201, `User A registered successfully (${userAEmail})`);
  const tokenA = (regARes.body.data && (regARes.body.data.accessToken || regARes.body.data.token)) || regARes.body.accessToken || regARes.body.token;
  assert(tokenA, 'User A received JWT token');

  // 2. Create customer Ravi Kumar for User A
  console.log('\n--- STEP 2: Create Customer Ravi Kumar ---');
  const custRes = await makeRequest('/api/customers', 'POST', {
    name: 'Ravi Kumar',
    phone: '9876543210',
    email: 'ravi.test@example.com',
    companyName: 'Kumar Traders',
    openingBalance: 0,
    creditLimit: 50000,
  }, tokenA);
  assert(custRes.status === 200 || custRes.status === 201, 'Customer Ravi Kumar created');
  const customerId = custRes.body.data ? custRes.body.data.id : custRes.body.customer.id;
  assert(customerId, `Customer ID acquired: ${customerId}`);

  // 3. Check initial state
  console.log('\n--- STEP 3: Check Initial State ---');
  const kpiInitial = await makeRequest('/api/analytics/kpi?profile_type=business', 'GET', null, tokenA);
  assert(kpiInitial.status === 200, 'Fetched initial KPI for User A');
  const kpiDataInit = kpiInitial.body.data || kpiInitial.body;
  assert(Number(kpiDataInit.totalRevenue) === 0, `Initial Total Revenue is 0 (got ${kpiDataInit.totalRevenue})`);
  assert(Number(kpiDataInit.outstandingReceivables) === 0, `Initial Receivables is 0 (got ${kpiDataInit.outstandingReceivables})`);

  // 4. Record Sale ₹1,500 (GAVE / Sale / Udhaar)
  console.log('\n--- STEP 4: Record Sale ₹1,500 (Gave ₹) ---');
  const sale1Res = await makeRequest(`/api/customers/${customerId}/ledger`, 'POST', {
    entryType: 'GAVE',
    amount: 1500,
    description: 'Cotton fabric shirts order #101',
    paymentMode: 'CREDIT',
  }, tokenA);
  assert(sale1Res.status === 200 || sale1Res.status === 201, 'Sale ₹1,500 recorded in Khata ledger');

  // 5. Verify state after Sale 1
  console.log('\n--- STEP 5: Verify State After Sale 1 ---');
  const custAfterSale1 = await makeRequest(`/api/customers/${customerId}`, 'GET', null, tokenA);
  const cust1 = custAfterSale1.body.data || custAfterSale1.body;
  assert(Number(cust1.currentBalance) === 1500, `Ravi Kumar balance is ₹1,500 (got ${cust1.currentBalance})`);

  const kpiAfterSale1 = await makeRequest('/api/analytics/kpi?profile_type=business', 'GET', null, tokenA);
  const kpi1 = kpiAfterSale1.body.data || kpiAfterSale1.body;
  assert(Number(kpi1.totalRevenue) === 1500, `Dashboard Total Revenue is ₹1,500 (got ${kpi1.totalRevenue})`);
  assert(Number(kpi1.outstandingReceivables) === 1500, `Dashboard Receivables is ₹1,500 (got ${kpi1.outstandingReceivables})`);

  const txAfterSale1 = await makeRequest('/api/transactions?limit=5', 'GET', null, tokenA);
  const txList1 = Array.isArray(txAfterSale1.body.data) ? txAfterSale1.body.data : (txAfterSale1.body.transactions || []);
  assert(txList1.some(t => (t.referenceType === 'KHATA_SALE' || t.category === 'Sales') && Number(t.amount) === 1500), 'Transactions list contains KHATA_SALE for ₹1,500');

  // 6. Record Payment ₹500 (GOT / Payment / Jama)
  console.log('\n--- STEP 6: Record Payment ₹500 (Got ₹) ---');
  const pay1Res = await makeRequest(`/api/customers/${customerId}/ledger`, 'POST', {
    entryType: 'GOT',
    amount: 500,
    description: 'UPI payment received',
    paymentMode: 'UPI',
  }, tokenA);
  assert(pay1Res.status === 200 || pay1Res.status === 201, 'Payment ₹500 recorded in Khata ledger');

  // 7. Verify state after Payment 1
  console.log('\n--- STEP 7: Verify State After Payment 1 ---');
  const custAfterPay1 = await makeRequest(`/api/customers/${customerId}`, 'GET', null, tokenA);
  const cust2 = custAfterPay1.body.data || custAfterPay1.body;
  assert(Number(cust2.currentBalance) === 1000, `Ravi Kumar balance is ₹1,000 (got ${cust2.currentBalance})`);

  const kpiAfterPay1 = await makeRequest('/api/analytics/kpi?profile_type=business', 'GET', null, tokenA);
  const kpi2 = kpiAfterPay1.body.data || kpiAfterPay1.body;
  assert(Number(kpi2.outstandingReceivables) === 1000, `Dashboard Receivables is ₹1,000 (got ${kpi2.outstandingReceivables})`);
  assert(Number(kpi2.totalRevenue) === 1500, `Total Revenue remains ₹1,500 without double counting (got ${kpi2.totalRevenue})`);

  // 8. Record Sale ₹2,000 (GAVE / Sale / Udhaar)
  console.log('\n--- STEP 8: Record Second Sale ₹2,000 (Gave ₹) ---');
  const sale2Res = await makeRequest(`/api/customers/${customerId}/ledger`, 'POST', {
    entryType: 'GAVE',
    amount: 2000,
    description: 'Bulk raw silk material #102',
    paymentMode: 'CREDIT',
  }, tokenA);
  assert(sale2Res.status === 200 || sale2Res.status === 201, 'Sale ₹2,000 recorded in Khata ledger');

  // 9. Verify state after Sale 2
  console.log('\n--- STEP 9: Verify State After Sale 2 ---');
  const custAfterSale2 = await makeRequest(`/api/customers/${customerId}`, 'GET', null, tokenA);
  const cust3 = custAfterSale2.body.data || custAfterSale2.body;
  assert(Number(cust3.currentBalance) === 3000, `Ravi Kumar balance is ₹3,000 (got ${cust3.currentBalance})`);

  const kpiAfterSale2 = await makeRequest('/api/analytics/kpi?profile_type=business', 'GET', null, tokenA);
  const kpi3 = kpiAfterSale2.body.data || kpiAfterSale2.body;
  assert(Number(kpi3.outstandingReceivables) === 3000, `Dashboard Receivables is ₹3,000 (got ${kpi3.outstandingReceivables})`);
  assert(Number(kpi3.totalRevenue) === 3500, `Total Revenue is ₹3,500 (₹1,500 + ₹2,000) (got ${kpi3.totalRevenue})`);

  // 10. Dynamic Search Verification
  console.log('\n--- STEP 10: Dynamic Search Verification ---');
  // Search by Name
  const searchNameRes = await makeRequest('/api/customers?search=Ravi', 'GET', null, tokenA);
  const byName = (searchNameRes.body.data && searchNameRes.body.data.customers) || searchNameRes.body.customers || [];
  assert(byName.length === 1 && byName[0].name === 'Ravi Kumar', 'Search by Name "Ravi" found Ravi Kumar');

  // Search by Mobile
  const searchPhoneRes = await makeRequest('/api/customers?search=98765', 'GET', null, tokenA);
  const byPhone = (searchPhoneRes.body.data && searchPhoneRes.body.data.customers) || searchPhoneRes.body.customers || [];
  assert(byPhone.length === 1 && byPhone[0].name === 'Ravi Kumar', 'Search by Phone "98765" found Ravi Kumar');

  // Search by Email
  const searchEmailRes = await makeRequest('/api/customers?search=ravi.test', 'GET', null, tokenA);
  const byEmail = (searchEmailRes.body.data && searchEmailRes.body.data.customers) || searchEmailRes.body.customers || [];
  assert(byEmail.length === 1 && byEmail[0].name === 'Ravi Kumar', 'Search by Email "ravi.test" found Ravi Kumar');

  // Search non-existent
  const searchNoneRes = await makeRequest('/api/customers?search=xyznonexistent', 'GET', null, tokenA);
  const byNone = (searchNoneRes.body.data && searchNoneRes.body.data.customers) || searchNoneRes.body.customers || [];
  assert(byNone.length === 0, 'Search by non-existent query returned 0 results');

  // 11. Cross-Account Data Isolation Test (User B)
  console.log('\n--- STEP 11: Cross-Account Data Isolation (User B) ---');
  const regBRes = await makeRequest('/api/auth/register', 'POST', {
    name: 'Bob Patel',
    email: userBEmail,
    password: 'Password123!',
    phone: '9234567891',
    businessName: 'Patel Logistics',
  });
  assert(regBRes.status === 200 || regBRes.status === 201, `User B registered successfully (${userBEmail})`);
  const tokenB = (regBRes.body.data && (regBRes.body.data.accessToken || regBRes.body.data.token)) || regBRes.body.accessToken || regBRes.body.token;
  assert(tokenB, 'User B received JWT token');

  // Check User B's customers
  const custBRes = await makeRequest('/api/customers', 'GET', null, tokenB);
  const custBList = (custBRes.body.data && custBRes.body.data.customers) || custBRes.body.customers || [];
  assert(custBList.length === 0, `User B has 0 customers (strict isolation verified, got ${custBList.length})`);
  assert(!custBList.some(c => c.email === 'ravi.test@example.com'), 'User B CANNOT see Ravi Kumar or ravi.test@example.com');

  // Check User B's KPIs
  const kpiBRes = await makeRequest('/api/analytics/kpi?profile_type=business', 'GET', null, tokenB);
  const kpiB = kpiBRes.body.data || kpiBRes.body;
  assert(Number(kpiB.totalRevenue) === 0, `User B's Total Revenue is isolated at ₹0 (got ${kpiB.totalRevenue})`);
  assert(Number(kpiB.outstandingReceivables) === 0, `User B's Receivables is isolated at ₹0 (got ${kpiB.outstandingReceivables})`);

  // Check User B's transactions
  const txBRes = await makeRequest('/api/transactions', 'GET', null, tokenB);
  const txBList = Array.isArray(txBRes.body.data) ? txBRes.body.data : (txBRes.body.transactions || []);
  assert(txBList.length === 0, `User B's Transactions is empty (got ${txBList.length})`);

  console.log('\n========================================================');
  console.log('🎉 ALL 11 VERIFICATION STAGES PASSED WITH 100% SUCCESS!');
  console.log('========================================================');
}

runTests().catch((err) => {
  console.error('Fatal Test Error:', err);
  process.exit(1);
});
