/**
 * Enterprenex Solutions — Company Management Portal Unified Operations Controller
 * 
 * Handles:
 * 1. Employee Directory & HR Actions
 * 2. Punch Clock Attendance & Leaves
 * 3. Task Management & Work Progression
 * 4. Projects & Milestones
 * 5. Secure Documents Vault
 * 6. Executive Command Overviews (CEO, CTO, CFO)
 * 7. Security Audit Trails
 */

const { PortalModel, ROLES, PERMISSIONS } = require('../models/portal.model');
const { successResponse, errorResponse } = require('../utils/response.util');

class PortalManagementController {
  // ─── EMPLOYEES & HR DIRECTORY ──────────────────────────
  static async getEmployees(req, res) {
    try {
      const departmentFilter = req.departmentScope || req.query.department || null;
      let employees = PortalModel.getAllEmployees(departmentFilter);

      // Mask sensitive salary data unless caller has explicit VIEW_SALARY permission
      const hasSalaryPermission = req.portalUser.permissions.includes(PERMISSIONS.VIEW_SALARY);
      if (!hasSalaryPermission) {
        employees = employees.map(e => {
          const { salaryAmount, ...safeEmp } = e;
          return safeEmp;
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Employees retrieved successfully',
        data: employees
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createEmployee(req, res) {
    try {
      const { name, email, role, department, designation, phone, salaryAmount, joiningDate } = req.body;
      if (!name || !email) {
        return errorResponse(res, { statusCode: 400, message: 'Name and email are required' });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      const result = PortalModel.createEmployee({
        name,
        email,
        role,
        department,
        designation,
        phone,
        salaryAmount,
        joiningDate
      });

      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'CREATE_EMPLOYEE',
        resourceType: 'EMPLOYEE',
        resourceId: result.employee.id,
        ipAddress: clientIp,
        details: { name, email, role, department }
      });

      return successResponse(res, {
        statusCode: 201,
        message: `Employee account created for ${name}. Onboarding credentials initialized.`,
        data: result
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async updateEmployee(req, res) {
    try {
      const empId = req.params.id;
      const updated = PortalModel.updateEmployee(empId, req.body);
      if (!updated) {
        return errorResponse(res, { statusCode: 404, message: 'Employee not found' });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'UPDATE_EMPLOYEE',
        resourceType: 'EMPLOYEE',
        resourceId: empId,
        ipAddress: clientIp,
        details: req.body
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Employee record updated successfully',
        data: updated
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async deleteEmployee(req, res) {
    try {
      const empId = req.params.id;
      const success = PortalModel.deleteEmployee(empId);
      if (!success) {
        return errorResponse(res, { statusCode: 404, message: 'Employee not found' });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'TERMINATE_EMPLOYEE',
        resourceType: 'EMPLOYEE',
        resourceId: empId,
        ipAddress: clientIp
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Employee account deactivated'
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── ATTENDANCE & LEAVES ───────────────────────────────
  static async clockIn(req, res) {
    try {
      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      const record = PortalModel.clockIn(req.portalUser.employeeId, clientIp, req.body.notes);

      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'PUNCH_CLOCK_IN',
        resourceType: 'ATTENDANCE',
        resourceId: record.id,
        ipAddress: clientIp
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Shift started. Clock-in timestamp logged.',
        data: record
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async clockOut(req, res) {
    try {
      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      const record = PortalModel.clockOut(req.portalUser.employeeId);

      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'PUNCH_CLOCK_OUT',
        resourceType: 'ATTENDANCE',
        resourceId: record.id,
        ipAddress: clientIp,
        details: { durationMinutes: record.durationMinutes }
      });

      return successResponse(res, {
        statusCode: 200,
        message: `Shift ended. Total duration: ${Math.floor(record.durationMinutes / 60)}h ${record.durationMinutes % 60}m.`,
        data: record
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getLiveAttendance(req, res) {
    try {
      let roster = PortalModel.getLiveAttendanceRoster();
      if (req.departmentScope) {
        roster = roster.filter(r => r.department === req.departmentScope);
      }
      return successResponse(res, {
        statusCode: 200,
        message: 'Live attendance roster retrieved',
        data: roster
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getMyAttendanceHistory(req, res) {
    try {
      const history = PortalModel.getAttendanceHistory(req.portalUser.employeeId);
      return successResponse(res, {
        statusCode: 200,
        message: 'Personal attendance records retrieved',
        data: history
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async applyLeave(req, res) {
    try {
      const { leaveType, startDate, endDate, reason } = req.body;
      if (!startDate || !endDate || !reason) {
        return errorResponse(res, { statusCode: 400, message: 'Start date, end date, and reason are required' });
      }

      const leave = PortalModel.applyLeave({
        employeeId: req.portalUser.employeeId,
        leaveType,
        startDate,
        endDate,
        reason
      });

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'LEAVE_APPLICATION_SUBMITTED',
        resourceType: 'LEAVE',
        resourceId: leave.id,
        ipAddress: clientIp,
        details: { leaveType, startDate, endDate }
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Leave application submitted for approval',
        data: leave
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getLeaves(req, res) {
    try {
      const { role, employeeId } = req.portalUser;
      let leaves = [];

      if (role === ROLES.EMPLOYEE || role === ROLES.INTERN) {
        leaves = PortalModel.getLeaves(null, employeeId);
      } else if (req.departmentScope) {
        leaves = PortalModel.getLeaves(req.departmentScope);
      } else {
        leaves = PortalModel.getLeaves();
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Leave applications retrieved',
        data: leaves
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async updateLeaveStatus(req, res) {
    try {
      const leaveId = req.params.id;
      const { status, note } = req.body;
      if (!status || !['APPROVED', 'REJECTED'].includes(status)) {
        return errorResponse(res, { statusCode: 400, message: 'Status must be APPROVED or REJECTED' });
      }

      const updated = PortalModel.updateLeaveStatus(leaveId, status, req.portalUser.name, note);
      if (!updated) {
        return errorResponse(res, { statusCode: 404, message: 'Leave application not found' });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: `LEAVE_${status}`,
        resourceType: 'LEAVE',
        resourceId: leaveId,
        ipAddress: clientIp,
        details: { status, note }
      });

      return successResponse(res, {
        statusCode: 200,
        message: `Leave application marked as ${status}`,
        data: updated
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── TASKS & KANBAN ────────────────────────────────────
  static async getTasks(req, res) {
    try {
      const { role, employeeId } = req.portalUser;
      let tasks = [];

      if (role === ROLES.EMPLOYEE || role === ROLES.INTERN) {
        // Strict Scoping: Employees see only tasks assigned to them
        tasks = PortalModel.getTasks({ employeeId });
      } else if (req.departmentScope) {
        tasks = PortalModel.getTasks({ department: req.departmentScope });
      } else {
        tasks = PortalModel.getTasks({});
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Tasks retrieved successfully',
        data: tasks
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createTask(req, res) {
    try {
      const { title, description, projectId, assigneeId, priority, deadline } = req.body;
      if (!title || !assigneeId) {
        return errorResponse(res, { statusCode: 400, message: 'Task title and assignee are required' });
      }

      const task = PortalModel.createTask({
        title,
        description,
        projectId,
        creatorId: req.portalUser.employeeId,
        assigneeId,
        priority,
        deadline
      });

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'CREATE_TASK',
        resourceType: 'TASK',
        resourceId: task.id,
        ipAddress: clientIp,
        details: { title, assigneeId, priority }
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Work task created and assigned successfully',
        data: task
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async updateTaskStatus(req, res) {
    try {
      const taskId = req.params.id;
      const { status, notes } = req.body;

      // Validate allowed transitions
      const validStatuses = ['TODO', 'IN_PROGRESS', 'BLOCKED', 'IN_REVIEW', 'COMPLETED'];
      if (!validStatuses.includes(status)) {
        return errorResponse(res, { statusCode: 400, message: 'Invalid task status' });
      }

      // Check task ownership if regular employee
      if (req.portalUser.role === ROLES.EMPLOYEE || req.portalUser.role === ROLES.INTERN) {
        const existing = PortalModel._tasks.get(String(taskId));
        if (!existing || existing.assigneeId !== req.portalUser.employeeId) {
          return errorResponse(res, {
            statusCode: 403,
            message: 'Forbidden: You can only update status on tasks assigned directly to you.'
          });
        }
      }

      const updated = PortalModel.updateTaskStatus(taskId, status, req.portalUser.name, notes);
      if (!updated) {
        return errorResponse(res, { statusCode: 404, message: 'Task not found' });
      }

      return successResponse(res, {
        statusCode: 200,
        message: `Task status updated to ${status}`,
        data: updated
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── PROJECTS ──────────────────────────────────────────
  static async getProjects(req, res) {
    try {
      const filter = req.departmentScope || req.query.department || null;
      let projects = PortalModel.getProjects(filter);

      // Employees and Interns see only projects they are members of
      if (req.portalUser.role === ROLES.EMPLOYEE || req.portalUser.role === ROLES.INTERN) {
        projects = projects.filter(p => p.members && p.members.includes(req.portalUser.employeeId));
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Projects retrieved successfully',
        data: projects
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createProject(req, res) {
    try {
      const { name, code, department, budget, startDate, deadline, description } = req.body;
      if (!name) {
        return errorResponse(res, { statusCode: 400, message: 'Project name is required' });
      }

      const project = PortalModel.createProject({
        name,
        code,
        department: req.departmentScope || department,
        managerId: req.portalUser.employeeId,
        budget,
        startDate,
        deadline,
        description
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Project created successfully',
        data: project
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── DOCUMENTS VAULT ───────────────────────────────────
  static async getDocuments(req, res) {
    try {
      const { role, permissions } = req.portalUser;
      const category = req.query.category || null;

      // Only Leadership, HR & Management can view confidential docs
      const canViewConfidential = [ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.CTO, ROLES.CFO, ROLES.HR].includes(role);
      const docs = PortalModel.getDocuments(category, canViewConfidential);

      return successResponse(res, {
        statusCode: 200,
        message: 'Documents retrieved successfully',
        data: docs
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async uploadDocument(req, res) {
    try {
      const { title, category, isConfidential } = req.body;
      if (!title) {
        return errorResponse(res, { statusCode: 400, message: 'Document title is required' });
      }

      // Employees cannot upload confidential company documents
      const isConf = Boolean(isConfidential);
      if (isConf && (req.portalUser.role === ROLES.EMPLOYEE || req.portalUser.role === ROLES.INTERN)) {
        return errorResponse(res, {
          statusCode: 403,
          message: 'Forbidden: Regular staff cannot mark documents as confidential.'
        });
      }

      const doc = PortalModel.uploadDocument({
        title,
        category,
        isConfidential: isConf,
        uploadedBy: req.portalUser.employeeId
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Document registered in company vault',
        data: doc
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── SPECIALIZED EXECUTIVE COCKPITS ────────────────────
  static async getCeoOverview(req, res) {
    try {
      const overview = PortalModel.getCeoOverview();
      return successResponse(res, {
        statusCode: 200,
        message: 'Executive CEO cockpit data retrieved',
        data: overview
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getCtoOverview(req, res) {
    try {
      const overview = PortalModel.getCtoOverview();
      return successResponse(res, {
        statusCode: 200,
        message: 'CTO engineering command metrics retrieved',
        data: overview
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getCfoOverview(req, res) {
    try {
      const overview = PortalModel.getCfoOverview();
      return successResponse(res, {
        statusCode: 200,
        message: 'CFO financial command summary retrieved',
        data: overview
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── USER & RBAC MANAGEMENT ───────────────────────────
  static async getUsers(req, res) {
    try {
      const users = PortalModel.getAllUsers();
      return successResponse(res, { statusCode: 200, message: 'Users retrieved', data: users });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createUser(req, res) {
    try {
      const user = PortalModel.createUser(req.body);
      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: req.portalUser.id,
        userEmail: req.portalUser.email,
        role: req.portalUser.role,
        action: 'CREATE_USER',
        resourceType: 'USER',
        resourceId: user.id,
        ipAddress: clientIp,
        details: { email: user.email, role: user.role }
      });
      return successResponse(res, { statusCode: 201, message: 'User created successfully', data: user });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async updateUser(req, res) {
    try {
      const updated = PortalModel.updateUser(req.params.id, req.body);
      if (!updated) return errorResponse(res, { statusCode: 404, message: 'User not found' });
      return successResponse(res, { statusCode: 200, message: 'User updated successfully', data: updated });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async deleteUser(req, res) {
    try {
      const deleted = PortalModel.deleteUser(req.params.id);
      if (!deleted) return errorResponse(res, { statusCode: 404, message: 'User not found' });
      return successResponse(res, { statusCode: 200, message: 'User disabled successfully' });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getRoles(req, res) {
    try {
      const roles = PortalModel.getAllRoles();
      return successResponse(res, { statusCode: 200, message: 'Roles and permissions retrieved', data: roles });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async updateRolePermissions(req, res) {
    try {
      const { role } = req.params;
      const { permissions } = req.body;
      const updated = PortalModel.updateRolePermissions(role, permissions);
      return successResponse(res, { statusCode: 200, message: `Permissions updated for role ${role}`, data: updated });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getPermissions(req, res) {
    try {
      return successResponse(res, {
        statusCode: 200,
        message: 'Master permissions list',
        data: Object.values(PERMISSIONS)
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── DEPARTMENTS & DESIGNATIONS ────────────────────────
  static async getDepartments(req, res) {
    try {
      const depts = PortalModel.getDepartments();
      return successResponse(res, { statusCode: 200, message: 'Departments retrieved', data: depts });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createDepartment(req, res) {
    try {
      const dept = PortalModel.createDepartment(req.body);
      return successResponse(res, { statusCode: 201, message: 'Department created', data: dept });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getDesignations(req, res) {
    try {
      const des = PortalModel.getDesignations();
      return successResponse(res, { statusCode: 200, message: 'Designations retrieved', data: des });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createDesignation(req, res) {
    try {
      const des = PortalModel.createDesignation(req.body);
      return successResponse(res, { statusCode: 201, message: 'Designation created', data: des });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── ONBOARDING & OFFBOARDING ──────────────────────────
  static async getOnboarding(req, res) {
    try {
      const list = PortalModel.getOnboardingList();
      return successResponse(res, { statusCode: 200, message: 'Onboarding pipelines retrieved', data: list });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createOnboarding(req, res) {
    try {
      const ob = PortalModel.createOnboarding(req.body);
      return successResponse(res, { statusCode: 201, message: 'Candidate onboarding initiated', data: ob });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async advanceOnboardingStep(req, res) {
    try {
      const updated = PortalModel.advanceOnboardingStep(req.params.id);
      if (!updated) return errorResponse(res, { statusCode: 404, message: 'Onboarding record not found' });
      return successResponse(res, { statusCode: 200, message: 'Onboarding stage advanced', data: updated });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getOffboarding(req, res) {
    try {
      const list = PortalModel.getOffboardingList();
      return successResponse(res, { statusCode: 200, message: 'Offboarding cases retrieved', data: list });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createOffboarding(req, res) {
    try {
      const off = PortalModel.createOffboarding(req.body);
      return successResponse(res, { statusCode: 201, message: 'Employee offboarding initiated', data: off });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async advanceOffboardingStep(req, res) {
    try {
      const { itemIndex, completed } = req.body;
      const updated = PortalModel.advanceOffboardingStep(req.params.id, itemIndex, completed);
      if (!updated) return errorResponse(res, { statusCode: 404, message: 'Offboarding record not found' });
      return successResponse(res, { statusCode: 200, message: 'Offboarding checklist updated', data: updated });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── MILESTONES ────────────────────────────────────────
  static async getMilestones(req, res) {
    try {
      const { projectId } = req.query;
      const list = PortalModel.getMilestones(projectId);
      return successResponse(res, { statusCode: 200, message: 'Milestones retrieved', data: list });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createMilestone(req, res) {
    try {
      const m = PortalModel.createMilestone(req.body);
      return successResponse(res, { statusCode: 201, message: 'Milestone created', data: m });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async updateMilestone(req, res) {
    try {
      const updated = PortalModel.updateMilestone(req.params.id, req.body);
      if (!updated) return errorResponse(res, { statusCode: 404, message: 'Milestone not found' });
      return successResponse(res, { statusCode: 200, message: 'Milestone updated', data: updated });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── TIME TRACKING ─────────────────────────────────────
  static async startTimeTracking(req, res) {
    try {
      const { taskId, projectId, notes } = req.body;
      const entry = PortalModel.startTimeTracking({
        employeeId: req.portalUser.employeeId,
        taskId,
        projectId,
        notes
      });
      return successResponse(res, { statusCode: 200, message: 'Work timer started', data: entry });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async stopTimeTracking(req, res) {
    try {
      const { notes } = req.body;
      const entry = PortalModel.stopTimeTracking({
        employeeId: req.portalUser.employeeId,
        notes
      });
      return successResponse(res, { statusCode: 200, message: 'Work timer stopped & hours logged', data: entry });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getTimeTrackingSummary(req, res) {
    try {
      const empId = req.query.employeeId || (req.portalUser.role === ROLES.EMPLOYEE ? req.portalUser.employeeId : null);
      const summary = PortalModel.getTimeTrackingSummary(empId);
      return successResponse(res, { statusCode: 200, message: 'Time tracking summary', data: summary });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── LEAVE TYPES & ATTENDANCE CALENDAR ─────────────────
  static async getLeaveTypes(req, res) {
    try {
      const types = PortalModel.getLeaveTypes();
      return successResponse(res, { statusCode: 200, message: 'Leave types retrieved', data: types });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createLeaveType(req, res) {
    try {
      const lt = PortalModel.createLeaveType(req.body);
      return successResponse(res, { statusCode: 201, message: 'Leave type configured', data: lt });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getAttendanceCalendar(req, res) {
    try {
      const { month } = req.query;
      const cal = PortalModel.getAttendanceCalendar(month);
      return successResponse(res, { statusCode: 200, message: 'Attendance calendar data', data: cal });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── KPIS & PERFORMANCE ────────────────────────────────
  static async getKpis(req, res) {
    try {
      const kpis = PortalModel.getKpis();
      return successResponse(res, { statusCode: 200, message: 'KPI configurations retrieved', data: kpis });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createKpi(req, res) {
    try {
      const kpi = PortalModel.createKpi(req.body);
      return successResponse(res, { statusCode: 201, message: 'KPI metric configured', data: kpi });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getGoals(req, res) {
    try {
      const empId = req.query.employeeId || (req.portalUser.role === ROLES.EMPLOYEE ? req.portalUser.employeeId : null);
      const goals = PortalModel.getGoals(empId);
      return successResponse(res, { statusCode: 200, message: 'Goals retrieved', data: goals });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createGoal(req, res) {
    try {
      const goal = PortalModel.createGoal({
        employeeId: req.body.employeeId || req.portalUser.employeeId,
        title: req.body.title,
        targetDate: req.body.targetDate,
        progress: req.body.progress
      });
      return successResponse(res, { statusCode: 201, message: 'Performance goal registered', data: goal });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getPerformanceReviews(req, res) {
    try {
      const empId = req.query.employeeId || (req.portalUser.role === ROLES.EMPLOYEE ? req.portalUser.employeeId : null);
      const reviews = PortalModel.getPerformanceReviews(empId);
      return successResponse(res, { statusCode: 200, message: 'Performance reviews retrieved', data: reviews });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createPerformanceReview(req, res) {
    try {
      const review = PortalModel.createPerformanceReview({
        ...req.body,
        reviewerId: req.portalUser.id,
        reviewerName: req.portalUser.name
      });
      return successResponse(res, { statusCode: 201, message: 'Performance review logged', data: review });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── ANNOUNCEMENTS & NOTIFICATIONS ─────────────────────
  static async getAnnouncements(req, res) {
    try {
      const announcements = PortalModel.getAnnouncements();
      return successResponse(res, { statusCode: 200, message: 'Announcements retrieved', data: announcements });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async createAnnouncement(req, res) {
    try {
      const ann = PortalModel.createAnnouncement({
        ...req.body,
        authorName: req.portalUser.name
      });
      return successResponse(res, { statusCode: 201, message: 'Company announcement posted', data: ann });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  static async getNotifications(req, res) {
    try {
      const notifs = PortalModel.getNotifications(req.portalUser.employeeId);
      return successResponse(res, { statusCode: 200, message: 'Notifications retrieved', data: notifs });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async markNotificationRead(req, res) {
    try {
      PortalModel.markNotificationRead(req.params.id);
      return successResponse(res, { statusCode: 200, message: 'Notification marked as read' });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── CLIENT PORTAL (STRICT ISOLATION) ──────────────────
  static async getClientProjects(req, res) {
    try {
      const projects = PortalModel.getClientProjects(req.portalUser.id || req.portalUser.email);
      return successResponse(res, {
        statusCode: 200,
        message: 'Client projects retrieved',
        data: projects
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getClientTasks(req, res) {
    try {
      const tasks = PortalModel.getClientTasks(req.portalUser.id || req.portalUser.email);
      return successResponse(res, {
        statusCode: 200,
        message: 'Shared client deliverables retrieved',
        data: tasks
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getClientDocuments(req, res) {
    try {
      const docs = PortalModel.getClientDocuments(req.portalUser.id || req.portalUser.email);
      return successResponse(res, {
        statusCode: 200,
        message: 'Shared client documents retrieved',
        data: docs
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  // ─── ANALYTICS & SETTINGS ──────────────────────────────
  static async getCompanyAnalytics(req, res) {
    try {
      const analytics = PortalModel.getCompanyAnalytics();
      return successResponse(res, { statusCode: 200, message: 'Company analytics metrics', data: analytics });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async getSettings(req, res) {
    try {
      const settings = PortalModel.getSettings();
      return successResponse(res, { statusCode: 200, message: 'Company settings retrieved', data: settings });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  static async updateSettings(req, res) {
    try {
      const updated = PortalModel.updateSettings(req.body);
      return successResponse(res, { statusCode: 200, message: 'Company settings updated', data: updated });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  // ─── SECURITY AUDIT LOGS ───────────────────────────────
  static async getAuditLogs(req, res) {
    try {
      const logs = PortalModel.getAuditLogs(100);
      return successResponse(res, {
        statusCode: 200,
        message: 'Security audit logs retrieved',
        data: logs
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }
}

module.exports = PortalManagementController;
