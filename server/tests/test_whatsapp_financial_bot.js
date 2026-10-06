/**
 * Automated Test Suite: ENX Money WhatsApp Financial Bot & Statements
 * Tests:
 * 1. "Balance" -> Instant real-time Account Summary
 * 2. "Statement" -> Automated PDF Khata Ledger report generation & delivery
 * 3. "Remind" -> Automated WhatsApp due payment reminders with UPI links sent directly to customers
 * 4. Meta WhatsApp Cloud API Webhook verification & payload ingestion
 *
 * Run: node tests/test_whatsapp_financial_bot.js
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { query } = require('../config/db');
const {
  processInboundMessage,
  verifyWebhook,
} = require('../controllers/whatsappWebhookController');
const { generateKhataStatementPdf } = require('../services/whatsappStatementService');
const { scanAndSendOverdueReminders } = require('../services/whatsappReminderService');
const { getSimulatorMessages, clearSimulatorMessages } = require('../services/whatsappMessageService');

async function runFinancialBotTests() {
  console.log('🧪 Starting ENX Money Automated WhatsApp Financial Bot Test Suite...\n');

  try {
    const testUserId = 'usr-admin-001';
    const testPhone = '919876543210';

    clearSimulatorMessages();

    // ──────────────────────────────────────────────────────────────────────────
    // Test 1: "Balance" Command -> Instant Account Summary
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 1: Processing "Balance" command...');
    const balResult = await processInboundMessage(testPhone, 'Balance');

    assert.ok(balResult.reply, 'Should return a reply message');
    assert.strictEqual(balResult.intent, 'GET_KPIS');
    assert.ok(
      balResult.reply.includes('Financial Summary') || balResult.reply.includes('Account Balance') || balResult.reply.includes('ACCOUNT SUMMARY'),
      'Reply must contain Financial Summary or Account Balance'
    );
    assert.ok(balResult.reply.includes('Total Revenue'), 'Reply must include Total Revenue');
    assert.ok(balResult.reply.includes('Total Expenses'), 'Reply must include Total Expenses');
    assert.ok(balResult.reply.includes('Net Operating Surplus') || balResult.reply.includes('Net Profit'), 'Reply must include Net Surplus/Profit');
    assert.ok(balResult.reply.includes('Statement'), 'Reply should guide user to Statement command');
    assert.ok(balResult.reply.includes('Remind'), 'Reply should guide user to Remind command');
    console.log('✅ Test 1 Passed: "Balance" returns instant formatted Account Summary.\n');

    // ──────────────────────────────────────────────────────────────────────────
    // Test 2: "Statement" Command -> Automated PDF Khata Ledger Report
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 2: Processing "Statement" command (PDF Khata Ledger generation)...');
    clearSimulatorMessages();
    const stmtResult = await processInboundMessage(testPhone, 'Statement');

    assert.ok(stmtResult.reply, 'Should return a text reply');
    assert.strictEqual(stmtResult.intent, 'GENERATE_STATEMENT');
    assert.ok(stmtResult.downloadUrl, 'Must return a downloadUrl');
    assert.ok(stmtResult.downloadUrl.endsWith('.pdf'), 'Download URL must be a PDF file');
    assert.ok(stmtResult.fileName, 'Must return a fileName');

    // Verify the file was created on disk in public/statements
    const expectedPdfPath = path.join(__dirname, '../public/statements', stmtResult.fileName);
    assert.ok(fs.existsSync(expectedPdfPath), `PDF file must exist on disk at ${expectedPdfPath}`);
    const stat = fs.statSync(expectedPdfPath);
    assert.ok(stat.size > 1000, `PDF file size should be > 1KB (actual: ${stat.size} bytes)`);

    // Verify outbound messages in simulator
    const outbox = getSimulatorMessages();
    const docMsg = outbox.find(m => m.type === 'document' || m.documentUrl);
    assert.ok(docMsg, 'Outbox must contain document message for WhatsApp Cloud API');
    console.log(`✅ Test 2 Passed: "Statement" generated valid PDF Khata report (${stat.size} bytes) & dispatched document.\n`);

    // ──────────────────────────────────────────────────────────────────────────
    // Test 3: "Remind" Command -> Customer Overdue Reminders with UPI Link
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 3: Processing "Remind" command (Overdue reminders to customers)...');
    clearSimulatorMessages();
    const remindResult = await processInboundMessage(testPhone, 'Remind');

    assert.ok(remindResult.reply, 'Should return confirmation summary to business owner');
    assert.strictEqual(remindResult.intent, 'TRIGGER_REMINDERS');

    // Check that customer reminders were sent
    const reminderOutbox = getSimulatorMessages();
    const customerReminders = reminderOutbox.filter(m => m.options && m.options.type === 'customer_payment_reminder');

    assert.ok(customerReminders.length >= 1, 'At least 1 customer reminder must be dispatched');
    assert.ok(customerReminders[0].text.includes('Payment Reminder'), 'Customer text must be a Payment Reminder');
    assert.ok(customerReminders[0].text.includes('upi://pay'), 'Customer text must contain one-tap UPI payment link');
    assert.ok(remindResult.reply.includes('Dispatched WhatsApp payment reminders'), 'Owner summary must confirm dispatched count');
    console.log(`✅ Test 3 Passed: "Remind" sent ${customerReminders.length} direct customer reminder(s) with UPI links.\n`);

    // ──────────────────────────────────────────────────────────────────────────
    // Test 4: Natural Language Inquiries
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 4: Natural language variations ("What is my balance?")...');
    const nlBal = await processInboundMessage(testPhone, 'What is my current balance?');
    assert.ok(nlBal.reply.includes('ACCOUNT SUMMARY') || nlBal.reply.includes('Financial Summary'));
    assert.strictEqual(nlBal.intent, 'GET_KPIS');

    console.log('Test 4b: Natural language variations ("Send me my khata ledger report")...');
    const nlStmt = await processInboundMessage(testPhone, 'Send me my khata ledger report');
    assert.ok(nlStmt.downloadUrl || nlStmt.reply.includes('.pdf'));
    assert.strictEqual(nlStmt.intent, 'GENERATE_STATEMENT');

    console.log('Test 4c: Natural language variations ("Send reminders to customers")...');
    const nlRem = await processInboundMessage(testPhone, 'Send reminders to customers');
    assert.strictEqual(nlRem.intent, 'TRIGGER_REMINDERS');
    console.log('✅ Test 4 Passed: Natural language variations correctly routed.\n');

    // ──────────────────────────────────────────────────────────────────────────
    // Test 5: Meta WhatsApp Cloud API Webhook Verification (hub.challenge)
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 5: Meta Webhook Verification (GET /webhook)...');
    let verifyStatus = 0;
    let verifyBody = '';
    const mockReq = {
      query: {
        'hub.mode': 'subscribe',
        'hub.verify_token': 'enx_money_webhook_token_2026',
        'hub.challenge': 'CHALLENGE_CODE_12345',
      },
    };
    const mockRes = {
      status: (code) => {
        verifyStatus = code;
        return {
          send: (body) => { verifyBody = body; },
        };
      },
      sendStatus: (code) => { verifyStatus = code; },
    };

    verifyWebhook(mockReq, mockRes);
    assert.strictEqual(verifyStatus, 200);
    assert.strictEqual(verifyBody, 'CHALLENGE_CODE_12345');
    console.log('✅ Test 5 Passed: Meta WhatsApp Webhook challenge verified successfully.\n');

    // ──────────────────────────────────────────────────────────────────────────
    // Test 6: Meta WhatsApp Inbound Webhook Payload Ingestion (POST /webhook)
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 6: Inbound Meta Cloud API message payload...');
    const metaPayload = {
      object: 'whatsapp_business_account',
      entry: [
        {
          id: 'WHATSAPP_BUSINESS_ACCOUNT_ID',
          changes: [
            {
              value: {
                messaging_product: 'whatsapp',
                metadata: {
                  display_phone_number: '15551234567',
                  phone_number_id: '105934812345678',
                },
                contacts: [{ profile: { name: 'Krishna' }, wa_id: testPhone }],
                messages: [
                  {
                    from: testPhone,
                    id: 'wamid.HBgLMTIzNDU2Nzg5MA==',
                    timestamp: '1727700000',
                    text: { body: 'Balance' },
                    type: 'text',
                  },
                ],
              },
              field: 'messages',
            },
          ],
        },
      ],
    };

    // Test processing inbound from payload
    const fromNumber = metaPayload.entry[0].changes[0].value.messages[0].from;
    const msgText = metaPayload.entry[0].changes[0].value.messages[0].text.body;
    const webhookRes = await processInboundMessage(fromNumber, msgText, metaPayload);
    assert.ok(
      webhookRes.reply.includes('Financial Summary') || webhookRes.reply.includes('Account Balance') || webhookRes.reply.includes('ACCOUNT SUMMARY')
    );
    console.log('✅ Test 6 Passed: Meta WhatsApp Cloud API payload parsed and executed.\n');

    // ──────────────────────────────────────────────────────────────────────────
    // Test 7: Web Portal Financial APIs (Summary, Statement, Dues, Remind)
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 7: Web Portal Domain APIs (apiGetSummary, apiGenerateStatement, apiGetCustomerDues, apiTriggerReminders)...');
    const { apiGetSummary, apiGenerateStatement, apiGetCustomerDues, apiTriggerReminders } = require('../controllers/whatsappWebhookController');

    // Test Summary API
    let summaryJson = null;
    await apiGetSummary({ query: { userId: testUserId } }, { json: (d) => { summaryJson = d; } }, () => {});
    assert.ok(summaryJson.success);
    assert.ok(summaryJson.data.totalRevenue > 0);

    // Test Statement API
    let stmtJson = null;
    await apiGenerateStatement({ query: { userId: testUserId, phone: testPhone } }, { json: (d) => { stmtJson = d; } }, () => {});
    assert.ok(stmtJson.success);
    assert.ok(stmtJson.data.downloadUrl.endsWith('.pdf'));

    // Test Customer Dues API
    let duesJson = null;
    await apiGetCustomerDues({ query: { userId: testUserId } }, { json: (d) => { duesJson = d; } }, () => {});
    assert.ok(duesJson.success);
    assert.ok(duesJson.count >= 1);
    assert.ok(duesJson.data[0].upiLink.includes('upi://pay'));

    // Test Trigger Reminders API
    let remindJson = null;
    await apiTriggerReminders({ body: { userId: testUserId } }, { json: (d) => { remindJson = d; } }, () => {});
    assert.ok(remindJson.success);
    assert.ok(remindJson.data.count >= 1);
    console.log('✅ Test 7 Passed: All Web Portal Domain APIs functional and verified.\n');

    // ──────────────────────────────────────────────────────────────────────────
    // Test 8: Financial Hub Web Portal UI file validation
    // ──────────────────────────────────────────────────────────────────────────
    console.log('Test 8: Verifying Financial Hub Web Portal HTML file...');
    const portalPath = path.join(__dirname, '../public/portal.html');
    assert.ok(fs.existsSync(portalPath), 'portal.html must exist in public directory');
    const portalHtml = fs.readFileSync(portalPath, 'utf8');
    assert.ok(portalHtml.includes('Automated Financial Hub & Statements'), 'Must contain Portal Title');
    assert.ok(portalHtml.includes('Generate & Download PDF Statement'), 'Must contain PDF statement button');
    assert.ok(portalHtml.includes('WhatsApp Due Payment Reminders'), 'Must contain WhatsApp reminders section');
    assert.ok(portalHtml.includes('Customer Debtor Khata Ledger'), 'Must contain Customer Khata Ledger');
    console.log('✅ Test 8 Passed: Financial Hub Web Portal UI is fully verified.\n');

    console.log('🎉 ================================================================ 🎉');
    console.log('   ALL AUTOMATED WHATSAPP FINANCIAL BOT & STATEMENT TESTS PASSED!   ');
    console.log('🎉 ================================================================ 🎉\n');

  } catch (err) {
    console.error('❌ Test Suite Failed:', err);
    process.exit(1);
  }
}

runFinancialBotTests();
