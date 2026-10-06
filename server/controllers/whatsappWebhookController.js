/**
 * WhatsApp Webhook & Simulator Controller
 * Routes inbound WhatsApp messages through verification, session management,
 * AI natural language understanding, and response dispatching.
 */

const {
  normalizePhone,
  getWhatsAppUser,
  startVerification,
  verifyOtp,
  getOrCreateSession,
  updateSessionState,
  resetSession,
  logMessage,
} = require('../services/whatsappAuthService');
const { processUserMessage, execGetFinancialKPIs } = require('../services/aiAgentService');
const { sendWhatsAppMessage, sendWhatsAppDocument, getSimulatorMessages, clearSimulatorMessages } = require('../services/whatsappMessageService');
const { verifyAndConsumeToken } = require('../services/whatsappHandoffService');
const { scanAndSendOverdueReminders, sendDailyFinancialDigest } = require('../services/whatsappReminderService');
const { generateKhataStatementPdf } = require('../services/whatsappStatementService');
const { query } = require('../config/db');

/**
 * 1. Meta WhatsApp Cloud API Webhook Verification (GET /webhook)
 */
function verifyWebhook(req, res) {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  const expectedToken = process.env.WHATSAPP_VERIFY_TOKEN || 'enx_money_webhook_token_2026';

  if (mode === 'subscribe' && token === expectedToken) {
    console.log('✅ WhatsApp Webhook verified successfully!');
    return res.status(200).send(challenge);
  }

  console.warn('❌ WhatsApp Webhook verification failed. Invalid token.');
  return res.sendStatus(403);
}

/**
 * Helper to process any inbound text message from a phone number
 */
async function processInboundMessage(phoneNumber, messageText, rawPayload = null) {
  const phone = normalizePhone(phoneNumber);
  const text = (messageText || '').trim();

  // Log inbound message
  const waUser = await getWhatsAppUser(phone);
  await logMessage({
    phoneNumber: phone,
    userId: waUser?.user_id || null,
    direction: 'inbound',
    body: text,
    rawPayload,
  });

  const session = await getOrCreateSession(phone, waUser?.user_id || null);

  // 1. Check if user is not verified yet
  if (!waUser || waUser.verification_status !== 'verified') {
    // If session is waiting for OTP
    if (session.state === 'AWAITING_OTP') {
      // User entered 6-digit OTP
      const otpMatch = text.match(/\b\d{6}\b/);
      if (otpMatch) {
        const otpRes = await verifyOtp(phone, otpMatch[0]);
        await sendWhatsAppMessage(phone, otpRes.message);
        await logMessage({
          phoneNumber: phone,
          userId: otpRes.user?.user_id || null,
          direction: 'outbound',
          body: otpRes.message,
          intent: 'OTP_VERIFY_RESULT',
        });
        return { reply: otpRes.message, user: otpRes.user, state: 'IDLE' };
      }
    }

    // Check if user entered an email address to pair
    const emailMatch = text.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/);
    if (emailMatch) {
      const initRes = await startVerification(phone, emailMatch[0]);
      await sendWhatsAppMessage(phone, initRes.message);
      await logMessage({
        phoneNumber: phone,
        userId: initRes.user?.id || null,
        direction: 'outbound',
        body: initRes.message,
        intent: 'OTP_GENERATED',
      });
      return { reply: initRes.message, state: 'AWAITING_OTP', otpCode: initRes.otpCode };
    }

    // If first-time onboarding prompt
    const welcomePrompt = `👋 *Welcome to ENX Money WhatsApp Assistant!*\n\n` +
      `To securely link your account, please reply with your *registered ENX Money email address* (e.g. \`admin@enx.com\`).\n\n` +
      `🔒 _Your financial data is protected with end-to-end banking encryption._`;

    await sendWhatsAppMessage(phone, welcomePrompt);
    await logMessage({
      phoneNumber: phone,
      userId: null,
      direction: 'outbound',
      body: welcomePrompt,
      intent: 'ONBOARDING_PROMPT',
    });

    return { reply: welcomePrompt, state: 'AWAITING_EMAIL' };
  }

  // 2. Verified User: Handle special command shortcuts
  const lower = text.toLowerCase();

  // Command: Help / Menu / Start
  if (lower === 'help' || lower === 'menu' || lower === 'start') {
    await resetSession(phone);
    const menu = `🤖 *ENX Money Smart Financial Assistant*\n\n` +
      `Hello *${waUser.user_name || 'Enterprise Owner'}*! Here is what you can ask me:\n\n` +
      `💰 *1️⃣ Balance:* Instant real-time Account Summary\n` +
      `📄 *2️⃣ Statement:* Generate & download official PDF Khata Ledger report\n` +
      `🔔 *3️⃣ Remind:* Send WhatsApp reminders with UPI links directly to debtor customers\n` +
      `📥 *4️⃣ Receivables:* "Who owes me money?"\n` +
      `📤 *5️⃣ Payables:* "What bills are due?"\n` +
      `🧾 *6️⃣ Transactions:* "Show recent transactions"\n` +
      `📊 *7️⃣ Expenses:* "Top expense categories this month"\n` +
      `🔗 *8️⃣ App Handoff:* "Open app link"\n\n` +
      `_Reply with a keyword (e.g. *Balance*, *Statement*, *Remind*) or ask naturally!_ 🚀`;

    await sendWhatsAppMessage(phone, menu);
    return { reply: menu, state: 'IDLE' };
  }

  // Command: "Balance" / "Bal" -> Instant Account Summary
  if (lower === 'balance' || lower === 'bal' || lower === 'summary') {
    const kpiRes = await execGetFinancialKPIs(waUser.user_id, { period: 'this_month' });
    await sendWhatsAppMessage(phone, kpiRes.formatted);
    await logMessage({
      phoneNumber: phone,
      userId: waUser.user_id,
      direction: 'outbound',
      body: kpiRes.formatted,
      intent: 'GET_KPIS',
    });
    return { reply: kpiRes.formatted, intent: 'GET_KPIS', toolCalled: 'getFinancialKPIs', state: 'IDLE' };
  }

  // Command: "Statement" / "Ledger" / "Khata" -> Instant PDF Khata Ledger Report
  if (lower === 'statement' || lower === 'ledger' || lower === 'khata' || lower === 'pdf') {
    const stmt = await generateKhataStatementPdf(waUser.user_id, phone);
    // 1. Send the PDF document attachment directly through WhatsApp Cloud API
    await sendWhatsAppDocument(phone, stmt.downloadUrl, stmt.fileName, '📄 Official ENX Money Khata Ledger Statement');
    // 2. Also send companion text message with download link & summary
    await sendWhatsAppMessage(phone, stmt.summaryText);
    await logMessage({
      phoneNumber: phone,
      userId: waUser.user_id,
      direction: 'outbound',
      body: stmt.summaryText,
      intent: 'GENERATE_STATEMENT',
      toolCalls: ['generateKhataStatement'],
    });
    return {
      reply: stmt.summaryText,
      intent: 'GENERATE_STATEMENT',
      toolCalled: 'generateKhataStatement',
      downloadUrl: stmt.downloadUrl,
      fileName: stmt.fileName,
      state: 'IDLE',
    };
  }

  // Command: "Remind" / "Send Reminders" -> Direct WhatsApp Overdue Payment Reminders to Customers
  if (lower === 'remind' || lower === 'reminders' || lower === 'send reminders' || lower === 'due reminders') {
    const remRes = await scanAndSendOverdueReminders(waUser.user_id);
    await sendWhatsAppMessage(phone, remRes.summaryText);
    await logMessage({
      phoneNumber: phone,
      userId: waUser.user_id,
      direction: 'outbound',
      body: remRes.summaryText,
      intent: 'TRIGGER_REMINDERS',
      toolCalls: ['triggerOverdueCustomerReminders'],
    });
    return {
      reply: remRes.summaryText,
      intent: 'TRIGGER_REMINDERS',
      toolCalled: 'triggerOverdueCustomerReminders',
      count: remRes.count,
      state: 'IDLE',
    };
  }

  if (lower === 'unlink' || lower === 'logout') {
    await query('DELETE FROM whatsapp_users WHERE phone_number = ?', [phone]);
    await resetSession(phone);
    const unlinkedMsg = '🔓 Your WhatsApp account has been unlinked from ENX Money. Send any message to link again.';
    await sendWhatsAppMessage(phone, unlinkedMsg);
    return { reply: unlinkedMsg, state: 'UNLINKED' };
  }

  // 3. Process with AI Engine (Gemini / Grok / NLP Tools)
  const aiResult = await processUserMessage({
    userId: waUser.user_id,
    phoneNumber: phone,
    messageText: text,
    sessionState: session.state,
    contextData: session.context_data,
  });

  // Update session state
  await updateSessionState(phone, aiResult.newState || 'IDLE', aiResult.newContext || {}, aiResult.intent);

  // Send reply
  await sendWhatsAppMessage(phone, aiResult.text);

  // Log outbound AI response
  await logMessage({
    phoneNumber: phone,
    userId: waUser.user_id,
    direction: 'outbound',
    body: aiResult.text,
    intent: aiResult.intent,
    toolCalls: aiResult.toolCalled ? [aiResult.toolCalled] : null,
    aiProvider: process.env.GEMINI_API_KEY ? 'gemini' : 'offline-nlp',
  });

  return {
    reply: aiResult.text,
    intent: aiResult.intent,
    toolCalled: aiResult.toolCalled,
    state: aiResult.newState || 'IDLE',
  };
}

/**
 * 2. Meta WhatsApp Cloud API Inbound Webhook (POST /webhook)
 */
async function handleWebhook(req, res, next) {
  try {
    const body = req.body;

    if (body.object === 'whatsapp_business_account') {
      const entry = body.entry?.[0];
      const changes = entry?.changes?.[0];
      const value = changes?.value;
      const message = value?.messages?.[0];

      if (message && message.type === 'text') {
        const from = message.from;
        const text = message.text?.body;
        await processInboundMessage(from, text, body);
      }
      return res.status(200).send('EVENT_RECEIVED');
    }

    res.sendStatus(404);
  } catch (err) {
    next(err);
  }
}

/**
 * 3. Twilio WhatsApp Webhook (POST /twilio-webhook)
 */
async function handleTwilioWebhook(req, res, next) {
  try {
    const from = req.body.From || req.body.from;
    const body = req.body.Body || req.body.body;

    if (from && body) {
      const result = await processInboundMessage(from, body, req.body);
      return res.type('text/xml').send(`<Response><Message>${result.reply}</Message></Response>`);
    }

    res.status(400).json({ success: false, message: 'Missing From or Body.' });
  } catch (err) {
    next(err);
  }
}

/**
 * 4. Interactive Simulator API (POST /simulate)
 * Allows testing the bot in real time via the Web Simulator console.
 */
async function simulateMessage(req, res, next) {
  try {
    const { phoneNumber = '919876543210', message } = req.body;

    if (!message) {
      return res.status(400).json({ success: false, message: 'Message text is required.' });
    }

    const result = await processInboundMessage(phoneNumber, message, { source: 'web_simulator' });
    const waUser = await getWhatsAppUser(phoneNumber);

    res.json({
      success: true,
      data: {
        phoneNumber: normalizePhone(phoneNumber),
        user: waUser,
        reply: result.reply,
        intent: result.intent,
        toolCalled: result.toolCalled,
        sessionState: result.state,
        otpCode: result.otpCode,
        downloadUrl: result.downloadUrl,
        fileName: result.fileName,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * 5. GET /sessions - Lists all WhatsApp paired users and active sessions
 */
async function getSessions(req, res, next) {
  try {
    const users = await query(
      `SELECT w.*, u.name as user_name, u.email as user_email, s.state as session_state, s.last_intent
       FROM whatsapp_users w
       LEFT JOIN users u ON w.user_id = u.id
       LEFT JOIN whatsapp_sessions s ON w.phone_number = s.phone_number
       ORDER BY w.updated_at DESC`
    );
    res.json({ success: true, count: users.length, data: users });
  } catch (err) {
    next(err);
  }
}

/**
 * 6. GET /logs - Message audit trail
 */
async function getLogs(req, res, next) {
  try {
    const { phone, limit = 50 } = req.query;
    let sql = 'SELECT * FROM whatsapp_messages';
    const params = [];

    if (phone) {
      sql += ' WHERE phone_number = ?';
      params.push(normalizePhone(phone));
    }

    sql += ' ORDER BY created_at DESC LIMIT ?';
    params.push(parseInt(limit));

    const rows = await query(sql, params);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    next(err);
  }
}

/**
 * 7. POST /reminders/trigger - Trigger overdue receivable reminders scan
 */
async function triggerReminderScan(req, res, next) {
  try {
    const userId = req.user ? req.user.id : (req.body.userId || 'usr-admin-001');
    const sent = await scanAndSendOverdueReminders(userId);
    res.json({ success: true, message: `Dispatched ${sent.length} payment reminders.`, count: sent.length, data: sent });
  } catch (err) {
    next(err);
  }
}

/**
 * 8. GET /handoff/verify - Verifies single-use magic handoff token
 */
async function handleHandoffVerify(req, res, next) {
  try {
    const { token } = req.query;
    const result = await verifyAndConsumeToken(token);
    if (!result.valid) {
      return res.status(400).json({ success: false, message: result.message });
    }
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * 9. GET /handoff/open - Web landing page for deep linking fallback
 */
async function handleHandoffOpen(req, res, next) {
  try {
    const { token } = req.query;
    const result = await verifyAndConsumeToken(token);

    if (!result.valid) {
      return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>ENX Money Handoff Error</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0b0f19; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
            .card { background: #161f30; border: 1px solid #23324d; padding: 32px; border-radius: 16px; max-width: 440px; text-align: center; }
            h2 { color: #f87171; margin-top: 0; }
            p { color: #94a3b8; line-height: 1.6; }
            a { display: inline-block; margin-top: 16px; background: #3b82f6; color: #fff; text-decoration: none; padding: 10px 20px; border-radius: 8px; font-weight: 600; }
          </style>
        </head>
        <body>
          <div class="card">
            <h2>⚠️ Invalid or Expired Link</h2>
            <p>${result.message || 'This secure handoff token is no longer valid. Please request a new link on WhatsApp.'}</p>
            <a href="https://wa.me/919226860060?text=Hi%20ENX%20Money%20AI%20Assistant">Open Official WhatsApp Chatbot</a>
          </div>
        </body>
        </html>
      `);
    }

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>ENX Money - Secure Handoff</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #070a13; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
          .card { background: #111827; border: 1px solid #1f2937; padding: 36px; border-radius: 20px; max-width: 480px; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.5); }
          .icon { font-size: 48px; margin-bottom: 12px; }
          h2 { color: #10b981; margin: 0 0 8px 0; }
          p { color: #9ca3af; font-size: 15px; }
          .badge { background: #1f2937; color: #60a5fa; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; display: inline-block; margin: 12px 0; border: 1px solid #374151; }
          .btn { display: block; width: 100%; box-sizing: border-box; background: linear-gradient(135deg, #10b981, #059669); color: #fff; text-decoration: none; padding: 14px; border-radius: 12px; font-weight: 700; margin-top: 20px; font-size: 16px; box-shadow: 0 4px 14px rgba(16, 185, 129, 0.4); }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="icon">🚀</div>
          <h2>Authentication Successful!</h2>
          <p>Welcome, <strong>${result.user.name}</strong> (${result.user.email}).</p>
          <div class="badge">Target: ${result.targetScreen.toUpperCase()} SCREEN</div>
          <p>You have securely transitioned from WhatsApp to ENX Money with full authenticated privileges.</p>
          <a class="btn" href="https://wa.me/919226860060?text=Hi%20ENX%20Money%20AI%20Assistant">Return to WhatsApp Chat</a>
        </div>
      </body>
      </html>
    `);
  } catch (err) {
    next(err);
  }
}
/**
 * 10. GET /summary - Returns real-time financial KPI summary for the Web Portal
 */
async function apiGetSummary(req, res, next) {
  try {
    const userId = req.user ? req.user.id : (req.query.userId || 'usr-admin-001');
    const period = req.query.period || 'this_month';
    const kpis = await execGetFinancialKPIs(userId, { period });
    res.json({ success: true, data: kpis });
  } catch (err) {
    next(err);
  }
}

/**
 * 11. GET /statement - Generates & serves/downloads PDF Khata statement
 */
async function apiGenerateStatement(req, res, next) {
  try {
    const userId = req.user ? req.user.id : (req.query.userId || 'usr-admin-001');
    const phone = req.query.phone || '919876543210';
    const stmt = await generateKhataStatementPdf(userId, phone);
    if (req.query.redirect === 'true' || req.query.download === 'true') {
      return res.redirect(stmt.downloadUrl);
    }
    res.json({ success: true, data: stmt });
  } catch (err) {
    next(err);
  }
}

/**
 * 12. GET /customers/dues - Returns debtor customers with UPI & checkout links
 */
async function apiGetCustomerDues(req, res, next) {
  try {
    const userId = req.user ? req.user.id : (req.query.userId || 'usr-admin-001');
    const rows = await query(
      `SELECT c.id, c.name, c.company_name, c.phone,
              COALESCE(c.outstanding_balance, c.current_balance, 0) as due_amount,
              u.name as business_name
       FROM customers c
       LEFT JOIN users u ON c.user_id = u.id
       WHERE c.user_id = ? AND (c.outstanding_balance > 0 OR c.current_balance > 0)`,
      [userId]
    );
    const customers = rows.map(c => {
      const businessName = c.business_name || 'ENX Money Enterprise';
      const due = parseFloat(c.due_amount || 0);
      return {
        id: c.id,
        name: c.name,
        companyName: c.company_name,
        phone: c.phone,
        dueAmount: due,
        upiLink: `upi://pay?pa=enxmoney@upi&pn=${encodeURIComponent(businessName)}&am=${due.toFixed(2)}&cu=INR`,
        checkoutLink: `/checkout?amount=${due.toFixed(2)}&name=${encodeURIComponent(c.name)}&ref=${c.id}`,
      };
    });
    res.json({ success: true, count: customers.length, data: customers });
  } catch (err) {
    next(err);
  }
}

/**
 * 13. POST /reminders/send - Triggers overdue customer reminder scan & WhatsApp dispatch
 */
async function apiTriggerReminders(req, res, next) {
  try {
    const userId = req.user ? req.user.id : (req.body.userId || 'usr-admin-001');
    const result = await scanAndSendOverdueReminders(userId);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * 14. GET /users - Returns active WhatsApp paired users for simulator selector
 */
async function apiGetUsers(req, res, next) {
  try {
    const users = await query(
      `SELECT w.*, u.name as user_name, u.email as user_email
       FROM whatsapp_users w
       LEFT JOIN users u ON w.user_id = u.id
       ORDER BY w.updated_at DESC`
    );
    const formatted = (users && users.length > 0) ? users.map(u => ({
      phoneNumber: u.phone_number,
      userName: u.user_name || u.phone_number,
      email: u.user_email || '',
      companyName: u.company_name || 'ENX Enterprise',
    })) : [
      { phoneNumber: '919876543210', userName: 'Anjali Enterprise Admin', email: 'admin@enx.com', companyName: 'Anjali Enterprise' }
    ];
    res.json({ success: true, users: formatted });
  } catch (err) {
    res.json({
      success: true,
      users: [
        { phoneNumber: '919876543210', userName: 'Anjali Enterprise Admin', email: 'admin@enx.com', companyName: 'Anjali Enterprise' }
      ]
    });
  }
}

/**
 * 15. GET /chats & DELETE /chats - Persistent chat history for simulator
 */
async function apiGetChats(req, res, next) {
  try {
    const { phoneNumber } = req.query;
    let sql = 'SELECT * FROM whatsapp_messages';
    const params = [];
    if (phoneNumber) {
      sql += ' WHERE phone_number = ?';
      params.push(normalizePhone(phoneNumber));
    }
    sql += ' ORDER BY created_at ASC LIMIT 100';
    const rows = await query(sql, params);
    const chats = (rows || []).map(r => ({
      direction: r.direction || 'inbound',
      message: r.body || '',
      timestamp: r.created_at || new Date().toISOString()
    }));
    res.json({ success: true, chats });
  } catch (err) {
    res.json({ success: true, chats: [] });
  }
}

async function apiClearChats(req, res, next) {
  try {
    const { phoneNumber } = req.query;
    if (phoneNumber) {
      await query('DELETE FROM whatsapp_messages WHERE phone_number = ?', [normalizePhone(phoneNumber)]);
    } else {
      await query('DELETE FROM whatsapp_messages');
    }
    res.json({ success: true, message: 'Chats cleared successfully.' });
  } catch (err) {
    res.json({ success: true, message: 'Chats cleared.' });
  }
}

/**
 * 16. POST /link-account - Binds real phone number & business profile to WhatsApp user
 */
async function apiLinkAccount(req, res, next) {
  try {
    const { phoneNumber, userName, email, companyName, profileType } = req.body;
    const phone = normalizePhone(phoneNumber);
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Invalid phone number.' });
    }
    await query(
      `INSERT INTO whatsapp_users (id, phone_number, user_id, verification_status, user_name, user_email, updated_at)
       VALUES (?, ?, ?, 'verified', ?, ?, NOW())
       ON DUPLICATE KEY UPDATE user_name = VALUES(user_name), user_email = VALUES(user_email), verification_status = 'verified', updated_at = NOW()`,
      [`wa-${phone}`, phone, 'usr-admin-001', userName, email]
    );
    res.json({
      success: true,
      message: 'Account linked successfully.',
      user: {
        phoneNumber: phone,
        userName: userName,
        email: email,
        companyName: companyName || userName,
        profileType: profileType || 'business'
      }
    });
  } catch (err) {
    next(err);
  }
}

/**
 * 17. POST /transaction - Records quick custom expense or income via simulator
 */
async function apiAddTransaction(req, res, next) {
  try {
    const { phoneNumber = '919876543210', amount, title, type = 'expense', category, paymentMode = 'upi' } = req.body;
    const msg = `Add ${type} ${amount} for ${title} mode ${paymentMode}`;
    const result = await processInboundMessage(phoneNumber, msg, { source: 'custom_tx' });
    res.json({
      success: true,
      data: {
        reply: result.reply,
        transaction: { amount, title, type, category, paymentMode }
      }
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  verifyWebhook,
  handleWebhook,
  handleTwilioWebhook,
  simulateMessage,
  processInboundMessage,
  getSessions,
  getLogs,
  triggerReminderScan,
  handleHandoffVerify,
  handleHandoffOpen,
  apiGetSummary,
  apiGenerateStatement,
  apiGetCustomerDues,
  apiTriggerReminders,
  apiGetUsers,
  apiGetChats,
  apiClearChats,
  apiLinkAccount,
  apiAddTransaction,
};
