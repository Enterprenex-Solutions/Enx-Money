const express = require('express');
const AuthController = require('../controllers/auth.controller');
const { otpRateLimiter } = require('../middleware/rateLimiter.middleware');
const { authenticateToken } = require('../middleware/auth.middleware');
const {
  validateRegister,
  validateLogin,
  validateSendOtp,
  validateVerifyOtp,
  validateForgotPassword,
  validateVerifyResetOtp,
  validateResetPassword,
} = require('../middleware/validate.middleware');

const SecurityQuestionsController = require('../controllers/security_questions.controller');

const router = express.Router();

// Public Authentication Endpoints
router.post(['/check-registered', '/check-registered/', '/check-account', '/check-account/'], AuthController.checkRegistered);
router.post(['/register', '/register/'], validateRegister, AuthController.register);
router.post(['/login', '/login/'], validateLogin, AuthController.login);
router.post(['/send-otp', '/send-otp/'], otpRateLimiter, validateSendOtp, AuthController.sendOtp);
router.post(['/resend-otp', '/resend-otp/'], otpRateLimiter, validateSendOtp, AuthController.resendOtp);
router.post(['/verify-otp', '/verify-otp/'], validateVerifyOtp, AuthController.verifyOtp);
router.post(['/forgot-password', '/forgot-password/'], validateForgotPassword, AuthController.forgotPassword);
router.post(['/verify-reset-otp', '/verify-reset-otp/'], validateVerifyResetOtp, AuthController.verifyResetOtp);
router.post(['/reset-password', '/reset-password/'], validateResetPassword, AuthController.resetPassword);

// Security Questions & Password Recovery Endpoints
router.get('/security-questions', SecurityQuestionsController.getCatalog);
router.post('/security-questions/setup', authenticateToken, SecurityQuestionsController.setupQuestions);
router.post('/security-questions/get-for-user', SecurityQuestionsController.getForUser);
router.post('/security-questions/verify', SecurityQuestionsController.verifyAnswers);

// Protected Profile Endpoints
router.get('/me', authenticateToken, AuthController.getMe);
router.get('/profile', authenticateToken, AuthController.getMe);
router.get('/user', authenticateToken, AuthController.getMe);
router.post('/change-password', authenticateToken, AuthController.changePassword);
router.post('/verify-password', authenticateToken, AuthController.verifyPassword);
router.post('/logout', authenticateToken, AuthController.logout);
router.post(['/kyc/verify', '/kyc'], authenticateToken, AuthController.submitKyc);

// Google Play Account Deletion Policy Compliance Endpoints
router.delete(['/account', '/delete-account'], authenticateToken, AuthController.deleteAccount);
router.post(['/request-deletion', '/delete-request'], AuthController.requestDeletion);

// Multi-Device Login Approval & Device Management Endpoints
router.get(['/device-approval-status/:requestId', '/device-approval-status/:requestId/'], AuthController.checkDeviceApprovalStatus);
router.get(['/pending-device-approvals', '/pending-device-approvals/'], authenticateToken, AuthController.getPendingDeviceApprovals);
router.post(['/approve-device', '/approve-device/'], authenticateToken, AuthController.approveDevice);
router.post(['/reject-device', '/reject-device/'], authenticateToken, AuthController.rejectDevice);
router.get(['/devices', '/devices/'], authenticateToken, AuthController.getUserDevices);
router.delete(['/devices/:deviceId', '/devices/:deviceId/'], authenticateToken, AuthController.revokeDevice);

module.exports = router;
