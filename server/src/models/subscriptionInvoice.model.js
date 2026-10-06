/**
 * ENX Money — Subscription Invoice Model
 * GST-ready invoice generation for subscription payments.
 */
const { v4: uuidv4 } = require('uuid');
const { query, isConnected, inMemoryStore } = require('../config/db.config');

async function _nextInvoiceNumber() {
  const year = new Date().getFullYear();
  if (!isConnected()) {
    const count = Array.from(inMemoryStore.subscriptionInvoices.values())
      .filter(i => i.invoice_number?.startsWith(`ENXI-${year}-`)).length;
    return `ENXI-${year}-${String(count + 1).padStart(4, '0')}`;
  }
  const [{ cnt }] = await query(
    `SELECT COUNT(*) as cnt FROM subscription_invoices WHERE invoice_number LIKE ?`,
    [`ENXI-${year}-%`]
  );
  return `ENXI-${year}-${String(cnt + 1).padStart(4, '0')}`;
}

async function createInvoice(data) {
  const id = uuidv4();
  const invoiceNumber = await _nextInvoiceNumber();
  const TAX_RATE = 18; // GST 18%
  const subtotal = parseFloat(data.subtotal || 0);
  const discount = parseFloat(data.discount || 0);
  const taxable = subtotal - discount;
  const tax_amount = parseFloat(((taxable * TAX_RATE) / 100).toFixed(2));
  const total = parseFloat((taxable + tax_amount).toFixed(2));

  const invoice = {
    id,
    invoice_number: invoiceNumber,
    user_id: data.user_id,
    subscription_id: data.subscription_id || null,
    payment_id: data.payment_id || null,
    plan_name: data.plan_name,
    billing_cycle: data.billing_cycle,
    subtotal,
    discount,
    tax_rate: TAX_RATE,
    tax_amount,
    total,
    currency: 'INR',
    status: 'PAID',
    invoice_date: new Date().toISOString(),
    billing_name: data.billing_name || null,
    billing_email: data.billing_email || null,
    billing_address: data.billing_address || null,
    gstin: data.gstin || null,
    pdf_url: null,
    created_at: new Date().toISOString(),
  };

  if (!isConnected()) {
    inMemoryStore.subscriptionInvoices.set(id, invoice);
    return invoice;
  }
  await query(
    `INSERT INTO subscription_invoices
       (id, invoice_number, user_id, subscription_id, payment_id, plan_name, billing_cycle,
        subtotal, discount, tax_rate, tax_amount, total, currency, status, invoice_date,
        billing_name, billing_email, billing_address, gstin)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'INR', 'PAID', NOW(), ?, ?, ?, ?)`,
    [id, invoiceNumber, invoice.user_id, invoice.subscription_id, invoice.payment_id,
     invoice.plan_name, invoice.billing_cycle, subtotal, discount, TAX_RATE, tax_amount,
     total, invoice.billing_name, invoice.billing_email, invoice.billing_address, invoice.gstin]
  );
  return invoice;
}

async function getUserInvoices(userId) {
  if (!isConnected()) {
    return Array.from(inMemoryStore.subscriptionInvoices.values())
      .filter(i => i.user_id === userId)
      .sort((a, b) => new Date(b.invoice_date) - new Date(a.invoice_date));
  }
  return query(
    'SELECT * FROM subscription_invoices WHERE user_id = ? ORDER BY invoice_date DESC',
    [userId]
  );
}

async function getInvoiceById(id, userId) {
  if (!isConnected()) {
    const inv = inMemoryStore.subscriptionInvoices.get(id);
    return inv?.user_id === userId ? inv : null;
  }
  const [inv] = await query(
    'SELECT * FROM subscription_invoices WHERE id = ? AND user_id = ?', [id, userId]
  );
  return inv || null;
}

module.exports = { createInvoice, getUserInvoices, getInvoiceById };
