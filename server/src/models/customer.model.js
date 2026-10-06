const db = require('../config/db.config');
const LocationService = require('../services/location.service');
const uuidv4 = () => crypto.randomUUID();

// In-memory store for customers and ledger tied to resilience store
const _customersStore = db.inMemoryStore.customers;
const _ledgerStore = db.inMemoryStore.khataEntries;

// Seed initial realistic mock customers with structured location data (Test environment only)
function seedInitialCustomers() {
  if (process.env.NODE_ENV !== 'test') return;
  if (_customersStore.size > 0) return;

  const mockCustomers = [
    {
      id: 'cust_001',
      userId: 1,
      name: 'Enx money',
      companyName: 'Enterprenex Solutions',
      phone: '9000000001',
      email: 'kishore@enterprenex.com',
      country: 'India',
      countryCode: 'IN',
      state: 'Telangana',
      stateCode: 'TS',
      district: 'Hyderabad',
      city: 'Hyderabad',
      pincode: '500001',
      addressLine: 'Shop 14, Main Cloth Market, Abids',
      landmark: 'Opposite SBI Main Branch',
      address: 'Shop 14, Main Cloth Market, Abids, Opposite SBI Main Branch, Hyderabad, Telangana - 500001, India',
      gstin: '36AABCU9603R1ZM',
      category: 'WHOLESALE',
      openingBalance: 500.00,
      currentBalance: 500.00, // Positive = You'll get (Due)
      creditLimit: 50000.00,
      blockOnCreditBreach: true,
      notes: 'Settles invoices bi-weekly via UPI/NEFT',
      tags: ['Wholesale', 'High Volume'],
      isActive: true,
      createdAt: new Date(Date.now() - 45 * 86400000).toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
      id: 'cust_002',
      userId: 1,
      name: 'Apex Retailers',
      companyName: 'Apex Mart LLP',
      phone: '9848022338',
      email: 'contact@apexmart.in',
      country: 'India',
      countryCode: 'IN',
      state: 'Karnataka',
      stateCode: 'KA',
      district: 'Bengaluru Urban',
      city: 'Bengaluru',
      pincode: '560034',
      addressLine: '4th Block, 100ft Road, Koramangala',
      landmark: 'Near Sony World Signal',
      address: '4th Block, 100ft Road, Koramangala, Near Sony World Signal, Bengaluru, Karnataka - 560034, India',
      gstin: '29AAACA1234E1ZR',
      category: 'REGULAR',
      openingBalance: 18500.00,
      currentBalance: 18500.00,
      creditLimit: 50000.00,
      blockOnCreditBreach: false,
      notes: 'Requires delivery challan copy with bill',
      tags: ['Retailer', 'Priority'],
      isActive: true,
      createdAt: new Date(Date.now() - 25 * 86400000).toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
      id: 'cust_003',
      userId: 1,
      name: 'Modern Supermarket',
      companyName: 'Modern Retail Corp',
      phone: '9876543210',
      email: 'billing@modernsuper.com',
      country: 'India',
      countryCode: 'IN',
      state: 'Telangana',
      stateCode: 'TS',
      district: 'Hyderabad',
      city: 'Hyderabad',
      pincode: '500034',
      addressLine: 'Plot 24, Road No. 36, Jubilee Hills',
      landmark: 'Near Metro Station',
      address: 'Plot 24, Road No. 36, Jubilee Hills, Near Metro Station, Hyderabad, Telangana - 500034, India',
      gstin: '36AAACM5678B1ZP',
      category: 'VIP',
      openingBalance: 0.00,
      currentBalance: 0.00,
      creditLimit: 150000.00,
      blockOnCreditBreach: true,
      notes: 'Key retail account with 30-day payment cycle',
      tags: ['VIP', 'Chain Store'],
      isActive: true,
      createdAt: new Date(Date.now() - 10 * 86400000).toISOString(),
      updatedAt: new Date().toISOString(),
    }
  ];

  for (const c of mockCustomers) {
    _customersStore.set(c.id, c);
  }

  // Seed sample ledger entries
  const mockEntries = [
    {
      id: 'ledg_001',
      userId: 1,
      customerId: 'cust_001',
      entryType: 'GAVE', // Udhaar
      amount: 500.00,
      balanceAfter: 500.00,
      paymentMode: 'CREDIT',
      invoiceNumber: 'INV-2026-0001',
      description: 'Cotton Fabric Supply - Order #001',
      entryDate: '2026-08-25',
      createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
    }
  ];

  for (const e of mockEntries) {
    _ledgerStore.set(e.id, e);
  }
}

seedInitialCustomers();

class CustomerModel {
  static async findAll({ userId, search, category, status, balanceType, state, district, pincode } = {}) {
    let list = [];
    for (const cust of _customersStore.values()) {
      const matchesUser = userId
        ? (String(cust.userId) === String(userId))
        : false;
      if (matchesUser && cust.isActive !== false) {
        list.push({ ...cust });
      }
    }

    const allCount = list.length;
    const duesPendingCount = list.filter(c => c.currentBalance > 0).length;
    const settledCount = list.filter(c => c.currentBalance <= 0).length;

    // Search filter across name, phone, email, gstin, city, district, state, pincode
    if (search) {
      const q = search.toLowerCase().trim();
      list = list.filter(c =>
        c.name.toLowerCase().includes(q) ||
        (c.companyName && c.companyName.toLowerCase().includes(q)) ||
        c.phone.includes(q) ||
        (c.email && c.email.toLowerCase().includes(q)) ||
        (c.gstin && c.gstin.toLowerCase().includes(q)) ||
        (c.district && c.district.toLowerCase().includes(q)) ||
        (c.state && c.state.toLowerCase().includes(q)) ||
        (c.pincode && c.pincode.includes(q)) ||
        (c.city && c.city.toLowerCase().includes(q))
      );
    }

    // Location specific filters
    if (state && state !== 'ALL') {
      list = list.filter(c => c.state === state);
    }
    if (district && district !== 'ALL') {
      list = list.filter(c => c.district === district);
    }
    if (pincode) {
      list = list.filter(c => c.pincode === pincode);
    }

    // Status filter
    if (status === 'due') {
      list = list.filter(c => c.currentBalance > 0);
    } else if (status === 'settled') {
      list = list.filter(c => c.currentBalance <= 0);
    }

    // Aggregate summary
    let totalReceivable = 0;
    let totalPayable = 0;
    list.forEach(c => {
      if (c.currentBalance > 0) totalReceivable += c.currentBalance;
      else if (c.currentBalance < 0) totalPayable += Math.abs(c.currentBalance);
    });

    return {
      customers: list,
      totalCount: list.length,
      allCount,
      duesPendingCount,
      settledCount,
      totalReceivable,
      totalPayable,
    };
  }

  static async findById(id) {
    const cust = _customersStore.get(id);
    if (!cust || cust.isActive === false) return null;

    let totalSales = 0;
    let totalPayments = 0;
    for (const e of _ledgerStore.values()) {
      if (e.customerId === id) {
        if (e.entryType === 'GAVE') {
          totalSales += Number(e.amount) || 0;
        } else if (e.entryType === 'GOT') {
          totalPayments += Number(e.amount) || 0;
        }
      }
    }

    const aging = {
      days0_30: cust.currentBalance > 0 ? cust.currentBalance * 0.6 : 0,
      days31_60: cust.currentBalance > 0 ? cust.currentBalance * 0.25 : 0,
      days61_90: cust.currentBalance > 0 ? cust.currentBalance * 0.10 : 0,
      days90Plus: cust.currentBalance > 0 ? cust.currentBalance * 0.05 : 0,
    };

    return {
      ...cust,
      totalSales: totalSales > 0 ? totalSales : (cust.currentBalance > 0 ? cust.currentBalance : 0),
      totalPayments: totalPayments > 0 ? totalPayments : 0,
      aging,
    };
  }

  static async create(data) {
    // 1. Location Hierarchy Validation (non-blocking for optional address fields)
    const cleanState = data.state ? String(data.state).trim() : '';
    const cleanDistrict = data.district ? String(data.district).trim() : '';
    const cleanPincode = data.pincode ? String(data.pincode).trim() : '';

    if (cleanState && cleanDistrict && cleanPincode) {
      const valResult = LocationService.validateLocationHierarchy({
        country: data.country || 'India',
        countryCode: data.countryCode || 'IN',
        state: cleanState,
        district: cleanDistrict,
        pincode: cleanPincode,
      });
      if (!valResult.valid) {
        console.warn(`[CustomerModel.create] Location validation warning: ${valResult.message}`);
      }
    } else if (cleanPincode && (!cleanState || !cleanDistrict)) {
      // Auto-populate state/district from pincode if available
      try {
        const pinResult = LocationService.lookupPincode(cleanPincode);
        if (pinResult && pinResult.valid) {
          if (!cleanState && pinResult.state) data.state = pinResult.state;
          if (!cleanDistrict && pinResult.district) data.district = pinResult.district;
        }
      } catch (err) {
        // Fallback gracefully
      }
    }

    const id = `cust_${uuidv4().replace(/-/g, '').slice(0, 8)}`;
    const country = data.country ? data.country.trim() : 'India';
    const countryCode = data.countryCode || 'IN';
    const state = data.state ? data.state.trim() : '';
    const stateCode = data.stateCode || (state ? state.slice(0, 2).toUpperCase() : '');
    const district = data.district ? data.district.trim() : '';
    const city = data.city ? data.city.trim() : district;
    const mandal = data.mandal ? data.mandal.trim() : city;
    const pincode = data.pincode ? String(data.pincode).trim() : '';
    const addressLine = data.addressLine ? data.addressLine.trim() : (data.address ? data.address.trim() : '');
    const landmark = data.landmark ? data.landmark.trim() : '';

    // Synthesize structured full address string
    let fullAddress = addressLine;
    if (landmark) fullAddress += `, ${landmark}`;
    if (mandal && mandal !== city) fullAddress += `, ${mandal}`;
    if (city && city !== district) fullAddress += `, ${city}`;
    if (district) fullAddress += `, ${district}`;
    if (state) fullAddress += `, ${state}`;
    if (pincode) fullAddress += ` - ${pincode}`;
    if (country) fullAddress += `, ${country}`;

    const newCust = {
      id,
      userId: data.userId || 1,
      name: data.name.trim(),
      companyName: data.companyName ? data.companyName.trim() : '',
      phone: data.phone.trim(),
      email: data.email ? data.email.trim() : '',
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
      gstin: data.gstin ? data.gstin.trim().toUpperCase() : '',
      category: data.category || 'REGULAR',
      openingBalance: Number(data.openingBalance) || 0.00,
      currentBalance: Number(data.openingBalance) || 0.00,
      creditLimit: Number(data.creditLimit) || 0.00,
      blockOnCreditBreach: Boolean(data.blockOnCreditBreach),
      notes: data.notes || '',
      tags: data.tags || ['Customer'],
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    _customersStore.set(id, newCust);

    // If opening balance > 0, record ledger entry
    if (newCust.openingBalance !== 0) {
      const entryType = newCust.openingBalance > 0 ? 'GAVE' : 'GOT';
      const entryId = `ledg_${uuidv4().replace(/-/g, '').slice(0, 8)}`;
      _ledgerStore.set(entryId, {
        id: entryId,
        userId: newCust.userId,
        customerId: id,
        entryType,
        amount: Math.abs(newCust.openingBalance),
        balanceAfter: newCust.openingBalance,
        paymentMode: 'OPENING_BALANCE',
        description: 'Opening Balance Setup',
        entryDate: new Date().toISOString().split('T')[0],
        createdAt: new Date().toISOString(),
      });
    }

    db.saveResilienceStore();
    return newCust;
  }

  static async update(id, data) {
    const cust = _customersStore.get(id);
    if (!cust || cust.isActive === false) return null;

    const updState = data.state !== undefined ? String(data.state).trim() : (cust.state || '');
    const updDistrict = data.district !== undefined ? String(data.district).trim() : (cust.district || '');
    const updPincode = data.pincode !== undefined ? String(data.pincode).trim() : (cust.pincode || '');

    if (updState && updDistrict && updPincode) {
      const valResult = LocationService.validateLocationHierarchy({
        country: data.country || cust.country || 'India',
        countryCode: data.countryCode || cust.countryCode || 'IN',
        state: updState,
        district: updDistrict,
        pincode: updPincode,
      });
      if (!valResult.valid) {
        console.warn(`[CustomerModel.update] Location validation warning: ${valResult.message}`);
      }
    }

    const updated = {
      ...cust,
      name: data.name !== undefined ? data.name.trim() : cust.name,
      companyName: data.companyName !== undefined ? data.companyName.trim() : cust.companyName,
      phone: data.phone !== undefined ? data.phone.trim() : cust.phone,
      email: data.email !== undefined ? data.email.trim() : cust.email,
      country: data.country !== undefined ? data.country.trim() : cust.country,
      countryCode: data.countryCode !== undefined ? data.countryCode : cust.countryCode,
      state: data.state !== undefined ? data.state.trim() : cust.state,
      stateCode: data.stateCode !== undefined ? data.stateCode : cust.stateCode,
      district: data.district !== undefined ? data.district.trim() : cust.district,
      city: data.city !== undefined ? data.city.trim() : cust.city,
      pincode: data.pincode !== undefined ? String(data.pincode).trim() : cust.pincode,
      addressLine: data.addressLine !== undefined ? data.addressLine.trim() : cust.addressLine,
      landmark: data.landmark !== undefined ? data.landmark.trim() : cust.landmark,
      gstin: data.gstin !== undefined ? data.gstin.trim().toUpperCase() : cust.gstin,
      creditLimit: data.creditLimit !== undefined ? Number(data.creditLimit) : cust.creditLimit,
      updatedAt: new Date().toISOString(),
    };

    _customersStore.set(id, updated);
    db.saveResilienceStore();
    return updated;
  }

  static async delete(id) {
    const cust = _customersStore.get(id);
    if (!cust) return false;
    cust.isActive = false;
    cust.updatedAt = new Date().toISOString();
    _customersStore.set(id, cust);
    db.saveResilienceStore();
    return true;
  }

  static async getLedger(customerId) {
    const list = [];
    for (const e of _ledgerStore.values()) {
      if (e.customerId === customerId) {
        list.push({ ...e });
      }
    }
    list.sort((a, b) => new Date(b.entryDate) - new Date(a.entryDate));
    return list;
  }

  static async addLedgerEntry({ userId = 1, customerId, entryType, amount, paymentMode = 'CASH', description = '', invoiceNumber = '' }) {
    const cust = _customersStore.get(customerId);
    if (!cust) throw new Error('Customer not found');

    const numAmount = Number(amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      throw new Error('Valid positive amount is required');
    }

    if (entryType === 'GAVE') {
      cust.currentBalance += numAmount;
    } else if (entryType === 'GOT') {
      cust.currentBalance -= numAmount;
    } else {
      throw new Error('Invalid entry type. Must be GAVE or GOT');
    }

    cust.updatedAt = new Date().toISOString();
    _customersStore.set(customerId, cust);

    const entryId = `ledg_${uuidv4().replace(/-/g, '').slice(0, 8)}`;
    const entry = {
      id: entryId,
      userId,
      customerId,
      entryType,
      amount: numAmount,
      balanceAfter: cust.currentBalance,
      paymentMode,
      description: description || (entryType === 'GAVE' ? 'Goods Sold on Credit' : 'Payment Received'),
      invoiceNumber,
      entryDate: new Date().toISOString().split('T')[0],
      createdAt: new Date().toISOString(),
    };

    _ledgerStore.set(entryId, entry);
    db.saveResilienceStore();

    // Sync with Business Transactions Store
    try {
      const TransactionModel = require('./transaction.model');
      if (entryType === 'GAVE') {
        await TransactionModel.create({
          userId: cust.userId || userId,
          accountType: 'BUSINESS',
          type: 'CREDIT',
          category: 'Sales',
          amount: numAmount,
          paymentMode: paymentMode || 'CREDIT',
          note: `Sale to ${cust.name}${description ? ': ' + description : ''}`,
          referenceType: 'KHATA_SALE',
          referenceId: entryId,
        });
      } else if (entryType === 'GOT') {
        await TransactionModel.create({
          userId: cust.userId || userId,
          accountType: 'BUSINESS',
          type: 'CREDIT',
          category: 'Customer Payment',
          amount: numAmount,
          paymentMode: paymentMode || 'CASH',
          note: `Payment from ${cust.name}${description ? ': ' + description : ''}`,
          referenceType: 'KHATA_PAYMENT',
          referenceId: entryId,
        });
      }
    } catch (err) {
      console.warn('[CustomerModel] Transaction sync warning:', err.message);
    }

    return { customer: cust, entry };
  }
}

module.exports = CustomerModel;
