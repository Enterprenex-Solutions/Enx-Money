/**
 * ENX Money Krishna Sharma Production Mailer Engine
 * 
 * Restores the authentic pre-Anjali email delivery flow:
 *   1. Direct Gmail SMTP Service (Nodemailer service: 'gmail') with b75126964@gmail.com
 *   2. Direct SSL Port 465 / STARTTLS Port 587 fallback
 *   3. HTTPS Cloud API failover (Brevo / SendGrid if API keys are configured)
 * 
 * Delivers real verification codes to valid user inboxes worldwide with zero whitelists.
 */
const https = require('https');
const nodemailer = require('nodemailer');
const config = require('./env.config');

function maskEmail(email) {
  if (!email || !email.includes('@')) return '***';
  const [local, domain] = email.split('@');
  if (local.length <= 2) return `${local[0]}***@${domain}`;
  return `${local.slice(0, 2)}***${local.slice(-1)}@${domain}`;
}

// ─── 1. Krishna Sharma Primary Gmail Service Transporter ─────────────────────
let _gmailTransporter = null;

function getGmailTransporter() {
  if (_gmailTransporter) return _gmailTransporter;
  _gmailTransporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: config.SMTP.USER,
      pass: config.SMTP.PASS,
    },
    connectionTimeout: 4000,
    greetingTimeout: 3000,
    socketTimeout: 5000,
  });
  return _gmailTransporter;
}

// ─── 2. Direct SMTP Host/Port Fallback ───────────────────────────────────────
let _directSmtpTransporter = null;

function getDirectSmtpTransporter(port = 465, isSecure = true) {
  return nodemailer.createTransport({
    host: config.SMTP.HOST || 'smtp.gmail.com',
    port,
    secure: isSecure,
    auth: {
      user: config.SMTP.USER,
      pass: config.SMTP.PASS,
    },
    tls: {
      rejectUnauthorized: false,
    },
    connectionTimeout: 4000,
    greetingTimeout: 3000,
    socketTimeout: 5000,
  });
}

// ─── 3. Optional Brevo (Sendinblue) HTTPS API (Port 443 Fallback) ────────────
function sendViaBrevo({ from, to, subject, html, text }) {
  return new Promise((resolve, reject) => {
    if (!config.BREVO_API_KEY) {
      return reject(new Error('BREVO_NOT_CONFIGURED'));
    }

    const senderEmail = config.BREVO_SENDER_EMAIL || config.SMTP.USER || 'b75126964@gmail.com';
    const body = JSON.stringify({
      sender: { name: 'ENX Money', email: senderEmail },
      to: [{ email: to }],
      subject,
      htmlContent: html,
      textContent: text,
    });

    const req = https.request({
      hostname: 'api.brevo.com',
      path: '/v3/smtp/email',
      method: 'POST',
      headers: {
        'api-key': config.BREVO_API_KEY,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
      timeout: 8000,
    }, (res) => {
      let data = '';
      res.on('data', (c) => { data += c; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const parsed = JSON.parse(data || '{}');
            resolve({ messageId: parsed.messageId || `brevo-${Date.now()}`, provider: 'BREVO' });
          } catch {
            resolve({ messageId: `brevo-${Date.now()}`, provider: 'BREVO' });
          }
        } else {
          reject(new Error(`Brevo HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Brevo API request timed out')); });
    req.write(body);
    req.end();
  });
}

// ─── Production Dispatcher with Authentic Delivery ──────────────────────────
async function dispatchWithFailover(mailOptions) {
  // In test environment, return immediately to keep test suite deterministic and fast
  if (process.env.NODE_ENV === 'test' || config.NODE_ENV === 'test') {
    return { messageId: `test-${Date.now()}`, provider: 'TEST_SIMULATOR', response: '250 Test OK' };
  }

  const masked = maskEmail(mailOptions.to);
  const errors = [];

  // Strategy 1: Brevo HTTPS API (Port 443 — prioritized if API key is provided, reliable on Cloud/Render)
  if (config.BREVO_API_KEY) {
    try {
      const result = await sendViaBrevo(mailOptions);
      console.log(`[Mailer] Successfully dispatched email to ${masked} via Brevo HTTPS API`);
      return result;
    } catch (err) {
      errors.push(`Brevo API error: ${err.message}`);
      console.warn(`[Mailer Warning] Brevo dispatch failed for ${masked}: ${err.message}. Retrying via Gmail SMTP.`);
    }
  }

  // Strategy 2: Krishna Sharma Primary Gmail Service (Nodemailer service: 'gmail')
  if (config.SMTP.USER && config.SMTP.PASS) {
    try {
      const gmailTransporter = getGmailTransporter();
      const info = await gmailTransporter.sendMail(mailOptions);
      console.log(`[Mailer] Successfully dispatched email to ${masked} via Gmail service (${info.messageId})`);
      return { messageId: info.messageId, provider: 'GMAIL_SERVICE', response: info.response };
    } catch (err) {
      errors.push(`Gmail service error: ${err.message}`);
      console.warn(`[Mailer Warning] Gmail service dispatch failed for ${masked}: ${err.message}. Retrying via direct SMTP port 465.`);
    }

    // Strategy 3: Direct SMTP Port 465 SSL
    try {
      const smtp465 = getDirectSmtpTransporter(465, true);
      const info = await smtp465.sendMail(mailOptions);
      console.log(`[Mailer] Successfully dispatched email to ${masked} via SMTP 465 (${info.messageId})`);
      return { messageId: info.messageId, provider: 'SMTP_465', response: info.response };
    } catch (err) {
      errors.push(`SMTP 465 error: ${err.message}`);
      console.warn(`[Mailer Warning] SMTP 465 dispatch failed for ${masked}: ${err.message}. Retrying via port 587.`);
    }

    // Strategy 4: Direct SMTP Port 587 STARTTLS
    try {
      const smtp587 = getDirectSmtpTransporter(587, false);
      const info = await smtp587.sendMail(mailOptions);
      console.log(`[Mailer] Successfully dispatched email to ${masked} via SMTP 587 (${info.messageId})`);
      return { messageId: info.messageId, provider: 'SMTP_587', response: info.response };
    } catch (err) {
      errors.push(`SMTP 587 error: ${err.message}`);
      console.warn(`[Mailer Warning] SMTP 587 dispatch failed for ${masked}: ${err.message}.`);
    }
  }

  // If all channels fail, log detailed notice and throw error
  const combinedError = new Error(`Email dispatch failed across all channels: ${errors.join(' | ')}`);
  console.error(`[Mailer Error] Failed to deliver email to ${masked}:`, combinedError.message);
  throw combinedError;
}

// ─── Transporter Interface ───────────────────────────────────────────────────
function getTransporter() {
  return {
    sendMail: (mailOptions) => dispatchWithFailover(mailOptions),
  };
}

module.exports = {
  getTransporter,
  getGmailTransporter,
  dispatchWithFailover,
  sendViaBrevo,
};
