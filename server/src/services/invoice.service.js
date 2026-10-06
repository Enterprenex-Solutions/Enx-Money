/**
 * ENX Money — Subscription Invoice Service
 * Handles GST calculations, invoice number sequencing, and invoice data preparation.
 */
const invoiceModel = require('../models/subscriptionInvoice.model');

/**
 * Generate a GST-compliant invoice for a subscription payment
 * @param {object} params
 * @param {string|number} params.userId
 * @param {string} params.subscriptionId
 * @param {string} params.paymentId
 * @param {string} params.planName
 * @param {string} params.billingCycle
 * @param {number} params.amount
 * @param {number} [params.discount]
 * @param {string} [params.billingName]
 * @param {string} [params.billingEmail]
 * @param {string} [params.billingAddress]
 * @param {string} [params.gstin]
 */
async function generateSubscriptionInvoice({
  userId,
  subscriptionId,
  paymentId,
  planName,
  billingCycle,
  amount,
  discount = 0,
  billingName,
  billingEmail,
  billingAddress,
  gstin,
}) {
  return invoiceModel.createInvoice({
    user_id: userId,
    subscription_id: subscriptionId,
    payment_id: paymentId,
    plan_name: planName,
    billing_cycle: billingCycle,
    subtotal: amount,
    discount,
    billing_name: billingName,
    billing_email: billingEmail,
    billing_address: billingAddress,
    gstin,
  });
}

/**
 * Get all invoices for a user
 * @param {string|number} userId
 */
async function getUserInvoices(userId) {
  return invoiceModel.getUserInvoices(userId);
}

module.exports = {
  generateSubscriptionInvoice,
  getUserInvoices,
};
