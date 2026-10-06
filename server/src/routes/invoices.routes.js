const express = require('express');
const InvoicesController = require('../controllers/invoices.controller');

const router = express.Router();

router.get('/', InvoicesController.getInvoices);
router.post('/', InvoicesController.createInvoice);
router.post('/preview-gst', InvoicesController.calculateGstPreview);
router.get(['/:id/pdf', '/:id/download-pdf', '/:id/download'], InvoicesController.downloadPdf);
router.get('/:id', InvoicesController.getInvoiceById);

module.exports = router;
