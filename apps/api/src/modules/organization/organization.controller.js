/**
 * ZeroCarbonix EWMS — Organization Controller
 * Manages Departments and Teams hierarchies
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class OrganizationController {
  getDepartments(req, res) {
    const list = repository.departments.filter(d => d.organizationId === req.organizationId);
    const withCounts = list.map(d => {
      const emps = repository.employees.filter(e => e.departmentId === d.id);
      const teams = repository.teams.filter(t => t.departmentId === d.id);
      return {
        ...d,
        employeeCount: emps.length,
        teamCount: teams.length,
      };
    });
    return res.json({ success: true, data: withCounts });
  }

  createDepartment(req, res) {
    const { name, code, description } = req.body;
    if (!name || !code) {
      return res.status(400).json({ success: false, error: 'Name and code are required' });
    }

    const id = `dept-${code.toLowerCase()}`;
    const dept = {
      id,
      organizationId: req.organizationId,
      name,
      code,
      description: description || null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    repository.departments.push(dept);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'DEPARTMENT_CREATE',
      entityName: 'departments',
      entityId: id,
      afterState: { name, code },
      ipAddress: req.ip,
    });

    return res.status(201).json({ success: true, data: dept });
  }

  getTeams(req, res) {
    const list = repository.teams.filter(t => t.organizationId === req.organizationId);
    return res.json({ success: true, data: list });
  }

  createTeam(req, res) {
    const { name, departmentId, description } = req.body;
    if (!name || !departmentId) {
      return res.status(400).json({ success: false, error: 'Name and departmentId are required' });
    }

    const id = `team-${Date.now()}`;
    const team = {
      id,
      organizationId: req.organizationId,
      departmentId,
      name,
      description: description || null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    repository.teams.push(team);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'TEAM_CREATE',
      entityName: 'teams',
      entityId: id,
      afterState: { name, departmentId },
      ipAddress: req.ip,
    });

    return res.status(201).json({ success: true, data: team });
  }
}

module.exports = new OrganizationController();
