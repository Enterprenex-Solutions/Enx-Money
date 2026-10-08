/**
 * ZeroCarbonix EWMS — Skill Matrix Controller
 * Manages employee skill catalog, self-ratings, and manager verification
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class SkillsController {
  getMatrix(req, res) {
    const employeeId = req.query.employeeId || req.user.id;
    const resolvedEmpId = employeeId.startsWith('emp-') ? employeeId : `emp-${employeeId}`;

    const skills = repository.employeeSkills.filter(s => s.employeeId === resolvedEmpId);
    res.json({
      success: true,
      data: skills,
    });
  }

  addOrUpdate(req, res) {
    const { skillName, category, selfRating } = req.body;
    if (!skillName || !selfRating) {
      return res.status(400).json({ error: 'skillName and selfRating are required' });
    }

    const selfEmpId = req.user.id.startsWith('emp-') ? req.user.id : `emp-${req.user.id}`;
    let skill = repository.employeeSkills.find(s => s.employeeId === selfEmpId && s.skillName.toLowerCase() === skillName.toLowerCase());

    if (skill) {
      skill.selfRating = selfRating;
      skill.category = category || skill.category;
    } else {
      skill = {
        id: `sk-${Date.now()}`,
        employeeId: selfEmpId,
        skillName,
        category: category || 'General',
        selfRating,
        verifiedRating: null,
        isVerified: false,
      };
      repository.employeeSkills.push(skill);
    }

    res.status(201).json({
      success: true,
      data: skill,
    });
  }

  verify(req, res) {
    const { id } = req.params;
    const { verifiedRating } = req.body;

    const skill = repository.employeeSkills.find(s => s.id === id);
    if (!skill) {
      return res.status(404).json({ error: 'Skill record not found' });
    }

    skill.verifiedRating = verifiedRating || skill.selfRating;
    skill.isVerified = true;
    skill.verifiedBy = req.user.id;

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'SKILL_VERIFIED',
      entityName: 'employee_skills',
      entityId: id,
      afterState: { skillName: skill.skillName, verifiedRating: skill.verifiedRating },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.json({
      success: true,
      data: skill,
    });
  }
}

module.exports = new SkillsController();
