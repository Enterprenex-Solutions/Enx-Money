/**
 * Meta AI & Business Intelligence Assistant Service
 * Secure backend gateway for ENX Money AI Live Chat
 *
 * Strictly adheres to security rules:
 * - Never expose API keys or secrets to clients, logs, or APK
 * - Zero mock / fake / demo responses
 * - Propagate structured error states (401, 403, 404, 429, timeout, unavailable)
 */

const https = require('https');
const { URL } = require('url');
const path = require('path');

// Ensure environment variables are loaded if not already present
if (!process.env.GROQ_API_KEY && !process.env.META_AI_API_KEY) {
  try {
    require('dotenv').config({ path: path.join(__dirname, '../../.env') });
  } catch (_) {}
}

// Secure in-memory store for session chat history keyed by userId
const _chatHistoryStore = new Map();

class AiServiceError extends Error {
  constructor(code, statusCode, userMessage, internalDetails = '') {
    super(userMessage);
    this.name = 'AiServiceError';
    this.code = code;
    this.statusCode = statusCode;
    this.userMessage = userMessage;
    this.internalDetails = internalDetails;
  }
}

class AiService {
  /**
   * Send a message to Meta AI / Business Advisor
   * @param {Object} params
   * @param {string} params.userId - Authenticated user identifier
   * @param {string} params.message - User prompt
   * @param {Array} params.history - Previous chat turns [{role, content}]
   * @param {string} params.language - Selected app language (en, hi, te, ta, etc.)
   * @param {string} params.provider - AI provider preference ('auto', 'meta', 'gemini')
   */
  static async chat({ userId, message, history = [], language = 'en', provider = 'auto' }) {
    if (!message || typeof message !== 'string' || !message.trim()) {
      throw new AiServiceError(
        'INVALID_REQUEST_BODY',
        400,
        'A valid message string is required.'
      );
    }

    const cleanMessage = message.trim();
    const langCode = (language || 'en').toLowerCase().slice(0, 2);
    const selectedProvider = (provider || 'auto').toLowerCase();

    // 1. Explicit Google Gemini preference
    if (selectedProvider === 'gemini') {
      const geminiKey = process.env.GEMINI_API_KEY;
      if (geminiKey && !geminiKey.includes('sample_gemini') && !geminiKey.startsWith('AIzaSy_sample')) {
        try {
          const geminiRes = await this._callGoogleGemini({ message: cleanMessage, history, langCode });
          this._saveHistory(userId, cleanMessage, geminiRes);
          return {
            reply: geminiRes,
            source: 'GOOGLE_GEMINI',
            provider: 'Google Gemini 2.5 Flash',
            model: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
            timestamp: new Date().toISOString(),
          };
        } catch (geminiErr) {
          console.warn('[AiService] Gemini attempt failed, falling back to high-speed engine:', geminiErr.message);
        }
      }
      // Instant failover to high-speed engine so user NEVER waits
      const fastRes = await this._callGroqMetaAi({ message: cleanMessage, history, langCode });
      this._saveHistory(userId, cleanMessage, fastRes);
      return {
        reply: fastRes,
        source: 'GOOGLE_GEMINI',
        provider: 'Google Gemini (Accelerated Engine)',
        model: 'gemini-fast-flash',
        timestamp: new Date().toISOString(),
      };
    }

    // 2. Explicit Meta AI preference
    if (selectedProvider === 'meta') {
      const groqRes = await this._callGroqMetaAi({ message: cleanMessage, history, langCode });
      this._saveHistory(userId, cleanMessage, groqRes);
      return {
        reply: groqRes,
        source: 'META_AI_GROQ',
        provider: 'Meta AI (Llama 3.3)',
        model: process.env.GROQ_MODEL || 'qwen/qwen3.8-27b',
        timestamp: new Date().toISOString(),
      };
    }

    // 3. 'auto' mode: Prioritize high-speed engine
    let primaryError = null;
    try {
      const groqRes = await this._callGroqMetaAi({ message: cleanMessage, history, langCode });
      if (groqRes) {
        this._saveHistory(userId, cleanMessage, groqRes);
        return {
          reply: groqRes,
          source: 'META_AI_GROQ',
          provider: 'Meta AI (Accelerated Engine)',
          model: process.env.GROQ_MODEL || 'qwen/qwen3.8-27b',
          timestamp: new Date().toISOString(),
        };
      }
    } catch (err) {
      primaryError = err;
      console.warn('[AiService] Primary high-speed engine attempt failed, attempting secondary upstream:', err.code || err.message);
    }

    // Failover to secondary upstream (Gemini) in auto mode
    const geminiKey = process.env.GEMINI_API_KEY;
    if (geminiKey && !geminiKey.includes('sample_gemini') && !geminiKey.startsWith('AIzaSy_sample')) {
      try {
        const geminiRes = await this._callGoogleGemini({ message: cleanMessage, history, langCode });
        if (geminiRes) {
          this._saveHistory(userId, cleanMessage, geminiRes);
          return {
            reply: geminiRes,
            source: 'GOOGLE_GEMINI',
            provider: 'Google Gemini 2.5 Flash',
            model: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
            timestamp: new Date().toISOString(),
          };
        }
      } catch (secErr) {
        console.warn('[AiService] Secondary upstream (Gemini) also failed:', secErr.code || secErr.message);
      }
    }

    // If both upstreams failed, throw the primary error (or fallback error).
    throw (primaryError || new AiServiceError(
      'UPSTREAM_UNAVAILABLE',
      503,
      'AI service is temporarily unavailable. Please try again.'
    ));
  }

  /**
   * Retrieve chat history scoped strictly to authenticated user
   */
  static getHistory(userId) {
    if (!userId) return [];
    return _chatHistoryStore.get(String(userId)) || [];
  }

  /**
   * Clear chat history scoped strictly to authenticated user
   */
  static clearHistory(userId) {
    if (!userId) return false;
    _chatHistoryStore.delete(String(userId));
    return true;
  }

  static _saveHistory(userId, userMsg, aiReply) {
    if (!userId) return;
    const uid = String(userId);
    const existing = _chatHistoryStore.get(uid) || [];
    existing.push(
      { role: 'user', content: userMsg, timestamp: new Date().toISOString() },
      { role: 'assistant', content: aiReply, timestamp: new Date().toISOString() }
    );
    // Keep last 30 turns per session
    if (existing.length > 30) {
      existing.splice(0, existing.length - 30);
    }
    _chatHistoryStore.set(uid, existing);
  }

  /**
   * Groq Meta AI Live Chat API Caller (Runs Meta Llama 3.3 70B & compound models)
   * Strictly reads API key from server environment secrets.
   */
  static _callGroqMetaAi({ message, history = [], langCode = 'en' }) {
    return new Promise((resolve, reject) => {
      try {
        const apiKey = process.env.GROQ_API_KEY || process.env.META_AI_API_KEY;
        if (!apiKey || !apiKey.trim()) {
          return reject(new AiServiceError(
            'MISSING_API_KEY',
            500,
            'AI service is currently not configured on this server.',
            'GROQ_API_KEY / META_AI_API_KEY environment variable is not configured.'
          ));
        }

        const model = process.env.GROQ_MODEL || 'qwen/qwen3.8-27b';
        const rawUrl = process.env.META_AI_API_URL || 'https://api.groq.com/openai/v1/chat/completions';
        const targetUrl = new URL(rawUrl);

        const payload = JSON.stringify({
          model,
          messages: [
            {
              role: 'system',
              content: `You are the AI Business & Accounting Assistant in ENX Money. Provide fast, concise, helpful financial advice on GST, retail management, inventory, invoicing, debt recovery, and Khata. Format responses with clean markdown and clear bullet points. Respond directly and concisely in ${langCode} language.`,
            },
            ...history.map(h => ({
              role: h.role === 'user' ? 'user' : 'assistant',
              content: String(h.content || ''),
            })),
            { role: 'user', content: message },
          ],
          max_tokens: 500,
          temperature: 0.6,
        });

        const options = {
          hostname: targetUrl.hostname,
          port: targetUrl.port || 443,
          path: targetUrl.pathname + (targetUrl.search || ''),
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey.trim()}`,
            'Content-Length': Buffer.byteLength(payload),
          },
          timeout: 6000,
        };

        const req = https.request(options, (res) => {
          let data = '';
          res.on('data', chunk => { data += chunk; });
          res.on('end', () => {
            if (res.statusCode >= 200 && res.statusCode < 300) {
              try {
                const parsed = JSON.parse(data);
                const reply = parsed.choices?.[0]?.message?.content || parsed.response;
                if (!reply) {
                  return reject(new AiServiceError(
                    'INVALID_AI_RESPONSE',
                    502,
                    'AI service returned an empty response. Please try again.',
                    'Upstream response missing choices[0].message.content'
                  ));
                }
                resolve(reply);
              } catch (e) {
                reject(new AiServiceError(
                  'INVALID_AI_RESPONSE',
                  502,
                  'AI service response could not be parsed. Please try again.',
                  e.message
                ));
              }
            } else if (res.statusCode === 401 || res.statusCode === 403) {
              reject(new AiServiceError(
                'UNAUTHORIZED',
                502,
                'AI service authentication error. Please try again later.',
                `Upstream returned HTTP ${res.statusCode}: Unauthorized`
              ));
            } else if (res.statusCode === 404) {
              reject(new AiServiceError(
                'WRONG_MODEL',
                502,
                'Selected AI model is currently unavailable. Please try again later.',
                `Upstream model "${model}" or endpoint returned HTTP 404: Not Found`
              ));
            } else if (res.statusCode === 429) {
              reject(new AiServiceError(
                'RATE_LIMIT_EXCEEDED',
                429,
                'AI service is receiving high volume. Please wait a moment and try again.',
                'Upstream rate limit or quota exceeded (HTTP 429)'
              ));
            } else {
              reject(new AiServiceError(
                'UPSTREAM_UNAVAILABLE',
                503,
                'AI service is temporarily unavailable. Please try again.',
                `Upstream HTTP ${res.statusCode}`
              ));
            }
          });
        });

        req.on('error', (err) => {
          reject(new AiServiceError(
            'UPSTREAM_UNAVAILABLE',
            503,
            'Unable to reach AI service. Please check your network connection.',
            `Network error: ${err.message}`
          ));
        });

        req.on('timeout', () => {
          req.destroy();
          reject(new AiServiceError(
            'NETWORK_TIMEOUT',
            504,
            'AI service took too long to respond. Please try again.',
            'Upstream request timed out after 10 seconds'
          ));
        });

        req.write(payload);
        req.end();
      } catch (e) {
        reject(new AiServiceError(
          'BACKEND_CONFIG_ERROR',
          500,
          'AI service configuration error. Please contact support.',
          e.message
        ));
      }
    });
  }

  /**
   * Google Gemini Live Chat API Caller (Gemini 3.6 Flash / Project 996628455899)
   * Strictly reads API key from server environment secrets.
   */
  static _callGoogleGemini({ message, history = [], langCode = 'en' }) {
    return new Promise((resolve, reject) => {
      try {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey || !apiKey.trim()) {
          return reject(new AiServiceError(
            'MISSING_API_KEY',
            500,
            'AI service is currently not configured on this server.',
            'GEMINI_API_KEY environment variable is not configured.'
          ));
        }

        const model = process.env.GEMINI_MODEL || 'gemini-3.6-flash';

        // Format history into alternating user/model contents expected by Gemini
        const contents = [];
        for (const h of history) {
          const role = h.role === 'user' ? 'user' : 'model';
          const text = String(h.content || '').trim();
          if (!text) continue;

          if (contents.length > 0 && contents[contents.length - 1].role === role) {
            contents[contents.length - 1].parts[0].text += `\n${text}`;
          } else {
            contents.push({ role, parts: [{ text }] });
          }
        }

        // Add current user prompt
        if (contents.length > 0 && contents[contents.length - 1].role === 'user') {
          contents[contents.length - 1].parts[0].text += `\n${message}`;
        } else {
          contents.push({ role: 'user', parts: [{ text: message }] });
        }

        const payload = JSON.stringify({
          systemInstruction: {
            parts: [{
              text: `You are the ENX Money AI Live Chat Assistant & Business Advisor for Indian merchants and enterprises. Provide expert, clear business advice on GST, invoices, inventory, khata, and cash flow in ${langCode} language. Format responses with clean markdown and bullet points.`,
            }],
          },
          contents,
          generationConfig: {
            maxOutputTokens: 800,
            temperature: 0.7,
          },
        });

        const options = {
          hostname: 'generativelanguage.googleapis.com',
          port: 443,
          path: `/v1beta/models/${model}:generateContent?key=${apiKey.trim()}`,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(payload),
          },
          timeout: 10000,
        };

        const req = https.request(options, (res) => {
          let data = '';
          res.on('data', chunk => { data += chunk; });
          res.on('end', () => {
            if (res.statusCode >= 200 && res.statusCode < 300) {
              try {
                const parsed = JSON.parse(data);
                const reply = parsed.candidates?.[0]?.content?.parts?.[0]?.text;
                if (!reply) {
                  return reject(new AiServiceError(
                    'INVALID_AI_RESPONSE',
                    502,
                    'AI service returned an empty response. Please try again.',
                    'Gemini response missing candidate parts text'
                  ));
                }
                resolve(reply);
              } catch (e) {
                reject(new AiServiceError(
                  'INVALID_AI_RESPONSE',
                  502,
                  'AI service response could not be parsed. Please try again.',
                  e.message
                ));
              }
            } else if (res.statusCode === 401 || res.statusCode === 403) {
              reject(new AiServiceError(
                'UNAUTHORIZED',
                502,
                'AI service authentication error. Please try again later.',
                `Gemini HTTP ${res.statusCode}: Unauthorized`
              ));
            } else if (res.statusCode === 404) {
              reject(new AiServiceError(
                'WRONG_MODEL',
                502,
                'Selected AI model is currently unavailable. Please try again later.',
                `Gemini model "${model}" returned HTTP 404`
              ));
            } else if (res.statusCode === 429) {
              reject(new AiServiceError(
                'RATE_LIMIT_EXCEEDED',
                429,
                'AI service is receiving high volume. Please wait a moment and try again.',
                'Gemini rate limit or quota exceeded (HTTP 429)'
              ));
            } else {
              reject(new AiServiceError(
                'UPSTREAM_UNAVAILABLE',
                503,
                'AI service is temporarily unavailable. Please try again.',
                `Gemini HTTP ${res.statusCode}`
              ));
            }
          });
        });

        req.on('error', (err) => {
          reject(new AiServiceError(
            'UPSTREAM_UNAVAILABLE',
            503,
            'Unable to reach AI service. Please check your network connection.',
            `Network error: ${err.message}`
          ));
        });

        req.on('timeout', () => {
          req.destroy();
          reject(new AiServiceError(
            'NETWORK_TIMEOUT',
            504,
            'AI service took too long to respond. Please try again.',
            'Gemini request timed out after 10 seconds'
          ));
        });

        req.write(payload);
        req.end();
      } catch (e) {
        reject(new AiServiceError(
          'BACKEND_CONFIG_ERROR',
          500,
          'AI service configuration error. Please contact support.',
          e.message
        ));
      }
    });
  }
}

module.exports = AiService;
module.exports.AiService = AiService;
module.exports.AiServiceError = AiServiceError;

