const express = require('express');
const InventoryController = require('../controllers/inventory.controller');
const InventoryModel = require('../models/inventory.model');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(optionalAuth);

router.get(['/', '/list', '/all'], InventoryController.getSuppliers);
router.post(['/', '/create', '/add'], InventoryController.createSupplier);
router.put(['/:id', '/update/:id'], InventoryController.updateSupplier);
router.delete(['/:id', '/delete/:id'], InventoryController.deleteSupplier);

router.get(['/:id', '/details/:id'], async (req, res) => {
  try {
    const supplier = await InventoryModel.findSupplierById(req.params.id);
    if (!supplier) return res.status(404).json({ success: false, message: 'Supplier not found' });
    res.json({ success: true, data: supplier });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
