/**
 * ENX Money — Entitlement Service
 * Central entitlement checking engine for subscription features & limits.
 */
const subscriptionModel = require('../models/subscription.model');

const FEATURE_CODES = {
  EXPENSE_TRACKING: 'EXPENSE_TRACKING',
  INCOME_TRACKING: 'INCOME_TRACKING',
  CUSTOM_CATEGORIES: 'CUSTOM_CATEGORIES',
  ADVANCED_REPORTS: 'ADVANCED_REPORTS',
  BANK_ACCOUNT: 'BANK_ACCOUNT',
  ACCOUNT_TRANSFER: 'ACCOUNT_TRANSFER',
  BUSINESS_EXPENSE: 'BUSINESS_EXPENSE',
  SETTLEMENT: 'SETTLEMENT',
  UPI: 'UPI',
  AUTOPAY: 'AUTOPAY',
  LOAN_MANAGEMENT: 'LOAN_MANAGEMENT',
  WHATSAPP_CHATBOT: 'WHATSAPP_CHATBOT',
  ADVANCED_ANALYTICS: 'ADVANCED_ANALYTICS',
  GST_REPORT: 'GST_REPORT',
  INVOICE_MANAGEMENT: 'INVOICE_MANAGEMENT',
  TEAM_MEMBER: 'TEAM_MEMBER',
  ROLE_MANAGEMENT: 'ROLE_MANAGEMENT',
  ADMIN_DASHBOARD: 'ADMIN_DASHBOARD',
  API_ACCESS: 'API_ACCESS',
  PRIORITY_SUPPORT: 'PRIORITY_SUPPORT',
};

/**
 * Check if a user is entitled to use a specific feature
 * @param {string|number} userId
 * @param {string} featureCode
 * @returns {Promise<{allowed: boolean, limit: number|null, plan_name: string}>}
 */
async function checkEntitlement(userId, featureCode) {
  await subscriptionModel.seedDefaultPlans();
  return subscriptionModel.checkEntitlement(userId, featureCode);
}

/**
 * Check numeric limit for a user's plan feature
 * @param {string|number} userId
 * @param {string} featureCode
 * @returns {Promise<number>}
 */
async function checkLimit(userId, featureCode) {
  await subscriptionModel.seedDefaultPlans();
  return subscriptionModel.checkLimit(userId, featureCode);
}

/**
 * Get all feature entitlements for a user
 * @param {string|number} userId
 * @returns {Promise<{plan: object, entitlements: object}>}
 */
async function getEntitlements(userId) {
  await subscriptionModel.seedDefaultPlans();
  return subscriptionModel.getEntitlements(userId);
}

module.exports = {
  FEATURE_CODES,
  checkEntitlement,
  checkLimit,
  getEntitlements,
};
