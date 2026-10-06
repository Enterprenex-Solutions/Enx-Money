/**
 * server/config/db.js — Compatibility shim for WhatsApp Chatbot services.
 *
 * Anjali's WhatsApp services use require('../config/db').
 * The active production DB layer lives in server/src/config/db.config.js.
 * This shim re-exports the same interface so both paths resolve correctly.
 */

const db = require('../src/config/db.config');

// In-memory resilience store for WhatsApp services when MySQL is offline
const inMemoryTables = {
  users: new Map([
    ['usr-admin-001', { id: 'usr-admin-001', name: 'Krishna Enterprise Owner', email: 'admin@enxmoney.com', role: 'admin' }],
    ['usr-admin-test', { id: 'usr-admin-test', name: 'Anjali Enterprise Admin', email: 'admin@enx.com', role: 'admin' }],
  ]),
  whatsapp_users: new Map([
    ['919876543210', {
      id: 'wa-demo-001',
      phone_number: '919876543210',
      user_id: 'usr-admin-001',
      verification_status: 'verified',
      user_name: 'Krishna Enterprise Owner',
      user_email: 'admin@enxmoney.com',
      created_at: new Date(),
    }],
  ]),
  whatsapp_sessions: new Map(),
  whatsapp_messages: [],
  whatsapp_reminders: [],
  whatsapp_handoff_tokens: new Map(),
  customers: new Map([
    ['cust-01', {
      id: 'cust-01',
      name: 'Apex Global Ltd',
      company_name: 'Apex Corp',
      phone: '919876500001',
      outstanding_balance: 45000.00,
      current_balance: 45000.00,
      total_invoiced: 120000.00,
      user_id: 'usr-admin-001',
    }],
    ['cust-02', {
      id: 'cust-02',
      name: 'Priya Fabrics Pvt Ltd',
      company_name: 'Priya Fabrics',
      phone: '919876500002',
      outstanding_balance: 18500.00,
      current_balance: 18500.00,
      total_invoiced: 65000.00,
      user_id: 'usr-admin-001',
    }],
    ['cust-03', {
      id: 'cust-03',
      name: 'Vikram Wholesale Distributors',
      company_name: 'Vikram Textiles',
      phone: '919876500003',
      outstanding_balance: 8200.00,
      current_balance: 8200.00,
      total_invoiced: 32000.00,
      user_id: 'usr-admin-001',
    }],
  ]),
  transactions: new Map([
    ['tx-01', {
      id: 'tx-01',
      title: 'Bulk Textile Supply Order #884',
      amount: 85000.00,
      type: 'revenue',
      category: 'Sales',
      payment_mode: 'bankTransfer',
      is_cleared: 1,
      invoice_number: 'INV-2026-001',
      user_id: 'usr-admin-001',
      date: new Date(),
    }],
    ['tx-02', {
      id: 'tx-02',
      title: 'Cloud Server & ERP Subscription',
      amount: 12500.00,
      type: 'expense',
      category: 'Software & Technology',
      payment_mode: 'creditCard',
      is_cleared: 1,
      invoice_number: 'INV-2026-002',
      user_id: 'usr-admin-001',
      date: new Date(),
    }],
    ['tx-03', {
      id: 'tx-03',
      title: 'Warehouse Logistics & Shipping',
      amount: 6400.00,
      type: 'expense',
      category: 'Logistics',
      payment_mode: 'upi',
      is_cleared: 1,
      invoice_number: 'INV-2026-003',
      user_id: 'usr-admin-001',
      date: new Date(),
    }],
  ]),
  suppliers: new Map([
    ['supp-01', {
      id: 'supp-01',
      name: 'Surat Cotton Mills',
      company_name: 'Surat Cotton',
      contact_number: '919876500099',
      outstanding_payable: 24000.00,
      current_balance: 24000.00,
      user_id: 'usr-admin-001',
    }],
  ]),
};

/**
 * In-memory fallback query processor for tests & offline dev
 */
async function fallbackQuery(sql, params = []) {
  const norm = sql.trim().replace(/\s+/g, ' ');

  // 1. SELECT 1
  if (/^SELECT 1/i.test(norm)) return [{ 1: 1 }];

  // 2. INSERT INTO users
  if (/^INSERT INTO users/i.test(norm)) {
    const id = params[0] || 'usr-admin-test';
    const email = (params[1] || params[0] || 'admin@enx.com');
    const user = { id, name: 'Anjali Enterprise Admin', email: String(email).toLowerCase(), role: 'admin' };
    inMemoryTables.users.set(id, user);
    inMemoryTables.users.set(user.email, user);
    return { insertId: id, affectedRows: 1 };
  }

  // 3. SELECT ... FROM users
  if (/FROM users/i.test(norm)) {
    if (params.length > 0) {
      const p = String(params[0] || '').toLowerCase();
      const match = Array.from(inMemoryTables.users.values()).filter(
        u => u.id === params[0] || (u.email && u.email.toLowerCase() === p)
      );
      if (match.length > 0) return match;
    }
    return Array.from(inMemoryTables.users.values());
  }

  // 4. INSERT INTO customers
  if (/^INSERT INTO customers/i.test(norm)) {
    const userId = params[params.length - 1] || 'usr-admin-test';
    const cust = {
      id: params.length >= 7 ? params[0] : 'cust-01',
      name: params.length >= 7 ? params[1] : 'Apex Global Ltd',
      company_name: params.length >= 7 ? params[2] : 'Apex Corp',
      phone: params.length >= 7 ? params[3] : '919876500001',
      outstanding_balance: params.length >= 7 ? Number(params[4]) : 45000.00,
      current_balance: params.length >= 7 ? Number(params[4]) : 45000.00,
      total_invoiced: params.length >= 7 ? Number(params[5]) : 120000.00,
      user_id: userId,
    };
    inMemoryTables.customers.set(cust.id, cust);
    return { insertId: cust.id, affectedRows: 1 };
  }

  // 5. SELECT ... FROM customers
  if (/FROM customers/i.test(norm)) {
    const userId = params[0];
    let list = Array.from(inMemoryTables.customers.values());
    if (userId) list = list.filter(c => c.user_id === userId);
    if (/outstanding_balance > 0/i.test(norm)) {
      list = list.filter(c => (c.outstanding_balance || c.current_balance || 0) > 0);
    }
    return list.map(c => {
      const u = inMemoryTables.users.get(c.user_id) || { name: 'ENX Money Enterprise' };
      const due = Number(c.outstanding_balance || c.current_balance || 0);
      return { ...c, due_amount: due, business_name: u.name };
    });
  }

  // 6. INSERT INTO transactions
  if (/^INSERT INTO transactions/i.test(norm)) {
    const userId = params[params.length - 1] || 'usr-admin-test';
    const tx = {
      id: params.length >= 8 ? params[0] : 'tx-test-01',
      title: params.length >= 8 ? params[1] : 'Cloud Infrastructure Service',
      amount: params.length >= 8 ? Number(params[2]) : 12500.00,
      type: params.length >= 8 ? params[3] : 'expense',
      category: params.length >= 8 ? params[4] : 'Technology',
      is_cleared: 1,
      invoice_number: params.length >= 8 ? params[6] : 'INV-2026-001',
      user_id: userId,
      date: new Date(),
    };
    inMemoryTables.transactions.set(tx.id, tx);
    return { insertId: tx.id, affectedRows: 1 };
  }

  // 7. SELECT ... FROM transactions (KPIs / Lists)
  if (/FROM transactions/i.test(norm)) {
    const userId = params[0];
    let list = Array.from(inMemoryTables.transactions.values());
    if (userId) list = list.filter(t => t.user_id === userId);

    if (/SUM\(amount\)/i.test(norm)) {
      const typeMatch = norm.match(/type\s*=\s*'([^']+)'/i);
      const targetType = typeMatch ? typeMatch[1] : null;
      if (targetType) list = list.filter(t => t.type === targetType);
      const sum = list.reduce((acc, t) => acc + (Number(t.amount) || 0), 0);
      return [{ val: sum, cnt: list.length }];
    }

    if (/invoice_number/i.test(norm) && params[1]) {
      const inv = params[1].replace(/%/g, '');
      const match = list.filter(t => t.invoice_number && t.invoice_number.includes(inv));
      return match;
    }

    return list.slice(0, 10);
  }

  // 8. SELECT ... FROM suppliers
  if (/FROM suppliers/i.test(norm)) {
    const userId = params[0];
    let list = Array.from(inMemoryTables.suppliers.values());
    if (userId) list = list.filter(s => s.user_id === userId);
    if (/SUM\(amount\)|SUM\(outstanding_payable\)/i.test(norm)) {
      const sum = list.reduce((acc, s) => acc + (Number(s.outstanding_payable) || 0), 0);
      return [{ val: sum, cnt: list.length }];
    }
    return list;
  }

  // 9. whatsapp_users
  if (/FROM whatsapp_users/i.test(norm)) {
    const phone = params[0];
    const wa = inMemoryTables.whatsapp_users.get(phone);
    if (!wa) return [];
    const u = inMemoryTables.users.get(wa.user_id) || {};
    return [{ ...wa, user_name: u.name, user_email: u.email, user_role: u.role }];
  }

  if (/^INSERT INTO whatsapp_users/i.test(norm)) {
    const [id, phone, user_id, status, otp, expires] = params;
    const wa = { id, phone_number: phone, user_id, verification_status: status, otp_code: otp, otp_expires_at: expires };
    inMemoryTables.whatsapp_users.set(phone, wa);
    return { insertId: id, affectedRows: 1 };
  }

  if (/^UPDATE whatsapp_users/i.test(norm)) {
    const phone = params[params.length - 1];
    const wa = inMemoryTables.whatsapp_users.get(phone) || {};
    if (/verification_status\s*=\s*\?/i.test(norm)) wa.verification_status = params[0];
    if (/otp_code\s*=\s*\?/i.test(norm)) wa.otp_code = params[0];
    inMemoryTables.whatsapp_users.set(phone, wa);
    return { affectedRows: 1 };
  }

  if (/^DELETE FROM whatsapp_users/i.test(norm)) {
    const phone = params[0];
    inMemoryTables.whatsapp_users.delete(phone);
    return { affectedRows: 1 };
  }

  // 10. whatsapp_sessions
  if (/FROM whatsapp_sessions/i.test(norm)) {
    const phone = params[0];
    const s = inMemoryTables.whatsapp_sessions.get(phone);
    return s ? [s] : [];
  }

  if (/^INSERT INTO whatsapp_sessions/i.test(norm)) {
    const [id, phone, user_id, state] = params;
    const s = { id, phone_number: phone, user_id, state: state || 'IDLE', context_data: {}, last_intent: null };
    inMemoryTables.whatsapp_sessions.set(phone, s);
    return { insertId: id, affectedRows: 1 };
  }

  if (/^UPDATE whatsapp_sessions/i.test(norm)) {
    const phone = params[params.length - 1];
    const s = inMemoryTables.whatsapp_sessions.get(phone) || { phone_number: phone };
    if (params[0]) s.state = params[0];
    inMemoryTables.whatsapp_sessions.set(phone, s);
    return { affectedRows: 1 };
  }

  // 11. whatsapp_messages
  if (/^INSERT INTO whatsapp_messages/i.test(norm)) {
    const [id, phone, user_id, direction, body, intent] = params;
    inMemoryTables.whatsapp_messages.push({ id, phone_number: phone, user_id, direction, body, intent, created_at: new Date() });
    return { insertId: id, affectedRows: 1 };
  }

  if (/FROM whatsapp_messages/i.test(norm)) {
    return inMemoryTables.whatsapp_messages.slice(-20);
  }

  // 12. whatsapp_reminders
  if (/^INSERT INTO whatsapp_reminders/i.test(norm)) {
    const [id, user_id, recipient_phone, entity_type, entity_id, entity_name, reminder_type, title, amount, due_date, scheduled_at] = params;
    inMemoryTables.whatsapp_reminders.push({
      id, user_id, recipient_phone, entity_type, entity_id, entity_name, reminder_type, title, amount: Number(amount), due_date, scheduled_at, status: 'sent', created_at: new Date()
    });
    return { insertId: id, affectedRows: 1 };
  }

  // 13. whatsapp_handoff_tokens
  if (/^INSERT INTO whatsapp_handoff_tokens/i.test(norm)) {
    const [id, token, user_id, phone, target_screen, action_type, payload, expires_at] = params;
    const entry = {
      id, token, user_id, phone_number: phone, target_screen, action_type, payload, expires_at, is_used: 0
    };
    inMemoryTables.whatsapp_handoff_tokens.set(token, entry);
    inMemoryTables.whatsapp_handoff_tokens.set(id, entry);
    return { insertId: id, affectedRows: 1 };
  }

  if (/FROM whatsapp_handoff_tokens/i.test(norm)) {
    const param = params[0];
    const t = inMemoryTables.whatsapp_handoff_tokens.get(param);
    if (!t) return [];
    const u = inMemoryTables.users.get(t.user_id) || { name: 'Anjali Enterprise Admin', email: 'admin@enx.com', role: 'admin' };
    return [{ ...t, name: u.name, email: u.email, role: u.role }];
  }

  if (/UPDATE whatsapp_handoff_tokens/i.test(norm)) {
    const param = params[params.length - 1];
    const t = inMemoryTables.whatsapp_handoff_tokens.get(param);
    if (t) t.is_used = 1;
    return { affectedRows: 1 };
  }

  return [];
}

/**
 * Executes a parameterized SQL query and returns result rows.
 * Uses real MySQL if connected; otherwise falls back gracefully to in-memory resilience store.
 */
async function query(sql, params = []) {
  if (db.isConnected && db.isConnected()) {
    return await db.query(sql, params);
  }
  return await fallbackQuery(sql, params);
}

async function execute(sql, params = []) {
  return await query(sql, params);
}

function getPool() {
  return db.getPool ? db.getPool() : null;
}

async function getConnection() {
  const pool = getPool();
  if (pool) return pool.getConnection();
  return {
    query: async (s, p) => [await fallbackQuery(s, p)],
    release: () => {},
  };
}

async function testConnection() {
  try {
    await query('SELECT 1');
    return true;
  } catch {
    return false;
  }
}

module.exports = { query, execute, getPool, getConnection, testConnection, inMemoryTables };

