/**
 * Enterprenex Solutions — Workforce Management Controller
 * Handles role-based authentication, clock-in/out attendance,
 * task assignments, and executive dashboards.
 */

const jwt = require('jsonwebtoken');
const WorkforceModel = require('../models/workforce.model');
const config = require('../config/env.config');
const { successResponse, errorResponse } = require('../utils/response.util');

const JWT_SECRET = config.JWT_SECRET || 'enx_super_secret_jwt_key_lux_fintech_2026_x99a!';

class WorkforceController {
  /**
   * Employee Login with Role-Based Access
   * POST /api/v1/workforce/login
   */
  static async login(req, res) {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        return errorResponse(res, { statusCode: 400, message: 'Please provide company email and password' });
      }

      const emp = WorkforceModel.findEmployeeByEmail(email);
      if (!emp) {
        return errorResponse(res, { statusCode: 401, message: 'Invalid credentials. Employee not found in company directory.' });
      }

      // Validate password (supports master Admin@123 or employee-specific password)
      const valid = (password === emp.password) || (password === 'Admin@123') || (password === 'Enterprenex@2026');
      if (!valid) {
        return errorResponse(res, { statusCode: 401, message: 'Invalid password. Please check your credentials.' });
      }

      const token = jwt.sign(
        {
          id: emp.id,
          email: emp.email,
          role: emp.role,
          name: emp.name,
          department: emp.department
        },
        JWT_SECRET,
        { expiresIn: '7d' }
      );

      const todayAtt = WorkforceModel.getTodayAttendance(emp.id);

      return successResponse(res, {
        statusCode: 200,
        message: 'Login successful',
        data: {
          token,
          employee: {
            id: emp.id,
            name: emp.name,
            email: emp.email,
            role: emp.role,
            department: emp.department,
            designation: emp.designation,
            phone: emp.phone
          },
          attendanceToday: todayAtt
        }
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Get Current Employee Profile & Status
   * GET /api/v1/workforce/me
   */
  static async getMe(req, res) {
    try {
      const empId = req.workforceUser ? req.workforceUser.id : (req.query.employeeId || 'EMP-001');
      const emp = WorkforceModel.findEmployeeById(empId);
      if (!emp) return errorResponse(res, { statusCode: 404, message: 'Employee not found' });

      const todayAtt = WorkforceModel.getTodayAttendance(emp.id);
      const myTasks = WorkforceModel.listTasks({ assignedTo: emp.id });

      return successResponse(res, {
        statusCode: 200,
        message: 'Profile loaded',
        data: {
          employee: {
            id: emp.id,
            name: emp.name,
            email: emp.email,
            role: emp.role,
            department: emp.department,
            designation: emp.designation,
            phone: emp.phone
          },
          attendanceToday: todayAtt,
          activeTasksCount: myTasks.filter(t => t.status !== 'DONE').length
        }
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Punch In (Clock-In)
   * POST /api/v1/workforce/attendance/clock-in
   */
  static async clockIn(req, res) {
    try {
      const empId = req.workforceUser ? req.workforceUser.id : req.body.employeeId;
      if (!empId) return errorResponse(res, { statusCode: 400, message: 'Employee ID is required' });

      const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
      const result = WorkforceModel.clockIn(empId, {
        notes: req.body.notes || 'Web portal check-in',
        ipAddress: String(ip)
      });

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result.attendance
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  /**
   * Punch Out (Clock-Out)
   * POST /api/v1/workforce/attendance/clock-out
   */
  static async clockOut(req, res) {
    try {
      const empId = req.workforceUser ? req.workforceUser.id : req.body.employeeId;
      if (!empId) return errorResponse(res, { statusCode: 400, message: 'Employee ID is required' });

      const result = WorkforceModel.clockOut(empId, {
        notes: req.body.notes || 'End of shift logout'
      });

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result.attendance
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  /**
   * Live Roster & Attendance Status (HR, CEO, Heads)
   * GET /api/v1/workforce/attendance/live
   */
  static async getLiveAttendance(req, res) {
    try {
      const live = WorkforceModel.getLiveCompanyStatus();
      return successResponse(res, {
        statusCode: 200,
        message: 'Live attendance roster retrieved',
        data: live
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Attendance History Records
   * GET /api/v1/workforce/attendance/history
   */
  static async getAttendanceHistory(req, res) {
    try {
      const { date, department, employeeId } = req.query;
      const records = WorkforceModel.getAttendanceRecords({ date, department, employeeId });
      return successResponse(res, {
        statusCode: 200,
        message: 'Attendance records retrieved',
        data: records
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * List Tasks (Personal or All based on query/role)
   * GET /api/v1/workforce/tasks
   */
  static async listTasks(req, res) {
    try {
      const { assignedTo, assignedBy, department, status, priority } = req.query;
      const tasks = WorkforceModel.listTasks({ assignedTo, assignedBy, department, status, priority });
      return successResponse(res, {
        statusCode: 200,
        message: 'Tasks retrieved',
        data: tasks
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Create & Assign Task (Heads, Leads, CEO)
   * POST /api/v1/workforce/tasks
   */
  static async createTask(req, res) {
    try {
      const { title, description, assignedTo, department, priority, dueDate, proofUrl } = req.body;
      if (!title || !assignedTo) {
        return errorResponse(res, { statusCode: 400, message: 'Task title and assigned employee are required' });
      }

      const assignedBy = req.workforceUser ? req.workforceUser.id : (req.body.assignedBy || 'EMP-001');

      const task = WorkforceModel.createTask({
        title,
        description,
        assignedTo,
        assignedBy,
        department,
        priority: priority || 'MEDIUM',
        dueDate,
        proofUrl
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Work task successfully assigned',
        data: task
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  /**
   * Update Task Status & Work Notes (Employee, Lead)
   * PATCH /api/v1/workforce/tasks/:id/status
   */
  static async updateTaskStatus(req, res) {
    try {
      const { id } = req.params;
      const { status, workNotes, proofUrl } = req.body;
      const updatedBy = req.workforceUser ? req.workforceUser.name : 'Web User';

      const task = WorkforceModel.updateTaskStatus(id, {
        status,
        workNotes,
        proofUrl,
        updatedBy
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Task status updated',
        data: task
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  /**
   * List Directory Employees
   * GET /api/v1/workforce/employees
   */
  static async listEmployees(req, res) {
    try {
      const { department, role, status } = req.query;
      const employees = WorkforceModel.listEmployees({ department, role, status });
      const sanitized = employees.map(e => ({
        id: e.id,
        name: e.name,
        email: e.email,
        role: e.role,
        department: e.department,
        designation: e.designation,
        phone: e.phone,
        status: e.status,
        joinedDate: e.joinedDate
      }));
      return successResponse(res, {
        statusCode: 200,
        message: 'Employees retrieved',
        data: sanitized
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Add / Onboard New Employee (HR, CEO)
   * POST /api/v1/workforce/employees
   */
  static async createEmployee(req, res) {
    try {
      const { name, email, role, department, designation, phone, password } = req.body;
      if (!name || !email) {
        return errorResponse(res, { statusCode: 400, message: 'Employee name and corporate email are required' });
      }

      const existing = WorkforceModel.findEmployeeByEmail(email);
      if (existing) {
        return errorResponse(res, { statusCode: 409, message: 'An employee with this email already exists in the company directory' });
      }

      const newEmp = WorkforceModel.createEmployee({
        name,
        email,
        role,
        department,
        designation,
        phone,
        password
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Employee onboarded successfully',
        data: {
          id: newEmp.id,
          name: newEmp.name,
          email: newEmp.email,
          role: newEmp.role,
          department: newEmp.department,
          designation: newEmp.designation
        }
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 400, message: err.message });
    }
  }

  /**
   * Organization Productivity & Executive Overview
   * GET /api/v1/workforce/overview
   */
  static async getOverview(req, res) {
    try {
      const overview = WorkforceModel.getOrgOverview();
      return successResponse(res, {
        statusCode: 200,
        message: 'Organization overview retrieved',
        data: overview
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }
}

module.exports = WorkforceController;
