/**
 * ZeroCarbonix EWMS — Centralized Audit Logging Service
 * Records: Who, What, When, IP/Device, Before Value, After Value
 */

const { repository } = require('../../database/ewms_repository');

class AuditService {
  log({
    organizationId = 'org-zc-001',
    actorId,
    action,
    entityName,
    entityId,
    beforeState = null,
    afterState = null,
    ipAddress = '127.0.0.1',
    userAgent = 'EWMS Web Client',
  }) {
    const record = {
      id: `audit-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      organizationId,
      actorId: actorId || 'SYSTEM',
      action,
      entityName,
      entityId: entityId ? String(entityId) : null,
      beforeState: beforeState ? (typeof beforeState === 'string' ? beforeState : JSON.stringify(beforeState)) : null,
      afterState: afterState ? (typeof afterState === 'string' ? afterState : JSON.stringify(afterState)) : null,
      ipAddress,
      userAgent,
      createdAt: new Date(),
    };

    repository.auditLogs.unshift(record);
    return record;
  }

  getLogs({ organizationId = 'org-zc-001', limit = 50, entityName = null }) {
    let logs = repository.auditLogs.filter(l => l.organizationId === organizationId);
    if (entityName) {
      logs = logs.filter(l => l.entityName === entityName);
    }
    return logs.slice(0, limit);
  }
}

module.exports = new AuditService();
