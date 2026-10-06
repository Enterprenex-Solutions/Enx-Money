const { body, validationResult } = require('express-validator');
const { errorResponse } = require('../utils/response.util');

/**
 * Middleware to check validation results
 */
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return errorResponse(res, {
      statusCode: 400,
      message: 'Validation failed',
      errors: errors.array().map((err) => ({
        field: err.path || err.param,
        message: err.msg,
      })),
    });
  }
  next();
}

const normalizeIdentifier = (req, res, next) => {
  if (req.body.identifier && !req.body.email && !req.body.phone) {
    const trimmed = String(req.body.identifier).trim();
    if (trimmed.includes('@')) {
      req.body.email = trimmed;
    } else {
      req.body.phone = trimmed;
    }
  }
  next();
};

/**
 * Validation rules for sending/resending OTP
 */
const validateSendOtp = [
  normalizeIdentifier,
  body('email')
    .optional({ values: 'falsy' })
    .trim()
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail({ gmail_remove_dots: false }),
  body('phone')
    .optional({ values: 'falsy' })
    .trim()
    .isMobilePhone('any', { strictMode: false })
    .withMessage('Please provide a valid mobile number'),
  body().custom((value, { req }) => {
    if (!req.body.email && !req.body.phone) {
      throw new Error('Either email or phone number is required to receive OTP');
    }
    return true;
  }),
  handleValidationErrors,
];

/**
 * Validation rules for verifying OTP
 */
const validateVerifyOtp = [
  normalizeIdentifier,
  body('email')
    .optional({ values: 'falsy' })
    .trim()
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail({ gmail_remove_dots: false }),
  body('phone')
    .optional({ values: 'falsy' })
    .trim()
    .isMobilePhone('any', { strictMode: false })
    .withMessage('Please provide a valid mobile number'),
  body('otp')
    .trim()
    .notEmpty()
    .withMessage('OTP is required')
    .isLength({ min: 6, max: 6 })
    .withMessage('OTP must be exactly 6 digits')
    .isNumeric()
    .withMessage('OTP must contain digits only'),
  body().custom((value, { req }) => {
    if (!req.body.email && !req.body.phone) {
      throw new Error('Either email or phone number is required to verify OTP');
    }
    return true;
  }),
  handleValidationErrors,
];

/**
 * Validation rules for user registration
 */
const validateRegister = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Full name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail({ gmail_remove_dots: false }),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long'),
  body('phone')
    .optional({ values: 'falsy' })
    .trim(),
  body('isBiometricEnabled')
    .optional()
    .isBoolean()
    .withMessage('isBiometricEnabled must be boolean'),
  handleValidationErrors,
];

/**
 * Validation rules for password login
 */
const validateLogin = [
  (req, res, next) => {
    if (!req.body.identifier && (req.body.email || req.body.phone)) {
      req.body.identifier = (req.body.email || req.body.phone).trim();
    }
    next();
  },
  body('identifier')
    .trim()
    .notEmpty()
    .withMessage('Email or mobile number is required'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  handleValidationErrors,
];

function isValidEmailOrPhone(val) {
  if (!val || typeof val !== 'string') return false;
  const str = val.trim();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (emailRegex.test(str)) return true;
  const digitsOnly = str.replace(/\D/g, '');
  if (digitsOnly.length >= 10 && digitsOnly.length <= 13) return true;
  return false;
}

/**
 * Validation rules for forgot password (request OTP)
 */
const validateForgotPassword = [
  (req, res, next) => {
    const ident = (req.body.identifier || req.body.email || '').trim();
    if (!ident) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'identifier', message: 'Email or mobile number is required' }],
      });
    }
    if (!isValidEmailOrPhone(ident)) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'email', message: 'Please provide a valid email address or 10-digit mobile number' }],
      });
    }
    req.body.identifier = ident;
    req.body.email = ident;
    next();
  },
  handleValidationErrors,
];

/**
 * Validation rules for verifying reset OTP
 */
const validateVerifyResetOtp = [
  (req, res, next) => {
    const ident = (req.body.identifier || req.body.email || '').trim();
    if (!ident) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'identifier', message: 'Email or mobile number is required' }],
      });
    }
    if (!isValidEmailOrPhone(ident)) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'email', message: 'Please provide a valid email address or 10-digit mobile number' }],
      });
    }
    req.body.identifier = ident;
    req.body.email = ident;
    next();
  },
  body('otp')
    .trim()
    .notEmpty()
    .withMessage('OTP is required')
    .isLength({ min: 6, max: 6 })
    .withMessage('OTP must be exactly 6 digits')
    .isNumeric()
    .withMessage('OTP must contain digits only'),
  handleValidationErrors,
];

/**
 * Validation rules for resetting password
 */
const validateResetPassword = [
  (req, res, next) => {
    const ident = (req.body.identifier || req.body.email || '').trim();
    if (!ident) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'identifier', message: 'Email or mobile number is required' }],
      });
    }
    if (!isValidEmailOrPhone(ident)) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'email', message: 'Please provide a valid email address or 10-digit mobile number' }],
      });
    }
    req.body.identifier = ident;
    req.body.email = ident;
    next();
  },
  body('newPassword')
    .notEmpty()
    .withMessage('New password is required')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long'),
  body('otp')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ min: 6, max: 6 })
    .withMessage('OTP must be exactly 6 digits')
    .isNumeric()
    .withMessage('OTP must contain digits only'),
  body('resetToken')
    .optional({ values: 'falsy' })
    .trim()
    .isString(),
  (req, res, next) => {
    if (!req.body.otp && !req.body.resetToken) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Validation failed',
        errors: [{ field: 'resetToken', message: 'Either resetToken or 6-digit OTP code is required' }],
      });
    }
    next();
  },
  handleValidationErrors,
];

/**
 * Validation rules for loan creation
 */
const validateCreateLoan = [
  body('loanType')
    .trim()
    .notEmpty()
    .withMessage('Loan type is required')
    .isIn(['Personal', 'Business', 'Vehicle', 'Home'])
    .withMessage('Loan type must be one of: Personal, Business, Vehicle, Home'),
  body('principalAmount')
    .notEmpty()
    .withMessage('Principal amount is required')
    .isFloat({ min: 1 })
    .withMessage('Principal amount must be a positive number greater than 0'),
  body('interestRate')
    .notEmpty()
    .withMessage('Interest rate is required')
    .isFloat({ min: 0, max: 100 })
    .withMessage('Interest rate must be between 0% and 100%'),
  body('tenureMonths')
    .notEmpty()
    .withMessage('Tenure in months is required')
    .isInt({ min: 1, max: 600 })
    .withMessage('Tenure must be between 1 and 600 months'),
  body('startDate')
    .notEmpty()
    .withMessage('Start date is required')
    .isISO8601()
    .withMessage('Start date must be a valid ISO 8601 date (YYYY-MM-DD)'),
  body('interestType')
    .optional()
    .isIn(['Reducing', 'Flat'])
    .withMessage('Interest type must be either Reducing or Flat'),
  handleValidationErrors,
];

/**
 * Validation rules for calculating EMI
 */
const validateCalculateEmi = [
  body('principalAmount')
    .notEmpty()
    .withMessage('Principal amount is required')
    .isFloat({ min: 1 })
    .withMessage('Principal amount must be greater than 0'),
  body('interestRate')
    .notEmpty()
    .withMessage('Interest rate is required')
    .isFloat({ min: 0, max: 100 })
    .withMessage('Interest rate must be between 0% and 100%'),
  body('tenureMonths')
    .notEmpty()
    .withMessage('Tenure months is required')
    .isInt({ min: 1, max: 600 })
    .withMessage('Tenure must be between 1 and 600 months'),
  body('interestType')
    .optional()
    .isIn(['Reducing', 'Flat'])
    .withMessage('Interest type must be either Reducing or Flat'),
  handleValidationErrors,
];

/**
 * Validation rules for previewing schedule
 */
const validatePreviewSchedule = [
  body('principalAmount')
    .notEmpty()
    .withMessage('Principal amount is required')
    .isFloat({ min: 1 })
    .withMessage('Principal amount must be greater than 0'),
  body('interestRate')
    .notEmpty()
    .withMessage('Interest rate is required')
    .isFloat({ min: 0, max: 100 })
    .withMessage('Interest rate must be between 0% and 100%'),
  body('tenureMonths')
    .notEmpty()
    .withMessage('Tenure months is required')
    .isInt({ min: 1, max: 600 })
    .withMessage('Tenure must be between 1 and 600 months'),
  body('startDate')
    .optional()
    .isISO8601()
    .withMessage('Start date must be a valid ISO 8601 date (YYYY-MM-DD)'),
  body('interestType')
    .optional()
    .isIn(['Reducing', 'Flat'])
    .withMessage('Interest type must be either Reducing or Flat'),
  handleValidationErrors,
];

/**
 * Validation rules for updating a loan
 */
const validateUpdateLoan = [
  body('loanType')
    .optional()
    .isIn(['Personal', 'Business', 'Vehicle', 'Home'])
    .withMessage('Loan type must be one of: Personal, Business, Vehicle, Home'),
  body('status')
    .optional()
    .isIn(['Active', 'Closed', 'Foreclosed'])
    .withMessage('Status must be one of: Active, Closed, Foreclosed'),
  body('principalAmount')
    .optional()
    .isFloat({ min: 1 })
    .withMessage('Principal amount must be greater than 0'),
  body('interestRate')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Interest rate must be between 0% and 100%'),
  body('tenureMonths')
    .optional()
    .isInt({ min: 1, max: 600 })
    .withMessage('Tenure must be between 1 and 600 months'),
  handleValidationErrors,
];

/**
 * Validation rules for marking EMI as paid
 */
const validateRecordPayment = [
  body('scheduleId')
    .optional()
    .trim(),
  body('amount')
    .optional()
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be a positive number'),
  body('paymentDate')
    .optional()
    .isISO8601()
    .withMessage('Payment date must be a valid ISO 8601 date'),
  body('lateFee')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Late fee must be a non-negative number'),
  handleValidationErrors,
];

/**
 * Validation rules for updating payment record
 */
const validateUpdatePayment = [
  body('amount')
    .optional()
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be a positive number'),
  body('lateFee')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Late fee must be a non-negative number'),
  body('notes')
    .optional()
    .isString()
    .withMessage('Notes must be a string'),
  handleValidationErrors,
];

module.exports = {
  validateSendOtp,
  validateVerifyOtp,
  validateRegister,
  validateLogin,
  validateForgotPassword,
  validateVerifyResetOtp,
  validateResetPassword,
  validateCreateLoan,
  validateUpdateLoan,
  validateCalculateEmi,
  validatePreviewSchedule,
  validateRecordPayment,
  validateUpdatePayment,
};
