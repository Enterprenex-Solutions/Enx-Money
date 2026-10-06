const { errorResponse } = require('../utils/response.util');
const config = require('../config/env.config');

/**
 * 404 Route Not Found Handler
 */
function notFoundHandler(req, res) {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  return errorResponse(res, {
    statusCode: 404,
    message: `API endpoint not found: ${req.method} ${req.originalUrl}`,
  });
}

/**
 * Global Error Handler
 */
function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  // Log in development/staging
  if (config.NODE_ENV !== 'test') {
    console.error(`[Error] ${req.method} ${req.originalUrl}:`, err);
  }

  const response = {
    statusCode,
    message,
  };

  if (err.code) {
    response.error = err.code;
  }

  if (err.errors) {
    response.errors = err.errors;
  }

  if (err.field || err.isRegistered) {
    response.data = {
      field: err.field,
      isRegistered: Boolean(err.isRegistered),
      matchedEmail: err.matchedEmail,
      matchedPhone: err.matchedPhone,
    };
  } else if (err.data) {
    response.data = err.data;
  }

  return errorResponse(res, response);
}

module.exports = {
  notFoundHandler,
  errorHandler,
};
