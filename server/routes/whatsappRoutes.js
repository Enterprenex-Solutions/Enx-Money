/**
 * WhatsApp Chatbot Routes
 * Webhook ingestion, real-time simulator, session management, and handoffs.
 */

const express = require('express');
const controller = require('../controllers/whatsappWebhookController');

const router = express.Router();

// 1. Meta WhatsApp Cloud API Webhook
router.get ('/webhook', controller.verifyWebhook);
router.post('/webhook', controller.handleWebhook);

// 2. Twilio WhatsApp Webhook
router.post('/twilio-webhook', controller.handleTwilioWebhook);

// 3. Web Simulator API (for real-time in-browser testing)
router.post('/simulate', controller.simulateMessage);

// 4. Session & Audit Management
router.get('/sessions', controller.getSessions);
router.get('/logs',     controller.getLogs);

// 5. Automated Reminders Trigger
router.post('/reminders/scan', controller.triggerReminderScan);
router.post(['/reminders/send', '/reminders/trigger'], controller.apiTriggerReminders);

// 6. Secure App Handoff Link Validation & Landing Page
router.get('/handoff/verify', controller.handleHandoffVerify);
router.get('/handoff/open',   controller.handleHandoffOpen);

// 7. Web Portal Financial APIs (Balance, Statement PDF, Debtor Customers)
router.get(['/summary', '/balance'], controller.apiGetSummary);
router.get(['/statement', '/statement-pdf', '/statement/generate'], controller.apiGenerateStatement);
router.get(['/customers/dues', '/receivables', '/debtors'], controller.apiGetCustomerDues);

// 8. Simulator Companion APIs (Users, Chats, Linking, Custom Transactions)
router.get('/users', controller.apiGetUsers);
router.get('/chats', controller.apiGetChats);
router.delete('/chats', controller.apiClearChats);
router.post('/link-account', controller.apiLinkAccount);
router.post('/transaction', controller.apiAddTransaction);

module.exports = router;
