/**
 * Supplies & Inventory Management Engine & Data Model
 * Implements Feature 4 of Functional Specification Document
 */

const crypto = require('crypto');
const db = require('../config/db.config');

// In-Memory Stores backed by Resilience Persistence
const _productsStore = db.inMemoryStore.products;
const _suppliersStore = db.inMemoryStore.suppliers;
const _purchaseOrdersStore = db.inMemoryStore.purchaseOrders;
const _stockLedgerStore = db.inMemoryStore.stockLedger;

// 1. Seed Initial Realistic Products
const initialProducts = [
  {
    id: 'prod_001',
    sku: 'SKU-COT-01',
    name: 'Cotton Fabric Rolls (100m)',
    category: 'Fabrics',
    unit: 'Rolls',
    hsnCode: '5208',
    costPrice: 3800.00,
    sellingPrice: 5000.00,
    gstRate: 18,
    reorderLevel: 10,
    currentStock: 45,
    barcode: '890123456701',
    qrCode: 'QR-COT-01',
    trackBatch: true,
    trackExpiry: false,
    valuationMethod: 'FIFO',
    costLayers: [{ quantity: 45, unitCost: 3800.00, date: '2026-08-01' }],
    status: 'ACTIVE',
    supplierId: 'supp_001',
    supplierName: 'Krishna Textiles Pvt Ltd',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prod_002',
    sku: 'SKU-BTN-05',
    name: 'Premium Horn Buttons (Box of 500)',
    category: 'Accessories',
    unit: 'Boxes',
    hsnCode: '9606',
    costPrice: 450.00,
    sellingPrice: 750.00,
    gstRate: 12,
    reorderLevel: 15,
    currentStock: 8, // Low Stock Trigger
    barcode: '890123456702',
    qrCode: 'QR-BTN-05',
    trackBatch: false,
    trackExpiry: false,
    valuationMethod: 'WEIGHTED_AVG',
    costLayers: [{ quantity: 8, unitCost: 450.00, date: '2026-08-10' }],
    status: 'ACTIVE',
    supplierId: 'supp_002',
    supplierName: 'Apex Trims & Fasteners',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prod_003',
    sku: 'SKU-ZPR-10',
    name: 'YKK Brass Zippers 12-inch',
    category: 'Hardware',
    unit: 'Pcs',
    hsnCode: '9607',
    costPrice: 22.00,
    sellingPrice: 45.00,
    gstRate: 18,
    reorderLevel: 50,
    currentStock: 250,
    barcode: '890123456703',
    qrCode: 'QR-ZPR-10',
    trackBatch: false,
    trackExpiry: false,
    valuationMethod: 'FIFO',
    costLayers: [{ quantity: 250, unitCost: 22.00, date: '2026-08-15' }],
    status: 'ACTIVE',
    supplierId: 'supp_002',
    supplierName: 'Apex Trims & Fasteners',
    createdAt: new Date().toISOString(),
  }
];

// 2. Seed Initial Suppliers (Test environment only)
const initialSuppliers = [
  {
    id: 'supp_001',
    name: 'Krishna Textiles Pvt Ltd',
    contactNumber: '9848022334',
    email: 'sales@krishnatextiles.in',
    address: 'Plot 45, Textile Park, Surat, Gujarat',
    gstin: '24AAACK1234F1Z5',
    openingBalance: 0.00,
    outstandingPayable: 25000.00,
    notes: 'Primary fabric roll vendor with 30-day credit terms',
    status: 'ACTIVE',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'supp_002',
    name: 'Apex Trims & Fasteners',
    contactNumber: '9123456789',
    email: 'orders@apextrims.com',
    address: 'Industrial Area Phase 2, Bengaluru, Karnataka',
    gstin: '29AABCA5678R1Z2',
    openingBalance: 0.00,
    outstandingPayable: 17000.00,
    notes: 'Buttons and zipper supplier',
    status: 'ACTIVE',
    createdAt: new Date().toISOString(),
  }
];

// 3. Seed Initial Purchase Orders (Test environment only)
const initialPOs = [
  {
    id: 'po_001',
    poNumber: 'PO/2026-27/0001',
    supplierId: 'supp_001',
    supplierName: 'Krishna Textiles Pvt Ltd',
    poDate: '2026-08-20',
    expectedDeliveryDate: '2026-08-28',
    items: [
      {
        productId: 'prod_001',
        productName: 'Cotton Fabric Rolls (100m)',
        quantity: 20,
        receivedQuantity: 20,
        unitCost: 3800.00,
        gstRate: 18,
        total: 89680.00,
      }
    ],
    subTotal: 76000.00,
    taxTotal: 13680.00,
    grandTotal: 89680.00,
    status: 'Received',
    notes: 'Quality inspection passed upon delivery.',
    createdAt: new Date().toISOString(),
  }
];

// 4. Seed Stock Movement Ledger (Test environment only)
const initialMovements = [
  {
    id: 'stk_001',
    productId: 'prod_001',
    productName: 'Cotton Fabric Rolls (100m)',
    type: 'PURCHASE',
    quantity: 20,
    previousStock: 25,
    newStock: 45,
    referenceType: 'PURCHASE_BILL',
    referenceId: 'PO/2026-27/0001',
    unitCost: 3800.00,
    reason: 'Purchase Inward from Krishna Textiles',
    user: 'Inventory Manager',
    createdAt: '2026-08-28T11:00:00.000Z',
  }
];

if (process.env.NODE_ENV === 'test') {
  for (const p of initialProducts) {
    _productsStore.set(p.id, p);
  }

  for (const s of initialSuppliers) {
    _suppliersStore.set(s.id, s);
  }

  for (const po of initialPOs) {
    _purchaseOrdersStore.set(po.id, po);
  }

  for (const m of initialMovements) {
    _stockLedgerStore.set(m.id, m);
  }
}

class InventoryModel {
  /**
   * List Products with Search, Category, and Stock Filters
   */
  static async findAll({ search, category, status = 'ACTIVE', lowStockOnly = false, userId } = {}) {
    let list = Array.from(_productsStore.values());

    if (userId) {
      list = list.filter(p => String(p.userId) === String(userId));
    }

    if (status && status !== 'ALL') {
      list = list.filter(p => p.status === status);
    }
    if (search) {
      const q = search.toLowerCase().trim();
      list = list.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.sku.toLowerCase().includes(q) ||
        (p.hsnCode && p.hsnCode.includes(q)) ||
        (p.barcode && p.barcode.includes(q))
      );
    }
    if (category && category !== 'ALL') {
      list = list.filter(p => p.category.toLowerCase() === category.toLowerCase());
    }
    if (lowStockOnly) {
      list = list.filter(p => p.currentStock <= p.reorderLevel);
    }

    list.sort((a, b) => a.name.localeCompare(b.name));
    return list;
  }

  static async findById(id) {
    return _productsStore.get(id) || null;
  }

  static async findBySku(sku) {
    const cleanSku = (sku || '').trim().toUpperCase();
    for (const p of _productsStore.values()) {
      if (p.sku.toUpperCase() === cleanSku) return p;
    }
    return null;
  }

  static async findByBarcodeOrQR(code) {
    const q = (code || '').trim();
    for (const p of _productsStore.values()) {
      if (p.barcode === q || p.qrCode === q) return p;
    }
    return null;
  }

  /**
   * Create New Product Master Item
   */
  static async createProduct(data) {
    const sku = (data.sku || `SKU-${Date.now().toString().slice(-5)}`).trim().toUpperCase();
    const existing = await this.findBySku(sku);
    if (existing) {
      throw new Error(`SKU '${sku}' already exists. Please choose a unique SKU.`);
    }

    const id = `prod_${Date.now()}`;
    const costPrice = Number(data.costPrice) || 0;
    const currentStock = Number(data.currentStock) || Number(data.stockQuantity) || 0;

    const product = {
      id,
      sku,
      name: data.name.trim(),
      category: data.category || 'General',
      unit: data.unit || 'Pcs',
      hsnCode: data.hsnCode || '',
      costPrice,
      sellingPrice: Number(data.sellingPrice) || 0,
      gstRate: Number(data.gstRate) || 18,
      reorderLevel: Number(data.reorderLevel) || 5,
      currentStock,
      barcode: data.barcode || `890${Date.now().toString().slice(-9)}`,
      qrCode: data.qrCode || `QR-${sku}`,
      trackBatch: Boolean(data.trackBatch),
      trackExpiry: Boolean(data.trackExpiry),
      valuationMethod: data.valuationMethod || 'FIFO',
      costLayers: currentStock > 0 ? [{ quantity: currentStock, unitCost: costPrice, date: new Date().toISOString() }] : [],
      status: 'ACTIVE',
      supplierId: data.supplierId || '',
      supplierName: data.supplierName || '',
      userId: data.userId || null,
      createdAt: new Date().toISOString(),
    };

    _productsStore.set(id, product);

    // If opening stock > 0, log to stock ledger
    if (currentStock > 0) {
      await this.recordStockMovement({
        productId: id,
        type: 'OPENING_STOCK',
        quantity: currentStock,
        unitCost: costPrice,
        reason: 'Initial Opening Stock Entry',
        referenceType: 'OPENING_BALANCE',
        referenceId: 'INIT',
      });
    }

    db.saveResilienceStore();
    return product;
  }

  /**
   * Update Product Master
   */
  static async updateProduct(id, data, userId = null) {
    const product = await this.findById(id);
    if (!product) throw new Error('Product not found');

    if (userId && product.userId && String(product.userId) !== String(userId)) {
      throw new Error('Unauthorized to update this product.');
    }

    if (data.sku && data.sku.trim().toUpperCase() !== product.sku) {
      const skuCheck = await this.findBySku(data.sku);
      if (skuCheck && skuCheck.id !== id) {
        throw new Error(`SKU '${data.sku}' already belongs to another product.`);
      }
      product.sku = data.sku.trim().toUpperCase();
    }

    if (data.name) product.name = data.name.trim();
    if (data.category) product.category = data.category.trim();
    if (data.unit) product.unit = data.unit.trim();
    if (data.hsnCode !== undefined || data.hsn_code !== undefined) {
      product.hsnCode = String(data.hsnCode ?? data.hsn_code ?? '').trim();
    }
    if (data.costPrice !== undefined || data.cost_price !== undefined) {
      product.costPrice = Math.max(0, Number(data.costPrice ?? data.cost_price) || 0);
    }
    if (data.sellingPrice !== undefined || data.selling_price !== undefined) {
      product.sellingPrice = Math.max(0, Number(data.sellingPrice ?? data.selling_price) || 0);
    }
    if (data.gstRate !== undefined || data.gst_rate !== undefined) {
      product.gstRate = Number(data.gstRate ?? data.gst_rate) || 18;
    }
    if (data.reorderLevel !== undefined || data.reorder_level !== undefined) {
      product.reorderLevel = Number(data.reorderLevel ?? data.reorder_level) || 10;
    }
    if (data.currentStock !== undefined || data.current_stock !== undefined || data.stockQuantity !== undefined || data.stock_quantity !== undefined) {
      product.currentStock = Math.max(0, parseInt(data.currentStock ?? data.current_stock ?? data.stockQuantity ?? data.stock_quantity, 10) || 0);
    }
    if (data.barcode !== undefined) product.barcode = data.barcode.trim();
    if (data.status) product.status = data.status;

    _productsStore.set(id, product);
    db.saveResilienceStore();
    return product;
  }

  /**
   * Delete Product Master
   */
  static async deleteProduct(id, userId = null) {
    const product = await this.findById(id);
    if (!product) return false;

    if (userId && product.userId && String(product.userId) !== String(userId)) {
      return false;
    }

    _productsStore.delete(id);
    db.saveResilienceStore();
    return true;
  }

  /**
   * Record Stock In (Purchase Receipt / Goods Inward)
   */
  static async stockIn({ productId, quantity, unitCost, supplierId, billNumber, batchNumber, expiryDate, notes }) {
    const product = await this.findById(productId);
    if (!product) throw new Error('Product not found');

    const qty = Number(quantity);
    if (isNaN(qty) || qty <= 0) throw new Error('Valid positive quantity is required for Stock In.');

    const cost = Number(unitCost) || product.costPrice;
    const prevStock = product.currentStock;
    product.currentStock += qty;

    // Add to FIFO Cost Layers
    if (!product.costLayers) product.costLayers = [];
    product.costLayers.push({
      quantity: qty,
      unitCost: cost,
      batchNumber: batchNumber || '',
      expiryDate: expiryDate || '',
      date: new Date().toISOString(),
    });

    _productsStore.set(productId, product);

    const movement = await this.recordStockMovement({
      productId,
      type: 'PURCHASE',
      quantity: qty,
      unitCost: cost,
      reason: notes || `Goods Inward (Bill: ${billNumber || 'N/A'})`,
      referenceType: 'PURCHASE_BILL',
      referenceId: billNumber || '',
    });

    db.saveResilienceStore();
    return { product, movement };
  }

  /**
   * Record Stock Out (Sale Dispatch / Consumption)
   */
  static async stockOut({ productId, quantity, invoiceNumber, notes }) {
    const product = await this.findById(productId);
    if (!product) throw new Error('Product not found');

    const qty = Number(quantity);
    if (isNaN(qty) || qty <= 0) throw new Error('Valid positive quantity is required for Stock Out.');

    if (product.currentStock < qty) {
      throw new Error(`Insufficient stock for '${product.name}'. Available: ${product.currentStock} ${product.unit}, Requested: ${qty} ${product.unit}`);
    }

    const prevStock = product.currentStock;
    product.currentStock -= qty;

    // Deduct FIFO Layers
    let remainingToDeduct = qty;
    if (product.costLayers) {
      for (const layer of product.costLayers) {
        if (layer.quantity >= remainingToDeduct) {
          layer.quantity -= remainingToDeduct;
          remainingToDeduct = 0;
          break;
        } else {
          remainingToDeduct -= layer.quantity;
          layer.quantity = 0;
        }
      }
      product.costLayers = product.costLayers.filter(l => l.quantity > 0);
    }

    _productsStore.set(productId, product);

    const movement = await this.recordStockMovement({
      productId,
      type: 'SALE',
      quantity: qty,
      unitCost: product.costPrice,
      reason: notes || `Sales Dispatch (Invoice: ${invoiceNumber || 'N/A'})`,
      referenceType: 'SALES_INVOICE',
      referenceId: invoiceNumber || '',
    });

    db.saveResilienceStore();
    return { product, movement };
  }

  /**
   * Manual Stock Adjustment (Damage, Theft, Return, Counting Error)
   */
  static async adjustStock({ productId, adjustmentType, quantity, reason, notes }) {
    const product = await this.findById(productId);
    if (!product) throw new Error('Product not found');

    const qty = Math.abs(Number(quantity));
    if (isNaN(qty) || qty <= 0) throw new Error('Valid positive quantity is required for adjustment.');

    const cleanType = (adjustmentType || 'DAMAGE').toUpperCase();
    const prevStock = product.currentStock;

    if (['DAMAGE', 'THEFT', 'ADJUSTMENT_OUT', 'RETURN_OUT'].includes(cleanType)) {
      if (product.currentStock < qty) {
        throw new Error(`Cannot adjust out more than available stock (${product.currentStock} ${product.unit}).`);
      }
      product.currentStock -= qty;
    } else {
      product.currentStock += qty;
    }

    _productsStore.set(productId, product);

    const movement = await this.recordStockMovement({
      productId,
      type: cleanType,
      quantity: qty,
      unitCost: product.costPrice,
      reason: `${reason || cleanType}: ${notes || 'Manual stock correction'}`,
      referenceType: 'MANUAL_ADJUSTMENT',
      referenceId: `ADJ-${Date.now().toString().slice(-4)}`,
    });

    db.saveResilienceStore();
    return { product, movement };
  }

  /**
   * Immutable Stock Movement Logger
   */
  static async recordStockMovement({ productId, type, quantity, unitCost, reason, referenceType, referenceId }) {
    const product = await this.findById(productId);
    const id = `stk_${Date.now()}_${Math.random().toString(36).slice(-3)}`;

    const log = {
      id,
      productId,
      productName: product ? product.name : 'Product',
      sku: product ? product.sku : '',
      type,
      quantity: Number(quantity),
      unitCost: Number(unitCost) || (product ? product.costPrice : 0),
      balanceAfter: product ? product.currentStock : 0,
      referenceType: referenceType || 'MANUAL',
      referenceId: referenceId || '',
      reason: reason || 'Inventory movement',
      user: 'Authorized User',
      createdAt: new Date().toISOString(),
    };

    _stockLedgerStore.set(id, log);
    return log;
  }

  /**
   * Get Stock Movement Ledger
   */
  static async getStockLedger({ productId, type } = {}) {
    let list = Array.from(_stockLedgerStore.values());
    if (productId) list = list.filter(m => m.productId === productId);
    if (type && type !== 'ALL') list = list.filter(m => m.type === type);

    list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return list;
  }

  /**
   * Supplier Master Management
   */
  static async getSuppliers(userId = null) {
    let list = Array.from(_suppliersStore.values()).filter(s => s.status === 'ACTIVE' || s.isActive !== false);
    if (userId) {
      list = list.filter(s => String(s.userId) === String(userId) || (process.env.NODE_ENV === 'test' && !s.userId) || !s.userId);
    }
    // Return newest suppliers first
    list.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    return list;
  }

  static async findSupplierById(id) {
    return _suppliersStore.get(id) || null;
  }

  static async createSupplier(data) {
    // 1. Validation - Name
    if (!data.name || !data.name.trim()) {
      throw new Error('Supplier name is required');
    }

    // 2. Validation - Contact Phone
    const phoneRaw = (data.contactNumber || data.phone || '').toString().trim();
    if (!phoneRaw) {
      throw new Error('Contact phone number is required');
    }
    const cleanPhone = phoneRaw.replace(/[\s\-\(\)]/g, '');
    const phoneRegex = /^(?:\+91|0)?[6-9]\d{9}$/;
    if (!phoneRegex.test(cleanPhone)) {
      throw new Error('Please enter a valid 10-digit Indian mobile number (e.g. 9848022334)');
    }

    // 3. Validation - GSTIN (if provided)
    const gstinRaw = (data.gstin || '').toString().trim().toUpperCase();
    if (gstinRaw) {
      const gstinRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
      if (!gstinRegex.test(gstinRaw)) {
        throw new Error('Invalid GSTIN format. Expected 15 characters (e.g. 24AAACK1234F1Z5)');
      }
    }

    const id = `supp_${Date.now()}`;
    const country = data.country ? data.country.trim() : 'India';
    const countryCode = data.countryCode || 'IN';
    const state = data.state ? data.state.trim() : '';
    const stateCode = data.stateCode || (state ? state.slice(0, 2).toUpperCase() : '36');
    const district = data.district ? data.district.trim() : '';
    const city = data.city ? data.city.trim() : (data.mandal ? data.mandal.trim() : district);
    const mandal = data.mandal ? data.mandal.trim() : city;
    const pincode = data.pincode ? String(data.pincode).trim() : '';
    const addressLine = data.addressLine ? data.addressLine.trim() : (data.address ? data.address.trim() : '');
    const landmark = data.landmark ? data.landmark.trim() : '';

    // Formatted full address string
    let fullAddress = addressLine;
    if (landmark) fullAddress = fullAddress ? `${fullAddress}, ${landmark}` : landmark;
    if (mandal && mandal !== city) fullAddress = fullAddress ? `${fullAddress}, ${mandal}` : mandal;
    if (city) fullAddress = fullAddress ? `${fullAddress}, ${city}` : city;
    if (district && district !== city) fullAddress = fullAddress ? `${fullAddress}, ${district}` : district;
    if (state) fullAddress = fullAddress ? `${fullAddress}, ${state}` : state;
    if (pincode) fullAddress = fullAddress ? `${fullAddress} - ${pincode}` : pincode;
    if (country) fullAddress = fullAddress ? `${fullAddress}, ${country}` : country;

    const openingPayable = Number(data.openingBalance) || Number(data.opening_balance) || Number(data.outstandingPayable) || Number(data.outstanding_payable) || 0.00;

    const supplier = {
      id,
      name: data.name.trim(),
      companyName: data.companyName ? data.companyName.trim() : '',
      contactNumber: cleanPhone,
      phone: cleanPhone,
      email: data.email ? data.email.trim().toLowerCase() : '',
      country,
      countryCode,
      state,
      stateCode,
      district,
      city,
      mandal,
      pincode,
      addressLine,
      landmark,
      address: fullAddress || addressLine,
      gstin: gstinRaw,
      category: data.category || 'RAW_MATERIALS',
      paymentTerms: data.paymentTerms || 'Net 30',
      dueDate: data.dueDate || null,
      dueReminderEnabled: Boolean(data.dueReminderEnabled),
      reminderDate: data.reminderDate || null,
      openingBalance: openingPayable,
      outstandingPayable: openingPayable,
      currentBalance: openingPayable,
      notes: data.notes ? data.notes.trim() : '',
      status: 'ACTIVE',
      isActive: true,
      userId: data.userId || 1,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // Store in-memory and write to resilience disk store
    _suppliersStore.set(id, supplier);
    db.saveResilienceStore();

    // SQL Database Persistence (if pool connected)
    try {
      if (db.pool && !db.isInMemoryFallback) {
        await db.query(`
          INSERT INTO suppliers (
            id, user_id, name, contact_number, email, company_name, gstin, address, state_code,
            opening_balance, current_balance, category, payment_terms, notes, is_active, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
          ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            contact_number = VALUES(contact_number),
            email = VALUES(email),
            company_name = VALUES(company_name),
            gstin = VALUES(gstin),
            address = VALUES(address),
            opening_balance = VALUES(opening_balance),
            current_balance = VALUES(current_balance),
            notes = VALUES(notes),
            updated_at = NOW()
        `, [
          id, String(supplier.userId), supplier.name, supplier.contactNumber,
          supplier.email || null, supplier.companyName || null, supplier.gstin || null,
          supplier.address || null, supplier.stateCode, supplier.openingBalance,
          supplier.outstandingPayable, supplier.category, supplier.paymentTerms,
          supplier.notes || null, true
        ]);
      }
    } catch (sqlErr) {
      console.warn('[InventoryModel.createSupplier] SQL storage notice (resilience store safe):', sqlErr.message);
    }

    return supplier;
  }

  static async updateSupplier(id, data, userId = null) {
    const supplier = await this.findSupplierById(id);
    if (!supplier) throw new Error('Supplier not found');

    if (userId && supplier.userId && String(supplier.userId) !== String(userId)) {
      throw new Error('Unauthorized to update this supplier.');
    }

    if (data.name) supplier.name = data.name.trim();
    if (data.companyName !== undefined) supplier.companyName = data.companyName ? data.companyName.trim() : '';
    if (data.contactNumber || data.phone) {
      const p = (data.contactNumber || data.phone).toString().trim().replace(/[\s\-\(\)]/g, '');
      supplier.contactNumber = p;
      supplier.phone = p;
    }
    if (data.email !== undefined) supplier.email = data.email ? data.email.trim().toLowerCase() : '';
    if (data.gstin !== undefined) supplier.gstin = data.gstin ? data.gstin.trim().toUpperCase() : '';
    if (data.address !== undefined) supplier.address = data.address ? data.address.trim() : '';
    if (data.category !== undefined) supplier.category = data.category;
    if (data.paymentTerms !== undefined) supplier.paymentTerms = data.paymentTerms;
    if (data.dueDate !== undefined) supplier.dueDate = data.dueDate;
    if (data.dueReminderEnabled !== undefined) supplier.dueReminderEnabled = Boolean(data.dueReminderEnabled);
    if (data.reminderDate !== undefined) supplier.reminderDate = data.reminderDate;
    if (data.outstandingPayable !== undefined) {
      supplier.outstandingPayable = Number(data.outstandingPayable) || 0.0;
      supplier.currentBalance = supplier.outstandingPayable;
    }
    if (data.notes !== undefined) supplier.notes = data.notes ? data.notes.trim() : '';
    supplier.updatedAt = new Date().toISOString();

    _suppliersStore.set(id, supplier);
    db.saveResilienceStore();
    return supplier;
  }

  static async deleteSupplier(id, userId = null) {
    const supplier = await this.findSupplierById(id);
    if (!supplier) return false;

    if (userId && supplier.userId && String(supplier.userId) !== String(userId)) {
      throw new Error('Unauthorized to delete this supplier.');
    }

    supplier.status = 'INACTIVE';
    supplier.isActive = false;
    _suppliersStore.set(id, supplier);
    db.saveResilienceStore();
    return true;
  }

  /**
   * Purchase Order Management
   */
  static async getPurchaseOrders(userId = null) {
    let list = Array.from(_purchaseOrdersStore.values());
    if (userId) {
      list = list.filter(po => String(po.userId) === String(userId));
    }
    list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return list;
  }

  static async createPurchaseOrder(data) {
    const id = `po_${Date.now()}`;
    const seq = _purchaseOrdersStore.size + 1;
    const poNumber = `PO/2026-27/${String(seq).padStart(4, '0')}`;

    let subTotal = 0;
    let taxTotal = 0;

    const items = (data.items || []).map(item => {
      const qty = Number(item.quantity) || 1;
      const unitCost = Number(item.unitCost) || 0;
      const gstRate = Number(item.gstRate) || 18;
      const itemSub = qty * unitCost;
      const itemTax = (itemSub * gstRate) / 100;
      subTotal += itemSub;
      taxTotal += itemTax;

      return {
        productId: item.productId,
        productName: item.productName,
        quantity: qty,
        receivedQuantity: 0,
        unitCost,
        gstRate,
        total: Number((itemSub + itemTax).toFixed(2)),
      };
    });

    const grandTotal = subTotal + taxTotal;

    const po = {
      id,
      poNumber,
      supplierId: data.supplierId,
      supplierName: data.supplierName || 'Supplier',
      userId: data.userId || null,
      poDate: data.poDate || new Date().toISOString().split('T')[0],
      expectedDeliveryDate: data.expectedDeliveryDate || '',
      items,
      subTotal: Number(subTotal.toFixed(2)),
      taxTotal: Number(taxTotal.toFixed(2)),
      grandTotal: Number(grandTotal.toFixed(2)),
      status: 'Issued',
      notes: data.notes || '',
      createdAt: new Date().toISOString(),
    };

    _purchaseOrdersStore.set(id, po);
    db.saveResilienceStore();
    return po;
  }

  /**
   * Receive PO Items & Stage Inventory
   */
  static async receivePurchaseOrder(poId, receivedQuantities = {}) {
    const po = _purchaseOrdersStore.get(poId);
    if (!po) throw new Error('Purchase Order not found');

    let allFullyReceived = true;

    for (const item of po.items) {
      const incoming = Number(receivedQuantities[item.productId]) || 0;
      if (incoming > 0) {
        item.receivedQuantity = (item.receivedQuantity || 0) + incoming;

        // Add to stock
        await this.stockIn({
          productId: item.productId,
          quantity: incoming,
          unitCost: item.unitCost,
          supplierId: po.supplierId,
          billNumber: po.poNumber,
          notes: `PO Receiving (${po.poNumber})`,
        });
      }

      if (item.receivedQuantity < item.quantity) {
        allFullyReceived = false;
      }
    }

    po.status = allFullyReceived ? 'Received' : 'Partially Received';
    _purchaseOrdersStore.set(poId, po);
    return po;
  }

  /**
   * Inventory Valuation & Executive KPI Summary
   */
  static async getInventorySummary(userId = null) {
    let products = Array.from(_productsStore.values()).filter(p => p.status === 'ACTIVE');
    if (userId) {
      products = products.filter(p => String(p.userId) === String(userId));
    }

    let totalStockQty = 0;
    let totalValuationPaise = 0n;
    let totalSellingPaise = 0n;
    let lowStockCount = 0;
    let outOfStockCount = 0;

    products.forEach(p => {
      const stock = Math.max(0, parseInt(p.currentStock, 10) || 0);
      const cost = Math.max(0, parseFloat(p.costPrice) || 0);
      const sell = Math.max(0, parseFloat(p.sellingPrice) || 0);

      totalStockQty += stock;

      // Integer arithmetic using paise to prevent binary floating-point inaccuracy
      const costPaise = Math.round(cost * 100);
      const sellPaise = Math.round(sell * 100);

      totalValuationPaise += BigInt(stock) * BigInt(costPaise);
      totalSellingPaise += BigInt(stock) * BigInt(sellPaise);

      const reorder = parseInt(p.reorderLevel, 10) || 10;
      if (stock <= 0) outOfStockCount++;
      else if (stock <= reorder) lowStockCount++;
    });

    const totalCostValuation = Number(totalValuationPaise) / 100;
    const totalPotentialSellingValue = Number(totalSellingPaise) / 100;
    const estimatedGrossMargin = Number((totalPotentialSellingValue - totalCostValuation).toFixed(2));

    let suppliers = Array.from(_suppliersStore.values()).filter(s => s.status === 'ACTIVE');
    if (userId) {
      suppliers = suppliers.filter(s => String(s.userId) === String(userId));
    }
    const totalOutstandingPayable = suppliers.reduce((sum, s) => sum + (Number(s.outstandingPayable) || 0), 0);

    return {
      total_inventory_valuation: Number(totalCostValuation.toFixed(2)),
      totalCostValuation: Number(totalCostValuation.toFixed(2)),
      currency: 'INR',
      totalProducts: products.length,
      totalStockQuantity: totalStockQty,
      total_stock_quantity: totalStockQty,
      totalPotentialSellingValue: Number(totalPotentialSellingValue.toFixed(2)),
      estimatedGrossMargin,
      lowStockCount,
      outOfStockCount,
      totalSuppliers: suppliers.length,
      totalOutstandingPayable: Number(totalOutstandingPayable.toFixed(2)),
    };
  }
}

module.exports = InventoryModel;
