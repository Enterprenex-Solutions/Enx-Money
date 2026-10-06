const db = require('../config/db.config');

const _settingsStore = new Map();

function getDefaultSettings(userId = 'default_user') {
  return {
    userId,
    profile: {
      fullName: 'Krishna Dev',
      email: 'krishna.dev@enxmoney.com',
      mobileNumber: '9876543210',
      avatarUrl: '',
      language: 'English (India)',
      timezone: 'Asia/Kolkata (IST +5:30)',
    },
    business: {
      businessName: 'Krishna Textiles & Supplies',
      businessType: 'Private Limited',
      industry: 'Textiles & Apparel Supplies',
      gstin: '36AAACK1234F1Z5',
      pan: 'AAACK1234F',
      addressLine: 'Plot 42, Textile Park, Gachibowli',
      country: 'India',
      state: 'Telangana',
      district: 'Hyderabad',
      pincode: '500032',
      contactNumber: '9876543210',
      businessEmail: 'contact@krishnatextiles.com',
      financialYear: '2026-2027',
    },
    personal: {
      fullName: 'Krishna Dev',
      monthlyIncome: 150000,
      personalAddress: 'Flat 402, Green Meadows',
      country: 'India',
      state: 'Telangana',
      district: 'Hyderabad',
      pincode: '500081',
      personalEmail: 'krishna.personal@enxmoney.com',
      mobileNumber: '9876543210',
    },
    finance: {
      defaultCurrency: 'INR',
      currencySymbol: '₹',
      financialYear: '2026-2027',
      defaultAccount: 'HDFC Business Current Account',
      defaultPaymentMode: 'BANK_TRANSFER',
      decimalPlaces: 2,
      numberFormat: 'LAKHS_CRORES', // Indian numbering format
    },
    transactions: {
      defaultCategory: 'Sales & Invoices',
      defaultPaymentMode: 'UPI',
      defaultAccount: 'HDFC Business Current Account',
      requireConfirmation: true,
      allowEditing: true,
      autoGenerateRef: true,
    },
    gst: {
      isGstRegistered: true,
      gstin: '36AAACK1234F1Z5',
      businessState: 'Telangana',
      defaultGstRate: 18,
      compositionScheme: false,
      reverseCharge: false,
    },
    notifications: {
      transactionAlerts: true,
      lowStockAlerts: true,
      emiReminders: true,
      gstReminders: true,
      paymentReminders: true,
      reconciliationMismatch: true,
      recurringAlerts: true,
      weeklyReports: false,
      monthlyReports: true,
      emailNotifications: true,
      pushNotifications: true,
    },
    reports: {
      defaultReportPeriod: 'THIS_MONTH',
      pdfOrientation: 'PORTRAIT',
      excelFormat: 'CSV',
      scheduledEmailReports: true,
      weeklySchedule: 'MONDAY',
      monthlySchedule: '1ST_OF_MONTH',
    },
    security: {
      twoFactorEnabled: false,
      securityAlerts: true,
      sessionTimeoutMinutes: 60,
      lastPasswordChange: new Date().toISOString(),
    },
    application: {
      language: 'en-IN',
      timezone: 'Asia/Kolkata',
      dateFormat: 'DD/MM/YYYY',
      numberFormat: 'en-IN',
      theme: 'DARK',
    },
    dataPrivacy: {
      dataRetentionMonths: 84, // 7 Years statutory compliance
      auditLogging: true,
    },
    updatedAt: new Date().toISOString(),
  };
}

class SettingsModel {
  static async getByUserId(userId) {
    if (!_settingsStore.has(userId)) {
      _settingsStore.set(userId, getDefaultSettings(userId));
    }
    return _settingsStore.get(userId);
  }

  static async updateSection(userId, sectionName, data) {
    const current = await this.getByUserId(userId);
    if (!current[sectionName]) {
      current[sectionName] = {};
    }
    current[sectionName] = {
      ...current[sectionName],
      ...data,
    };
    current.updatedAt = new Date().toISOString();
    _settingsStore.set(userId, current);
    return current;
  }

  static async resetSection(userId, sectionName) {
    const defaults = getDefaultSettings(userId);
    const current = await this.getByUserId(userId);
    if (defaults[sectionName]) {
      current[sectionName] = defaults[sectionName];
      current.updatedAt = new Date().toISOString();
      _settingsStore.set(userId, current);
    }
    return current;
  }
}

module.exports = SettingsModel;
