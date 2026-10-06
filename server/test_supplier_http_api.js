const http = require('http');
const app = require('./src/app');

async function testHttpRoutes() {
  console.log('====================================================');
  console.log('🌐 TESTING FULL HTTP API ROUTES FOR SUPPLIERS');
  console.log('====================================================\n');

  const server = app.listen(0);
  const port = server.address().port;

  function request(method, path, body = null, headers = {}) {
    return new Promise((resolve, reject) => {
      const payload = body ? JSON.stringify(body) : null;
      const req = http.request(
        {
          hostname: '127.0.0.1',
          port,
          path,
          method,
          headers: {
            'Content-Type': 'application/json',
            ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
            ...headers,
          },
        },
        (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => {
            try {
              resolve({ status: res.statusCode, body: data ? JSON.parse(data) : {} });
            } catch (e) {
              resolve({ status: res.statusCode, raw: data });
            }
          });
        }
      );
      req.on('error', reject);
      if (payload) req.write(payload);
      req.end();
    });
  }

  let passed = 0;
  let failed = 0;

  function assert(condition, name, details = '') {
    if (condition) {
      console.log(`✅ PASS: ${name}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${name} - ${details}`);
      failed++;
    }
  }

  try {
    // 1. GET /api/inventory/suppliers (Empty or initial list)
    const listRes1 = await request('GET', '/api/inventory/suppliers');
    assert(listRes1.status === 200, 'GET /api/inventory/suppliers returns 200 OK');
    assert(Array.isArray(listRes1.body.data || listRes1.body), 'GET suppliers returns array');

    // 2. GET /api/suppliers alias route
    const listRes2 = await request('GET', '/api/suppliers');
    assert(listRes2.status === 200, 'GET /api/suppliers returns 200 OK');

    // 3. POST /api/inventory/suppliers - Validation Error (Missing phone)
    const badRes = await request('POST', '/api/inventory/suppliers', {
      name: 'No Phone Supplier',
    });
    assert(badRes.status === 400, 'POST supplier without phone returns 400 Bad Request');

    // 4. POST /api/inventory/suppliers - Validation Error (Invalid GSTIN)
    const badGstRes = await request('POST', '/api/inventory/suppliers', {
      name: 'Bad GST Supplier',
      contactNumber: '9848022338',
      gstin: 'NOT_A_VALID_GST',
    });
    assert(badGstRes.status === 400, 'POST supplier with invalid GSTIN returns 400 Bad Request');

    // 5. POST /api/inventory/suppliers - Successful creation with complete hierarchy
    const newSupplierPayload = {
      name: 'Sri Krishna Steels & Hardware',
      companyName: 'Krishna Industrial Steels LLP',
      contactNumber: '9123456789',
      email: 'sales@krishnasteels.com',
      gstin: '36AAAAA0000A1Z5',
      country: 'India',
      state: 'Telangana',
      district: 'Hyderabad',
      city: 'Secunderabad',
      pincode: '500003',
      addressLine: 'MG Road, General Bazar',
      category: 'HARDWARE',
      openingBalance: 75000,
      outstandingPayable: 75000,
      paymentTerms: 'Net 45 Days',
      dueDate: '2026-11-15',
      dueReminderEnabled: true,
      reminderDate: '2026-11-12',
    };

    const createRes = await request('POST', '/api/inventory/suppliers', newSupplierPayload);
    assert(createRes.status === 201 || createRes.status === 200, `POST /api/inventory/suppliers returns ${createRes.status} Created`);
    const created = createRes.body.data || createRes.body;
    assert(created && created.id, 'Created supplier contains unique ID');
    assert(created.outstandingPayable === 75000, 'Outstanding payable is 75000');
    assert(created.paymentTerms === 'Net 45 Days', 'Payment terms saved properly');
    assert(created.district === 'Hyderabad', 'District saved properly');

    // 6. Immediate GET check to confirm presence in list
    const listResAfter = await request('GET', '/api/inventory/suppliers');
    const allSuppliers = listResAfter.body.data || listResAfter.body;
    const found = allSuppliers.find(s => s.id === created.id);
    assert(found !== undefined, 'Newly created supplier is immediately listed via HTTP GET');
    assert(found && found.name === 'Sri Krishna Steels & Hardware', 'Supplier name matches in list');

    // 7. Check Analytics KPI endpoint updates outstanding payables
    const kpiRes = await request('GET', '/api/v1/analytics/kpi');
    assert(kpiRes.status === 200, 'GET /api/v1/analytics/kpi returns 200 OK');
    const kpiData = kpiRes.body.data || kpiRes.body;
    assert(Number(kpiData.outstandingPayables) >= 75000, `Analytics outstandingPayables (₹${kpiData.outstandingPayables}) reflects supplier opening balance`);

  } catch (err) {
    console.error('Test execution error:', err);
    failed++;
  } finally {
    server.close();
  }

  console.log('\n====================================================');
  console.log(`HTTP RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log('====================================================');
  process.exit(failed > 0 ? 1 : 0);
}

testHttpRoutes();
