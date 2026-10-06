/**
 * WhatsApp Messaging Service
 * Dispatches outbound text and document messages via Meta WhatsApp Cloud API,
 * Twilio WhatsApp API, or the Web Simulator.
 */

// In-memory simulator message log for the browser test console
const simulatorOutbox = [];

/**
 * Sends a WhatsApp text message to a phone number.
 */
async function sendWhatsAppMessage(recipientPhone, messageText, options = {}) {
  const phone = String(recipientPhone).replace(/[^\d+]/g, '');
  const provider = (process.env.WHATSAPP_PROVIDER || 'simulator').toLowerCase(); // 'meta', 'twilio', 'simulator'

  // Log in-memory for simulator
  simulatorOutbox.push({
    id: `sim-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    recipientPhone: phone,
    text: messageText,
    type: 'text',
    timestamp: new Date().toISOString(),
    options,
  });

  // Trim simulator outbox to last 100 items
  if (simulatorOutbox.length > 100) simulatorOutbox.shift();

  // 1. Meta WhatsApp Cloud API (Graph API v21.0)
  const metaToken = process.env.WHATSAPP_ACCESS_TOKEN || process.env.WHATSAPP_META_TOKEN;
  if ((provider === 'meta' || provider === 'whatsapp_cloud') && metaToken && process.env.WHATSAPP_PHONE_NUMBER_ID) {
    try {
      const url = `https://graph.facebook.com/v21.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`;
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${metaToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: phone,
          type: 'text',
          text: { body: messageText },
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        console.warn('⚠️ Meta WhatsApp Cloud API responded with error:', data?.error?.message || res.statusText);
        return { success: false, provider: 'meta', error: data?.error?.message, data };
      }
      return { success: true, provider: 'meta', data };
    } catch (err) {
      console.error('Meta WhatsApp Cloud API network error:', err.message);
      return { success: false, provider: 'meta', error: err.message };
    }
  }

  // 2. Twilio WhatsApp API
  if (provider === 'twilio' && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    try {
      const auth = Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');
      const fromNumber = process.env.TWILIO_WHATSAPP_NUMBER || 'whatsapp:+14155238886';
      const toNumber = phone.startsWith('whatsapp:') ? phone : `whatsapp:+${phone}`;

      const params = new URLSearchParams();
      params.append('From', fromNumber);
      params.append('To', toNumber);
      params.append('Body', messageText);

      const res = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });
      const data = await res.json();
      return { success: res.ok, provider: 'twilio', data };
    } catch (err) {
      console.error('Twilio WhatsApp API error:', err.message);
      return { success: false, provider: 'twilio', error: err.message };
    }
  }

  // Default / Simulator Mode
  return {
    success: true,
    provider: 'simulator',
    message: 'Message delivered to WhatsApp Simulator.',
  };
}

/**
 * Sends a PDF or document attachment via Meta WhatsApp Cloud API.
 * Users directly receive the PDF document inside their WhatsApp conversation.
 */
async function sendWhatsAppDocument(recipientPhone, documentUrl, fileName = 'Statement.pdf', caption = '', options = {}) {
  const phone = String(recipientPhone).replace(/[^\d+]/g, '');
  const provider = (process.env.WHATSAPP_PROVIDER || 'simulator').toLowerCase();

  // Log in-memory for simulator
  simulatorOutbox.push({
    id: `sim-doc-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    recipientPhone: phone,
    text: caption || `📄 Document: ${fileName}`,
    type: 'document',
    documentUrl,
    fileName,
    caption,
    timestamp: new Date().toISOString(),
    options,
  });

  if (simulatorOutbox.length > 100) simulatorOutbox.shift();

  // 1. Meta WhatsApp Cloud API Document Delivery
  const metaToken = process.env.WHATSAPP_ACCESS_TOKEN || process.env.WHATSAPP_META_TOKEN;
  if ((provider === 'meta' || provider === 'whatsapp_cloud') && metaToken && process.env.WHATSAPP_PHONE_NUMBER_ID) {
    try {
      const url = `https://graph.facebook.com/v21.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`;
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${metaToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: phone,
          type: 'document',
          document: {
            link: documentUrl,
            caption: caption || fileName,
            filename: fileName,
          },
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        console.warn('⚠️ Meta WhatsApp Cloud API Document error:', data?.error?.message || res.statusText);
        return { success: false, provider: 'meta', error: data?.error?.message, data };
      }
      return { success: true, provider: 'meta', data };
    } catch (err) {
      console.error('Meta WhatsApp Document API error:', err.message);
      return { success: false, provider: 'meta', error: err.message };
    }
  }

  // 2. Twilio Media URL Fallback
  if (provider === 'twilio' && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    try {
      const auth = Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');
      const fromNumber = process.env.TWILIO_WHATSAPP_NUMBER || 'whatsapp:+14155238886';
      const toNumber = phone.startsWith('whatsapp:') ? phone : `whatsapp:+${phone}`;

      const params = new URLSearchParams();
      params.append('From', fromNumber);
      params.append('To', toNumber);
      params.append('Body', caption || `📄 Document: ${fileName}`);
      params.append('MediaUrl', documentUrl);

      const res = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });
      const data = await res.json();
      return { success: res.ok, provider: 'twilio', data };
    } catch (err) {
      console.error('Twilio WhatsApp Document error:', err.message);
      return { success: false, provider: 'twilio', error: err.message };
    }
  }

  return {
    success: true,
    provider: 'simulator',
    message: 'PDF document queued and rendered in WhatsApp Simulator.',
    documentUrl,
    fileName,
  };
}

/**
 * Gets simulator outbox messages for testing & dashboard.
 */
function getSimulatorMessages(phoneNumber = null) {
  if (phoneNumber) {
    const clean = String(phoneNumber).replace(/[^\d+]/g, '');
    return simulatorOutbox.filter(m => m.recipientPhone.includes(clean));
  }
  return simulatorOutbox;
}

/**
 * Clears simulator outbox.
 */
function clearSimulatorMessages() {
  simulatorOutbox.length = 0;
}

module.exports = {
  sendWhatsAppMessage,
  sendWhatsAppDocument,
  getSimulatorMessages,
  clearSimulatorMessages,
};
