const express = require('express');
const CustomerModel = require('../models/customer.model');
const InventoryModel = require('../models/inventory.model');
const InvoiceModel = require('../models/invoice.model');

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const query = (req.query.q || '').trim().toLowerCase();
    const userId = req.user ? req.user.id : 1;

    if (!query) {
      return res.json({
        success: true,
        data: {
          customers: [],
          suppliers: [],
          products: [],
          invoices: [],
          khata: [],
        }
      });
    }

    // 1. Search Customers
    const custRes = await CustomerModel.findAll({ userId, search: query });
    const customers = custRes.customers || [];

    // 2. Search Suppliers
    const suppliers = (await InventoryModel.getSuppliers()).filter(s =>
      s.name.toLowerCase().includes(query) ||
      (s.companyName && s.companyName.toLowerCase().includes(query)) ||
      (s.contactNumber && s.contactNumber.includes(query)) ||
      (s.gstin && s.gstin.toLowerCase().includes(query))
    );

    // 3. Search Products
    const products = (await InventoryModel.getProducts({ search: query })).products || [];

    // 4. Search Invoices
    const invoices = await InvoiceModel.findAll({ search: query });

    return res.json({
      success: true,
      data: {
        customers,
        suppliers,
        products,
        invoices,
        totalMatches: customers.length + suppliers.length + products.length + invoices.length,
      }
    });
  } catch (err) {
    console.error('[Search API Error]', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
