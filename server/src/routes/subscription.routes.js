/**
 * ENX Money — Subscription & Billing Routes
 */
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/subscription.controller');
const { authenticate, optionalAuth } = require('../middleware/auth.middleware');

// Public — plan listing (no auth needed for marketing page)
router.get('/plans', ctrl.getPlans);

// Payment Gateway Webhooks (Razorpay / Cashfree / PhonePe / Direct Webhook)
router.post('/webhook', ctrl.subscriptionWebhook);

// Authenticated subscription management
router.get('/', authenticate, ctrl.getSubscription);
router.post(['/checkout', '/create-order', '/create_order'], optionalAuth, ctrl.checkout);
router.post('/verify', optionalAuth, ctrl.verifyPayment);
router.post('/cancel', authenticate, ctrl.cancelSubscription);
router.post('/reactivate', authenticate, ctrl.reactivateSubscription);
router.post('/upgrade', authenticate, ctrl.upgradeSubscription);
router.post('/downgrade', authenticate, ctrl.downgradeSubscription);
router.get('/payments', authenticate, ctrl.getPayments);
router.get('/invoices', authenticate, ctrl.getInvoices);
router.get('/invoices/:id/pdf', optionalAuth, ctrl.downloadInvoicePdf);

module.exports = router;
