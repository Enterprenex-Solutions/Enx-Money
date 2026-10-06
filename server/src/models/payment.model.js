/**
 * ENX Money — Subscription Payment Model
 * Handles Razorpay payment records for subscriptions.
 */
const { v4: uuidv4 } = require('uuid');
const { query, isConnected, inMemoryStore } = require('../config/db.config');

async function createPaymentOrder(data) {
  const id = uuidv4();
  const record = {
    id,
    user_id: data.user_id,
    subscription_id: data.subscription_id || null,
    plan_id: data.plan_id,
    order_id: data.order_id,
    amount: data.amount,
    currency: data.currency || 'INR',
    billing_cycle: data.billing_cycle || 'MONTHLY',
    status: 'CREATED',
    coupon_code: data.coupon_code || null,
    discount_amount: data.discount_amount || 0,
    idempotency_key: data.idempotency_key || null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };
  if (!isConnected()) {
    inMemoryStore.subscriptionPayments.set(id, record);
    return record;
  }
  await query(
    `INSERT INTO subscription_payments
       (id, user_id, subscription_id, plan_id, order_id, amount, currency,
        billing_cycle, status, coupon_code, discount_amount, idempotency_key)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'CREATED', ?, ?, ?)`,
    [id, record.user_id, record.subscription_id, record.plan_id, record.order_id,
     record.amount, record.currency, record.billing_cycle,
     record.coupon_code, record.discount_amount, record.idempotency_key]
  );
  return record;
}

async function updatePaymentStatus(orderId, status, gatewayData = {}) {
  if (!isConnected()) {
    for (const [key, rec] of inMemoryStore.subscriptionPayments.entries()) {
      if (rec.order_id === orderId) {
        const updated = {
          ...rec, status,
          gateway_payment_id: gatewayData.payment_id || rec.gateway_payment_id,
          gateway_signature: gatewayData.signature || rec.gateway_signature,
          payment_method: gatewayData.method || rec.payment_method,
          failure_reason: gatewayData.failure_reason || rec.failure_reason,
          paid_at: status === 'SUCCESS' ? new Date().toISOString() : rec.paid_at,
          updated_at: new Date().toISOString(),
        };
        inMemoryStore.subscriptionPayments.set(key, updated);
        return updated;
      }
    }
    return null;
  }
  await query(
    `UPDATE subscription_payments
     SET status = ?, gateway_payment_id = ?, gateway_signature = ?,
         payment_method = ?, failure_reason = ?,
         paid_at = IF(? = 'SUCCESS', NOW(), paid_at), updated_at = NOW()
     WHERE order_id = ?`,
    [status, gatewayData.payment_id || null, gatewayData.signature || null,
     gatewayData.method || null, gatewayData.failure_reason || null, status, orderId]
  );
  const [updated] = await query('SELECT * FROM subscription_payments WHERE order_id = ?', [orderId]);
  return updated;
}

async function getPaymentByOrderId(orderId) {
  if (!isConnected()) {
    return Array.from(inMemoryStore.subscriptionPayments.values()).find(p => p.order_id === orderId) || null;
  }
  const [row] = await query('SELECT * FROM subscription_payments WHERE order_id = ?', [orderId]);
  return row || null;
}

async function getUserPayments(userId, page = 1, limit = 10) {
  const offset = (page - 1) * limit;
  if (!isConnected()) {
    const all = Array.from(inMemoryStore.subscriptionPayments.values())
      .filter(p => p.user_id === userId)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    return { payments: all.slice(offset, offset + limit), total: all.length };
  }
  const payments = await query(
    `SELECT sp.*, pl.display_name as plan_display_name
     FROM subscription_payments sp
     JOIN subscription_plans pl ON sp.plan_id = pl.id
     WHERE sp.user_id = ?
     ORDER BY sp.created_at DESC LIMIT ? OFFSET ?`,
    [userId, limit, offset]
  );
  const [{ total }] = await query(
    'SELECT COUNT(*) as total FROM subscription_payments WHERE user_id = ?', [userId]
  );
  return { payments, total };
}

module.exports = { createPaymentOrder, updatePaymentStatus, getPaymentByOrderId, getUserPayments };
