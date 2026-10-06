/**
 * Automated Test Suite: ENX Money WhatsApp Chatbot
 * Run: node tests/test_whatsapp_chatbot.js
 */

const assert = require('assert');
const { migrateWhatsApp } = require('../database/migrate_whatsapp');
const {
  normalizePhone,
  getWhatsAppUser,
  startVerification,
  verifyOtp,
  getOrCreateSession,
  updateSessionState,
} = require('../services/whatsappAuthService');
const {
  execGetFinancialKPIs,
  execGetOutstandingReceivables,
  execGetRecentTransactions,
  execCheckTransactionStatus,
  processUserMessage,
} = require('../services/aiAgentService');
const { createHandoffToken, verifyAndConsumeToken } = require('../services/whatsappHandoffService');
const { query } = require('../config/db');

async function runTests() {
  console.log('🧪 Starting ENX Money WhatsApp Chatbot Test Suite...\n');

  try {
    // 1. Run Migration
    console.log('Test 1: Running WhatsApp Database Migration...');
    await migrateWhatsApp();
    console.log('✅ Test 1 Passed: WhatsApp schema migrated successfully.\n');

    // Ensure test user exists
    const testUserId = 'usr-admin-test';
    const testEmail = 'admin@enx.com';
    const testPhone = '919876543210';

    await query(
      `INSERT INTO users (id, name, email, password_hash, role)
       VALUES (?, 'Anjali Enterprise Admin', ?, 'hash123', 'admin')
       ON DUPLICATE KEY UPDATE name = VALUES(name)`,
      [testUserId, testEmail]
    );

    // Seed test customers and transactions
    await query(
      `INSERT INTO customers (id, name, company_name, phone, outstanding_balance, total_invoiced, user_id)
       VALUES ('cust-01', 'Apex Global Ltd', 'Apex Corp', '919876500001', 45000.00, 120000.00, ?)
       ON DUPLICATE KEY UPDATE outstanding_balance = VALUES(outstanding_balance)`,
      [testUserId]
    );

    await query(
      `INSERT INTO transactions (id, title, amount, type, category, is_cleared, invoice_number, user_id, date)
       VALUES ('tx-test-01', 'Cloud Infrastructure Service', 12500.00, 'expense', 'Technology', 1, 'INV-2026-001', ?, NOW())
       ON DUPLICATE KEY UPDATE title = VALUES(title)`,
      [testUserId]
    );

    // 2. Phone Normalization
    console.log('Test 2: Phone Number Normalization...');
    assert.strictEqual(normalizePhone('+91 98765 43210'), '919876543210');
    assert.strictEqual(normalizePhone('9876543210'), '919876543210');
    console.log('✅ Test 2 Passed: Phone normalizer handles international & local formats.\n');

    // 3. User Pairing & OTP Flow
    console.log('Test 3: User Pairing & OTP Verification...');
    const startRes = await startVerification(testPhone, testEmail);
    assert.strictEqual(startRes.success, true);
    assert.ok(startRes.otpCode, 'OTP should be generated');

    const verifyRes = await verifyOtp(testPhone, startRes.otpCode);
    assert.strictEqual(verifyRes.success, true);
    console.log('✅ Test 3 Passed: User verification & OTP pairing succeeded.\n');

    // 4. Financial Query Tool (KPIs)
    console.log('Test 4: Financial KPI Aggregation Tool...');
    const kpis = await execGetFinancialKPIs(testUserId, { period: 'all' });
    assert.ok(kpis.formatted.includes('Financial Summary'));
    console.log('✅ Test 4 Passed: KPI retrieval formatted correctly.\n');

    // 5. Receivables Query Tool
    console.log('Test 5: Outstanding Customer Receivables Tool...');
    const recv = await execGetOutstandingReceivables(testUserId);
    assert.ok(recv.count >= 1);
    assert.ok(recv.formatted.includes('Apex Global Ltd'));
    console.log('✅ Test 5 Passed: Customer dues retrieved accurately.\n');

    // 6. Invoice Status Lookup
    console.log('Test 6: Invoice Status Lookup Tool...');
    const invRes = await execCheckTransactionStatus(testUserId, { invoice_number: 'INV-2026-001' });
    assert.strictEqual(invRes.found, true);
    assert.ok(invRes.formatted.includes('INV-2026-001'));
    console.log('✅ Test 6 Passed: Invoice lookup resolved.\n');

    // 7. Secure Handoff Link Generation & Verification
    console.log('Test 7: Secure App Handoff Token Generation & Single-Use Consumption...');
    const handoff = await createHandoffToken(testUserId, testPhone, 'transactions', 'view_report');
    assert.ok(handoff.token.startsWith('enx_'));
    assert.ok(handoff.webLink.includes(handoff.token));

    // Verify token
    const consumeRes = await verifyAndConsumeToken(handoff.token);
    assert.strictEqual(consumeRes.valid, true);
    assert.strictEqual(consumeRes.targetScreen, 'transactions');

    // Verify cannot be reused (Single-Use protection)
    const replayRes = await verifyAndConsumeToken(handoff.token);
    assert.strictEqual(replayRes.valid, false, 'Consumed token must not be reusable');
    console.log('✅ Test 7 Passed: Cryptographic handoff tokens generated and single-use enforced.\n');

    // 8. Conversational Message Pipeline (AI Agent)
    console.log('Test 8: Full Conversational Message Processing Pipeline...');
    const chatRes = await processUserMessage({
      userId: testUserId,
      phoneNumber: testPhone,
      messageText: 'What is my current balance and profit?',
      sessionState: 'IDLE',
      contextData: {},
    });
    assert.ok(chatRes.text.length > 10);
    assert.ok(chatRes.intent);
    console.log('✅ Test 8 Passed: Natural language financial processing pipeline working.\n');

    console.log('🎉 ========================================================= 🎉');
    console.log('    ALL WHATSAPP CHATBOT INTEGRATION TESTS PASSED (8/8)!    ');
    console.log('🎉 ========================================================= 🎉');
    process.exit(0);

  } catch (err) {
    console.error('❌ Test Suite Failed:', err);
    process.exit(1);
  }
}

runTests();
