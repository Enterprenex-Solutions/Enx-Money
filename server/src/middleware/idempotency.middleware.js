/**
 * Idempotency Middleware for Financial and Transactional Operations
 * Ensures that network retries (e.g., across 3G/4G/5G transitions) do not duplicate transactions,
 * invoices, customer ledger entries, or payments.
 */

const idempotencyCache = new Map();
const IDEMPOTENCY_TTL_MS = 2 * 60 * 60 * 1000; // 2 hours

// Periodically clean expired entries
setInterval(() => {
  const now = Date.now();
  for (const [key, record] of idempotencyCache.entries()) {
    if (now - record.timestamp > IDEMPOTENCY_TTL_MS) {
      idempotencyCache.delete(key);
    }
  }
}, 15 * 60 * 1000).unref();

function idempotencyMiddleware(req, res, next) {
  // Only apply to mutating HTTP methods
  if (!['POST', 'PUT', 'PATCH'].includes(req.method)) {
    return next();
  }

  const idempotencyKey = req.headers['x-idempotency-key'] || req.headers['idempotency-key'];
  if (!idempotencyKey) {
    return next();
  }

  const userId = req.user ? req.user.id : (req.ip || 'anonymous');
  const cacheKey = `${userId}:${req.method}:${req.baseUrl || ''}${req.path}:${idempotencyKey}`;

  const cached = idempotencyCache.get(cacheKey);
  if (cached) {
    if (cached.status === 'IN_PROGRESS') {
      return res.status(409).json({
        success: false,
        message: 'A duplicate request with this idempotency key is currently processing. Please wait.',
      });
    }

    // Return the previously generated response
    res.set('X-Idempotent-Replayed', 'true');
    return res.status(cached.statusCode).json(cached.body);
  }

  // Mark in progress
  idempotencyCache.set(cacheKey, {
    status: 'IN_PROGRESS',
    timestamp: Date.now(),
  });

  // Intercept response
  const originalJson = res.json.bind(res);
  res.json = function (body) {
    // Only cache successful or intentional business client responses (e.g. 200, 201, 400)
    if (res.statusCode < 500) {
      idempotencyCache.set(cacheKey, {
        status: 'COMPLETED',
        statusCode: res.statusCode,
        body,
        timestamp: Date.now(),
      });
    } else {
      // If server error, release key so retry can re-attempt cleanly
      idempotencyCache.delete(cacheKey);
    }
    return originalJson(body);
  };

  next();
}

module.exports = idempotencyMiddleware;
