/**
 * ZeroCarbonix EWMS — Project Risks Controller
 * Tracks project risks register and computes project health score
 */

const { repository } = require('../../database/ewms_repository');
const { calculateProjectHealthScore } = require('../../../../../packages/shared/src/dto');
const auditService = require('../audit/audit.service');

class RisksController {
  list(req, res) {
    const { projectId } = req.query;
    let risks = repository.projectRisks.filter(r => r.organizationId === req.organizationId);
    if (projectId) {
      risks = risks.filter(r => r.projectId === projectId);
    }

    // Compute health scores for all projects
    const allProjectIds = Array.from(new Set([
      ...repository.projects.map(p => p.id),
      ...repository.projectRisks.map(r => r.projectId),
      ...repository.tasks.map(t => t.projectId).filter(Boolean),
    ]));

    const projectsWithHealth = allProjectIds.map(prjId => {
      const prj = repository.projects.find(p => p.id === prjId);
      const prjTasks = repository.tasks.filter(t => t.projectId === prjId);
      const completed = prjTasks.filter(t => t.status === 'COMPLETED').length;
      const overdue = prjTasks.filter(t => t.status !== 'COMPLETED' && t.deadline && new Date(t.deadline) < new Date()).length;
      const openPrjRisks = repository.projectRisks.filter(r => r.projectId === prjId && r.status === 'OPEN').length;

      const healthScore = calculateProjectHealthScore({
        totalTasks: prjTasks.length,
        completedTasks: completed,
        overdueTasks: overdue,
        openRisks: openPrjRisks,
      });

      return {
        projectId: prjId,
        projectName: prj ? prj.name : prjId,
        healthScore,
        totalTasks: prjTasks.length,
        completedTasks: completed,
        openRisks: openPrjRisks,
      };
    });

    res.json({
      success: true,
      data: risks,
      projectHealthScores: projectsWithHealth,
    });
  }

  create(req, res) {
    const { projectId, title, severity = 'MEDIUM', probability = 'MEDIUM', impact, mitigationPlan } = req.body;
    if (!projectId || !title) {
      return res.status(400).json({ error: 'projectId and title are required' });
    }

    const risk = {
      id: `rsk-${Date.now()}`,
      organizationId: req.organizationId,
      projectId,
      title,
      severity,
      probability,
      impact: impact || '',
      mitigationPlan: mitigationPlan || '',
      status: 'OPEN',
      createdAt: new Date(),
    };

    repository.projectRisks.push(risk);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'PROJECT_RISK_REGISTERED',
      entityName: 'project_risks',
      entityId: risk.id,
      afterState: { projectId, title, severity },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: risk,
    });
  }
}

module.exports = new RisksController();
