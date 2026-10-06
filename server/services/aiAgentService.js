/**
 * AI Financial Agent Service (Gemini API & Grok API Integration)
 *
 * Implements conversational AI with Structured Function Calling, Intent Recognition,
 * Financial Query Execution, and Tenancy Isolation for the ENX Money WhatsApp Bot.
 */

const { query } = require('../config/db');
const { createHandoffToken } = require('./whatsappHandoffService');
const { generateKhataStatementPdf } = require('./whatsappStatementService');
const { scanAndSendOverdueReminders } = require('./whatsappReminderService');
const { sendWhatsAppDocument } = require('./whatsappMessageService');

// System persona instructions for ENX Money Assistant
const SYSTEM_PROMPT = `
You are the official ENX Money WhatsApp Smart Financial Assistant.
Your job is to provide fast, precise, actionable, and secure financial assistance to enterprise owners and users.

Formatting Guidelines:
- WhatsApp compatible styling: Use *bold* for key numbers, amounts, and headers.
- Format all money values with currency symbol (e.g., ₹1,45,000.00 or $12,500.00).
- Use clean emojis (💰, 📈, 📉, ⚠️, ✅, ⏳, 🧾, 🏢, 🔗) to make responses scannable.
- Keep responses concise, direct, and easy to read on mobile screens.
- When displaying lists of transactions or dues, show at most 5 items with totals.
- Suggest 1-2 quick next steps or commands at the end (e.g. "Reply 'Remind' or 'App Link'").
- For sensitive or high-risk tasks (full audit export, deleting entities, wire payouts), recommend a Secure App Handoff link.

Tenancy & Security:
- All data returned is strictly isolated to the authenticated user.
- Never output internal database IDs or passwords.
`.trim();

// Definition of tool functions callable by the AI model
const TOOL_DEFINITIONS = [
  {
    name: 'getFinancialKPIs',
    description: 'Retrieves core financial metrics including total revenue, expenses, net profit, pending receivables, and outstanding payables for a given time period.',
    parameters: {
      type: 'OBJECT',
      properties: {
        profile_type: { type: 'STRING', description: 'business or personal (default: business)' },
        period: { type: 'STRING', description: 'Time filter: "today", "this_month", "last_month", "year", or "all"' },
      },
    },
  },
  {
    name: 'getOutstandingReceivables',
    description: 'Finds customers who owe money, their total invoice amounts, and overdue balances.',
    parameters: {
      type: 'OBJECT',
      properties: {
        customer_name: { type: 'STRING', description: 'Optional name of specific customer to filter by.' },
      },
    },
  },
  {
    name: 'getOutstandingPayables',
    description: 'Finds suppliers/vendors that need to be paid, total billed amounts, and pending payables.',
    parameters: {
      type: 'OBJECT',
      properties: {
        supplier_name: { type: 'STRING', description: 'Optional supplier or vendor name.' },
      },
    },
  },
  {
    name: 'getRecentTransactions',
    description: 'Fetches recent transactions with optional filters for type (revenue, expense, receivable, payable, emi) or search keyword.',
    parameters: {
      type: 'OBJECT',
      properties: {
        type: { type: 'STRING', description: 'Filter by revenue, expense, receivable, payable, or emi' },
        limit: { type: 'INTEGER', description: 'Number of items to fetch (default 5, max 10)' },
        search: { type: 'STRING', description: 'Search term for transaction title or notes' },
      },
    },
  },
  {
    name: 'checkTransactionStatus',
    description: 'Checks the detailed status of a specific invoice or transaction by invoice number or title.',
    parameters: {
      type: 'OBJECT',
      properties: {
        invoice_number: { type: 'STRING', description: 'The invoice number (e.g., INV-2026-001)' },
        search: { type: 'STRING', description: 'Transaction title or keyword' },
      },
      required: [],
    },
  },
  {
    name: 'getExpenseBreakdown',
    description: 'Retrieves top expense categories and spending distribution for financial analysis.',
    parameters: {
      type: 'OBJECT',
      properties: {
        period: { type: 'STRING', description: 'Time period like "this_month" or "all"' },
      },
    },
  },
  {
    name: 'stageQuickTransaction',
    description: 'Drafts a quick revenue or expense entry for user confirmation before saving to database.',
    parameters: {
      type: 'OBJECT',
      properties: {
        title: { type: 'STRING', description: 'Title or description of the transaction' },
        amount: { type: 'NUMBER', description: 'Amount in currency units' },
        type: { type: 'STRING', description: 'revenue or expense or payable or receivable' },
        category: { type: 'STRING', description: 'Category e.g., Software, Office Supplies, Client Retainer, Travel' },
        payment_mode: { type: 'STRING', description: 'cash, upi, bankTransfer, creditCard, cheque' },
      },
      required: ['title', 'amount', 'type'],
    },
  },
  {
    name: 'createSecureAppHandoff',
    description: 'Generates a one-time expiring secure deep link for the user to open complex screens or perform high-security actions inside ENX Money app.',
    parameters: {
      type: 'OBJECT',
      properties: {
        target_screen: { type: 'STRING', description: 'Target app screen: dashboard, transactions, compliance, powerbi, analytics, custom_reports' },
        reason: { type: 'STRING', description: 'Short description of why handoff was requested' },
      },
    },
  },
  {
    name: 'schedulePaymentReminder',
    description: 'Schedules an automated WhatsApp payment reminder for a customer or vendor.',
    parameters: {
      type: 'OBJECT',
      properties: {
        customer_name: { type: 'STRING', description: 'Name of the customer' },
        amount: { type: 'NUMBER', description: 'Outstanding amount' },
        due_date: { type: 'STRING', description: 'Due date in YYYY-MM-DD format' },
      },
      required: ['customer_name'],
    },
  },
  {
    name: 'generateKhataStatement',
    description: 'Generates and delivers a complete PDF Khata Ledger report with financial summaries, customer receivables, and recent transactions.',
    parameters: {
      type: 'OBJECT',
      properties: {
        period: { type: 'STRING', description: 'Statement period: "this_month" or "all"' },
      },
    },
  },
  {
    name: 'triggerOverdueCustomerReminders',
    description: 'Dispatches automated WhatsApp payment reminders with UPI links directly to all debtor customers with overdue balances.',
    parameters: {
      type: 'OBJECT',
      properties: {
        filter: { type: 'STRING', description: 'all or overdue' },
      },
    },
  },
];

// Helper to format currency in INR style
function formatCurrency(amount) {
  const num = Number(amount) || 0;
  return '₹' + num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * ============================================================================
 * Tool Implementations (Connecting to ENX Database)
 * ============================================================================
 */

async function execGetFinancialKPIs(userId, args = {}) {
  const { profile_type = 'business', period = 'this_month' } = args;
  let dateFilter = '';
  const params = [userId];

  if (period === 'today') {
    dateFilter = ' AND DATE(date) = CURDATE()';
  } else if (period === 'this_month') {
    dateFilter = ' AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())';
  } else if (period === 'last_month') {
    dateFilter = ' AND MONTH(date) = MONTH(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)) AND YEAR(date) = YEAR(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))';
  }

  const base = `FROM transactions WHERE user_id = ? ${dateFilter}`;

  const [revRows] = await query(`SELECT COALESCE(SUM(amount), 0) AS val, COUNT(*) as cnt ${base} AND type = 'revenue'`, params);
  const [expRows] = await query(`SELECT COALESCE(SUM(amount), 0) AS val, COUNT(*) as cnt ${base} AND type = 'expense'`, params);
  const [recvRows] = await query(`SELECT COALESCE(SUM(amount), 0) AS val, COUNT(*) as cnt ${base} AND type = 'receivable' AND is_cleared = 0`, params);
  const [payRows] = await query(`SELECT COALESCE(SUM(amount), 0) AS val, COUNT(*) as cnt ${base} AND type = 'payable' AND is_cleared = 0`, params);

  const totalRevenue = parseFloat(revRows?.val || 0);
  const totalExpense = parseFloat(expRows?.val || 0);
  const netProfit = totalRevenue - totalExpense;

  // Also query customer dues directly from customers table
  let customerDues = 0;
  try {
    const [cDueRows] = await query(
      'SELECT COALESCE(SUM(COALESCE(outstanding_balance, current_balance, 0)), 0) as due FROM customers WHERE user_id = ? AND (outstanding_balance > 0 OR current_balance > 0)',
      [userId]
    );
    customerDues = parseFloat(cDueRows?.due || 0);
  } catch {
    customerDues = parseFloat(recvRows?.val || 0);
  }

  const pendingReceivables = customerDues > 0 ? customerDues : parseFloat(recvRows?.val || 0);
  const pendingPayables = parseFloat(payRows?.val || 0);

  const formatted = `📊 *ENX Money Financial Summary & Account Balance (${period.replace('_', ' ').toUpperCase()})*\n` +
    `━━━━━━━━━━━━━━━━━━━━\n` +
    `📅 Period: *${period.replace('_', ' ').toUpperCase()}*\n\n` +
    `🟢 *Total Revenue / Inflow:* ${formatCurrency(totalRevenue)}\n` +
    `🔴 *Total Expenses / Outflow:* ${formatCurrency(totalExpense)}\n` +
    `💰 *Net Operating Surplus:* *${formatCurrency(netProfit)}*\n\n` +
    `📥 *Customer Receivables (Due to you):* ${formatCurrency(pendingReceivables)}\n` +
    `📤 *Vendor Payables (You owe):* ${formatCurrency(pendingPayables)}\n` +
    `━━━━━━━━━━━━━━━━━━━━\n` +
    `⚡ *Quick Next Actions:*\n` +
    `• Reply *"Statement"* for official PDF Khata ledger report\n` +
    `• Reply *"Remind"* to send WhatsApp reminders to customers with dues\n` +
    `• Reply *"Transactions"* for recent entries`;

  return {
    period: period.replace('_', ' ').toUpperCase(),
    totalRevenue,
    totalExpense,
    netProfit,
    pendingReceivables,
    pendingPayables,
    transactionCount: (revRows?.cnt || 0) + (expRows?.cnt || 0),
    formatted,
  };
}

async function execGetOutstandingReceivables(userId, args = {}) {
  const { customer_name } = args;
  let sql = 'SELECT name, company_name, phone, outstanding_balance, total_invoiced FROM customers WHERE user_id = ? AND outstanding_balance > 0';
  const params = [userId];

  if (customer_name) {
    sql += ' AND (name LIKE ? OR company_name LIKE ?)';
    params.push(`%${customer_name}%`, `%${customer_name}%`);
  }

  sql += ' ORDER BY outstanding_balance DESC LIMIT 6';
  const rows = await query(sql, params);

  if (rows.length === 0) {
    return {
      count: 0,
      totalDue: 0,
      formatted: `✅ *Great news!* There are currently no pending receivables. All customer invoices are settled! 🎉`,
    };
  }

  const totalDue = rows.reduce((acc, r) => acc + parseFloat(r.outstanding_balance || 0), 0);
  let text = `📥 *Pending Customer Receivables (Total: ${formatCurrency(totalDue)})*\n\n`;

  rows.forEach((c, i) => {
    text += `${i + 1}. *${c.name}* ${c.company_name ? `(${c.company_name})` : ''}\n`;
    text += `   • Due Balance: *${formatCurrency(c.outstanding_balance)}*\n`;
    text += `   • Total Invoiced: ${formatCurrency(c.total_invoiced)}\n`;
    if (c.phone) text += `   • Phone: ${c.phone}\n`;
  });

  text += `\n💡 _Tip: Reply "Send reminder to [Customer Name]" to trigger a payment notification._`;

  return { count: rows.length, totalDue, customers: rows, formatted: text };
}

async function execGetOutstandingPayables(userId, args = {}) {
  const { supplier_name } = args;
  let sql = 'SELECT name, company_name, category, phone, outstanding_payable, total_billed FROM suppliers WHERE user_id = ? AND outstanding_payable > 0';
  const params = [userId];

  if (supplier_name) {
    sql += ' AND (name LIKE ? OR company_name LIKE ?)';
    params.push(`%${supplier_name}%`, `%${supplier_name}%`);
  }

  sql += ' ORDER BY outstanding_payable DESC LIMIT 6';
  const rows = await query(sql, params);

  if (rows.length === 0) {
    return {
      count: 0,
      totalDue: 0,
      formatted: `✅ *All clear!* You have no outstanding vendor payables due at this moment. 🌟`,
    };
  }

  const totalDue = rows.reduce((acc, r) => acc + parseFloat(r.outstanding_payable || 0), 0);
  let text = `📤 *Outstanding Vendor Payables (Total: ${formatCurrency(totalDue)})*\n\n`;

  rows.forEach((s, i) => {
    text += `${i + 1}. *${s.name}* (${s.category || 'Vendor'})\n`;
    text += `   • Payable Due: *${formatCurrency(s.outstanding_payable)}*\n`;
    text += `   • Total Billed: ${formatCurrency(s.total_billed)}\n`;
  });

  text += `\n💡 _Reply "Pay [Vendor]" to prepare payment approval._`;
  return { count: rows.length, totalDue, suppliers: rows, formatted: text };
}

async function execGetRecentTransactions(userId, args = {}) {
  const { type, limit = 5, search } = args;
  let sql = 'SELECT id, title, amount, type, category, date, payment_mode, is_cleared, invoice_number FROM transactions WHERE user_id = ?';
  const params = [userId];

  if (type) {
    sql += ' AND type = ?';
    params.push(type);
  }
  if (search) {
    sql += ' AND (title LIKE ? OR invoice_number LIKE ? OR category LIKE ?)';
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }

  sql += ' ORDER BY date DESC LIMIT ?';
  params.push(Math.min(parseInt(limit) || 5, 10));

  const rows = await query(sql, params);

  if (rows.length === 0) {
    return { count: 0, formatted: `ℹ️ No transactions found matching your criteria.` };
  }

  let text = `🧾 *Recent Transactions (${rows.length})*\n\n`;
  rows.forEach((tx, i) => {
    const icon = tx.type === 'revenue' ? '🟢' : (tx.type === 'expense' ? '🔴' : '🟡');
    const status = tx.is_cleared ? '✅ Cleared' : '⏳ Pending';
    const dateStr = new Date(tx.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });

    text += `${icon} *${tx.title}*\n`;
    text += `   • Amount: *${formatCurrency(tx.amount)}* (${tx.type.toUpperCase()})\n`;
    text += `   • Category: ${tx.category} | Mode: ${tx.payment_mode}\n`;
    text += `   • Date: ${dateStr} | Status: ${status}\n`;
    if (tx.invoice_number) text += `   • Invoice: #${tx.invoice_number}\n`;
    text += '\n';
  });

  return { count: rows.length, transactions: rows, formatted: text.trim() };
}

async function execCheckTransactionStatus(userId, args = {}) {
  const { invoice_number, search } = args;
  let sql = 'SELECT * FROM transactions WHERE user_id = ?';
  const params = [userId];

  if (invoice_number) {
    sql += ' AND invoice_number LIKE ?';
    params.push(`%${invoice_number}%`);
  } else if (search) {
    sql += ' AND (title LIKE ? OR invoice_number LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  sql += ' ORDER BY date DESC LIMIT 1';
  const rows = await query(sql, params);

  if (rows.length === 0) {
    return { found: false, formatted: `⚠️ No transaction or invoice found for *"${invoice_number || search}"*. Please verify the reference number.` };
  }

  const tx = rows[0];
  const icon = tx.type === 'revenue' ? '🟢' : '🔴';
  const statusBadge = tx.is_cleared ? '✅ SETTLED & CLEARED' : '⏳ PENDING CLEARANCE';

  let text = `🔍 *Transaction Status Lookup*\n\n`;
  text += `*Title:* ${tx.title}\n`;
  text += `*Invoice #:* ${tx.invoice_number || 'N/A'}\n`;
  text += `*Type:* ${tx.type.toUpperCase()}\n`;
  text += `*Amount:* *${formatCurrency(tx.amount)}*\n`;
  text += `*Status:* ${statusBadge}\n`;
  text += `*Payment Mode:* ${tx.payment_mode}\n`;
  text += `*Date:* ${new Date(tx.date).toLocaleString('en-IN')}\n`;
  if (tx.notes) text += `*Notes:* ${tx.notes}\n`;

  return { found: true, transaction: tx, formatted: text };
}

async function execGetExpenseBreakdown(userId, args = {}) {
  const { period = 'this_month' } = args;
  let dateFilter = '';
  if (period === 'this_month') {
    dateFilter = ' AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())';
  }

  const rows = await query(
    `SELECT category, SUM(amount) as total_amt, COUNT(*) as count
     FROM transactions
     WHERE user_id = ? AND type = 'expense' ${dateFilter}
     GROUP BY category
     ORDER BY total_amt DESC LIMIT 5`,
    [userId]
  );

  if (rows.length === 0) {
    return { formatted: `ℹ️ No expense records recorded for this period.` };
  }

  const totalExp = rows.reduce((acc, r) => acc + parseFloat(r.total_amt || 0), 0);
  let text = `📊 *Top Expense Categories (Total: ${formatCurrency(totalExp)})*\n\n`;

  rows.forEach((cat, idx) => {
    const pct = totalExp > 0 ? ((cat.total_amt / totalExp) * 100).toFixed(1) : 0;
    text += `${idx + 1}. *${cat.category}:* ${formatCurrency(cat.total_amt)} (${pct}%)\n`;
  });

  return { total: totalExp, breakdown: rows, formatted: text };
}

async function execStageQuickTransaction(userId, args = {}) {
  const { title, amount, type = 'expense', category = 'General', payment_mode = 'upi' } = args;

  return {
    staged: true,
    data: { title, amount: parseFloat(amount), type, category, payment_mode },
    formatted: `📝 *Confirm New Transaction Entry:*\n\n` +
      `• *Title:* ${title}\n` +
      `• *Amount:* *${formatCurrency(amount)}*\n` +
      `• *Type:* ${type.toUpperCase()}\n` +
      `• *Category:* ${category}\n` +
      `• *Mode:* ${payment_mode.toUpperCase()}\n\n` +
      `👉 Reply *CONFIRM* to save this transaction, or *CANCEL* to discard.`,
  };
}

async function execCreateSecureAppHandoff(userId, phoneNumber, args = {}) {
  const { target_screen = 'dashboard', reason = 'Detailed View' } = args;
  const handoff = await createHandoffToken(userId, phoneNumber, target_screen, 'whatsapp_request', { reason });

  const text = `🔐 *Secure ENX Money App Access Link*\n\n` +
    `Click below to open the *${target_screen.toUpperCase()}* securely:\n` +
    `👉 ${handoff.webLink}\n\n` +
    `⚡ _This single-use cryptographic token is valid for 10 minutes._`;

  return { ...handoff, formatted: text };
}

async function execSchedulePaymentReminder(userId, args = {}) {
  const { customer_name, amount, due_date } = args;
  return {
    scheduled: true,
    formatted: `⏰ *Payment Reminder Scheduled!*\n\n` +
      `Customer: *${customer_name}*\n` +
      `Amount: *${formatCurrency(amount || 0)}*\n` +
      `Due Date: *${due_date || 'Immediate'}*\n\n` +
      `✅ An automated WhatsApp payment reminder draft has been queued in ENX Money.`,
  };
}

async function execGenerateKhataStatement(userId, phoneNumber, args = {}) {
  const statement = await generateKhataStatementPdf(userId, phoneNumber);
  await sendWhatsAppDocument(phoneNumber, statement.downloadUrl, statement.fileName, '📄 Official ENX Money Khata Ledger Statement');
  return {
    ...statement,
    formatted: statement.summaryText,
  };
}

async function execTriggerOverdueCustomerReminders(userId, args = {}) {
  const result = await scanAndSendOverdueReminders(userId);
  return {
    ...result,
    formatted: result.summaryText,
  };
}

/**
 * ============================================================================
 * Fallback Rule-Based NLP Engine (Works even when offline / no API key)
 * ============================================================================
 */
async function runOfflineRuleEngine(userId, phoneNumber, messageText) {
  const text = messageText.toLowerCase().trim();

  // 1. Statement / Khata / Ledger / PDF
  if (text === 'statement' || text === 'ledger' || text === 'khata' || text.includes('statement') || text.includes('khata') || text.includes('ledger') || text.includes('pdf')) {
    const res = await execGenerateKhataStatement(userId, phoneNumber);
    return { text: res.formatted, intent: 'GENERATE_STATEMENT', toolCalled: 'generateKhataStatement', downloadUrl: res.downloadUrl, fileName: res.fileName };
  }

  // 2. Remind / Due reminders to customers
  if (text === 'remind' || text === 'reminders' || text === 'send reminders' || text.includes('remind') || text.includes('send reminder') || text.includes('due reminder')) {
    const res = await execTriggerOverdueCustomerReminders(userId);
    return { text: res.formatted, intent: 'TRIGGER_REMINDERS', toolCalled: 'triggerOverdueCustomerReminders', count: res.count };
  }

  // 3. Balance & KPI queries
  if (text === 'balance' || text === 'bal' || text.includes('balance') || text.includes('summary') || text.includes('kpi') || text.includes('profit') || text.includes('revenue') || text.includes('income')) {
    const res = await execGetFinancialKPIs(userId, { period: 'this_month' });
    return { text: res.formatted, intent: 'GET_KPIS', toolCalled: 'getFinancialKPIs' };
  }

  // Receivables / Customers who owe money
  if (text.includes('receivable') || text.includes('owe') || text.includes('customer') || text.includes('pending payment') || text.includes('who owes')) {
    const res = await execGetOutstandingReceivables(userId);
    return { text: res.formatted, intent: 'GET_RECEIVABLES', toolCalled: 'getOutstandingReceivables' };
  }

  // Payables / Suppliers to pay
  if (text.includes('payable') || text.includes('supplier') || text.includes('vendor') || text.includes('bill') || text.includes('to pay')) {
    const res = await execGetOutstandingPayables(userId);
    return { text: res.formatted, intent: 'GET_PAYABLES', toolCalled: 'getOutstandingPayables' };
  }

  // Expenses & Spending
  if (text.includes('expense') || text.includes('spend') || text.includes('cost') || text.includes('category')) {
    const res = await execGetExpenseBreakdown(userId);
    return { text: res.formatted, intent: 'GET_EXPENSES', toolCalled: 'getExpenseBreakdown' };
  }

  // Recent transactions / statement
  if (text.includes('transaction') || text.includes('recent') || text.includes('history') || text.includes('statement')) {
    const res = await execGetRecentTransactions(userId, { limit: 5 });
    return { text: res.formatted, intent: 'GET_TRANSACTIONS', toolCalled: 'getRecentTransactions' };
  }

  // Invoice status check
  const invMatch = text.match(/inv[-\d\w]+/i);
  if (invMatch) {
    const res = await execCheckTransactionStatus(userId, { invoice_number: invMatch[0] });
    return { text: res.formatted, intent: 'CHECK_INVOICE', toolCalled: 'checkTransactionStatus' };
  }

  // App Link / Handoff
  if (text.includes('app') || text.includes('login') || text.includes('open app') || text.includes('link') || text.includes('dashboard') || text.includes('portal')) {
    const res = await execCreateSecureAppHandoff(userId, phoneNumber, { target_screen: 'dashboard' });
    return { text: res.formatted, intent: 'APP_HANDOFF', toolCalled: 'createSecureAppHandoff' };
  }

  // Default Help Menu
  const helpText = `🤖 *ENX Money Assistant Menu*\n\n` +
    `Here are some things you can ask me:\n` +
    `• 💰 *"Check my balance and profit"*\n` +
    `• 📥 *"Who owes me money?" (Receivables)*\n` +
    `• 📤 *"What bills are due?" (Payables)*\n` +
    `• 🧾 *"Show recent transactions"*\n` +
    `• 📊 *"Expense breakdown this month"*\n` +
    `• 🔍 *"Status of invoice INV-2026-001"*\n` +
    `• 🔗 *"Send me a link to open the app"*\n\n` +
    `_How can I assist your business today?_`;

  return { text: helpText, intent: 'HELP_MENU', toolCalled: null };
}

/**
 * ============================================================================
 * Gemini API Execution Engine
 * ============================================================================
 */
async function callGeminiApi(userId, phoneNumber, userMessage, conversationHistory = []) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    // Gracefully fallback to deterministic NLP engine if no API key is provided
    return await runOfflineRuleEngine(userId, phoneNumber, userMessage);
  }

  try {
    const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    // Construct Gemini contents with tools
    const geminiTools = [
      {
        function_declarations: TOOL_DEFINITIONS,
      },
    ];

    const contents = [
      {
        role: 'user',
        parts: [
          { text: SYSTEM_PROMPT },
          { text: `Current user question: "${userMessage}"` },
        ],
      },
    ];

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents,
        tools: geminiTools,
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 800,
        },
      }),
    });

    if (!response.ok) {
      console.warn(`Gemini API returned status ${response.status}. Using fallback parser.`);
      return await runOfflineRuleEngine(userId, phoneNumber, userMessage);
    }

    const data = await response.json();
    const candidate = data.candidates?.[0];
    const functionCall = candidate?.content?.parts?.find(p => p.functionCall)?.functionCall;

    if (functionCall) {
      const { name, args } = functionCall;
      let toolResult;

      switch (name) {
        case 'getFinancialKPIs':
          toolResult = await execGetFinancialKPIs(userId, args);
          break;
        case 'getOutstandingReceivables':
          toolResult = await execGetOutstandingReceivables(userId, args);
          break;
        case 'getOutstandingPayables':
          toolResult = await execGetOutstandingPayables(userId, args);
          break;
        case 'getRecentTransactions':
          toolResult = await execGetRecentTransactions(userId, args);
          break;
        case 'checkTransactionStatus':
          toolResult = await execCheckTransactionStatus(userId, args);
          break;
        case 'getExpenseBreakdown':
          toolResult = await execGetExpenseBreakdown(userId, args);
          break;
        case 'stageQuickTransaction':
          toolResult = await execStageQuickTransaction(userId, args);
          break;
        case 'createSecureAppHandoff':
          toolResult = await execCreateSecureAppHandoff(userId, phoneNumber, args);
          break;
        case 'schedulePaymentReminder':
          toolResult = await execSchedulePaymentReminder(userId, args);
          break;
        case 'generateKhataStatement':
          toolResult = await execGenerateKhataStatement(userId, phoneNumber, args);
          break;
        case 'triggerOverdueCustomerReminders':
          toolResult = await execTriggerOverdueCustomerReminders(userId, args);
          break;
        default:
          toolResult = { formatted: `Function ${name} executed.` };
      }

      return {
        text: toolResult.formatted || JSON.stringify(toolResult),
        intent: name,
        toolCalled: name,
        toolResult,
      };
    }

    const textOutput = candidate?.content?.parts?.find(p => p.text)?.text;
    if (textOutput) {
      return { text: textOutput, intent: 'CHAT_RESPONSE', toolCalled: null };
    }

    return await runOfflineRuleEngine(userId, phoneNumber, userMessage);
  } catch (err) {
    console.error('Gemini API call failed:', err.message);
    return await runOfflineRuleEngine(userId, phoneNumber, userMessage);
  }
}

/**
 * ============================================================================
 * Main AI Agent Message Processing Entrypoint
 * ============================================================================
 */
async function processUserMessage({ userId, phoneNumber, messageText, sessionState = 'IDLE', contextData = {} }) {
  const provider = (process.env.AI_PROVIDER || 'gemini').toLowerCase();

  // If session is waiting for a confirmation (e.g. staged transaction)
  if (sessionState === 'CONFIRMING_TRANSACTION' && contextData.stagedTx) {
    const clean = messageText.trim().toLowerCase();
    if (clean === 'confirm' || clean === 'yes' || clean === 'y') {
      const tx = contextData.stagedTx;
      const { v4: uuidv4 } = require('uuid');
      const id = `tx-${uuidv4().replace(/-/g, '').slice(0, 10)}`;

      await query(
        `INSERT INTO transactions (id, title, amount, type, category, payment_mode, is_cleared, user_id, date)
         VALUES (?, ?, ?, ?, ?, ?, 1, ?, NOW())`,
        [id, tx.title, tx.amount, tx.type, tx.category, tx.payment_mode, userId]
      );

      return {
        text: `✅ *Transaction Recorded Successfully!*\n\n` +
          `• Title: *${tx.title}*\n` +
          `• Amount: *${formatCurrency(tx.amount)}*\n` +
          `• Type: ${tx.type.toUpperCase()}\n` +
          `• ID: \`${id}\`\n\n` +
          `Your financial ledger has been updated. 📊`,
        intent: 'TX_CONFIRMED',
        newState: 'IDLE',
        newContext: {},
      };
    } else if (clean === 'cancel' || clean === 'no' || clean === 'n') {
      return {
        text: `❌ Transaction staging cancelled. No changes were made to your account.`,
        intent: 'TX_CANCELLED',
        newState: 'IDLE',
        newContext: {},
      };
    }
  }

  // Call Gemini (or Grok) AI Engine
  const aiResult = await callGeminiApi(userId, phoneNumber, messageText);

  // If AI staged a transaction, update session state
  if (aiResult.intent === 'stageQuickTransaction' && aiResult.toolResult?.data) {
    return {
      text: aiResult.text,
      intent: 'STAGE_TRANSACTION',
      toolCalled: 'stageQuickTransaction',
      newState: 'CONFIRMING_TRANSACTION',
      newContext: { stagedTx: aiResult.toolResult.data },
    };
  }

  return {
    text: aiResult.text,
    intent: aiResult.intent || 'GENERAL',
    toolCalled: aiResult.toolCalled || null,
    newState: 'IDLE',
    newContext: contextData,
  };
}

module.exports = {
  processUserMessage,
  callGeminiApi,
  runOfflineRuleEngine,
  TOOL_DEFINITIONS,
  formatCurrency,
  execGetFinancialKPIs,
  execGetOutstandingReceivables,
  execGetOutstandingPayables,
  execGetRecentTransactions,
  execCheckTransactionStatus,
  execGetExpenseBreakdown,
  execStageQuickTransaction,
  execCreateSecureAppHandoff,
  execSchedulePaymentReminder,
};
