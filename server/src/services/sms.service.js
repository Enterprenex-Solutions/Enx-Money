/**
 * Real International SMS OTP Service
 * Dispatches verification codes via Twilio, AWS SNS, or HTTP SMS Gateway with E.164 formatting.
 * Zero hardcoded or demo OTPs in production.
 */

const https = require('https');
const config = require('../config/env.config');

class SmsService {
  /**
   * Format phone number to international E.164 format (+[country code][number])
   * @param {string} phone 
   * @param {string} defaultCountryCode (default: +91)
   */
  static formatToE164(phone, defaultCountryCode = '+91') {
    if (!phone) return null;
    let clean = String(phone).replace(/[^0-9+]/g, '');
    if (clean.startsWith('+')) {
      return clean;
    }
    if (clean.startsWith('00')) {
      return '+' + clean.substring(2);
    }
    // Remove leading zero if present
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    const cleanDefault = defaultCountryCode.startsWith('+') ? defaultCountryCode : `+${defaultCountryCode}`;
    return `${cleanDefault}${clean}`;
  }

  /**
   * Validate if phone number complies with E.164 standard (+[1-9][0-9]{6,14})
   */
  static isValidE164(phone) {
    if (!phone) return false;
    return /^\+[1-9]\d{6,14}$/.test(phone);
  }

  /**
   * Check if AWS SNS or Twilio SMS provider is configured
   */
  static isSmsConfigured() {
    return !!(
      process.env.FAST2SMS_API_KEY ||
      config.SMS?.FAST2SMS_API_KEY ||
      (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) ||
      (config.SMS?.TWILIO_ACCOUNT_SID && config.SMS?.TWILIO_AUTH_TOKEN && config.SMS?.TWILIO_PHONE_NUMBER) ||
      (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) ||
      config.SMS?.GATEWAY_URL ||
      process.env.SMS_GATEWAY_URL
    );
  }

  /**
   * Dispatch real SMS OTP via Twilio, AWS SNS, or Gateway
   * @param {Object} options
   * @param {string} options.phone
   * @param {string} options.otp
   * @param {number} options.expiryMinutes
   */
  static async sendOtpSms(optionsOrPhone, maybeOtp, maybeExpiry = 5) {
    let phone, otp, expiryMinutes;
    if (typeof optionsOrPhone === 'object' && optionsOrPhone !== null) {
      phone = optionsOrPhone.phone;
      otp = optionsOrPhone.otp;
      expiryMinutes = optionsOrPhone.expiryMinutes || 5;
    } else {
      phone = optionsOrPhone;
      otp = maybeOtp;
      expiryMinutes = maybeExpiry || 5;
    }
    const formattedPhone = this.formatToE164(phone);
    if (!formattedPhone || !this.isValidE164(formattedPhone)) {
      return {
        success: false,
        error: 'INVALID_PHONE_NUMBER',
        message: 'Invalid international mobile phone number format.',
      };
    }

    const message = `Your ENX Money verification code is ${otp}. Valid for ${expiryMinutes} minutes. Never share this code with anyone.`;
    const maskedPhone = `${formattedPhone.slice(0, 4)}****${formattedPhone.slice(-2)}`;

    // 1. Check Fast2SMS (India's leading instant OTP SMS route)
    const fast2smsKey = process.env.FAST2SMS_API_KEY || config.SMS?.FAST2SMS_API_KEY;
    if (fast2smsKey) {
      try {
        const cleanNumber = formattedPhone.replace(/^\+91/, '').replace(/^0/, '');
        const postData = JSON.stringify({
          route: 'otp',
          variables_values: String(otp),
          numbers: cleanNumber,
        });

        const fastRes = await new Promise((resolve, reject) => {
          const req = https.request(
            {
              hostname: 'www.fast2sms.com',
              path: '/dev/bulkV2',
              method: 'POST',
              headers: {
                authorization: fast2smsKey,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData),
              },
              timeout: 8000,
            },
            (res) => {
              let data = '';
              res.on('data', (chunk) => (data += chunk));
              res.on('end', () => {
                try {
                  const parsed = JSON.parse(data);
                  if (parsed.return || parsed.status_code === 200) {
                    resolve(parsed);
                  } else {
                    reject(new Error(parsed.message || `Fast2SMS code ${parsed.status_code}`));
                  }
                } catch {
                  if (res.statusCode >= 200 && res.statusCode < 300) resolve({});
                  else reject(new Error(`Fast2SMS HTTP ${res.statusCode}: ${data}`));
                }
              });
            }
          );
          req.on('error', reject);
          req.on('timeout', () => {
            req.destroy();
            reject(new Error('Fast2SMS request timed out'));
          });
          req.write(postData);
          req.end();
        });

        console.log(`[SMS Service] Dispatched Fast2SMS OTP to ${maskedPhone}:`, fastRes.message || 'Success');
        return { success: true, provider: 'FAST2SMS', phone: formattedPhone };
      } catch (f2sError) {
        console.warn(`[SMS Service Warning] Fast2SMS dispatch failed: ${f2sError.message}`);
      }
    }

    // 2. Check Twilio (Native HTTPS / Port 443 — works seamlessly on all hosting)
    const twilioSid = config.SMS?.TWILIO_ACCOUNT_SID || process.env.TWILIO_ACCOUNT_SID;
    const twilioToken = config.SMS?.TWILIO_AUTH_TOKEN || process.env.TWILIO_AUTH_TOKEN;
    const twilioFrom = config.SMS?.TWILIO_PHONE_NUMBER || process.env.TWILIO_PHONE_NUMBER;

    if (twilioSid && twilioToken && twilioFrom) {
      try {
        const auth = Buffer.from(`${twilioSid}:${twilioToken}`).toString('base64');
        const postData = new URLSearchParams({
          To: formattedPhone,
          From: twilioFrom,
          Body: message,
        }).toString();

        await new Promise((resolve, reject) => {
          const req = https.request(
            {
              hostname: 'api.twilio.com',
              path: `/2010-04-01/Accounts/${twilioSid}/Messages.json`,
              method: 'POST',
              headers: {
                Authorization: `Basic ${auth}`,
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(postData),
              },
              timeout: 8000,
            },
            (res) => {
              let data = '';
              res.on('data', (chunk) => (data += chunk));
              res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                  try { resolve(JSON.parse(data)); } catch { resolve({}); }
                } else {
                  reject(new Error(`Twilio HTTP ${res.statusCode}: ${data}`));
                }
              });
            }
          );
          req.on('error', reject);
          req.on('timeout', () => {
            req.destroy();
            reject(new Error('Twilio request timed out'));
          });
          req.write(postData);
          req.end();
        });

        console.log(`[SMS Service] Dispatched Twilio OTP to ${maskedPhone}`);
        return { success: true, provider: 'TWILIO', phone: formattedPhone };
      } catch (twilioError) {
        console.warn(`[SMS Service Warning] Twilio dispatch failed: ${twilioError.message}`);
      }
    }

    // 2. Check AWS SNS
    if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
      try {
        let SNSClient, PublishCommand;
        try {
          const awsSns = require('@aws-sdk/client-sns');
          SNSClient = awsSns.SNSClient;
          PublishCommand = awsSns.PublishCommand;
        } catch {
          SNSClient = null;
        }

        if (SNSClient && PublishCommand) {
          const snsClient = new SNSClient({
            region: process.env.AWS_REGION || 'ap-south-1',
            credentials: {
              accessKeyId: process.env.AWS_ACCESS_KEY_ID,
              secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
            },
          });

          const command = new PublishCommand({
            PhoneNumber: formattedPhone,
            Message: message,
            MessageAttributes: {
              'AWS.SNS.SMS.SMSType': {
                DataType: 'String',
                StringValue: 'Transactional',
              },
            },
          });

          await snsClient.send(command);
          console.log(`[SMS Service] Dispatched AWS SNS OTP to ${maskedPhone}`);
          return { success: true, provider: 'AWS_SNS', phone: formattedPhone };
        }
      } catch (awsError) {
        console.warn(`[SMS Service Warning] AWS SNS dispatch failed: ${awsError.message}`);
      }
    }

    // 3. Generic webhook / HTTP SMS gateway (Fast2SMS / MSG91 / Textlocal)
    const gatewayUrl = config.SMS?.GATEWAY_URL || process.env.SMS_GATEWAY_URL;
    const gatewayKey = config.SMS?.GATEWAY_API_KEY || process.env.SMS_GATEWAY_API_KEY;

    if (gatewayUrl) {
      try {
        const url = new URL(gatewayUrl);
        const postData = JSON.stringify({
          phone: formattedPhone,
          message,
          otp,
        });

        await new Promise((resolve, reject) => {
          const req = https.request(
            {
              hostname: url.hostname,
              port: url.port || (url.protocol === 'https:' ? 443 : 80),
              path: url.pathname + url.search,
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData),
                ...(gatewayKey ? { Authorization: `Bearer ${gatewayKey}` } : {}),
              },
              timeout: 8000,
            },
            (res) => {
              res.resume();
              if (res.statusCode >= 200 && res.statusCode < 300) {
                resolve();
              } else {
                reject(new Error(`SMS Gateway HTTP ${res.statusCode}`));
              }
            }
          );
          req.on('error', reject);
          req.on('timeout', () => {
            req.destroy();
            reject(new Error('SMS Gateway timeout'));
          });
          req.write(postData);
          req.end();
        });

        console.log(`[SMS Service] Dispatched Gateway OTP to ${maskedPhone}`);
        return { success: true, provider: 'GATEWAY', phone: formattedPhone };
      } catch (gwErr) {
        console.warn(`[SMS Service Warning] Gateway dispatch failed: ${gwErr.message}`);
      }
    }

    // 4. In development or test environments, simulate cleanly
    if (process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test') {
      console.log(`[SMS Service DEV] Simulated SMS to ${maskedPhone}`);
      return { success: true, provider: 'SIMULATED_DEV', phone: formattedPhone };
    }

    return {
      success: false,
      error: 'SMS_SERVICE_UNAVAILABLE',
      message: 'SMS service is temporarily unavailable. Please verify via Email.',
    };
  }
}

module.exports = SmsService;
