const express = require('express');
const InventoryController = require('../controllers/inventory.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(optionalAuth);

// Products
router.get('/', InventoryController.getProducts);
router.post('/', InventoryController.createProduct);
router.get('/products', InventoryController.getProducts);
router.post('/products', InventoryController.createProduct);
router.get('/products/:id', InventoryController.getProductById);
router.put('/products/:id', InventoryController.updateProduct);
router.delete('/products/:id', InventoryController.deleteProduct);
router.delete('/:id', InventoryController.deleteProduct);

// Stock Actions
router.post('/stock-in', InventoryController.stockIn);
router.post('/stock-out', InventoryController.stockOut);
router.post('/adjust', InventoryController.adjustStock);

// Suppliers
router.get('/suppliers', InventoryController.getSuppliers);
router.post('/suppliers', InventoryController.createSupplier);

// Purchase Orders
router.get('/purchase-orders', InventoryController.getPurchaseOrders);
router.post('/purchase-orders', InventoryController.createPurchaseOrder);
router.patch('/purchase-orders/:id/receive', InventoryController.receivePurchaseOrder);

// Movement Ledger & Summary
router.get('/ledger', InventoryController.getLedger);
router.get('/summary', InventoryController.getSummary);
router.get('/valuation', InventoryController.getValuation);

module.exports = router;
