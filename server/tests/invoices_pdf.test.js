const request = require('supertest');
const app = require('../src/app');

describe('PDF Download API Endpoints', () => {
  let createdInvoiceId;
  let createdCustomerId;

  beforeAll(async () => {
    // Create customer
    const custRes = await request(app)
      .post('/api/v1/customers/create')
      .send({
        name: 'Venkatesh Rao',
        phone: '9876543210',
        email: 'venkatesh@example.com',
        openingBalance: 1200,
        gstin: '36AAACV1234F1Z0',
      });
    if (custRes.body && custRes.body.data) {
      createdCustomerId = custRes.body.data.id;
    }

    // Add ledger entry
    if (createdCustomerId) {
      await request(app)
        .post(`/api/v1/customers/${createdCustomerId}/ledger`)
        .send({
          entryType: 'GAVE',
          amount: 5000,
          paymentMode: 'CASH',
          description: 'Cotton Fabric Sale',
        });
    }

    // Create invoice
    const invRes = await request(app)
      .post('/api/v1/invoices')
      .send({
        customerId: createdCustomerId || 'cust_test_1',
        customerName: 'Venkatesh Rao',
        customerGstin: '36AAACV1234F1Z0',
        items: [
          {
            description: 'Silk Yarn (Spool)',
            hsnCode: '5004',
            quantity: 5,
            unitPrice: 1200,
            discount: 0,
            gstRate: 18,
          },
        ],
      });
    if (invRes.body && invRes.body.data) {
      createdInvoiceId = invRes.body.data.id;
    }
  });

  test('GET /api/v1/invoices/:id/pdf streams a valid uncorrupted PDF document', async () => {
    const res = await request(app)
      .get(`/api/v1/invoices/${createdInvoiceId || 'inv_001'}/pdf`)
      .expect(200);

    expect(res.headers['content-type']).toBe('application/pdf');
    expect(res.headers['content-disposition']).toContain('attachment; filename=');
    // Check for standard PDF magic header '%PDF'
    const isPdfHeader = res.body.slice(0, 4).toString() === '%PDF' || res.text.startsWith('%PDF');
    expect(isPdfHeader).toBe(true);
  });

  test('GET /api/v1/customers/:id/statement-pdf streams a valid uncorrupted statement PDF', async () => {
    const res = await request(app)
      .get(`/api/v1/customers/${createdCustomerId}/statement-pdf`)
      .expect(200);

    expect(res.headers['content-type']).toBe('application/pdf');
    expect(res.headers['content-disposition']).toContain('attachment; filename=');
    const isPdfHeader = res.body.slice(0, 4).toString() === '%PDF' || res.text.startsWith('%PDF');
    expect(isPdfHeader).toBe(true);
  });

  test('GET /api/v1/invoices/non_existent_id/pdf returns 404', async () => {
    const res = await request(app)
      .get('/api/v1/invoices/non_existent_id_99999/pdf')
      .expect(404);

    expect(res.body.success).toBe(false);
  });
});
