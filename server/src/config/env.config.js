const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT, 10) || 5000,

  DATABASE_URL: process.env.DATABASE_URL || '',

  // Database
  DB: {
    HOST: process.env.DB_HOST || 'localhost',
    PORT: parseInt(process.env.DB_PORT, 10) || 3306,
    USER: process.env.DB_USER || 'root',
    PASSWORD: process.env.DB_PASSWORD || '',
    NAME: process.env.DB_NAME || 'enx_money',
    CONNECTION_LIMIT: parseInt(process.env.DB_CONNECTION_LIMIT, 10) || 10,
  },

  // JWT
  JWT: {
    SECRET: process.env.JWT_SECRET || 'enx_money_super_secret_jwt_key_2026',
    EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  },

  // OTP & Security
  OTP: {
    EXPIRY_MINUTES: parseInt(process.env.OTP_EXPIRY_MINUTES, 10) || 5,
    RESEND_COOLDOWN_SECONDS: parseInt(process.env.OTP_RESEND_COOLDOWN_SECONDS, 10) || 60,
    MAX_VERIFY_ATTEMPTS: parseInt(process.env.OTP_MAX_VERIFY_ATTEMPTS, 10) || 5,
  },

  // Multi-Channel Transactional Email Providers (HTTPS / Port 443)
  BREVO_API_KEY: process.env.BREVO_API_KEY || process.env.SENDINBLUE_API_KEY || '',
  BREVO_SENDER_EMAIL: process.env.BREVO_SENDER_EMAIL || 'support@enterprenex.solutions',
  SENDGRID_API_KEY: process.env.SENDGRID_API_KEY || '',

  // Mailer (SMTP — port 465 SSL or 587 STARTTLS)
  SMTP: {
    HOST: process.env.SMTP_HOST || 'smtp.gmail.com',
    PORT: parseInt(process.env.SMTP_PORT, 10) || 465,
    SECURE: process.env.SMTP_SECURE !== 'false',
    USER: process.env.SMTP_USER || 'b75126964@gmail.com',
    PASS: process.env.SMTP_PASS || 'bucymvqwsdazcofc',
    FROM: process.env.EMAIL_FROM || 'ENX Money <support@enterprenex.solutions>',
  },

  // SMS Configuration (Fast2SMS / Twilio / AWS SNS / Generic Gateway)
  SMS: {
    FAST2SMS_API_KEY: process.env.FAST2SMS_API_KEY || '',
    TWILIO_ACCOUNT_SID: process.env.TWILIO_ACCOUNT_SID || '',
    TWILIO_AUTH_TOKEN: process.env.TWILIO_AUTH_TOKEN || '',
    TWILIO_PHONE_NUMBER: process.env.TWILIO_PHONE_NUMBER || '',
    GATEWAY_URL: process.env.SMS_GATEWAY_URL || '',
    GATEWAY_API_KEY: process.env.SMS_GATEWAY_API_KEY || '',
  },

  // CORS
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',

  // Company & Compliance Contact
  COMPANY_NAME: process.env.COMPANY_NAME || 'Enterprenex Solutions Pvt. Ltd.',
  COMPANY_ADDRESS: process.env.COMPANY_ADDRESS || 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
  SUPPORT_EMAIL: process.env.SUPPORT_EMAIL || 'support@enterprenex.solutions',
  TECHNICAL_SUPPORT_EMAIL: process.env.TECHNICAL_SUPPORT_EMAIL || 'support@enterprenex.solutions',
  BILLING_EMAIL: process.env.BILLING_EMAIL || 'billing@enterprenex.solutions',
  COMPANY_EMAIL: process.env.COMPANY_EMAIL || 'info@enterprenex.solutions',
  SUPPORT_PHONE: process.env.SUPPORT_PHONE || '+91-9226860060',
  COMPANY_PHONE: process.env.COMPANY_PHONE || '+91-9226860060',
  PRIVACY_CONTACT_EMAIL: process.env.PRIVACY_CONTACT_EMAIL || 'privacy@enxmoney.com',
  GRIEVANCE_OFFICER: process.env.GRIEVANCE_OFFICER || 'Mr. Rohit Pawar',
  GRIEVANCE_EMAIL: process.env.GRIEVANCE_EMAIL || 'grievance@enxmoney.com',
  LEGAL_CONTACT_EMAIL: process.env.LEGAL_CONTACT_EMAIL || 'info@enterprenex.solutions',
  WEBSITE_DOMAIN: process.env.WEBSITE_DOMAIN || 'https://enxmoney.enterprenex.solutions',
  LEGAL_HOST_URL: process.env.LEGAL_HOST_URL || 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/',

  // Privacy Policy Configuration
  PRIVACY_POLICY_VERSION: process.env.PRIVACY_POLICY_VERSION || '1.0',
  PRIVACY_POLICY_EFFECTIVE_DATE: process.env.PRIVACY_POLICY_EFFECTIVE_DATE || 'October 4, 2026',
  PRIVACY_POLICY_LAST_UPDATED: process.env.PRIVACY_POLICY_LAST_UPDATED || 'October 4, 2026',

  // Legal & Terms Configuration
  TERMS_VERSION: process.env.TERMS_VERSION || '1.0',
  TERMS_EFFECTIVE_DATE: process.env.TERMS_EFFECTIVE_DATE || 'October 4, 2026',
  TERMS_LAST_UPDATED: process.env.TERMS_LAST_UPDATED || 'October 4, 2026',
  GOVERNING_LAW: process.env.GOVERNING_LAW || 'Laws of the Republic of India',
  JURISDICTION: process.env.JURISDICTION || 'Courts of competent jurisdiction in Chhatrapati Sambhajinagar, Maharashtra, India',

  // Refund Policy Configuration
  REFUND_POLICY_VERSION: process.env.REFUND_POLICY_VERSION || '1.0',
  REFUND_POLICY_EFFECTIVE_DATE: process.env.REFUND_POLICY_EFFECTIVE_DATE || 'October 4, 2026',
  REFUND_POLICY_LAST_UPDATED: process.env.REFUND_POLICY_LAST_UPDATED || 'October 4, 2026',
  REFUND_WINDOW_DAYS: parseInt(process.env.REFUND_WINDOW_DAYS, 10) || 7,
};
