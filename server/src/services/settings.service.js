const SettingsModel = require('../models/settings.model');
const LocationService = require('./location.service');
const UserModel = require('../models/user.model');
const bcrypt = require('bcryptjs');

class SettingsService {
  static async getSettings(userId) {
    return SettingsModel.getByUserId(userId);
  }

  static async updateProfile(userId, data) {
    const { fullName, mobileNumber, language, timezone } = data;
    return SettingsModel.updateSection(userId, 'profile', {
      fullName,
      mobileNumber,
      language,
      timezone,
    });
  }

  static async updateBusiness(userId, data) {
    const {
      businessName,
      businessType,
      industry,
      gstin,
      pan,
      addressLine,
      country = 'India',
      state,
      district,
      pincode,
      contactNumber,
      businessEmail,
      financialYear,
    } = data;

    // Validate location hierarchy if provided
    if (state || district || pincode) {
      const locValidation = LocationService.validateLocationHierarchy({
        country,
        state,
        district,
        pincode,
      });
      if (!locValidation.valid) {
        const err = new Error(locValidation.message || 'Invalid business location hierarchy');
        err.statusCode = 400;
        throw err;
      }
    }

    return SettingsModel.updateSection(userId, 'business', {
      businessName,
      businessType,
      industry,
      gstin,
      pan,
      addressLine,
      country,
      state,
      district,
      pincode,
      contactNumber,
      businessEmail,
      financialYear,
    });
  }

  static async updatePersonal(userId, data) {
    const {
      fullName,
      monthlyIncome,
      personalAddress,
      country = 'India',
      state,
      district,
      pincode,
      personalEmail,
      mobileNumber,
    } = data;

    if (state || district || pincode) {
      const locValidation = LocationService.validateLocationHierarchy({
        country,
        state,
        district,
        pincode,
      });
      if (!locValidation.valid) {
        const err = new Error(locValidation.message || 'Invalid personal location hierarchy');
        err.statusCode = 400;
        throw err;
      }
    }

    return SettingsModel.updateSection(userId, 'personal', {
      fullName,
      monthlyIncome: Number(monthlyIncome) || 0,
      personalAddress,
      country,
      state,
      district,
      pincode,
      personalEmail,
      mobileNumber,
    });
  }

  static async updateFinance(userId, data) {
    return SettingsModel.updateSection(userId, 'finance', data);
  }

  static async updateTransactions(userId, data) {
    return SettingsModel.updateSection(userId, 'transactions', data);
  }

  static async updateGst(userId, data) {
    return SettingsModel.updateSection(userId, 'gst', data);
  }

  static async updateNotifications(userId, data) {
    return SettingsModel.updateSection(userId, 'notifications', data);
  }

  static async updateReports(userId, data) {
    return SettingsModel.updateSection(userId, 'reports', data);
  }

  static async updateSecurity(userId, data) {
    const { currentPassword, newPassword, twoFactorEnabled } = data;
    if (newPassword) {
      const user = await UserModel.findById(userId);
      if (user && user.password_hash) {
        const match = await bcrypt.compare(currentPassword, user.password_hash);
        if (!match) {
          const err = new Error('Current password does not match.');
          err.statusCode = 401;
          throw err;
        }
      }
      const newHash = await bcrypt.hash(newPassword, 10);
      await UserModel.updateUserDetails(userId, { passwordHash: newHash });
    }

    return SettingsModel.updateSection(userId, 'security', {
      twoFactorEnabled: Boolean(twoFactorEnabled),
      lastPasswordChange: new Date().toISOString(),
    });
  }

  static async updateApplication(userId, data) {
    return SettingsModel.updateSection(userId, 'application', data);
  }

  static async resetSection(userId, sectionName) {
    return SettingsModel.resetSection(userId, sectionName);
  }
}

module.exports = SettingsService;
