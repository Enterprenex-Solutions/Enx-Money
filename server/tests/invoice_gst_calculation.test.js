const InvoiceModel = require('../src/models/invoice.model');

describe('Invoice GST Calculation', () => {
  test('0% GST should not be replaced with the default 18%', () => {
    const result = InvoiceModel.calculateGST({
      merchantStateCode: '36',
      customerStateCode: '29',
      invoiceType: 'GST',
      items: [
        {
          description: 'Pineapple Cake',
          quantity: 1,
          unitPrice: 550,
          gstRate: 0,
        },
      ],
    });

    expect(result.items[0].gstRate).toBe(0);
    expect(result.igstTotal).toBe(0);
    expect(result.grandTotal).toBe(550);
  });

  test('18% GST should still calculate correctly', () => {
    const result = InvoiceModel.calculateGST({
      merchantStateCode: '36',
      customerStateCode: '29',
      invoiceType: 'GST',
      items: [
        {
          description: 'Test Product',
          quantity: 1,
          unitPrice: 550,
          gstRate: 18,
        },
      ],
    });

    expect(result.items[0].gstRate).toBe(18);
    expect(result.igstTotal).toBe(99);
    expect(result.grandTotal).toBe(649);
  });

  test('Missing GST rate should default to 18%', () => {
    const result = InvoiceModel.calculateGST({
      merchantStateCode: '36',
      customerStateCode: '29',
      invoiceType: 'GST',
      items: [
        {
          description: 'Test Product',
          quantity: 1,
          unitPrice: 550,
        },
      ],
    });

    expect(result.items[0].gstRate).toBe(18);
    expect(result.igstTotal).toBe(99);
    expect(result.grandTotal).toBe(649);
  });
});

