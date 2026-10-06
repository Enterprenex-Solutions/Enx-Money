const express = require('express');
const TransactionController = require('../controllers/transaction.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();
router.use(optionalAuth);

// General Transaction List & Creation
router.get('/', TransactionController.getTransactions);
router.post('/', TransactionController.createTransaction);

// Daily Book & Running Balances
router.get('/daily-book', TransactionController.getDailyBook);

// Periodic Aggregations
router.get('/weekly-report', TransactionController.getWeeklyReport);
router.get('/monthly-report', TransactionController.getMonthlyReport);

// Expense Checking
router.get('/expense-checking', TransactionController.getExpenseChecking);

// Recurring Transactions
router.get('/recurring', TransactionController.getRecurring);
router.post('/recurring', TransactionController.createRecurring);

// Balance Reconciliation
router.post('/reconciliation', TransactionController.reconcile);

module.exports = router;
