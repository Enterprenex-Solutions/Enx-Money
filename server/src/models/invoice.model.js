/**
 * GST Invoicing Engine & Store
 * Implements Section 3 of Functional Specification Document
 */

const db = require('../config/db.config');

// In-Memory Store backed by Resilience Persistence
const _invoicesStore = db.inMemoryStore.invoices;

// Sample Seed Invoices
const seedInvoices = [
  {
    id: 'inv_001',
    invoiceNumber: 'INV/2026-27/0001',
    invoiceType: 'GST', // 'GST' or 'NON_GST'
    invoiceDate: '2026-08-25',
    customerId: 'cust_001',
    customerName: 'Enx money',
    customerGstin: '36AABCU9603R1ZM',
    customerStateCode: '36', // Telangana
    merchantStateCode: '36', // Telangana -> Intra-State
    isIntraState: true,
    items: [
      {
        id: 'item_1',
        description: 'Cotton Fabric Rolls (100m)',
        hsnCode: '5208',
        quantity: 2,
        unitPrice: 5000.00,
        discount: 1000.00,
        taxableValue: 9000.00,
        gstRate: 18,
        cgstRate: 9,
        cgstAmount: 810.00,
        sgstRate: 9,
        sgstAmount: 810.00,
        igstRate: 0,
        igstAmount: 0.00,
        total: 10620.00,
      }
    ],
    taxableTotal: 9000.00,
    cgstTotal: 810.00,
    sgstTotal: 810.00,
    igstTotal: 0.00,
    cessTotal: 0.00,
    roundOff: 0.00,
    grandTotal: 10620.00,
    paymentStatus: 'UNPAID', // 'PAID', 'PARTIAL', 'UNPAID'
    amountPaid: 0.00,
    balanceDue: 10620.00,
    notes: 'Payment due within 15 days.',
    createdAt: new Date().toISOString(),
  }
];

if (process.env.NODE_ENV === 'test') {
  for (const inv of seedInvoices) {
    _invoicesStore.set(inv.id, inv);
  }
}

class InvoiceModel {
  /**
   * GST Calculation Engine (Exact Section 3 Formulas)
   */
  static calculateGST({
    items = [],
    merchantStateCode = '36',
    customerStateCode = '36',
    invoiceType = 'GST',
    cessRate = 0,
  }) {
    const isIntraState = merchantStateCode.trim() === customerStateCode.trim();
    let taxableTotal = 0;
    let cgstTotal = 0;
    let sgstTotal = 0;
    let igstTotal = 0;

    const processedItems = items.map((item, idx) => {
      const qty = Number(item.quantity) || 1;
      const unitPrice = Number(item.unitPrice) || 0;
      const discount = Number(item.discount) || 0;
      const taxableValue = Math.max(0, (unitPrice * qty) - discount);
      taxableTotal += taxableValue;

      const gstRate = invoiceType === 'GST' ? (Number(item.gstRate) || 18) : 0;
      let cgstRate = 0, sgstRate = 0, igstRate = 0;
      let cgstAmount = 0, sgstAmount = 0, igstAmount = 0;

      if (invoiceType === 'GST' && gstRate > 0) {
        if (isIntraState) {
          cgstRate = gstRate / 2;
          sgstRate = gstRate / 2;
          cgstAmount = (taxableValue * cgstRate) / 100;
          sgstAmount = (taxableValue * sgstRate) / 100;
          cgstTotal += cgstAmount;
          sgstTotal += sgstAmount;
        } else {
          igstRate = gstRate;
          igstAmount = (taxableValue * igstRate) / 100;
          igstTotal += igstAmount;
        }
      }

      const itemTotal = taxableValue + cgstAmount + sgstAmount + igstAmount;

      return {
        id: item.id || `item_${idx + 1}`,
        description: item.description || 'Goods / Services',
        hsnCode: item.hsnCode || '9983',
        quantity: qty,
        unitPrice,
        discount,
        taxableValue,
        gstRate,
        cgstRate,
        cgstAmount,
        sgstRate,
        sgstAmount,
        igstRate,
        igstAmount,
        total: itemTotal,
      };
    });

    const cessTotal = (taxableTotal * (Number(cessRate) || 0)) / 100;
    const rawTotal = taxableTotal + cgstTotal + sgstTotal + igstTotal + cessTotal;
    const grandTotal = Math.round(rawTotal);
    const roundOff = Number((grandTotal - rawTotal).toFixed(2));

    return {
      isIntraState,
      items: processedItems,
      taxableTotal: Number(taxableTotal.toFixed(2)),
      cgstTotal: Number(cgstTotal.toFixed(2)),
      sgstTotal: Number(sgstTotal.toFixed(2)),
      igstTotal: Number(igstTotal.toFixed(2)),
      cessTotal: Number(cessTotal.toFixed(2)),
      roundOff,
      grandTotal,
    };
  }

  static async findAll({ search, status, invoiceType, userId } = {}) {
    let list = Array.from(_invoicesStore.values());
    if (userId) {
      list = list.filter(inv => String(inv.userId) === String(userId) || (process.env.NODE_ENV === 'test' && !inv.userId));
    } else if (process.env.NODE_ENV !== 'test') {
      return [];
    }
    if (search) {
      const q = search.toLowerCase();
      list = list.filter(inv =>
        inv.invoiceNumber.toLowerCase().includes(q) ||
        inv.customerName.toLowerCase().includes(q) ||
        (inv.customerGstin && inv.customerGstin.toLowerCase().includes(q))
      );
    }
    if (status && status !== 'ALL') {
      list = list.filter(inv => inv.paymentStatus === status);
    }
    if (invoiceType && invoiceType !== 'ALL') {
      list = list.filter(inv => inv.invoiceType === invoiceType);
    }
    return list;
  }

  static async findById(id) {
    return _invoicesStore.get(id) || null;
  }

  static async create(data) {
    const id = `inv_${Date.now()}`;
    const seq = _invoicesStore.size + 1;
    const invoiceNumber = data.invoiceNumber || `INV/2026-27/${String(seq).padStart(4, '0')}`;

    const calculation = this.calculateGST({
      items: data.items || [],
      merchantStateCode: data.merchantStateCode || '36',
      customerStateCode: (data.customerGstin ? data.customerGstin.slice(0, 2) : data.customerStateCode) || '36',
      invoiceType: data.invoiceType || 'GST',
      cessRate: data.cessRate || 0,
    });

    const newInvoice = {
      id,
      invoiceNumber,
      invoiceType: data.invoiceType || 'GST',
      invoiceDate: data.invoiceDate || new Date().toISOString().split('T')[0],
      customerId: data.customerId || '',
      customerName: data.customerName || 'Cash Customer',
      customerGstin: data.customerGstin || '',
      userId: data.userId || null,
      customerStateCode: (data.customerGstin ? data.customerGstin.slice(0, 2) : '36'),
      merchantStateCode: data.merchantStateCode || '36',
      ...calculation,
      paymentStatus: data.paymentStatus || 'UNPAID',
      amountPaid: Number(data.amountPaid) || 0,
      balanceDue: Math.max(0, calculation.grandTotal - (Number(data.amountPaid) || 0)),
      notes: data.notes || '',
      createdAt: new Date().toISOString(),
    };

    _invoicesStore.set(id, newInvoice);
    db.saveResilienceStore();

    // 1. Deduct Inventory Stock for invoiced items
    const InventoryModel = require('./inventory.model');
    for (const itm of (data.items || [])) {
      if (itm.productId) {
        try {
          await InventoryModel.stockOut({
            productId: itm.productId,
            quantity: itm.quantity || 1,
            invoiceNumber: newInvoice.invoiceNumber,
            notes: `Sale invoice ${newInvoice.invoiceNumber} for ${newInvoice.customerName}`,
          });
        } catch (stockErr) {
          console.warn(`[InvoiceModel] Stock deduction note for ${itm.productId}:`, stockErr.message);
        }
      }
    }

    // 2. Create Khata Ledger entry for customer if customerId exists
    if (newInvoice.customerId) {
      const CustomerModel = require('./customer.model');
      try {
        await CustomerModel.addLedgerEntry({
          userId: data.userId || 1,
          customerId: newInvoice.customerId,
          entryType: 'GAVE',
          amount: newInvoice.grandTotal,
          paymentMode: 'CREDIT',
          description: `GST Invoice #${newInvoice.invoiceNumber}`,
          invoiceNumber: newInvoice.invoiceNumber,
        });

        // If partial or full payment made at time of invoice creation
        if (newInvoice.amountPaid > 0) {
          await CustomerModel.addLedgerEntry({
            userId: data.userId || 1,
            customerId: newInvoice.customerId,
            entryType: 'GOT',
            amount: newInvoice.amountPaid,
            paymentMode: 'CASH',
            description: `Payment against Invoice #${newInvoice.invoiceNumber}`,
            invoiceNumber: newInvoice.invoiceNumber,
          });
        }
      } catch (khataErr) {
        console.warn(`[InvoiceModel] Khata entry note:`, khataErr.message);
      }
    }

    return newInvoice;
  }
}

module.exports = InvoiceModel;
