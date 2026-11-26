const express = require('express');
const ExpensesController = require('../controllers/expenses.controller');

const { authenticateToken } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticateToken);
router.use(require('../middleware/idempotency.middleware'));

router.get('/summary', ExpensesController.getExpenseSummary);
router.get('/categories', ExpensesController.getCategories);
router.get('/:id', ExpensesController.getExpenseById);
router.get('/', ExpensesController.getExpenses);

router.post('/', ExpensesController.createExpense);
router.put('/:id', ExpensesController.updateExpense);
router.delete('/:id', ExpensesController.deleteExpense);

module.exports = router;
