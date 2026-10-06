const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('./env.config');

const STORE_FILE = process.env.NODE_ENV === 'test'
  ? path.join(__dirname, '../../database/enx_resilience_store.test.json')
  : path.join(__dirname, '../../database/enx_resilience_store.json');

let pool = null;
let isInMemoryFallback = false;
const inMemoryStore = {
  users: new Map(),
  otps: new Map(),
  tokenBlacklist: new Set(),
  loans: new Map(),
  emiSchedules: new Map(),
  loanPayments: new Map(),
  prepayments: new Map(),
  loanReminders: new Map(),
  devices: new Map(),
  deviceApprovalRequests: new Map(),
  customers: new Map(),
  suppliers: new Map(),
  products: new Map(),
  invoices: new Map(),
  transactions: new Map(),
  khataEntries: new Map(),
  stockLedger: new Map(),
  purchaseOrders: new Map(),
  // Subscription & Billing
  subscriptionPlans: new Map(),
  planFeatures: new Map(),
  subscriptions: new Map(),
  subscriptionPayments: new Map(),
  subscriptionInvoices: new Map(),
  coupons: new Map(),
};

/**
 * Load persisted entities from disk resilience file
 */
function loadResilienceStore() {
  try {
    if (fs.existsSync(STORE_FILE)) {
      const raw = fs.readFileSync(STORE_FILE, 'utf8');
      const data = JSON.parse(raw);
      if (data.users && Array.isArray(data.users)) {
        for (const u of data.users) {
          if (u && u.email) {
            inMemoryStore.users.set(u.email.toLowerCase().trim(), u);
          }
        }
        console.log(`[Resilience Store] Loaded ${inMemoryStore.users.size} persisted user(s) from disk.`);
      }

      // Only seed default test user if explicitly in test environment
      if (process.env.NODE_ENV === 'test' && inMemoryStore.users.size === 0) {
        const defaultUser = {
          id: 1,
          name: 'Kishore',
          email: 'kishore@enterprenex.com',
          phone: '+919000000001',
          password_hash: '$2a$10$v/Vp5ZCF9tygYmdeOecVZ.HR3Y9td8GNv9ibnMWil4pbOIwaj/Or6',
          passwordHash: '$2a$10$v/Vp5ZCF9tygYmdeOecVZ.HR3Y9td8GNv9ibnMWil4pbOIwaj/Or6',
          status: 'ACTIVE',
          is_email_verified: true,
          isEmailVerified: true,
          is_biometric_enabled: false,
          isBiometricEnabled: false,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        inMemoryStore.users.set(defaultUser.email, defaultUser);
      }
      if (data.devices && Array.isArray(data.devices)) {
        for (const d of data.devices) {
          const uId = d.user_id || d.userId;
          const devId = d.device_id || d.deviceId;
          if (uId && devId) {
            inMemoryStore.devices.set(`${uId}_${devId}`, d);
          } else if (d.id) {
            inMemoryStore.devices.set(d.id, d);
          }
        }
      }
      if (data.customers && Array.isArray(data.customers)) {
        for (const c of data.customers) {
          if (c && c.id) inMemoryStore.customers.set(c.id, c);
        }
      }
      if (data.suppliers && Array.isArray(data.suppliers)) {
        for (const s of data.suppliers) {
          if (s && s.id) inMemoryStore.suppliers.set(s.id, s);
        }
      }
      if (data.products && Array.isArray(data.products)) {
        for (const p of data.products) {
          if (p && p.id) inMemoryStore.products.set(p.id, p);
        }
      }
      if (data.invoices && Array.isArray(data.invoices)) {
        for (const inv of data.invoices) {
          if (inv && inv.id) inMemoryStore.invoices.set(inv.id, inv);
        }
      }
      if (data.transactions && Array.isArray(data.transactions)) {
        for (const t of data.transactions) {
          if (t && t.id) inMemoryStore.transactions.set(t.id, t);
        }
      }
      if (data.khataEntries && Array.isArray(data.khataEntries)) {
        for (const k of data.khataEntries) {
          if (k && k.id) inMemoryStore.khataEntries.set(k.id, k);
        }
      }
      if (data.stockLedger && Array.isArray(data.stockLedger)) {
        for (const sl of data.stockLedger) {
          if (sl && sl.id) inMemoryStore.stockLedger.set(sl.id, sl);
        }
      }
      if (data.purchaseOrders && Array.isArray(data.purchaseOrders)) {
        for (const po of data.purchaseOrders) {
          if (po && po.id) inMemoryStore.purchaseOrders.set(po.id, po);
        }
      }
    }
  } catch (err) {
    console.warn('[Resilience Store] Notice reading disk store:', err.message);
  }
}

/**
 * Clean expired cache entries (OTPs, tokens)
 */
function cleanCache() {
  const now = Date.now();
  // Clear expired OTPs
  for (const [id, otp] of inMemoryStore.otps.entries()) {
    if (new Date(otp.expires_at).getTime() <= now || otp.is_used) {
      inMemoryStore.otps.delete(id);
    }
  }
  // Clear expired blacklisted tokens
  for (const [token, data] of inMemoryStore.tokenBlacklist.entries()) {
    if (data.expiresAt && new Date(data.expiresAt).getTime() <= now) {
      inMemoryStore.tokenBlacklist.delete(token);
    }
  }
}

/**
 * Save all business entities to disk resilience file atomically
 */
function saveResilienceStore() {
  try {
    const data = {
      users: Array.from(inMemoryStore.users.values()),
      devices: Array.from(inMemoryStore.devices.values()),
      customers: Array.from(inMemoryStore.customers.values()),
      suppliers: Array.from(inMemoryStore.suppliers.values()),
      products: Array.from(inMemoryStore.products.values()),
      invoices: Array.from(inMemoryStore.invoices.values()),
      transactions: Array.from(inMemoryStore.transactions.values()),
      khataEntries: Array.from(inMemoryStore.khataEntries.values()),
      stockLedger: Array.from(inMemoryStore.stockLedger.values()),
      purchaseOrders: Array.from(inMemoryStore.purchaseOrders.values()),
      savedAt: new Date().toISOString(),
    };
    const dir = path.dirname(STORE_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(STORE_FILE, JSON.stringify(data, null, 2), 'utf8');
  } catch (err) {
    console.warn('[Resilience Store] Notice writing disk store:', err.message);
  }
}

/**
 * Initialize Database Connection and Create Tables if needed
 */
async function initDb() {
  // Always load persisted state from disk on startup
  loadResilienceStore();

  let dbHost = config.DB.HOST;
  let dbPort = config.DB.PORT;
  let dbUser = config.DB.USER;
  let dbPassword = config.DB.PASSWORD;
  let dbName = config.DB.NAME;

  if (config.DATABASE_URL) {
    try {
      const parsedUrl = new URL(config.DATABASE_URL);
      dbHost = parsedUrl.hostname || dbHost;
      dbPort = parseInt(parsedUrl.port, 10) || dbPort;
      dbUser = decodeURIComponent(parsedUrl.username || '') || dbUser;
      dbPassword = decodeURIComponent(parsedUrl.password || '') || dbPassword;
      const pathname = parsedUrl.pathname ? parsedUrl.pathname.replace(/^\//, '') : '';
      if (pathname) dbName = pathname;
    } catch (err) {
      console.warn('[Database] Failed to parse DATABASE_URL, using separate DB config fields:', err.message);
    }
  }

  try {
    // 1. Attempt connection to MySQL server without database specified first to create DB if needed
    const connection = await mysql.createConnection({
      host: dbHost,
      port: dbPort,
      user: dbUser,
      password: dbPassword,
    });

    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`);
    await connection.end();

    // 2. Initialize connection pool
    pool = mysql.createPool({
      host: dbHost,
      port: dbPort,
      user: dbUser,
      password: dbPassword,
      database: dbName,
      waitForConnections: true,
      connectionLimit: config.DB.CONNECTION_LIMIT,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0,
    });

    // 3. Create tables
    await createTables();
    console.log(`[Database] MySQL connected & initialized on ${dbHost}:${dbPort}/${dbName}`);
    return true;
  } catch (error) {
    console.warn(`[Database Warning] MySQL connection failed (${error.message}). Running in In-Memory / Resilience mode with disk persistence.`);
    isInMemoryFallback = true;
    return false;
  }
}

/**
 * Table Creation Schema Queries
 */
async function createTables() {
  if (!pool) return;

  const usersTable = `
    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(36) PRIMARY KEY,
      email VARCHAR(255) NOT NULL UNIQUE,
      name VARCHAR(100) DEFAULT NULL,
      phone VARCHAR(20) DEFAULT NULL,
      password_hash VARCHAR(255) DEFAULT NULL,
      is_biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
      status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
      is_email_verified BOOLEAN NOT NULL DEFAULT TRUE,
      last_login_at DATETIME DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_users_email (email),
      INDEX idx_users_phone (phone)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  await pool.query(usersTable);

  // Safe migrations for existing tables
  try {
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) DEFAULT NULL AFTER phone;');
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS is_biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE AFTER password_hash;');
  } catch (_) {
    // Older MySQL versions without IF NOT EXISTS on ALTER column ignore if already present
  }

  const otpsTable = `
    CREATE TABLE IF NOT EXISTS otps (
      id VARCHAR(36) PRIMARY KEY,
      email VARCHAR(255) NOT NULL,
      otp_hash VARCHAR(255) NOT NULL,
      purpose VARCHAR(50) NOT NULL DEFAULT 'AUTH',
      attempts INT NOT NULL DEFAULT 0,
      is_used BOOLEAN NOT NULL DEFAULT FALSE,
      expires_at DATETIME NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_otps_email_expires (email, expires_at, is_used)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const tokenBlacklistTable = `
    CREATE TABLE IF NOT EXISTS token_blacklist (
      id VARCHAR(36) PRIMARY KEY,
      token_hash VARCHAR(255) NOT NULL UNIQUE,
      user_id VARCHAR(36) DEFAULT NULL,
      expires_at DATETIME NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_token_hash (token_hash)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  await pool.query(otpsTable);
  await pool.query(tokenBlacklistTable);

  const loansTable = `
    CREATE TABLE IF NOT EXISTS loans (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      loan_type ENUM('Personal', 'Business', 'Vehicle', 'Home') NOT NULL,
      principal_amount DECIMAL(15, 2) NOT NULL,
      interest_rate DECIMAL(5, 2) NOT NULL,
      tenure_months INT NOT NULL,
      start_date DATE NOT NULL,
      interest_type ENUM('Flat', 'Reducing') NOT NULL DEFAULT 'Reducing',
      emi_amount DECIMAL(15, 2) NOT NULL,
      total_interest DECIMAL(15, 2) NOT NULL,
      total_payable DECIMAL(15, 2) NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'Active',
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_loans_user_id (user_id),
      INDEX idx_loans_status (status),
      CONSTRAINT fk_loans_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const emiSchedulesTable = `
    CREATE TABLE IF NOT EXISTS emi_schedules (
      id VARCHAR(36) PRIMARY KEY,
      loan_id VARCHAR(36) NOT NULL,
      installment_number INT NOT NULL,
      due_date DATE NOT NULL,
      opening_balance DECIMAL(15, 2) NOT NULL,
      principal_amount DECIMAL(15, 2) NOT NULL,
      interest_amount DECIMAL(15, 2) NOT NULL,
      emi_amount DECIMAL(15, 2) NOT NULL,
      closing_balance DECIMAL(15, 2) NOT NULL,
      status ENUM('Paid', 'Pending', 'Overdue') NOT NULL DEFAULT 'Pending',
      paid_date DATETIME DEFAULT NULL,
      late_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_emi_loan_id (loan_id),
      INDEX idx_emi_due_date (due_date),
      INDEX idx_emi_status (status),
      INDEX idx_emi_loan_installment (loan_id, installment_number),
      CONSTRAINT fk_emi_schedules_loan FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const loanPaymentsTable = `
    CREATE TABLE IF NOT EXISTS loan_payments (
      id VARCHAR(36) PRIMARY KEY,
      loan_id VARCHAR(36) NOT NULL,
      emi_schedule_id VARCHAR(36) DEFAULT NULL,
      amount DECIMAL(15, 2) NOT NULL,
      payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      payment_type VARCHAR(50) NOT NULL DEFAULT 'EMI',
      late_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      notes VARCHAR(255) DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_payments_loan_id (loan_id),
      INDEX idx_payments_emi_id (emi_schedule_id),
      CONSTRAINT fk_loan_payments_loan FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE,
      CONSTRAINT fk_loan_payments_emi FOREIGN KEY (emi_schedule_id) REFERENCES emi_schedules (id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const prepaymentsTable = `
    CREATE TABLE IF NOT EXISTS prepayments (
      id VARCHAR(36) PRIMARY KEY,
      loan_id VARCHAR(36) NOT NULL,
      amount DECIMAL(15, 2) NOT NULL,
      payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      interest_saved DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      revised_tenure INT NOT NULL,
      revised_emi DECIMAL(15, 2) NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_prepayments_loan_id (loan_id),
      CONSTRAINT fk_prepayments_loan FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const loanRemindersTable = `
    CREATE TABLE IF NOT EXISTS loan_reminders (
      id VARCHAR(36) PRIMARY KEY,
      loan_id VARCHAR(36) NOT NULL,
      schedule_id VARCHAR(36) NOT NULL,
      user_id VARCHAR(36) NOT NULL,
      reminder_type VARCHAR(50) NOT NULL,
      channel VARCHAR(20) NOT NULL DEFAULT 'EMAIL',
      emi_amount DECIMAL(15, 2) NOT NULL,
      due_date VARCHAR(50) NOT NULL,
      sent_date VARCHAR(50) NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'SENT',
      message TEXT DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_reminders_loan_id (loan_id),
      INDEX idx_reminders_schedule_id (schedule_id),
      INDEX idx_reminders_user_id (user_id),
      INDEX idx_reminders_dedup (schedule_id, reminder_type, sent_date),
      CONSTRAINT fk_reminders_loan FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE,
      CONSTRAINT fk_reminders_schedule FOREIGN KEY (schedule_id) REFERENCES emi_schedules (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const customersTable = `
    CREATE TABLE IF NOT EXISTS customers (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      name VARCHAR(150) NOT NULL,
      phone VARCHAR(25) NOT NULL,
      email VARCHAR(255) DEFAULT NULL,
      company_name VARCHAR(200) DEFAULT NULL,
      country VARCHAR(100) DEFAULT 'India',
      country_code VARCHAR(10) DEFAULT 'IN',
      state VARCHAR(100) DEFAULT 'Telangana',
      state_code VARCHAR(10) DEFAULT '36',
      district VARCHAR(100) DEFAULT NULL,
      city VARCHAR(100) DEFAULT NULL,
      pincode VARCHAR(20) DEFAULT NULL,
      address_line VARCHAR(255) DEFAULT NULL,
      landmark VARCHAR(255) DEFAULT NULL,
      address TEXT DEFAULT NULL,
      gstin VARCHAR(25) DEFAULT NULL,
      category VARCHAR(50) DEFAULT 'REGULAR',
      opening_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      current_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      credit_limit DECIMAL(15, 2) NOT NULL DEFAULT 50000.00,
      block_on_credit_breach BOOLEAN NOT NULL DEFAULT FALSE,
      notes TEXT DEFAULT NULL,
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_cust_user_id (user_id),
      INDEX idx_cust_phone (phone)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const suppliersTable = `
    CREATE TABLE IF NOT EXISTS suppliers (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      name VARCHAR(150) NOT NULL,
      contact_number VARCHAR(25) NOT NULL,
      email VARCHAR(255) DEFAULT NULL,
      company_name VARCHAR(200) DEFAULT NULL,
      gstin VARCHAR(25) DEFAULT NULL,
      address TEXT DEFAULT NULL,
      state_code VARCHAR(10) DEFAULT '36',
      opening_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      current_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      category VARCHAR(50) DEFAULT 'RAW_MATERIALS',
      payment_terms VARCHAR(100) DEFAULT 'Net 30',
      notes TEXT DEFAULT NULL,
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_supp_user_id (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const productsTable = `
    CREATE TABLE IF NOT EXISTS products (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      sku VARCHAR(100) NOT NULL,
      name VARCHAR(200) NOT NULL,
      category VARCHAR(100) DEFAULT 'General',
      unit VARCHAR(50) DEFAULT 'Pcs',
      hsn_code VARCHAR(20) DEFAULT '9999',
      cost_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      selling_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      gst_rate DECIMAL(5, 2) NOT NULL DEFAULT 18.00,
      reorder_level INT NOT NULL DEFAULT 10,
      current_stock INT NOT NULL DEFAULT 0,
      barcode VARCHAR(100) DEFAULT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
      supplier_id VARCHAR(36) DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_prod_user_id (user_id),
      INDEX idx_prod_sku (sku)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const invoicesTable = `
    CREATE TABLE IF NOT EXISTS invoices (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      invoice_number VARCHAR(100) NOT NULL,
      invoice_type VARCHAR(20) NOT NULL DEFAULT 'GST',
      invoice_date DATE NOT NULL,
      customer_id VARCHAR(36) NOT NULL,
      customer_name VARCHAR(150) NOT NULL,
      customer_gstin VARCHAR(25) DEFAULT NULL,
      customer_phone VARCHAR(25) DEFAULT NULL,
      customer_state_code VARCHAR(10) DEFAULT '36',
      merchant_state_code VARCHAR(10) DEFAULT '36',
      is_intra_state BOOLEAN NOT NULL DEFAULT TRUE,
      taxable_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      cgst_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      sgst_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      igst_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      cess_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      round_off DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      grand_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
      amount_paid DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      balance_due DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      notes TEXT DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_inv_user_id (user_id),
      INDEX idx_inv_customer_id (customer_id),
      INDEX idx_inv_number (invoice_number)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const invoiceItemsTable = `
    CREATE TABLE IF NOT EXISTS invoice_items (
      id VARCHAR(36) PRIMARY KEY,
      invoice_id VARCHAR(36) NOT NULL,
      product_id VARCHAR(36) DEFAULT NULL,
      description VARCHAR(255) NOT NULL,
      hsn_code VARCHAR(20) DEFAULT NULL,
      quantity INT NOT NULL DEFAULT 1,
      unit_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      discount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      taxable_value DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      gst_rate DECIMAL(5, 2) NOT NULL DEFAULT 18.00,
      cgst_rate DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      cgst_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      sgst_rate DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      sgst_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      igst_rate DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      igst_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_item_invoice_id (invoice_id),
      CONSTRAINT fk_item_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const khataEntriesTable = `
    CREATE TABLE IF NOT EXISTS khata_entries (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      customer_id VARCHAR(36) DEFAULT NULL,
      supplier_id VARCHAR(36) DEFAULT NULL,
      entry_type ENUM('GAVE', 'GOT') NOT NULL,
      amount DECIMAL(15, 2) NOT NULL,
      balance_after DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
      payment_mode VARCHAR(50) NOT NULL DEFAULT 'CASH',
      description TEXT DEFAULT NULL,
      reference_id VARCHAR(100) DEFAULT NULL,
      reference_type VARCHAR(50) DEFAULT 'MANUAL',
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_khata_user_id (user_id),
      INDEX idx_khata_customer_id (customer_id),
      INDEX idx_khata_supplier_id (supplier_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const paymentsTable = `
    CREATE TABLE IF NOT EXISTS payments (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      customer_id VARCHAR(36) DEFAULT NULL,
      supplier_id VARCHAR(36) DEFAULT NULL,
      invoice_id VARCHAR(36) DEFAULT NULL,
      amount DECIMAL(15, 2) NOT NULL,
      payment_mode VARCHAR(50) NOT NULL DEFAULT 'UPI',
      payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      reference_number VARCHAR(100) DEFAULT NULL,
      notes TEXT DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_pay_user_id (user_id),
      INDEX idx_pay_customer_id (customer_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  await pool.query(loansTable);
  await pool.query(emiSchedulesTable);
  const userDevicesTable = `
    CREATE TABLE IF NOT EXISTS user_devices (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      device_id VARCHAR(100) NOT NULL,
      device_name VARCHAR(150) DEFAULT NULL,
      platform VARCHAR(50) DEFAULT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'APPROVED',
      ip_address VARCHAR(45) DEFAULT NULL,
      last_active_at DATETIME DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_user_device (user_id, device_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const deviceApprovalRequestsTable = `
    CREATE TABLE IF NOT EXISTS device_approval_requests (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      device_id VARCHAR(100) NOT NULL,
      device_name VARCHAR(150) DEFAULT NULL,
      platform VARCHAR(50) DEFAULT NULL,
      ip_address VARCHAR(45) DEFAULT NULL,
      verification_code VARCHAR(10) DEFAULT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
      expires_at DATETIME NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_dev_req_user (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  await pool.query(userDevicesTable);
  await pool.query(deviceApprovalRequestsTable);
  await pool.query(loanPaymentsTable);
  await pool.query(prepaymentsTable);
  await pool.query(loanRemindersTable);
  await pool.query(customersTable);
  await pool.query(suppliersTable);
  await pool.query(productsTable);
  await pool.query(invoicesTable);
  await pool.query(invoiceItemsTable);
  await pool.query(khataEntriesTable);
  await pool.query(paymentsTable);

  // ── Subscription & Billing Tables ──────────────────────────────────────────
  const subscriptionPlansTable = `
    CREATE TABLE IF NOT EXISTS subscription_plans (
      id VARCHAR(36) PRIMARY KEY,
      name VARCHAR(50) NOT NULL UNIQUE,
      display_name VARCHAR(100) NOT NULL,
      description TEXT DEFAULT NULL,
      price_monthly DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      price_yearly DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      currency VARCHAR(10) NOT NULL DEFAULT 'INR',
      trial_days INT NOT NULL DEFAULT 0,
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      sort_order INT NOT NULL DEFAULT 0,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_plan_name (name)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const planFeaturesTable = `
    CREATE TABLE IF NOT EXISTS plan_features (
      id VARCHAR(36) PRIMARY KEY,
      plan_id VARCHAR(36) NOT NULL,
      feature_code VARCHAR(100) NOT NULL,
      feature_name VARCHAR(200) NOT NULL,
      is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
      limit_value INT DEFAULT NULL COMMENT 'NULL means unlimited; 0 means disabled',
      limit_type ENUM('BOOLEAN','COUNT','UNLIMITED') NOT NULL DEFAULT 'BOOLEAN',
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_pf_plan_id (plan_id),
      INDEX idx_pf_feature_code (feature_code),
      UNIQUE KEY uq_plan_feature (plan_id, feature_code)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const subscriptionsTable = `
    CREATE TABLE IF NOT EXISTS subscriptions (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      plan_id VARCHAR(36) NOT NULL,
      status ENUM('TRIALING','ACTIVE','PAST_DUE','PAUSED','CANCELLED','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
      billing_cycle ENUM('MONTHLY','YEARLY') NOT NULL DEFAULT 'MONTHLY',
      start_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      current_period_start DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      current_period_end DATETIME NOT NULL,
      trial_end DATETIME DEFAULT NULL,
      cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
      auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
      gateway_customer_id VARCHAR(100) DEFAULT NULL,
      gateway_subscription_id VARCHAR(100) DEFAULT NULL,
      downgrade_to_plan_id VARCHAR(36) DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_sub_user_id (user_id),
      INDEX idx_sub_status (status),
      INDEX idx_sub_period_end (current_period_end)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const subscriptionPaymentsTable = `
    CREATE TABLE IF NOT EXISTS subscription_payments (
      id VARCHAR(36) PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      subscription_id VARCHAR(36) DEFAULT NULL,
      plan_id VARCHAR(36) NOT NULL,
      order_id VARCHAR(100) NOT NULL UNIQUE COMMENT 'Razorpay order_id',
      gateway_payment_id VARCHAR(100) DEFAULT NULL,
      gateway_signature VARCHAR(255) DEFAULT NULL,
      amount DECIMAL(10,2) NOT NULL,
      currency VARCHAR(10) NOT NULL DEFAULT 'INR',
      billing_cycle ENUM('MONTHLY','YEARLY') NOT NULL DEFAULT 'MONTHLY',
      status ENUM('CREATED','PENDING','SUCCESS','FAILED','REFUNDED','PARTIALLY_REFUNDED') NOT NULL DEFAULT 'CREATED',
      coupon_code VARCHAR(50) DEFAULT NULL,
      discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      payment_method VARCHAR(50) DEFAULT NULL,
      paid_at DATETIME DEFAULT NULL,
      failure_reason TEXT DEFAULT NULL,
      idempotency_key VARCHAR(100) DEFAULT NULL UNIQUE,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_sp_user_id (user_id),
      INDEX idx_sp_order_id (order_id),
      INDEX idx_sp_status (status)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const subscriptionInvoicesTable = `
    CREATE TABLE IF NOT EXISTS subscription_invoices (
      id VARCHAR(36) PRIMARY KEY,
      invoice_number VARCHAR(50) NOT NULL UNIQUE,
      user_id VARCHAR(36) NOT NULL,
      subscription_id VARCHAR(36) DEFAULT NULL,
      payment_id VARCHAR(36) DEFAULT NULL,
      plan_name VARCHAR(100) NOT NULL,
      billing_cycle VARCHAR(20) NOT NULL,
      subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      discount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      tax_rate DECIMAL(5,2) NOT NULL DEFAULT 18.00,
      tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      currency VARCHAR(10) NOT NULL DEFAULT 'INR',
      status ENUM('DRAFT','ISSUED','PAID','VOID') NOT NULL DEFAULT 'PAID',
      invoice_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      due_date DATETIME DEFAULT NULL,
      pdf_url VARCHAR(500) DEFAULT NULL,
      billing_name VARCHAR(200) DEFAULT NULL,
      billing_email VARCHAR(255) DEFAULT NULL,
      billing_address TEXT DEFAULT NULL,
      gstin VARCHAR(25) DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_si_user_id (user_id),
      INDEX idx_si_invoice_number (invoice_number)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  const couponsTable = `
    CREATE TABLE IF NOT EXISTS coupons (
      id VARCHAR(36) PRIMARY KEY,
      code VARCHAR(50) NOT NULL UNIQUE,
      discount_type ENUM('PERCENTAGE','FLAT') NOT NULL DEFAULT 'PERCENTAGE',
      discount_value DECIMAL(10,2) NOT NULL,
      max_discount DECIMAL(10,2) DEFAULT NULL,
      minimum_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      applicable_plans JSON DEFAULT NULL COMMENT 'null = all plans',
      valid_from DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      valid_until DATETIME DEFAULT NULL,
      usage_limit INT DEFAULT NULL,
      per_user_limit INT NOT NULL DEFAULT 1,
      used_count INT NOT NULL DEFAULT 0,
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_coupon_code (code)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  await pool.query(subscriptionPlansTable);
  await pool.query(planFeaturesTable);
  await pool.query(subscriptionsTable);
  await pool.query(subscriptionPaymentsTable);
  await pool.query(subscriptionInvoicesTable);
  await pool.query(couponsTable);

  console.log('[Database] Schema initialized. No demo users seeded — production mode.');
}



/**
 * Execute a SQL query
 */
async function query(sql, params) {
  if (pool && !isInMemoryFallback) {
    const [results] = await pool.query(sql, params);
    return results;
  }
  throw new Error('Database pool not connected');
}

/**
 * Check if pool is connected
 */
function isConnected() {
  return pool !== null && !isInMemoryFallback;
}

module.exports = {
  initDb,
  query,
  isConnected,
  getPool: () => pool,
  isInMemoryFallback: () => isInMemoryFallback,
  inMemoryStore,
  saveResilienceStore,
  loadResilienceStore,
  cleanCache,
};

