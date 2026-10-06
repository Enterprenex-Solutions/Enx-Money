/**
 * ENX Money — Entitlement Middleware
 * Enforces plan-level feature access on API routes.
 */
const entitlementService = require('../services/entitlement.service');

/**
 * Require a specific feature entitlement.
 * If user is not subscribed or plan doesn't include the feature, responds with 403.
 * @param {string} featureCode
 */
function requireEntitlement(featureCode) {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id || null;

      // Admin bypass
      if (req.user?.role === 'admin' || req.user?.role === 'superadmin') {
        return next();
      }

      const entitlement = await entitlementService.checkEntitlement(userId, featureCode);

      if (!entitlement.allowed) {
        return res.status(403).json({
          success: false,
          upgrade_required: true,
          feature_code: featureCode,
          current_plan: entitlement.planName || 'FREE',
          message: `The ${featureCode.replace(/_/g, ' ').toLowerCase()} feature is not available on your current ${entitlement.planName || 'FREE'} plan. Please upgrade to unlock this feature.`,
        });
      }

      // Attach entitlement info to request for downstream handlers
      req.entitlement = entitlement;
      return next();
    } catch (err) {
      console.error(`[Entitlement Middleware] Error checking ${featureCode}:`, err);
      // In case of error, permit or fail gracefully
      return next();
    }
  };
}

module.exports = {
  requireEntitlement,
};
