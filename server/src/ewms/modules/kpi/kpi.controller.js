/**
 * ZeroCarbonix EWMS — KPI Controller
 * Enforces role-based KPI templates, weighted formula math, and "signal, not verdict" principle
 */

const { repository } = require('../../database/ewms_repository');
const { calculateKpiScore, ROLE_KPI_TEMPLATES } = require('../../../../../packages/shared/src/dto');
const auditService = require('../audit/audit.service');

class KpiController {
  getTemplates(req, res) {
    res.json({
      success: true,
      data: repository.kpiTemplates,
      standardRoleTemplates: ROLE_KPI_TEMPLATES,
    });
  }

  getEmployeeKpis(req, res) {
    const employeeId = req.params.employeeId || req.user.id;
    const records = repository.employeeKpis.filter(k => k.employeeId === employeeId || k.employeeId === `emp-${employeeId}`);
    res.json({
      success: true,
      data: records,
      philosophy: {
        signalNotVerdict: true,
        notice: 'Dashboard numbers are management signals, not automatic judgments. Always allow human review.',
      },
    });
  }

  evaluateKpi(req, res) {
    const { employeeId, templateId, period, metrics } = req.body;
    if (!employeeId || !metrics || !Array.isArray(metrics)) {
      return res.status(400).json({ error: 'Missing employeeId or metrics array' });
    }

    const { totalScore, totalWeight, isWeightValid } = calculateKpiScore(metrics);
    if (!isWeightValid) {
      return res.status(400).json({
        error: `Invalid weights: Total weight must equal 100%. Received: ${totalWeight}%`,
      });
    }

    const kpiRecord = {
      id: `ekpi-${Date.now()}`,
      organizationId: req.organizationId,
      employeeId,
      templateId: templateId || 'custom',
      period: period || '2026-Q1',
      metrics,
      calculatedScore: totalScore,
      signalNotice: 'Management signal for career growth; not an automated verdict.',
      reviewedBy: req.user.id,
      createdAt: new Date(),
    };

    repository.employeeKpis.push(kpiRecord);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'KPI_EVALUATION_RECORDED',
      entityName: 'employee_kpis',
      entityId: kpiRecord.id,
      afterState: { employeeId, score: totalScore },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: kpiRecord,
    });
  }
}

module.exports = new KpiController();
