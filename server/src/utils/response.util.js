/**
 * Formats a successful API response
 */
function successResponse(res, { statusCode = 200, message = 'Success', data = null, meta = null }) {
  const response = {
    success: true,
    message,
    data,
  };
  if (meta) {
    response.meta = meta;
  }
  return res.status(statusCode).json(response);
}

/**
 * Formats an error API response
 */
function errorResponse(res, { statusCode = 500, message = 'An unexpected error occurred', errors = null, error = null, data = null }) {
  const response = {
    success: false,
    message,
  };
  if (error) {
    response.error = error;
  }
  if (errors) {
    response.errors = errors;
  }
  if (data) {
    response.data = data;
  }
  return res.status(statusCode).json(response);
}

module.exports = {
  successResponse,
  errorResponse,
};
