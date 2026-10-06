const express = require('express');
const ExpensesController = require('../controllers/expenses.controller');

const router = express.Router();

router.get('/summary', ExpensesController.getExpenseSummary);
router.get('/categories', ExpensesController.getCategories);
router.get('/:id', ExpensesController.getExpenseById);
router.get('/', ExpensesController.getExpenses);

router.post('/', ExpensesController.createExpense);
router.put('/:id', ExpensesController.updateExpense);
router.delete('/:id', ExpensesController.deleteExpense);

module.exports = router;
