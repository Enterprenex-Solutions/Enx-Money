const SettingsService = require('../services/settings.service');
const { successResponse } = require('../utils/response.util');

class SettingsController {
  static async getSettings(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const settings = await SettingsService.getSettings(userId);
      return successResponse(res, {
        statusCode: 200,
        message: 'Settings retrieved successfully',
        data: settings,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateProfile(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateProfile(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Profile settings updated successfully',
        data: updated.profile,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateBusiness(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateBusiness(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Business settings updated successfully',
        data: updated.business,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updatePersonal(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updatePersonal(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Personal settings updated successfully',
        data: updated.personal,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateFinance(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateFinance(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Finance settings updated successfully',
        data: updated.finance,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateTransactions(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateTransactions(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Transaction settings updated successfully',
        data: updated.transactions,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateGst(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateGst(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'GST settings updated successfully',
        data: updated.gst,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateNotifications(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateNotifications(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Notification settings updated successfully',
        data: updated.notifications,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateReports(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateReports(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Report settings updated successfully',
        data: updated.reports,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateSecurity(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateSecurity(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Security settings updated successfully',
        data: updated.security,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateApplication(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const updated = await SettingsService.updateApplication(userId, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Application settings updated successfully',
        data: updated.application,
      });
    } catch (error) {
      next(error);
    }
  }

  static async resetSection(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const { section } = req.body;
      const updated = await SettingsService.resetSection(userId, section);
      return successResponse(res, {
        statusCode: 200,
        message: `Section ${section} reset to default`,
        data: updated[section],
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = SettingsController;
