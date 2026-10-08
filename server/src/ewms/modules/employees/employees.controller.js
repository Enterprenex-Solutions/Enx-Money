/**
 * ZeroCarbonix EWMS — Employees Controller
 * Enforces sensitive field encryption and role-based data masking.
 */

const { repository, hashPassword } = require('../../database/ewms_repository');
const { sanitizeEmployeeProfile } = require('../../common/guards/auth_rbac.guard');
const encryptionService = require('../../database/encryption.service');
const auditService = require('../audit/audit.service');

class EmployeesController {
  list(req, res) {
    const requestingUser = req.user;
    let list = repository.employees.filter(e => e.organizationId === req.organizationId);

    // If client, return 403 or empty (clients do not see employee directory)
    if (requestingUser.role === 'CLIENT') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Clients cannot access internal employee roster',
      });
    }

    // Sanitize every record
    const sanitized = list.map(emp => {
      const dept = repository.departments.find(d => d.id === emp.departmentId);
      const team = repository.teams.find(t => t.id === emp.teamId);
      const profile = sanitizeEmployeeProfile(emp, requestingUser);
      return {
        ...profile,
        departmentName: dept ? dept.name : 'General',
        teamName: team ? team.name : 'Direct',
      };
    });

    return res.json({
      success: true,
      data: sanitized,
    });
  }

  getById(req, res) {
    const { id } = req.params;
    const emp = repository.employees.find(e => (e.id === id || e.userId === id) && e.organizationId === req.organizationId);

    if (!emp) {
      return res.status(404).json({ success: false, error: 'Employee not found' });
    }

    if (req.user.role === 'CLIENT') {
      return res.status(403).json({ success: false, error: 'Forbidden: Clients cannot view employee profiles' });
    }

    const dept = repository.departments.find(d => d.id === emp.departmentId);
    const team = repository.teams.find(t => t.id === emp.teamId);
    const sanitized = sanitizeEmployeeProfile(emp, req.user);

    return res.json({
      success: true,
      data: {
        ...sanitized,
        departmentName: dept ? dept.name : 'General',
        teamName: team ? team.name : 'Direct',
      },
    });
  }

  create(req, res) {
    const {
      firstName,
      lastName,
      email,
      role = 'EMPLOYEE',
      departmentId,
      teamId,
      designation,
      employmentType = 'FULL_TIME',
      workMode = 'OFFICE',
      salary,
      bankAccount,
      taxId,
    } = req.body;

    if (!firstName || !lastName || !email || !designation) {
      return res.status(400).json({
        success: false,
        error: 'First name, last name, email, and designation are required',
      });
    }

    const existingUser = repository.users.find(u => u.email.toLowerCase() === email.toLowerCase());
    if (existingUser) {
      return res.status(400).json({ success: false, error: 'User with this email already exists' });
    }

    const userId = `usr-${Date.now()}`;
    const defaultPassword = 'ZeroCarbonix@2026';

    const user = {
      id: userId,
      organizationId: req.organizationId,
      email,
      passwordHash: hashPassword(defaultPassword),
      role,
      isMfaEnabled: false,
      mfaSecret: null,
      status: 'ACTIVE',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const empId = `emp-${userId}`;
    const employeeCode = `ZC-${Math.floor(1000 + Math.random() * 9000)}`;

    const employee = {
      id: empId,
      organizationId: req.organizationId,
      userId,
      employeeCode,
      firstName,
      lastName,
      email,
      personalEmail: `${firstName.toLowerCase()}@gmail.com`,
      phone: '+91 98000 00000',
      emergencyContact: '+91 98000 11111',
      designation,
      departmentId: departmentId || 'dept-eng',
      teamId: teamId || 'team-backend',
      employmentType,
      employmentStatus: 'ACTIVE',
      workLocation: 'Bengaluru Innovation Center',
      workMode,
      joiningDate: new Date(),
      salaryEncrypted: salary ? encryptionService.encrypt(salary) : null,
      bankAccountEncrypted: bankAccount ? encryptionService.encrypt(bankAccount) : null,
      taxIdEncrypted: taxId ? encryptionService.encrypt(taxId) : null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    repository.users.push(user);
    repository.employees.push(employee);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'EMPLOYEE_ONBOARD',
      entityName: 'employees',
      entityId: empId,
      afterState: { email, role, designation, employeeCode },
      ipAddress: req.ip,
    });

    return res.status(201).json({
      success: true,
      message: 'Employee onboarded successfully',
      data: {
        employee: sanitizeEmployeeProfile(employee, req.user),
        defaultPassword,
      },
    });
  }
}

module.exports = new EmployeesController();
