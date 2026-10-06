const http = require('http');
const InventoryModel = require('./src/models/inventory.model');
const AnalyticsService = require('./src/services/analytics.service');

async function runTests() {
  console.log('====================================================');
  console.log('🧪 RUNNING COMPREHENSIVE SUPPLIER FLOW TEST SUITE');
  console.log('====================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, testName, details = '') {
    if (condition) {
      console.log(`✅ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${testName} - ${details}`);
      failed++;
    }
  }

  // 1. Mobile Number Validation Test
  console.log('--- 1. MOBILE NUMBER VALIDATION ---');
  const validMobiles = ['9876543210', '+919876543210', '08123456789', '7001234567'];
  for (const m of validMobiles) {
    try {
      const sup = await InventoryModel.createSupplier({
        userId: 999,
        name: `Test Vendor ${m}`,
        contactNumber: m,
        companyName: 'Test Corp',
      });
      assert(sup && sup.id, `Valid mobile accepted: ${m}`);
    } catch (e) {
      assert(false, `Valid mobile accepted: ${m}`, e.message);
    }
  }

  const invalidMobiles = ['12345', 'abcdefghij', '5555555555', '0000000000', '1234567890123'];
  for (const im of invalidMobiles) {
    try {
      await InventoryModel.createSupplier({
        userId: 999,
        name: 'Invalid Mobile Vendor',
        contactNumber: im,
      });
      assert(false, `Invalid mobile rejected: ${im}`, 'Expected error but succeeded');
    } catch (e) {
      assert(true, `Invalid mobile rejected: ${im} (${e.message})`);
    }
  }

  // 2. GSTIN Validation Test
  console.log('\n--- 2. GSTIN VALIDATION ---');
  const validGSTINs = ['36AAAAA0000A1Z5', '27ABCDE1234F1Z5', '29ABCDE1234F2Z5'];
  for (const g of validGSTINs) {
    try {
      const sup = await InventoryModel.createSupplier({
        userId: 999,
        name: `GST Vendor ${g}`,
        contactNumber: '9876543210',
        gstin: g,
      });
      assert(sup && sup.gstin === g.toUpperCase(), `Valid GSTIN accepted: ${g}`);
    } catch (e) {
      assert(false, `Valid GSTIN accepted: ${g}`, e.message);
    }
  }

  const invalidGSTINs = ['INVALIDGST123', '36AAAAA0000A', '1234567890123456', '36AAAAA0000A15Z'];
  for (const ig of invalidGSTINs) {
    try {
      await InventoryModel.createSupplier({
        userId: 999,
        name: 'Invalid GST Vendor',
        contactNumber: '9876543210',
        gstin: ig,
      });
      assert(false, `Invalid GSTIN rejected: ${ig}`, 'Expected error but succeeded');
    } catch (e) {
      assert(true, `Invalid GSTIN rejected: ${ig} (${e.message})`);
    }
  }

  // 3. Full Address Hierarchy Test (Country -> State -> District -> Mandal/City -> Pincode)
  console.log('\n--- 3. ADDRESS HIERARCHY TEST ---');
  const fullSupplierData = {
    userId: 999,
    name: 'Balaji Industrial Spares',
    companyName: 'Balaji Heavy Industries Pvt Ltd',
    contactNumber: '9848022338',
    email: 'accounts@balajispares.in',
    gstin: '36ABCDE1234F1Z5',
    country: 'India',
    countryCode: 'IN',
    state: 'Telangana',
    district: 'Hyderabad',
    city: 'Banjara Hills',
    mandal: 'Shaikpet',
    pincode: '500034',
    addressLine: 'Plot 42, Road No 12',
    landmark: 'Opposite City Center Mall',
    openingBalance: 45000.50,
    outstandingPayable: 45000.50,
    paymentTerms: 'Net 30 Days',
    dueDate: '2026-10-30',
    dueReminderEnabled: true,
    reminderDate: '2026-10-27',
    notes: 'Primary supplier for CNC machinery components'
  };

  let savedSupplier;
  try {
    savedSupplier = await InventoryModel.createSupplier(fullSupplierData);
    assert(savedSupplier && savedSupplier.id, 'Full supplier created with ID');
    assert(savedSupplier.country === 'India', 'Country is India');
    assert(savedSupplier.state === 'Telangana', 'State is Telangana');
    assert(savedSupplier.district === 'Hyderabad', 'District is Hyderabad');
    assert(savedSupplier.city === 'Banjara Hills', 'City is Banjara Hills');
    assert(savedSupplier.pincode === '500034', 'Pincode is 500034');
    assert(savedSupplier.address.includes('Plot 42'), 'Address contains line address');
    assert(savedSupplier.paymentTerms === 'Net 30 Days', 'Payment terms saved');
    assert(savedSupplier.dueDate === '2026-10-30', 'Due date saved');
    assert(savedSupplier.dueReminderEnabled === true, 'Due reminder enabled');
    assert(savedSupplier.reminderDate === '2026-10-27', 'Reminder date saved');
    assert(savedSupplier.outstandingPayable === 45000.50, 'Outstanding payable matches opening balance');
    assert(savedSupplier.currentBalance === 45000.50, 'Current balance reflects payable');
  } catch (e) {
    assert(false, 'Create full supplier', e.message);
  }

  // 4. Immediate Retrieval in Supplier List
  console.log('\n--- 4. IMMEDIATE RETRIEVAL IN LIST ---');
  try {
    const list = await InventoryModel.getSuppliers(999);
    assert(Array.isArray(list) && list.length > 0, `Supplier list retrieved, count = ${list.length}`);
    const found = list.find(s => s.id === savedSupplier.id);
    assert(found !== undefined, 'Newly saved supplier is immediately found in list');
    assert(found && found.name === 'Balaji Industrial Spares', 'Supplier name matches');
    assert(found && found.gstin === '36ABCDE1234F1Z5', 'GSTIN matches');
  } catch (e) {
    assert(false, 'Supplier list retrieval', e.message);
  }

  // 5. Opening Payable & Data Analysis / Dashboard Reflection
  console.log('\n--- 5. DATA ANALYSIS & PAYABLES AGGREGATION ---');
  try {
    const kpi = await AnalyticsService.getKpi(999);
    assert(kpi !== null, 'Financial KPI summary calculated successfully');
    assert(kpi.outstandingPayables >= 45000.50, `Dashboard outstandingPayables (${kpi.outstandingPayables}) accounts for supplier opening balance`);
    console.log(`   Outstanding Payables in Dashboard: ₹${kpi.outstandingPayables}`);
    console.log(`   Total Revenue: ₹${kpi.totalRevenue}`);
    console.log(`   Total Expenses: ₹${kpi.totalExpense}`);
    console.log(`   Net Profit: ₹${kpi.netProfit}`);
  } catch (e) {
    assert(false, 'Data analysis calculation', e.message);
  }

  // 6. Persistence across findById & update
  console.log('\n--- 6. PERSISTENCE & UPDATE ---');
  try {
    const fetched = await InventoryModel.findSupplierById(savedSupplier.id, 999);
    assert(fetched && fetched.name === 'Balaji Industrial Spares', 'findSupplierById returns correct supplier');

    const updated = await InventoryModel.updateSupplier(savedSupplier.id, {
      paymentTerms: 'Net 15 Days',
      dueDate: '2026-10-15',
    }, 999);
    assert(updated && updated.paymentTerms === 'Net 15 Days', 'Supplier payment terms updated');
    assert(updated && updated.dueDate === '2026-10-15', 'Supplier due date updated');

    const recheck = await InventoryModel.findSupplierById(savedSupplier.id, 999);
    assert(recheck && recheck.paymentTerms === 'Net 15 Days', 'Updated fields persisted in store');
  } catch (e) {
    assert(false, 'Update and persistence', e.message);
  }

  console.log('\n====================================================');
  console.log(`RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log('====================================================');
  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(err => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
