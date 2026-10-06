const express = require('express');
const CustomersController = require('../controllers/customers.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

// Allow optional auth for smooth development/demo testing
const auth = optionalAuth || ((req, res, next) => next());

// Customer Management CRUD (Supports '/', '/create', '/add', '/list', '/search', etc.)
router.get(['/', '/list', '/all', '/search'], auth, CustomersController.getCustomers);
router.post(['/', '/create', '/add'], auth, CustomersController.createCustomer);
router.get(['/:id', '/details/:id'], auth, CustomersController.getCustomerById);
router.put(['/:id', '/update/:id'], auth, CustomersController.updateCustomer);
router.delete(['/:id', '/delete/:id'], auth, CustomersController.deleteCustomer);

// Khata Ledger & Reminders
router.get(['/:id/ledger', '/:id/ledger/entries'], auth, CustomersController.getCustomerLedger);
router.post(['/:id/ledger', '/:id/ledger/entries'], auth, CustomersController.addLedgerEntry);
router.get(['/:id/statement-pdf', '/:id/pdf'], auth, CustomersController.downloadStatementPdf);
router.post(['/:id/remind', '/:id/reminder'], auth, CustomersController.sendReminder);

module.exports = router;
