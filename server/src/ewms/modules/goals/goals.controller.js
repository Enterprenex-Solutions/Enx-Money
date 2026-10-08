/**
 * ZeroCarbonix EWMS — Goals & OKRs Controller
 * Connects Objectives to Key Results and computes automated progress roll-up
 */

const { repository } = require('../../database/ewms_repository');
const { calculateOkrProgress } = require('../../../../../packages/shared/src/dto');
const auditService = require('../audit/audit.service');

class GoalsController {
  list(req, res) {
    const objectives = repository.objectives.filter(o => o.organizationId === req.organizationId);
    const enriched = objectives.map(obj => {
      const krs = repository.keyResults.filter(kr => kr.objectiveId === obj.id);
      const computedProgress = calculateOkrProgress(krs);
      return {
        ...obj,
        progress: computedProgress,
        keyResults: krs,
      };
    });

    res.json({
      success: true,
      data: enriched,
    });
  }

  create(req, res) {
    const { title, description, level, departmentId, targetQuarter, keyResults = [] } = req.body;
    if (!title) {
      return res.status(400).json({ error: 'Title is required for an objective' });
    }

    const objId = `obj-${Date.now()}`;
    const newObj = {
      id: objId,
      organizationId: req.organizationId,
      title,
      description: description || '',
      level: level || 'EMPLOYEE',
      departmentId: departmentId || null,
      targetQuarter: targetQuarter || '2026-Q1',
      progress: 0,
      createdAt: new Date(),
    };

    repository.objectives.push(newObj);

    const createdKrs = [];
    keyResults.forEach((kr, idx) => {
      const krItem = {
        id: `kr-${Date.now()}-${idx}`,
        objectiveId: objId,
        title: kr.title,
        targetValue: kr.targetValue || 100,
        currentValue: kr.currentValue || 0,
        unit: kr.unit || '%',
      };
      repository.keyResults.push(krItem);
      createdKrs.push(krItem);
    });

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'OBJECTIVE_CREATED',
      entityName: 'objectives',
      entityId: objId,
      afterState: { title, level },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: {
        ...newObj,
        progress: calculateOkrProgress(createdKrs),
        keyResults: createdKrs,
      },
    });
  }

  updateKeyResult(req, res) {
    const { id } = req.params;
    const { currentValue } = req.body;

    const kr = repository.keyResults.find(k => k.id === id);
    if (!kr) {
      return res.status(404).json({ error: 'Key Result not found' });
    }

    kr.currentValue = Number(currentValue);

    // Recompute objective progress
    const siblingKrs = repository.keyResults.filter(k => k.objectiveId === kr.objectiveId);
    const obj = repository.objectives.find(o => o.id === kr.objectiveId);
    if (obj) {
      obj.progress = calculateOkrProgress(siblingKrs);
    }

    res.json({
      success: true,
      data: kr,
      objectiveProgress: obj ? obj.progress : 0,
    });
  }
}

module.exports = new GoalsController();
