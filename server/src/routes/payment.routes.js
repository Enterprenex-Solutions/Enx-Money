/**
 * ENX Money — Payment Gateway Routes
 * Handles Order Creation, Signature Verification, and Webhooks for Razorpay / Cashfree / PhonePe
 */
const express = require('express');
const router = express.Router();
const paymentCtrl = require('../controllers/payment.controller');
const subscriptionCtrl = require('../controllers/subscription.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

// 1. Create order for Payment Gateway checkout SDK (Razorpay Standard & Subscriptions)
router.post(['/create-order', '/order', '/orders'], optionalAuth, (req, res, next) => {
  if (req.body && req.body.plan_id) {
    return subscriptionCtrl.checkout(req, res, next);
  }
  return paymentCtrl.createOrder(req, res, next);
});

// 2. Server-side payment signature verification
router.post(['/verify-payment', '/verify'], optionalAuth, (req, res, next) => {
  if (req.body && req.body.plan_id) {
    return subscriptionCtrl.verifyPayment(req, res, next);
  }
  return paymentCtrl.verifyPayment(req, res, next);
});

// 3. Explicit Subscription checkout & verification routes
router.post('/subscription/create-order', optionalAuth, subscriptionCtrl.checkout);
router.post('/subscription/verify', optionalAuth, subscriptionCtrl.verifyPayment);


// 4. Payment capture webhook listener
router.post('/webhook', subscriptionCtrl.subscriptionWebhook);

module.exports = router;

