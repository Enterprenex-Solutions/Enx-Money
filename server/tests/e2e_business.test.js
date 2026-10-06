const CustomerModel = require('../src/models/customer.model');
const InventoryModel = require('../src/models/inventory.model');
const InvoiceModel = require('../src/models/invoice.model');

describe('E2E Business Suite: Customers, Inventory & Invoices', () => {
  let createdCust;
  let createdProd;
  let createdInvoice;

  test('1. Creates and lists customers with dynamic balance', async () => {
    createdCust = await CustomerModel.create({
      userId: 'user_test_01',
      name: 'Ravi Teja Traders',
      phone: '9988776655',
      email: 'ravi@traders.com',
      companyName: 'Ravi Fabrics & Trims',
      gstin: '36ABCDE1234F1Z5',
      openingBalance: 2000.00,
    });

    expect(createdCust).toBeDefined();
    expect(createdCust.name).toBe('Ravi Teja Traders');

    const listRes = await CustomerModel.findAll({ userId: 'user_test_01' });
    expect(listRes.customers.length).toBeGreaterThan(0);
  });

  test('1b. Creates customer with minimal fields (name, phone, default country) without throwing location error', async () => {
    const minimalCust = await CustomerModel.create({
      userId: 'user_test_01',
      name: 'John Doe Enterprise',
      phone: '9876543210',
      country: 'India',
      countryCode: 'IN',
      state: '',
      district: '',
      pincode: '',
    });

    expect(minimalCust).toBeDefined();
    expect(minimalCust.name).toBe('John Doe Enterprise');
    expect(minimalCust.phone).toBe('9876543210');

    const listRes = await CustomerModel.findAll({ userId: 'user_test_01' });
    const found = listRes.customers.find(c => c.id === minimalCust.id);
    expect(found).toBeDefined();
    expect(found.name).toBe('John Doe Enterprise');
  });

  test('2. Creates products in inventory with stock levels', async () => {
    createdProd = await InventoryModel.createProduct({
      sku: `SKU-SILK-${Date.now()}`,
      name: 'Pure Mulberry Silk (10m Roll)',
      category: 'Fabrics',
      unit: 'Rolls',
      hsnCode: '5007',
      costPrice: 800.00,
      sellingPrice: 1000.00,
      gstRate: 18.00,
      currentStock: 100,
    });

    expect(createdProd).toBeDefined();
    expect(createdProd.currentStock).toBe(100);
  });

  test('3. Generates GST Invoice, deducts stock, and debits customer ledger', async () => {
    createdInvoice = await InvoiceModel.create({
      userId: 'user_test_01',
      customerId: createdCust.id,
      customerName: createdCust.name,
      customerGstin: createdCust.gstin,
      merchantStateCode: '36',
      customerStateCode: '36', // Intra-state: 9% CGST + 9% SGST
      items: [
        {
          productId: createdProd.id,
          description: createdProd.name,
          hsnCode: createdProd.hsnCode,
          quantity: 5,
          unitPrice: 1000.00,
          discount: 0,
          gstRate: 18,
        }
      ],
    });

    expect(createdInvoice).toBeDefined();
    expect(createdInvoice.taxableTotal).toBe(5000);
    expect(createdInvoice.cgstTotal).toBe(450);
    expect(createdInvoice.sgstTotal).toBe(450);
    expect(createdInvoice.grandTotal).toBe(5900);

    // Verify automated stock deduction
    const updatedProd = await InventoryModel.findById(createdProd.id);
    expect(updatedProd.currentStock).toBe(95);

    // Verify customer balance updated
    const updatedCust = await CustomerModel.findById(createdCust.id);
    expect(updatedCust.currentBalance).toBe(2000 + 5900);
  });
});
