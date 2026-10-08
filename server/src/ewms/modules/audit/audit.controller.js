/**
 * ZeroCarbonix EWMS — Audit Controller
 * Exposes immutable security and change audit trails
 */

const auditService = require('./audit.service');

class AuditController {
  getLogs(req, res) {
    const limit = parseInt(req.query.limit, 10) || 50;
    const entityName = req.query.entity || null;
    const logs = auditService.getLogs({
      organizationId: req.organizationId,
      limit,
      entityName,
    });

    return res.json({
      success: true,
      data: logs,
    });
  }
}

module.exports = new AuditController();
