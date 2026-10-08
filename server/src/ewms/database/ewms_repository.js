/**
 * ZeroCarbonix EWMS — Enterprise Resilient Data Repository
 * Holds full in-memory store with PostgreSQL/Prisma sync capability
 * Seeds all 8 enterprise roles, departments, teams, projects, tasks, attendance, and audit logs.
 */

const crypto = require('crypto');
const encryptionService = require('./encryption.service');

// Password hash helper
function hashPassword(password) {
  const salt = 'zc_salt_2026_fixed';
  return crypto.pbkdf2Sync(password, salt, 1000, 32, 'sha256').toString('hex');
}

function verifyPassword(password, storedHash) {
  const incomingHash = hashPassword(password);
  return incomingHash === storedHash;
}

class EwmsRepository {
  constructor() {
    this.reset();
  }

  reset() {
    this.organizations = [];
    this.users = [];
    this.roles = [];
    this.permissions = [];
    this.rolePermissions = [];
    this.departments = [];
    this.teams = [];
    this.employees = [];
    this.projects = [];
    this.projectMembers = [];
    this.projectMilestones = [];
    this.tasks = [];
    this.taskAssignees = [];
    this.taskDependencies = [];
    this.workSessions = [];
    this.attendanceRecords = [];
    this.auditLogs = [];

    this.seedDefaults();
  }

  seedDefaults() {
    const orgId = 'org-zc-001';
    this.organizations.push({
      id: orgId,
      name: 'ZeroCarbonix Technologies Pvt Ltd',
      slug: 'zerocarbonix',
      domain: 'zerocarbonix.com',
      status: 'ACTIVE',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    });

    // 1. Roles
    const roleDefs = [
      { code: 'SUPER_ADMIN', name: 'Super Administrator', description: 'Platform-wide control' },
      { code: 'COMPANY_ADMIN', name: 'Company Administrator', description: 'Company config, users, roles' },
      { code: 'HR_ADMIN', name: 'HR Administrator', description: 'People, attendance, leave, documents' },
      { code: 'PROJECT_MANAGER', name: 'Project Manager', description: 'Projects, tasks, timesheets, team KPIs' },
      { code: 'TEAM_LEAD', name: 'Team Lead', description: 'Team tasks, reviews, approvals' },
      { code: 'EMPLOYEE', name: 'Employee', description: 'Own work, profile, time, goals' },
      { code: 'INTERN', name: 'Intern', description: 'Simplified access and tasks' },
      { code: 'CLIENT', name: 'Client / External', description: 'Limited project visibility' },
    ];

    roleDefs.forEach((r, idx) => {
      this.roles.push({
        id: `role-${r.code.toLowerCase()}`,
        organizationId: orgId,
        code: r.code,
        name: r.name,
        description: r.description,
        createdAt: new Date('2026-01-01'),
        updatedAt: new Date('2026-01-01'),
      });
    });

    // 2. Departments
    const deptEngineering = { id: 'dept-eng', organizationId: orgId, code: 'ENG', name: 'Engineering & Technology', description: 'Software, Architecture & QA' };
    const deptProduct = { id: 'dept-prd', organizationId: orgId, code: 'PRD', name: 'Product & Design', description: 'Product Roadmap & UI/UX' };
    const deptPeople = { id: 'dept-hr', organizationId: orgId, code: 'HR', name: 'People & Culture', description: 'Talent Acquisition & Employee Success' };
    const deptOps = { id: 'dept-ops', organizationId: orgId, code: 'OPS', name: 'Cloud & Infrastructure', description: 'DevOps, SRE & Cybersecurity' };

    this.departments.push(deptEngineering, deptProduct, deptPeople, deptOps);

    // 3. Teams
    const teamBackend = { id: 'team-backend', organizationId: orgId, departmentId: 'dept-eng', name: 'Backend Core' };
    const teamFrontend = { id: 'team-frontend', organizationId: orgId, departmentId: 'dept-eng', name: 'Frontend Systems' };
    const teamDevOps = { id: 'team-devops', organizationId: orgId, departmentId: 'dept-ops', name: 'Cloud Infrastructure' };

    this.teams.push(teamBackend, teamFrontend, teamDevOps);

    // 4. Default Seed Users & Employees
    const defaultPassHash = hashPassword('ZeroCarbonix@2026');

    const seedUsersData = [
      {
        id: 'usr-superadmin',
        email: 'superadmin@zerocarbonix.com',
        role: 'SUPER_ADMIN',
        empCode: 'ZC-001',
        firstName: 'Vikram',
        lastName: 'Mehra',
        designation: 'Principal Architect / Founder',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '250000',
        bank: 'HDFC Bank - 50100492817291',
        taxId: 'ABCDE1234F',
      },
      {
        id: 'usr-admin',
        email: 'admin@zerocarbonix.com',
        role: 'COMPANY_ADMIN',
        empCode: 'ZC-002',
        firstName: 'Aarti',
        lastName: 'Sharma',
        designation: 'Operations Director',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '180000',
        bank: 'ICICI Bank - 002105019283',
        taxId: 'BKIPA9876C',
      },
      {
        id: 'usr-hr',
        email: 'hr@zerocarbonix.com',
        role: 'HR_ADMIN',
        empCode: 'ZC-003',
        firstName: 'Sneha',
        lastName: 'Patil',
        designation: 'Head of People Operations',
        deptId: 'dept-hr',
        teamId: null,
        salary: '120000',
        bank: 'Axis Bank - 912010029381',
        taxId: 'CPQRS4567M',
      },
      {
        id: 'usr-pm',
        email: 'pm@zerocarbonix.com',
        role: 'PROJECT_MANAGER',
        empCode: 'ZC-004',
        firstName: 'Rahul',
        lastName: 'Deshmukh',
        designation: 'Lead Technical Project Manager',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '160000',
        bank: 'Kotak Bank - 2910492817',
        taxId: 'DMNPK3456L',
      },
      {
        id: 'usr-lead',
        email: 'lead@zerocarbonix.com',
        role: 'TEAM_LEAD',
        empCode: 'ZC-005',
        firstName: 'Ananya',
        lastName: 'Sen',
        designation: 'Engineering Team Lead',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '140000',
        bank: 'SBI - 20491829104',
        taxId: 'EOPST7890Q',
      },
      {
        id: 'usr-employee',
        email: 'employee@zerocarbonix.com',
        role: 'EMPLOYEE',
        empCode: 'ZC-006',
        firstName: 'Kishore',
        lastName: 'Kumar',
        designation: 'Senior Full-Stack Engineer',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '95000',
        bank: 'HDFC Bank - 501009827162',
        taxId: 'FQRST1234Z',
      },
      {
        id: 'usr-intern',
        email: 'intern@zerocarbonix.com',
        role: 'INTERN',
        empCode: 'ZC-007',
        firstName: 'Priya',
        lastName: 'Nair',
        designation: 'Software Engineering Intern',
        deptId: 'dept-eng',
        teamId: 'team-frontend',
        salary: '35000',
        bank: 'Canara Bank - 1092837461',
        taxId: 'GHIJK5678W',
      },
      {
        id: 'usr-client',
        email: 'client@acmecorp.com',
        role: 'CLIENT',
        empCode: 'ZC-EXT-01',
        firstName: 'John',
        lastName: 'Acme',
        designation: 'VP Engineering (Acme Corp)',
        deptId: null,
        teamId: null,
        salary: null,
        bank: null,
        taxId: null,
      },
    ];

    seedUsersData.forEach(u => {
      this.users.push({
        id: u.id,
        organizationId: orgId,
        email: u.email,
        passwordHash: defaultPassHash,
        role: u.role,
        isMfaEnabled: false,
        mfaSecret: null,
        status: 'ACTIVE',
        lastLoginAt: new Date(),
        createdAt: new Date('2026-01-01'),
        updatedAt: new Date('2026-01-01'),
      });

      this.employees.push({
        id: `emp-${u.id}`,
        organizationId: orgId,
        userId: u.id,
        employeeCode: u.empCode,
        firstName: u.firstName,
        lastName: u.lastName,
        email: u.email,
        personalEmail: `${u.firstName.toLowerCase()}@gmail.com`,
        phone: '+91 98765 43210',
        emergencyContact: '+91 98765 00000',
        designation: u.designation,
        departmentId: u.deptId,
        teamId: u.teamId,
        reportingManagerId: u.role === 'EMPLOYEE' ? 'emp-usr-pm' : null,
        teamLeadId: u.role === 'EMPLOYEE' ? 'emp-usr-lead' : null,
        employmentType: u.role === 'INTERN' ? 'INTERN' : (u.role === 'CLIENT' ? 'CONTRACT' : 'FULL_TIME'),
        employmentStatus: 'ACTIVE',
        workLocation: 'Bengaluru Innovation Center',
        workMode: 'HYBRID',
        joiningDate: new Date('2026-01-15'),
        salaryEncrypted: encryptionService.encrypt(u.salary),
        bankAccountEncrypted: encryptionService.encrypt(u.bank),
        taxIdEncrypted: encryptionService.encrypt(u.taxId),
        createdAt: new Date('2026-01-01'),
        updatedAt: new Date('2026-01-01'),
      });
    });

    // 5. Projects
    const prjAlpha = {
      id: 'prj-alpha',
      organizationId: orgId,
      code: 'PRJ-ALPHA',
      name: 'Enterprise Cloud Platform (EWMS)',
      description: 'ZeroCarbonix core modular work and employee management platform',
      clientId: 'usr-client',
      projectManagerId: 'emp-usr-pm',
      startDate: new Date('2026-02-01'),
      expectedEndDate: new Date('2026-12-31'),
      budget: 1500000,
      priority: 'HIGH',
      status: 'ACTIVE',
      techStack: 'NestJS, Next.js, PostgreSQL, Redis, S3',
      createdAt: new Date('2026-02-01'),
      updatedAt: new Date('2026-02-01'),
    };

    const prjBeta = {
      id: 'prj-beta',
      organizationId: orgId,
      code: 'PRJ-BETA',
      name: 'AI Workload Prediction Engine',
      description: 'Predictive analytics module for sprint resource optimization',
      clientId: 'usr-client',
      projectManagerId: 'emp-usr-pm',
      startDate: new Date('2026-03-01'),
      expectedEndDate: new Date('2026-11-30'),
      budget: 850000,
      priority: 'MEDIUM',
      status: 'PLANNED',
      techStack: 'Python, FastAPI, Scikit-Learn, PyTorch',
      createdAt: new Date('2026-03-01'),
      updatedAt: new Date('2026-03-01'),
    };

    this.projects.push(prjAlpha, prjBeta);

    // 6. Project Members
    this.projectMembers.push(
      { id: 'pm-1', projectId: 'prj-alpha', employeeId: 'emp-usr-pm', roleInProject: 'PROJECT_MANAGER', allocatedPercentage: 100 },
      { id: 'pm-2', projectId: 'prj-alpha', employeeId: 'emp-usr-lead', roleInProject: 'TECH_LEAD', allocatedPercentage: 100 },
      { id: 'pm-3', projectId: 'prj-alpha', employeeId: 'emp-usr-employee', roleInProject: 'BACKEND_DEVELOPER', allocatedPercentage: 100 },
      { id: 'pm-4', projectId: 'prj-alpha', employeeId: 'emp-usr-intern', roleInProject: 'CONTRIBUTOR', allocatedPercentage: 50 },
    );

    // 7. Tasks with Dependency Chains
    // Task 1: TSK-101 (Prerequisite - COMPLETED)
    const tsk101 = {
      id: 'tsk-101',
      organizationId: orgId,
      projectId: 'prj-alpha',
      taskNumber: 'TSK-101',
      title: 'Design OAuth2 & Dual-Token JWT Schema',
      description: 'Formulate access/refresh token rotation and argon2 hashing architecture',
      priority: 'HIGH',
      status: 'COMPLETED',
      createdById: 'emp-usr-lead',
      reviewerId: 'emp-usr-pm',
      startDate: new Date('2026-02-05'),
      dueDate: new Date('2026-02-12'),
      estimatedHours: 10.0,
      actualHours: 9.5,
      acceptanceCriteria: 'Clean token model with refresh hash rotation',
      createdAt: new Date('2026-02-05'),
      updatedAt: new Date('2026-02-12'),
    };

    // Task 2: TSK-102 (Depends on TSK-101 - IN_PROGRESS)
    const tsk102 = {
      id: 'tsk-102',
      organizationId: orgId,
      projectId: 'prj-alpha',
      taskNumber: 'TSK-102',
      title: 'Implement Authentication & RBAC API Endpoints',
      description: 'Create login, refresh, MFA, and permission guards in NestJS',
      priority: 'URGENT',
      status: 'IN_PROGRESS',
      createdById: 'emp-usr-lead',
      reviewerId: 'emp-usr-pm',
      startDate: new Date('2026-02-13'),
      dueDate: new Date('2026-02-20'),
      estimatedHours: 15.0,
      actualHours: 8.0,
      acceptanceCriteria: 'Pass unit tests with 403 on permission violation',
      createdAt: new Date('2026-02-13'),
      updatedAt: new Date('2026-02-15'),
    };

    // Task 3: TSK-103 (Depends on TSK-102 - ASSIGNED)
    const tsk103 = {
      id: 'tsk-103',
      organizationId: orgId,
      projectId: 'prj-alpha',
      taskNumber: 'TSK-103',
      title: 'Build Web Portal Authentication & MFA Screen',
      description: 'Next.js App Router login screen with quick role switcher',
      priority: 'HIGH',
      status: 'ASSIGNED',
      createdById: 'emp-usr-lead',
      reviewerId: 'emp-usr-pm',
      startDate: new Date('2026-02-21'),
      dueDate: new Date('2026-02-28'),
      estimatedHours: 12.0,
      actualHours: 0.0,
      acceptanceCriteria: 'Responsive minimalist UI in Tailwind CSS',
      createdAt: new Date('2026-02-13'),
      updatedAt: new Date('2026-02-13'),
    };

    this.tasks.push(tsk101, tsk102, tsk103);

    // Dependencies
    this.taskDependencies.push(
      { id: 'td-1', taskId: 'tsk-102', dependsOnTaskId: 'tsk-101', dependencyType: 'BLOCKS' },
      { id: 'td-2', taskId: 'tsk-103', dependsOnTaskId: 'tsk-102', dependencyType: 'BLOCKS' },
    );

    // Assignees
    this.taskAssignees.push(
      { id: 'ta-1', taskId: 'tsk-101', employeeId: 'emp-usr-employee', assignedAt: new Date('2026-02-05'), acceptedAt: new Date('2026-02-05') },
      { id: 'ta-2', taskId: 'tsk-102', employeeId: 'emp-usr-employee', assignedAt: new Date('2026-02-13'), acceptedAt: new Date('2026-02-13') },
      { id: 'ta-3', taskId: 'tsk-103', employeeId: 'emp-usr-employee', assignedAt: new Date('2026-02-13'), acceptedAt: null },
    );

    // 8. Sample Work Sessions & Attendance
    this.workSessions.push(
      {
        id: 'ws-1',
        organizationId: orgId,
        employeeId: 'emp-usr-employee',
        taskId: 'tsk-102',
        sessionType: 'WORK',
        startedAt: new Date(Date.now() - 3 * 3600 * 1000),
        stoppedAt: new Date(Date.now() - 1 * 3600 * 1000),
        durationSeconds: 7200, // 2 hours
        notes: 'Developing RBAC guard tests',
        createdAt: new Date(),
      },
      {
        id: 'ws-2',
        organizationId: orgId,
        employeeId: 'emp-usr-employee',
        taskId: 'tsk-102',
        sessionType: 'BREAK',
        startedAt: new Date(Date.now() - 1 * 3600 * 1000),
        stoppedAt: new Date(Date.now() - 45 * 60 * 1000),
        durationSeconds: 900, // 15 mins
        notes: 'Coffee break',
        createdAt: new Date(),
      }
    );

    this.attendanceRecords.push({
      id: 'att-1',
      organizationId: orgId,
      employeeId: 'emp-usr-employee',
      workDate: new Date().toISOString().split('T')[0],
      clockIn: new Date(Date.now() - 4 * 3600 * 1000),
      clockOut: null,
      totalHours: 4.0,
      status: 'PRESENT',
      notes: 'Active shift in office',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // 9. Initial Audit Record
    this.auditLogs.push({
      id: 'audit-001',
      organizationId: orgId,
      actorId: 'usr-superadmin',
      action: 'SYSTEM_BOOTSTRAP',
      entityName: 'organizations',
      entityId: orgId,
      beforeState: null,
      afterState: JSON.stringify({ name: 'ZeroCarbonix Technologies' }),
      ipAddress: '127.0.0.1',
      userAgent: 'System Seed Service',
      createdAt: new Date('2026-01-01'),
    });
  }
}

const repository = new EwmsRepository();

module.exports = {
  repository,
  hashPassword,
  verifyPassword,
};
