const express = require('express');
const authRoutes = require('./auth.routes');
const loanRoutes = require('./loan.routes');
const cardsRoutes = require('./cards.routes');
const customersRoutes = require('./customers.routes');
const invoicesRoutes = require('./invoices.routes');
const inventoryRoutes = require('./inventory.routes');
const transactionsRoutes = require('./transactions.routes');
const locationRoutes = require('./location.routes');
const financeRoutes = require('./finance.routes');
const analyticsRoutes = require('./analytics.routes');
const settingsRoutes = require('./settings.routes');
const suppliersRoutes = require('./suppliers.routes');
const expensesRoutes = require('./expenses.routes');
const complianceRoutes = require('./compliance.routes');
const powerBiRoutes = require('./powerBi.routes');
const bankRoutes = require('./bank.routes');
const kycRoutes = require('./kyc.routes');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

// Mount optionalAuth globally so all routes receive req.user if Bearer token is present
router.use(optionalAuth);

// KYC & Digital Identity routes (DigiLocker / Aadhaar / PAN)
router.use(['/kyc', '/v1/kyc'], kycRoutes);

// Bank Verification & Account Aggregator routes
router.use('/bank', bankRoutes);
router.use('/v1/bank', bankRoutes);

// 1. Auth & Users routes
router.use(['/auth', '/v1/auth'], authRoutes);
router.use(['/user', '/users', '/v1/user', '/v1/users'], authRoutes);

// 2. Customers & Khata routes (Feature 1 - supports /customers, /customer, /v1/customers, /v1/customer)
router.use(['/customers', '/customer', '/v1/customers', '/v1/customer'], customersRoutes);

// 2b. Suppliers routes
router.use('/suppliers', suppliersRoutes);
router.use('/v1/suppliers', suppliersRoutes);

// 2c. Business Expenses routes
router.use('/expenses', expensesRoutes);
router.use('/v1/expenses', expensesRoutes);

// 3. Invoices & GST Invoicing routes (Feature 7)
router.use('/invoices', invoicesRoutes);
router.use('/v1/invoices', invoicesRoutes);

// 4. Inventory & Supplies routes (Feature 4)
router.use('/inventory', inventoryRoutes);
router.use('/v1/inventory', inventoryRoutes);

// 5. Transactions & Daily Book (Feature 5)
router.use('/transactions', transactionsRoutes);
router.use('/v1/transactions', transactionsRoutes);

// 6. Dual-Mode Finance, Profiles, Accounts, Transfers & Net Worth (Feature 2)
router.use('/finance', financeRoutes);
router.use('/v1/finance', financeRoutes);

// 6b. UPI Custom Handles & VPA Alias Management (e.g. /api/v1/upi/check-handle)
const upiRoutes = require('./upi.routes');
router.use(['/upi', '/v1/upi'], upiRoutes);

// 6c. Dashboard Live Metrics (GET /api/v1/dashboard/metrics)
const dashboardRoutes = require('./dashboard.routes');
router.use(['/dashboard', '/v1/dashboard'], dashboardRoutes);

// 7. Analytics, Charts, Power BI & Custom Reports (Feature 3)
router.use('/analytics', analyticsRoutes);
router.use('/v1/analytics', analyticsRoutes);

// 8. Loans & EMI Amortization routes (Feature 6)
router.use('/loans', loanRoutes);
router.use('/v1/loans', loanRoutes);

// 9. Cards Vault routes
router.use('/cards', cardsRoutes);

// 10. Location & Cascading Address routes
router.use(['/locations', '/location', '/v1/locations', '/v1/location'], locationRoutes);

const searchRoutes = require('./search.routes');

// 11. Centralized Settings routes
router.use('/settings', settingsRoutes);
router.use('/v1/settings', settingsRoutes);

// 12. Global Search API
router.use('/search', searchRoutes);
router.use('/v1/search', searchRoutes);

// 13. Data Analysis Compliance (Section 21) & Power BI Integration
router.use('/compliance', complianceRoutes);
router.use('/v1/compliance', complianceRoutes);
router.use('/powerbi', powerBiRoutes);
router.use('/v1/powerbi', powerBiRoutes);

// 14. Meta AI Assistant routes
const aiRoutes = require('./ai.routes');
router.use(['/ai', '/v1/ai', '/api/ai'], aiRoutes);

// 15. Admin Analytics & Security routes
const adminRoutes = require('./admin.routes');
router.use(['/admin', '/v1/admin', '/api/admin'], adminRoutes);

// 16. WhatsApp Chatbot Interaction Layer (Anjali)
// Routes: /api/v1/whatsapp/webhook, /simulate, /sessions, /logs, /reminders/scan, /handoff/*
const whatsappRoutes = require('../../routes/whatsappRoutes');
router.use(['/whatsapp', '/v1/whatsapp'], whatsappRoutes);

// 17. Subscription & Billing (Plans, Entitlements, Checkout, Invoices)
const subscriptionRoutes = require('./subscription.routes');
const subscriptionCtrl = require('../controllers/subscription.controller');
router.use(['/subscription', '/v1/subscription'], subscriptionRoutes);

// 17a. Entitlements
router.get(['/entitlements', '/v1/entitlements'], subscriptionCtrl.getEntitlements);
router.get(['/entitlements/:feature', '/v1/entitlements/:feature'], subscriptionCtrl.checkFeature);

// 17b. Coupon validation
router.post(['/coupons/validate', '/v1/coupons/validate'], subscriptionCtrl.validateCoupon);

// 17c. Razorpay & Subscription Webhook endpoints
router.post(['/webhooks/razorpay', '/v1/webhooks/razorpay'], subscriptionCtrl.razorpayWebhook);
router.post(['/subscription/webhook', '/v1/subscription/webhook'], subscriptionCtrl.subscriptionWebhook);

// 18. Payment Gateway SDK Integration (Razorpay Standard & Subscriptions)
const paymentCtrl = require('../controllers/payment.controller');
const paymentRoutes = require('./payment.routes');

router.post(['/create-order', '/v1/create-order'], (req, res, next) => {
  if (req.body && req.body.plan_id) {
    return subscriptionCtrl.checkout(req, res, next);
  }
  return paymentCtrl.createOrder(req, res, next);
});

router.post(['/verify-payment', '/v1/verify-payment'], (req, res, next) => {
  if (req.body && req.body.plan_id) {
    return subscriptionCtrl.verifyPayment(req, res, next);
  }
  return paymentCtrl.verifyPayment(req, res, next);
});

router.use(['/payment', '/v1/payment'], paymentRoutes);

// 19. Workforce & Task Management (Enterprenex Internal HRMS & Work Delivery)
const workforceRoutes = require('./workforce.routes');
router.use(['/workforce', '/v1/workforce'], workforceRoutes);

module.exports = router;





