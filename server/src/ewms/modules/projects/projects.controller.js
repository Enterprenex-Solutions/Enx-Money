/**
 * ZeroCarbonix EWMS — Projects Controller
 * Client isolation: Clients see only projects they are assigned to.
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class ProjectsController {
  list(req, res) {
    const user = req.user;
    let list = repository.projects.filter(p => p.organizationId === req.organizationId);

    // Strict Client Isolation: Clients see only projects where they are assigned as client
    if (user.role === 'CLIENT') {
      list = list.filter(p => p.clientId === user.id);
    }

    const projectsWithDetails = list.map(p => {
      const tasks = repository.tasks.filter(t => t.projectId === p.id);
      const members = repository.projectMembers.filter(m => m.projectId === p.id);
      const completedTasks = tasks.filter(t => t.status === 'COMPLETED').length;
      const progress = tasks.length > 0 ? Math.round((completedTasks / tasks.length) * 100) : 0;

      return {
        ...p,
        totalTasks: tasks.length,
        completedTasks,
        progress,
        teamCount: members.length,
      };
    });

    return res.json({
      success: true,
      data: projectsWithDetails,
    });
  }

  getById(req, res) {
    const { id } = req.params;
    const project = repository.projects.find(p => p.id === id && p.organizationId === req.organizationId);

    if (!project) {
      return res.status(404).json({ success: false, error: 'Project not found' });
    }

    if (req.user.role === 'CLIENT' && project.clientId !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Forbidden: Access to this project is not permitted' });
    }

    const tasks = repository.tasks.filter(t => t.projectId === project.id);
    const members = repository.projectMembers.filter(m => m.projectId === project.id);
    const milestones = repository.projectMilestones.filter(m => m.projectId === project.id);

    return res.json({
      success: true,
      data: {
        ...project,
        tasks,
        members,
        milestones,
      },
    });
  }

  create(req, res) {
    const {
      name,
      code,
      description,
      clientId,
      projectManagerId,
      startDate,
      expectedEndDate,
      budget,
      priority = 'MEDIUM',
      techStack = 'Full-Stack',
    } = req.body;

    if (!name || !code || !startDate || !expectedEndDate) {
      return res.status(400).json({
        success: false,
        error: 'Project name, code, start date, and expected end date are required',
      });
    }

    const id = `prj-${Date.now()}`;
    const project = {
      id,
      organizationId: req.organizationId,
      code,
      name,
      description: description || null,
      clientId: clientId || null,
      projectManagerId: projectManagerId || req.user.employeeId,
      startDate: new Date(startDate),
      expectedEndDate: new Date(expectedEndDate),
      budget: budget ? parseFloat(budget) : null,
      priority,
      status: 'ACTIVE',
      techStack,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    repository.projects.push(project);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'PROJECT_CREATE',
      entityName: 'projects',
      entityId: id,
      afterState: { name, code, budget, priority },
      ipAddress: req.ip,
    });

    return res.status(201).json({
      success: true,
      message: 'Project created successfully',
      data: project,
    });
  }
}

module.exports = new ProjectsController();
