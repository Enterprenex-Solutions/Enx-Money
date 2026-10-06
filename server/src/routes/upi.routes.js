const express = require('express');
const FinanceController = require('../controllers/finance.controller');

const router = express.Router();

// Real-time handle availability check (GET /api/v1/upi/check-handle?vpa=revanth@enxmoney)
router.get('/check-handle', FinanceController.checkHandleAvailability);

// Retrieve active, primary, and suggested UPI handles
router.get('/handles', FinanceController.getUpiHandles);

// Create custom handle and bind to primary bank account
router.post('/create-handle', FinanceController.createCustomHandle);

// Set primary handle
router.patch('/handles/:id/primary', FinanceController.setPrimaryHandle);
router.post('/handles/:id/primary', FinanceController.setPrimaryHandle);
router.post('/set-primary', FinanceController.setPrimaryHandle);

// Toggle handle active/inactive status
router.patch('/handles/:id/status', FinanceController.toggleHandleStatus);
router.post('/handles/:id/status', FinanceController.toggleHandleStatus);
router.post('/toggle-status', FinanceController.toggleHandleStatus);

// Delete handle
router.delete('/handles/:id', FinanceController.deleteHandle);
router.post('/delete-handle', FinanceController.deleteHandle);

module.exports = router;
