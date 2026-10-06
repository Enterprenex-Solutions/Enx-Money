/**
 * WhatsApp Reminder & Notification Engine
 * Schedules, tracks, and delivers payment reminders, overdue receivable alerts,
 * and daily enterprise financial summaries with direct UPI settlement links.
 */

const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');
const { sendWhatsAppMessage } = require('./whatsappMessageService');

// Helper to format currency in INR style
function formatCurrency(amount) {
  const num = Number(amount) || 0;
  return '₹' + num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * Creates and queues a payment reminder in the database.
 */
async function createReminder({
  userId,
  recipientPhone,
  entityType = 'customer',
  entityId = null,
  entityName,
  reminderType = 'receivable_overdue',
  title,
  amount = 0,
  dueDate = null,
  scheduledAt = new Date(),
}) {
  const id = `rem-${uuidv4().replace(/-/g, '').slice(0, 10)}`;
  const cleanPhone = String(recipientPhone).replace(/[^\d+]/g, '');

  await query(
    `INSERT INTO whatsapp_reminders (id, user_id, recipient_phone, entity_type, entity_id, entity_name, reminder_type, title, amount, due_date, status, scheduled_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'sent', ?)`,
    [id, userId, cleanPhone, entityType, entityId, entityName, reminderType, title, amount, dueDate, scheduledAt]
  );

  return { id, title, amount, scheduledAt, status: 'sent' };
}

/**
 * Scans for overdue customer receivables and directly sends WhatsApp reminder notices
 * to each customer with their outstanding balance and a one-tap UPI payment link.
 */
async function scanAndSendOverdueReminders(userId) {
  // Query customers with overdue balance
  const rows = await query(
    `SELECT c.id, c.name, c.company_name, c.phone,
            COALESCE(c.outstanding_balance, c.current_balance, 0) as due_amount,
            u.name as business_name
     FROM customers c
     LEFT JOIN users u ON c.user_id = u.id
     WHERE c.user_id = ? AND (c.outstanding_balance > 0 OR c.current_balance > 0) AND c.phone IS NOT NULL`,
    [userId]
  );

  // If no customers have pending dues
  if (!rows || rows.length === 0) {
    return {
      success: true,
      count: 0,
      totalReminded: 0,
      results: [],
      summaryText: `🎉 *All Customer Accounts Settled!*\n\n` +
        `You have *zero overdue receivables* at this time. All customer ledgers are in good standing! ✨`,
    };
  }

  const results = [];
  let totalDueReminded = 0;

  for (const cust of rows) {
    const dueAmount = parseFloat(cust.due_amount || cust.outstanding_balance || cust.current_balance) || 0;
    if (dueAmount <= 0) continue;

    totalDueReminded += dueAmount;
    const businessName = cust.business_name || 'ENX Money Enterprise';
    const upiLink = `upi://pay?pa=enxmoney@upi&pn=${encodeURIComponent(businessName)}&am=${dueAmount.toFixed(2)}&cu=INR`;

    // Personalized reminder sent directly to the debtor customer
    const customerMsg = `🔔 *Payment Reminder from ${businessName}*\n\n` +
      `Dear *${cust.name}*,\n` +
      `This is a friendly reminder that your outstanding balance of *${formatCurrency(dueAmount)}* with *${businessName}* is due for settlement.\n\n` +
      `💳 *One-Tap UPI Payment Link:*\n` +
      `${upiLink}\n\n` +
      `Kindly arrange the payment at your earliest convenience. If you have already made the transfer, please reply with the payment reference / UTR number.\n\n` +
      `Thank you for your valued business! 🙏`;

    // Dispatch directly to customer's WhatsApp
    await sendWhatsAppMessage(cust.phone, customerMsg, {
      type: 'customer_payment_reminder',
      amount: dueAmount,
      customerId: cust.id,
    });

    // Record audit reminder in database
    await createReminder({
      userId,
      recipientPhone: cust.phone,
      entityType: 'customer',
      entityId: cust.id,
      entityName: cust.name,
      reminderType: 'receivable_overdue',
      title: `Overdue balance reminder for ${cust.name}`,
      amount: dueAmount,
      scheduledAt: new Date(),
    });

    results.push({
      customerId: cust.id,
      customerName: cust.name,
      phone: cust.phone,
      amount: dueAmount,
    });
  }

  // Construct detailed report for the business owner
  let ownerSummary = `✅ *Automated Customer Due Reminders Sent!*\n` +
    `━━━━━━━━━━━━━━━━━━━━\n` +
    `Dispatched WhatsApp payment reminders to *${results.length}* customer(s):\n\n`;

  results.forEach((r, idx) => {
    ownerSummary += `${idx + 1}. *${r.customerName}*: ${formatCurrency(r.amount)}\n` +
      `   📱 Sent to: +${r.phone}\n`;
  });

  ownerSummary += `\n💰 *Total Overdue Reminded:* *${formatCurrency(totalDueReminded)}*\n` +
    `📲 Customers received instant payment details and UPI links.`;

  return {
    success: true,
    count: results.length,
    totalReminded: totalDueReminded,
    results,
    summaryText: ownerSummary,
  };
}

/**
 * Sends a daily morning financial digest to the registered user on WhatsApp.
 */
async function sendDailyFinancialDigest(userId, userPhone) {
  const [rev] = await query('SELECT COALESCE(SUM(amount), 0) AS val FROM transactions WHERE user_id = ? AND type = "revenue" AND MONTH(date) = MONTH(CURRENT_DATE())', [userId]);
  const [exp] = await query('SELECT COALESCE(SUM(amount), 0) AS val FROM transactions WHERE user_id = ? AND type = "expense" AND MONTH(date) = MONTH(CURRENT_DATE())', [userId]);
  const [recv] = await query('SELECT COALESCE(SUM(amount), 0) AS val FROM customers WHERE user_id = ? AND (outstanding_balance > 0 OR current_balance > 0)', [userId]);
  const [pay] = await query('SELECT COALESCE(SUM(outstanding_payable), 0) AS val FROM suppliers WHERE user_id = ? AND (outstanding_payable > 0 OR current_balance > 0)', [userId]);

  const totalRev = parseFloat(rev?.val || 0);
  const totalExp = parseFloat(exp?.val || 0);
  const totalRecv = parseFloat(recv?.val || 0);
  const totalPay = parseFloat(pay?.val || 0);

  const digestText = `☀️ *ENX Money Daily Briefing*\n\n` +
    `Here is your morning financial health summary for *${new Date().toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'short' })}*:\n\n` +
    `🟢 *Month Revenue:* ${formatCurrency(totalRev)}\n` +
    `🔴 *Month Expenses:* ${formatCurrency(totalExp)}\n` +
    `💰 *Net Operating Surplus:* ${formatCurrency(totalRev - totalExp)}\n` +
    `📥 *Pending Receivables:* ${formatCurrency(totalRecv)}\n` +
    `📤 *Pending Vendor Dues:* ${formatCurrency(totalPay)}\n\n` +
    `_Reply "Statement" for PDF report or "Remind" to send customer notices._ 🚀`;

  await sendWhatsAppMessage(userPhone, digestText);
  return { success: true, message: digestText };
}

module.exports = {
  createReminder,
  scanAndSendOverdueReminders,
  sendDailyFinancialDigest,
};
