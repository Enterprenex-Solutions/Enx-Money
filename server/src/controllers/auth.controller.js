const AuthService = require('../services/auth.service');
const { successResponse } = require('../utils/response.util');

class AuthController {
  /**
   * POST /api/v1/auth/register
   */
  static async register(req, res, next) {
    try {
      const { name, businessName, email, phone, password } = req.body;
      const result = await AuthService.register({ name, businessName, email, phone, password });
      return successResponse(res, {
        statusCode: 201,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/check-registered
   */
  static async checkRegistered(req, res, next) {
    try {
      const { email, phone } = req.body;
      const result = await AuthService.checkRegistered({ email, phone });
      return successResponse(res, {
        statusCode: 200,
        message: 'Account identifier is available.',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 409) {
        return res.status(409).json({
          success: false,
          statusCode: 409,
          message: error.message,
          error: error.code || 'ALREADY_REGISTERED',
          data: {
            field: error.field,
            isRegistered: true,
            matchedEmail: error.matchedEmail,
            matchedPhone: error.matchedPhone,
          },
        });
      }
      next(error);
    }
  }


  /**
   * POST /api/v1/auth/login
   */
  static async login(req, res, next) {
    try {
      const { identifier, email, password, deviceId, deviceName, platform } = req.body;
      const ipAddress = req.headers['x-forwarded-for'] || req.socket?.remoteAddress || req.ip;
      const result = await AuthService.loginWithPassword({
        identifier: identifier || email,
        password,
        deviceId,
        deviceName,
        platform,
        ipAddress,
      });

      if (result.requiresOtpVerification) {
        return successResponse(res, {
          statusCode: 200,
          message: result.message,
          data: {
            requiresOtpVerification: true,
            email: result.email,
          },
        });
      }

      if (result.requiresDeviceApproval) {
        return successResponse(res, {
          statusCode: 200,
          message: result.message,
          data: {
            requiresDeviceApproval: true,
            approvalRequestId: result.approvalRequestId,
            deviceId: result.deviceId,
            deviceName: result.deviceName,
            verificationCode: result.verificationCode,
            expiresAt: result.expiresAt,
          },
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Logged in successfully',
        data: {
          token: result.accessToken,
          ...result,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/verify-otp
   */
  static async verifyOtp(req, res, next) {
    try {
      const { email, phone, otp, purpose, deviceId, deviceName, platform, devicePlatform, name, businessName, password } = req.body;
      const ipAddress = req.headers['x-forwarded-for'] || req.socket?.remoteAddress || req.ip;
      const result = await AuthService.verifyOtp({
        email,
        phone,
        otp,
        purpose,
        deviceId,
        deviceName,
        platform: platform || devicePlatform,
        devicePlatform,
        ipAddress,
        name,
        businessName,
        password,
      });

      if (result.requiresDeviceApproval) {
        return successResponse(res, {
          statusCode: 200,
          message: result.message,
          data: {
            requiresDeviceApproval: true,
            approvalRequestId: result.approvalRequestId,
            deviceId: result.deviceId,
            deviceName: result.deviceName,
            verificationCode: result.verificationCode,
            expiresAt: result.expiresAt,
          },
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: {
          token: result.accessToken,
          ...result,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/send-otp
   */
  static async sendOtp(req, res, next) {
    try {
      const { email, phone, purpose } = req.body;
      const result = await AuthService.sendOtp({ email, phone, purpose });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: {
          email: result.email,
          phone: result.phone,
          expiryMinutes: result.expiryMinutes,
          cooldownSeconds: result.cooldownSeconds,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/resend-otp
   */
  static async resendOtp(req, res, next) {
    try {
      const { email, phone, purpose } = req.body;
      const result = await AuthService.resendOtp({ email, phone, purpose });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: {
          email: result.email,
          phone: result.phone,
          expiryMinutes: result.expiryMinutes,
          cooldownSeconds: result.cooldownSeconds,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/forgot-password
   */
  static async forgotPassword(req, res, next) {
    try {
      const { email, identifier } = req.body;
      const result = await AuthService.forgotPassword({ email, identifier: identifier || email });
      return successResponse(res, {
        statusCode: 200,
        message: 'Password reset OTP sent to your email',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/verify-reset-otp
   */
  static async verifyResetOtp(req, res, next) {
    try {
      const { email, identifier, otp } = req.body;
      const result = await AuthService.verifyResetOtp({ email, identifier: identifier || email, otp });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/reset-password
   */
  static async resetPassword(req, res, next) {
    try {
      const { email, identifier, otp, resetToken, newPassword } = req.body;
      const result = await AuthService.resetPassword({ email, identifier: identifier || email, otp, resetToken, newPassword });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/auth/me
   */
  static async getMe(req, res, next) {
    try {
      const result = await AuthService.getMe(req.user.id);
      return successResponse(res, {
        statusCode: 200,
        data: {
          user: result,
          ...result,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/change-password
   */
  static async changePassword(req, res, next) {
    try {
      const userId = req.user.userId || req.user.id;
      const { currentPassword, newPassword } = req.body;
      const result = await AuthService.changePassword({ userId, currentPassword, newPassword });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/verify-password
   */
  static async verifyPassword(req, res, next) {
    try {
      const userId = req.user.userId || req.user.id;
      const { password } = req.body;
      const result = await AuthService.verifyPassword({ userId, password });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/logout
   */
  static async logout(req, res, next) {
    try {
      const token = req.headers.authorization ? req.headers.authorization.split(' ')[1] : null;
      await AuthService.logout({ token, userId: req.user ? req.user.id : null });
      return successResponse(res, {
        statusCode: 200,
        message: 'Logged out successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/auth/account or /api/users/account
   */
  static async deleteAccount(req, res, next) {
    try {
      const userId = req.user.userId || req.user.id;
      const token = req.headers.authorization ? req.headers.authorization.split(' ')[1] : null;
      const result = await AuthService.deleteAccount(userId, token);
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: null,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/request-deletion or /api/users/request-deletion (Public external web request)
   */
  static async requestDeletion(req, res, next) {
    try {
      const { email, reason } = req.body;
      if (!email) {
        return res.status(400).json({ success: false, message: 'Email address is required' });
      }
      const result = await AuthService.requestDeletion({ email, reason });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: null,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/kyc or /api/auth/kyc/verify (Tokenized Reference KYC flow)
   */
  static async submitKyc(req, res, next) {
    try {
      const { documentType, documentReference, panNumber } = req.body;
      const result = await AuthService.submitKyc(req.user ? req.user.id : req.user?.sub, {
        documentType,
        documentReference,
        panNumber,
      });
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/auth/device-approval-status/:requestId
   */
  static async checkDeviceApprovalStatus(req, res, next) {
    try {
      const { requestId } = req.params;
      const result = await AuthService.checkDeviceApprovalStatus(requestId);
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/auth/pending-device-approvals
   */
  static async getPendingDeviceApprovals(req, res, next) {
    try {
      const userId = req.user.id || req.user.sub;
      const result = await AuthService.getPendingDeviceApprovals(userId);
      return successResponse(res, {
        statusCode: 200,
        message: 'Pending device approvals retrieved',
        data: { pendingApprovals: result },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/approve-device
   */
  static async approveDevice(req, res, next) {
    try {
      const userId = req.user.id || req.user.sub;
      const { requestId } = req.body;
      const result = await AuthService.approveDevice(userId, requestId);
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/reject-device
   */
  static async rejectDevice(req, res, next) {
    try {
      const userId = req.user.id || req.user.sub;
      const { requestId } = req.body;
      const result = await AuthService.rejectDevice(userId, requestId);
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/auth/devices
   */
  static async getUserDevices(req, res, next) {
    try {
      const userId = req.user.id || req.user.sub;
      const result = await AuthService.getUserDevices(userId);
      return successResponse(res, {
        statusCode: 200,
        message: 'User devices retrieved',
        data: { devices: result },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/v1/auth/devices/:deviceId
   */
  static async revokeDevice(req, res, next) {
    try {
      const userId = req.user.id || req.user.sub;
      const { deviceId } = req.params;
      const result = await AuthService.revokeDevice(userId, deviceId);
      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AuthController;
