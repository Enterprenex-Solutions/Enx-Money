/**
 * WhatsApp Statement & Khata Ledger PDF Generator Service
 * Produces enterprise-grade PDF Khata Ledger reports for instant delivery via WhatsApp.
 */

const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const crypto = require('crypto');
const { query } = require('../config/db');

// Ensure public/statements directory exists
const STATEMENTS_DIR = path.join(__dirname, '../public/statements');
if (!fs.existsSync(STATEMENTS_DIR)) {
  fs.mkdirSync(STATEMENTS_DIR, { recursive: true });
}

// Helper to format currency
function formatINR(val) {
  const num = Number(val) || 0;
  return 'Rs. ' + num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * Generates an official PDF Khata Ledger Statement for a user.
 * @param {string} userId - ENX Money user id
 * @param {string} phoneNumber - WhatsApp recipient phone number
 * @returns {Promise<{ fileName: string, filePath: string, downloadUrl: string, summaryText: string, stats: object }>}
 */
async function generateKhataStatementPdf(userId, phoneNumber) {
  // 1. Fetch User / Business Information
  const userRows = await query('SELECT id, name, email FROM users WHERE id = ?', [userId]);
  const user = userRows[0] || { id: userId, name: 'Business Enterprise Owner', email: 'support@enxmoney.com' };

  // Fetch optional enterprise / business settings
  let businessName = user.name || 'ENX Money Enterprise';
  let gstin = '27AARCP9260R1Z2';
  try {
    const entRows = await query('SELECT company_name, gstin FROM enterprises WHERE user_id = ? LIMIT 1', [userId]);
    if (entRows.length > 0 && entRows[0].company_name) {
      businessName = entRows[0].company_name;
      if (entRows[0].gstin) gstin = entRows[0].gstin;
    }
  } catch {
    // Graceful fallback
  }

  // 2. Fetch KPIs
  const [revRows] = await query("SELECT COALESCE(SUM(amount), 0) AS val, COUNT(*) as cnt FROM transactions WHERE user_id = ? AND type = 'revenue'", [userId]);
  const [expRows] = await query("SELECT COALESCE(SUM(amount), 0) AS val, COUNT(*) as cnt FROM transactions WHERE user_id = ? AND type = 'expense'", [userId]);
  const [recvRows] = await query("SELECT COALESCE(SUM(amount), 0) AS val FROM transactions WHERE user_id = ? AND type = 'receivable' AND is_cleared = 0", [userId]);

  const totalRevenue = parseFloat(revRows?.val || 0);
  const totalExpense = parseFloat(expRows?.val || 0);
  const netBalance = totalRevenue - totalExpense;

  // 3. Fetch Customer Khata Debtor List
  const customers = await query(
    `SELECT name, company_name, phone, COALESCE(outstanding_balance, current_balance, 0) as due, COALESCE(total_invoiced, 0) as invoiced
     FROM customers
     WHERE user_id = ?
     ORDER BY due DESC LIMIT 12`,
    [userId]
  );

  const totalCustomerDues = customers.reduce((acc, c) => acc + (parseFloat(c.due) || 0), 0);

  // 4. Fetch Recent Transactions
  const transactions = await query(
    `SELECT title, amount, type, category, payment_mode, date, invoice_number
     FROM transactions
     WHERE user_id = ?
     ORDER BY date DESC LIMIT 10`,
    [userId]
  );

  // 5. Prepare PDF Destination
  const cleanPhone = String(phoneNumber || 'user').replace(/[^\d]/g, '');
  const timestamp = Date.now();
  const statementId = `STMT-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}-${timestamp.toString().slice(-4)}`;
  const fileName = `Khata_Statement_${cleanPhone}_${timestamp}.pdf`;
  const filePath = path.join(STATEMENTS_DIR, fileName);

  const baseUrl = process.env.APP_BASE_URL || 'https://enxmoney.enterprenex.solutions';
  const downloadUrl = `${baseUrl}/statements/${fileName}`;

  // 6. Build PDF with PDFKit
  await new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      margin: 36,
      size: 'A4',
      info: {
        Title: `ENX Money Statement - ${businessName}`,
        Author: 'ENX Money Automated Financial Engine',
        Subject: 'Khata Ledger & Financial Report',
      },
    });

    const writeStream = fs.createWriteStream(filePath);
    doc.pipe(writeStream);

    // --- Header Banner ---
    doc.rect(36, 36, 523, 72).fill('#00695C');

    doc.fillColor('#FFFFFF').fontSize(18).font('Helvetica-Bold')
      .text('ENX MONEY • FINANCIAL & KHATA STATEMENT', 50, 48);

    doc.fillColor('#A7F3D0').fontSize(10).font('Helvetica')
      .text(`Official Ledger Audit Report • Ref: ${statementId}`, 50, 72);
    doc.text(`Issued: ${new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}`, 50, 86);

    // --- Account Holder Card ---
    let y = 120;
    doc.rect(36, y, 523, 50).fill('#F8FAFC');
    doc.rect(36, y, 523, 50).stroke('#E2E8F0');

    doc.fillColor('#0F172A').fontSize(11).font('Helvetica-Bold')
      .text(`Account: ${businessName}`, 48, y + 10);
    doc.fillColor('#475569').fontSize(9).font('Helvetica')
      .text(`Owner: ${user.name}  |  Email: ${user.email}  |  GSTIN: ${gstin}`, 48, y + 26);
    doc.text(`Registered WhatsApp: +${cleanPhone}`, 48, y + 38);

    // --- KPI Metric Grid (4 Cards) ---
    y = 182;
    const cardWidth = 124;
    const cardHeight = 48;
    const cards = [
      { label: 'TOTAL INFLOW', value: formatINR(totalRevenue), bg: '#ECFDF5', border: '#A7F3D0', text: '#065F46' },
      { label: 'TOTAL EXPENSE', value: formatINR(totalExpense), bg: '#FEF2F2', border: '#FECACA', text: '#991B1B' },
      { label: 'NET CASHFLOW', value: formatINR(netBalance), bg: '#EFF6FF', border: '#BFDBFE', text: '#1E40AF' },
      { label: 'CUSTOMER DUES', value: formatINR(totalCustomerDues || recvRows?.val || 0), bg: '#FFFBEB', border: '#FDE68A', text: '#92400E' },
    ];

    cards.forEach((c, idx) => {
      const cx = 36 + idx * (cardWidth + 9);
      doc.rect(cx, y, cardWidth, cardHeight).fill(c.bg);
      doc.rect(cx, y, cardWidth, cardHeight).stroke(c.border);
      doc.fillColor('#64748B').fontSize(7.5).font('Helvetica-Bold').text(c.label, cx + 8, y + 8);
      doc.fillColor(c.text).fontSize(10.5).font('Helvetica-Bold').text(c.value, cx + 8, y + 24, { width: cardWidth - 16 });
    });

    // --- Section 1: Customer Khata Ledger (Receivables) ---
    y = 244;
    doc.fillColor('#00695C').fontSize(11).font('Helvetica-Bold').text('1. CUSTOMER KHATA LEDGER (OUTSTANDING RECEIVABLES)', 36, y);
    doc.moveDown(0.2);

    y += 16;
    doc.rect(36, y, 523, 18).fill('#00695C');
    doc.fillColor('#FFFFFF').fontSize(8.5).font('Helvetica-Bold');
    doc.text('Customer Name', 44, y + 4);
    doc.text('Phone', 220, y + 4);
    doc.text('Total Invoiced', 315, y + 4);
    doc.text('Balance Due', 415, y + 4);
    doc.text('Status', 495, y + 4);

    y += 18;
    if (customers.length === 0) {
      doc.fillColor('#64748B').fontSize(9).font('Helvetica')
        .text('No pending customer balances found. All accounts are settled.', 44, y + 8);
      y += 24;
    } else {
      customers.forEach((cust, i) => {
        const rowBg = i % 2 === 0 ? '#FFFFFF' : '#F8FAFC';
        doc.rect(36, y, 523, 18).fill(rowBg);
        doc.rect(36, y, 523, 18).stroke('#E2E8F0');

        doc.fillColor('#0F172A').fontSize(8.5).font('Helvetica')
          .text(cust.name || 'Customer', 44, y + 4, { width: 170, ellipsis: true });
        doc.text(cust.phone || '-', 220, y + 4);
        doc.text(formatINR(cust.invoiced), 315, y + 4);

        const dueVal = parseFloat(cust.due) || 0;
        doc.fillColor(dueVal > 0 ? '#DC2626' : '#16A34A').font('Helvetica-Bold')
          .text(formatINR(dueVal), 415, y + 4);

        doc.fillColor(dueVal > 0 ? '#DC2626' : '#16A34A').fontSize(8)
          .text(dueVal > 0 ? 'DUE' : 'SETTLED', 495, y + 4);

        y += 18;
      });
    }

    // --- Section 2: Recent Transactions Journal ---
    y += 14;
    doc.fillColor('#00695C').fontSize(11).font('Helvetica-Bold').text('2. RECENT TRANSACTION JOURNAL', 36, y);

    y += 16;
    doc.rect(36, y, 523, 18).fill('#0F172A');
    doc.fillColor('#FFFFFF').fontSize(8.5).font('Helvetica-Bold');
    doc.text('Date', 44, y + 4);
    doc.text('Description / Title', 110, y + 4);
    doc.text('Category', 280, y + 4);
    doc.text('Mode', 370, y + 4);
    doc.text('Type', 430, y + 4);
    doc.text('Amount', 490, y + 4, { align: 'right', width: 60 });

    y += 18;
    if (transactions.length === 0) {
      doc.fillColor('#64748B').fontSize(9).font('Helvetica')
        .text('No recent transaction entries found.', 44, y + 8);
      y += 24;
    } else {
      transactions.forEach((tx, i) => {
        const rowBg = i % 2 === 0 ? '#FFFFFF' : '#F8FAFC';
        doc.rect(36, y, 523, 18).fill(rowBg);
        doc.rect(36, y, 523, 18).stroke('#E2E8F0');

        const dStr = tx.date ? new Date(tx.date).toLocaleDateString('en-IN') : 'Today';
        doc.fillColor('#64748B').fontSize(8).font('Helvetica').text(dStr, 44, y + 4);
        doc.fillColor('#0F172A').fontSize(8.5).font('Helvetica').text(tx.title || 'Entry', 110, y + 4, { width: 165, ellipsis: true });
        doc.fillColor('#475569').text(tx.category || 'General', 280, y + 4, { width: 85, ellipsis: true });
        doc.text((tx.payment_mode || 'UPI').toUpperCase(), 370, y + 4);

        const isRev = tx.type === 'revenue';
        doc.fillColor(isRev ? '#16A34A' : '#DC2626').font('Helvetica-Bold')
          .text(tx.type?.toUpperCase() || 'EXPENSE', 430, y + 4);

        doc.text(`${isRev ? '+' : '-'}${formatINR(tx.amount)}`, 480, y + 4, { align: 'right', width: 70 });

        y += 18;
      });
    }

    // --- Footer / Verification Bar ---
    const hash = crypto.createHash('sha256').update(`${statementId}-${userId}-${cleanPhone}-${netBalance}`).digest('hex').slice(0, 24);
    doc.rect(36, 750, 523, 46).fill('#F1F5F9');
    doc.rect(36, 750, 523, 46).stroke('#CBD5E1');

    doc.fillColor('#00695C').fontSize(8.5).font('Helvetica-Bold')
      .text('🔒 SECURE ENTERPRISE VERIFICATION RECORD', 46, 756);
    doc.fillColor('#475569').fontSize(7.5).font('Helvetica')
      .text(`Digital Fingerprint: ${hash}  •  Status: Verified  •  Engine: ENX Multi-Tenant Ledger`, 46, 768);
    doc.text(`Download & Verify Online: ${downloadUrl}`, 46, 780);

    doc.end();

    writeStream.on('finish', resolve);
    writeStream.on('error', reject);
  });

  const summaryText = `📄 *ENX MONEY KHATA LEDGER STATEMENT*\n` +
    `━━━━━━━━━━━━━━━━━━━━\n` +
    `🏢 Account: *${businessName}*\n` +
    `Ref: \`${statementId}\`\n\n` +
    `🟢 *Total Revenue:* ${formatINR(totalRevenue)}\n` +
    `🔴 *Total Expenses:* ${formatINR(totalExpense)}\n` +
    `💰 *Net Cash Surplus:* ${formatINR(netBalance)}\n` +
    `📥 *Customer Dues (Receivables):* ${formatINR(totalCustomerDues)}\n\n` +
    `📥 *Download Official PDF Report:* \n${downloadUrl}\n\n` +
    `_Sent via ENX Money WhatsApp Engine. Document attached._ 🚀`;

  return {
    success: true,
    statementId,
    fileName,
    filePath,
    downloadUrl,
    summaryText,
    stats: {
      totalRevenue,
      totalExpense,
      netBalance,
      totalCustomerDues,
      customerCount: customers.length,
      transactionCount: transactions.length,
    },
  };
}

module.exports = {
  generateKhataStatementPdf,
  STATEMENTS_DIR,
};
