/**
 * Database Seed Script
 * Run: node database/seed.js
 * Inserts a default admin user and sample financial data into MySQL.
 */

const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { query, testConnection } = require('../config/db');

async function seed() {
  console.log('🌱 Seeding database with sample data...');

  const ok = await testConnection();
  if (!ok) {
    console.error('❌ Cannot connect to MySQL. Run `npm run db:init` first.');
    process.exit(1);
  }

  // --- Create default admin user ---
  const userId = `usr-${uuidv4().replace(/-/g, '').slice(0, 8)}`;
  const passwordHash = await bcrypt.hash('admin123', 10);

  const existingUser = await query('SELECT id FROM users WHERE email = ?', ['admin@enxmoney.com']);
  let activeUserId = userId;

  if (existingUser.length === 0) {
    await query(
      'INSERT INTO users (id, name, email, password_hash, role) VALUES (?, ?, ?, ?, ?)',
      [userId, 'ENX Admin', 'admin@enxmoney.com', passwordHash, 'admin']
    );
    console.log('✔ Created admin user: admin@enxmoney.com / admin123');
  } else {
    activeUserId = existingUser[0].id;
    console.log('✔ Admin user already exists.');
  }

  // --- Enterprises ---
  const existingEnts = await query('SELECT id FROM enterprises WHERE user_id = ?', [activeUserId]);
  if (existingEnts.length === 0) {
    const ents = [
      [`ent-${uuidv4().slice(0, 8)}`, 'Rajesh Traders Pvt Ltd', '27AAACR5055K1ZV', 'rajesh@traders.com', '9876543210', 'Mumbai, Maharashtra', activeUserId],
      [`ent-${uuidv4().slice(0, 8)}`, 'Suresh Industries', '29AABCS6432H1ZS', 'suresh@industries.com', '8765432109', 'Bengaluru, Karnataka', activeUserId],
    ];
    for (const e of ents) {
      await query('INSERT INTO enterprises (id, company_name, gstin, email, phone, address, user_id) VALUES (?,?,?,?,?,?,?)', e);
    }
    console.log(`✔ Seeded ${ents.length} enterprises.`);
  }

  // --- Customers ---
  const existingCust = await query('SELECT id FROM customers WHERE user_id = ?', [activeUserId]);
  if (existingCust.length === 0) {
    const customers = [
      [`cust-${uuidv4().slice(0, 8)}`, 'Amit Sharma', 'Sharma Enterprises', '9876001234', 'amit@sharma.com', 'Delhi', 85000, 15000, activeUserId],
      [`cust-${uuidv4().slice(0, 8)}`, 'Priya Nair', 'Nair Solutions', '8765002345', 'priya@nair.com', 'Kochi, Kerala', 120000, 40000, activeUserId],
      [`cust-${uuidv4().slice(0, 8)}`, 'Vikram Gupta', 'Gupta Exports', '7654003456', 'vikram@gupta.com', 'Ahmedabad, Gujarat', 60000, 0, activeUserId],
    ];
    for (const c of customers) {
      await query('INSERT INTO customers (id, name, company_name, phone, email, address, total_invoiced, outstanding_balance, user_id) VALUES (?,?,?,?,?,?,?,?,?)', c);
    }
    console.log(`✔ Seeded ${customers.length} customers.`);
  }

  // --- Suppliers ---
  const existingSupp = await query('SELECT id FROM suppliers WHERE user_id = ?', [activeUserId]);
  if (existingSupp.length === 0) {
    const suppliers = [
      [`supp-${uuidv4().slice(0, 8)}`, 'Ravi Kumar', 'Kumar Logistics', 'Logistics', '9988776655', 'ravi@kumarlogi.com', 'Chennai, TN', 95000, 25000, activeUserId],
      [`supp-${uuidv4().slice(0, 8)}`, 'Sunita Patel', 'Patel Raw Materials', 'Raw Materials', '8877665544', 'sunita@patel.com', 'Surat, Gujarat', 140000, 50000, activeUserId],
    ];
    for (const s of suppliers) {
      await query('INSERT INTO suppliers (id, name, company_name, category, phone, email, address, total_billed, outstanding_payable, user_id) VALUES (?,?,?,?,?,?,?,?,?,?)', s);
    }
    console.log(`✔ Seeded ${suppliers.length} suppliers.`);
  }

  // --- Transactions ---
  const existingTx = await query('SELECT id FROM transactions WHERE user_id = ?', [activeUserId]);
  if (existingTx.length === 0) {
    const now = new Date();
    const mkDate = (daysAgo) => new Date(now.getTime() - daysAgo * 86400000).toISOString().slice(0, 19).replace('T', ' ');
    const txId = () => `tx-${uuidv4().slice(0, 8)}`;

    const txns = [
      [txId(), 'Software Consulting Q3', 75000, 'revenue', 'business', 'Consulting', mkDate(1), 'bankTransfer', 'Monthly consulting retainer', 18, 'INV-2026-001', 1, null, null, null, activeUserId],
      [txId(), 'Office Rent - August', 35000, 'expense', 'business', 'Rent', mkDate(3), 'bankTransfer', 'Monthly office rent', 0, null, 1, null, null, null, activeUserId],
      [txId(), 'Digital Marketing Services', 25000, 'revenue', 'business', 'Marketing', mkDate(5), 'upi', null, 18, 'INV-2026-002', 1, null, null, null, activeUserId],
      [txId(), 'Team Dinner', 5500, 'expense', 'personal', 'Food & Dining', mkDate(2), 'creditCard', 'Team outing expense', 0, null, 1, null, null, null, activeUserId],
      [txId(), 'Raw Material Purchase', 48000, 'payable', 'business', 'Inventory', mkDate(7), 'cheque', 'Monthly stock refill', 5, 'PO-2026-011', 0, null, null, null, activeUserId],
      [txId(), 'Client Receivable - Sharma', 15000, 'receivable', 'business', 'Consulting', mkDate(10), 'bankTransfer', 'Outstanding invoice payment', 0, 'INV-2026-003', 0, null, null, null, activeUserId],
      [txId(), 'Vehicle EMI', 12500, 'emi', 'personal', 'EMI', mkDate(15), 'bankTransfer', 'Car loan EMI August', 0, null, 1, null, null, null, activeUserId],
      [txId(), 'AWS Cloud Services', 8200, 'expense', 'business', 'Technology', mkDate(4), 'creditCard', 'Monthly AWS bill', 18, 'AWS-2026-08', 1, null, null, null, activeUserId],
    ];

    for (const t of txns) {
      await query(
        'INSERT INTO transactions (id, title, amount, type, profile_type, category, date, payment_mode, notes, gst_rate, invoice_number, is_cleared, enterprise_id, customer_id, supplier_id, user_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
        t
      );
    }
    console.log(`✔ Seeded ${txns.length} transactions.`);
  }

  console.log('');
  console.log('✅ Database seed completed!');
  console.log('   Login: admin@enxmoney.com / admin123');
  console.log('');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed error:', err.message);
  process.exit(1);
});
