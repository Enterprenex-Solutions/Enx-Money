const express = require('express');
const LoanController = require('../controllers/loan.controller');
const { authenticateToken } = require('../middleware/auth.middleware');
const {
  validateCreateLoan,
  validateUpdateLoan,
  validateCalculateEmi,
  validatePreviewSchedule,
  validateRecordPayment,
  validateUpdatePayment,
} = require('../middleware/validate.middleware');

const router = express.Router();

// 1. Public / Utility calculation routes
router.post('/calculate', validateCalculateEmi, LoanController.calculateEmi);
router.post('/preview-schedule', validatePreviewSchedule, LoanController.previewSchedule);

// 2. Protected routes requiring JWT authentication
router.use(authenticateToken);

// User-wide Schedule & Payment Aggregates (must be defined before /:id routes)
router.get('/schedules/upcoming', LoanController.getUpcomingEmis);
router.get('/schedules/overdue', LoanController.getOverdueEmis);
router.put('/payments/:paymentId', validateUpdatePayment, LoanController.updatePayment);

// EMI Due & Overdue Reminder Routes
router.get('/reminders/config', LoanController.getRemindersConfig);
router.put('/reminders/config', LoanController.updateRemindersConfig);
router.get('/reminders/pending', LoanController.getPendingReminders);
router.post('/reminders/trigger-check', LoanController.triggerReminderCheck);
router.get('/reminders/history', LoanController.getReminderHistory);

// Loan Core CRUD
router.post('/', validateCreateLoan, LoanController.createLoan);
router.get('/', LoanController.getLoans);
router.get('/:id', LoanController.getLoanById);
router.put('/:id', validateUpdateLoan, LoanController.updateLoan);
router.delete('/:id', LoanController.deleteLoan);

// Loan Sub-resources (Summary, Schedules, Payments)
router.get('/:id/summary', LoanController.getLoanSummary);
router.get('/:id/schedule', LoanController.getSchedule);
router.get('/:id/schedules/upcoming', LoanController.getUpcomingEmis);
router.get('/:id/schedules/overdue', LoanController.getOverdueEmis);
router.get('/:id/schedules/:scheduleId/late-fee', LoanController.getScheduleLateFee);
router.post('/:id/payments', validateRecordPayment, LoanController.markEmiAsPaid);
router.get('/:id/payments', LoanController.getPaymentHistory);
router.post('/:id/regenerate-schedule', LoanController.regenerateSchedule);

// Prepayment and Foreclosure Endpoints
router.post('/:id/prepayment/simulate', LoanController.simulatePrepayment);
router.post('/:id/prepayment/apply', LoanController.applyPrepayment);
router.post('/:id/foreclosure/simulate', LoanController.simulateForeclosure);
router.post('/:id/foreclosure/apply', LoanController.applyForeclosure);

module.exports = router;
