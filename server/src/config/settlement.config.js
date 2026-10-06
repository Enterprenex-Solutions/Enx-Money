/**
 * ENX Money — Merchant Payout & Settlement Configuration
 * Configures the direct merchant settlement routing for all subscription plan transactions.
 */

const SETTLEMENT_CONFIG = {
  BENEFICIARY_NAME: process.env.SETTLEMENT_BENEFICIARY_NAME || 'Rohit Samadhan Pawar',
  BANK_NAME: process.env.SETTLEMENT_BANK_NAME || 'Jio Payments Bank',
  ACCOUNT_NUMBER: process.env.SETTLEMENT_ACCOUNT_NUMBER || '002021712159733',
  IFSC_CODE: process.env.SETTLEMENT_IFSC_CODE || 'JIOP0000001',
  URN_NUMBER: process.env.SETTLEMENT_URN_NUMBER || '92603438',
  CURRENCY: 'INR',
  GST_RATE: 18,
  MERCHANT_GSTIN: process.env.SETTLEMENT_GSTIN || '27AARCP9260R1Z2',
  BUSINESS_LEGAL_NAME: 'ENX Money (Enterprenex Solution Pvt Ltd)',
  BUSINESS_ADDRESS: 'Level 4, Cyber Gateway, Hitec City, Hyderabad, Telangana - 500081',
  SUPPORT_EMAIL: 'billing@enxmoney.com',
  MERCHANT_UPI_VPA: process.env.MERCHANT_UPI_VPA || '8767443493@jiopay',
  MERCHANT_UPI_LINK: process.env.MERCHANT_UPI_LINK || 'https://razorpay.me/@rohitsamadhanpawar4145',
};

/**
 * Returns metadata notes payload to attach to payment gateway orders / transfers
 */
function getSettlementMetadata(extra = {}) {
  return {
    beneficiary_name: SETTLEMENT_CONFIG.BENEFICIARY_NAME,
    bank_name: SETTLEMENT_CONFIG.BANK_NAME,
    account_number: SETTLEMENT_CONFIG.ACCOUNT_NUMBER,
    ifsc_code: SETTLEMENT_CONFIG.IFSC_CODE,
    urn_number: SETTLEMENT_CONFIG.URN_NUMBER,
    settlement_destination: 'MERCHANT_DIRECT_SETTLEMENT',
    payout_mode: 'DIRECT_BANK_SETTLEMENT',
    ...extra,
  };
}

module.exports = {
  SETTLEMENT_CONFIG,
  getSettlementMetadata,
};
