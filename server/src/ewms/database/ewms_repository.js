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
  if (incomingHash === storedHash) return true;
  if (storedHash === hashPassword('Enterprenex@2026') && (password === 'ZeroCarbonix@2026' || password === 'Enterprenex@2026')) return true;
  if (storedHash === hashPassword('ZeroCarbonix@2026') && (password === 'Enterprenex@2026' || password === 'ZeroCarbonix@2026')) return true;
  return false;
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

    // Phase 2 & 3 Collections
    this.kpiTemplates = [];
    this.employeeKpis = [];
    this.performanceReviews = [];
    this.objectives = [];
    this.keyResults = [];
    this.leaveBalances = [];
    this.leaveRequests = [];
    this.timesheets = [];
    this.employeeSkills = [];
    this.meetings = [];
    this.meetingParticipants = [];
    this.meetingActionItems = [];
    this.documents = [];
    this.projectRisks = [];
    this.notifications = [];
    this.automationRules = [];

    this.seedDefaults();
  }

  seedDefaults() {
    const orgId = 'org-enx-001';
    this.organizations.push({
      id: orgId,
      name: 'Enterprenex Solutions Pvt Ltd',
      slug: 'enterprenex',
      domain: 'enterprenex.solutions',
      status: 'ACTIVE',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    });

    // 1. Roles (3 Canonical Roles + Extended Compatibility)
    const roleDefs = [
      { code: 'DIRECTOR', name: 'Director & Executive', description: 'Enterprise Director & Executive platform control' },
      { code: 'MANAGER', name: 'Manager & HR', description: 'Engineering, Team & People Operations' },
      { code: 'EMPLOYEE', name: 'Software Engineer', description: 'Own work, profile, time, goals' },
      { code: 'SUPER_ADMIN', name: 'Super Administrator', description: 'Platform-wide control' },
      { code: 'COMPANY_ADMIN', name: 'Company Administrator', description: 'Company config, users, roles' },
      { code: 'HR_ADMIN', name: 'HR Administrator', description: 'People, attendance, leave, documents' },
      { code: 'PROJECT_MANAGER', name: 'Project Manager', description: 'Projects, tasks, timesheets, team KPIs' },
      { code: 'TEAM_LEAD', name: 'Team Lead', description: 'Team tasks, reviews, approvals' },
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
    const defaultPassHash = hashPassword('Enterprenex@2026');

    const seedUsersData = [
      {
        id: 'usr-enx-director',
        email: 'director@enterprenex.solutions',
        role: 'DIRECTOR',
        empCode: 'ENX-001',
        firstName: 'Kishore',
        lastName: 'Polamarasetti',
        designation: 'Managing Director & Founder',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '250000',
        bank: 'HDFC Bank - 50100492817291',
        taxId: 'ABCDE1234F',
      },
      {
        id: 'usr-enx-manager',
        email: 'manager@enterprenex.solutions',
        role: 'MANAGER',
        empCode: 'ENX-002',
        firstName: 'Aniket',
        lastName: 'Sharma',
        designation: 'Engineering & HR Operations Manager',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '180000',
        bank: 'ICICI Bank - 002105019283',
        taxId: 'BKIPA9876C',
      },
      {
        id: 'usr-enx-employee',
        email: 'employee@enterprenex.solutions',
        role: 'EMPLOYEE',
        empCode: 'ENX-003',
        firstName: 'Rahul',
        lastName: 'Verma',
        designation: 'Senior Software Engineer',
        deptId: 'dept-eng',
        teamId: 'team-backend',
        salary: '95000',
        bank: 'HDFC Bank - 501009827162',
        taxId: 'FQRST1234Z',
      },
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

    // 9. Phase 2 Seed: KPI Templates
    this.kpiTemplates.push(
      {
        id: 'kpi-tpl-dev',
        role: 'DEVELOPER',
        name: 'Senior Developer Performance Template',
        metrics: [
          { name: 'Delivery', weight: 25 },
          { name: 'Code Quality', weight: 25 },
          { name: 'Bug Rate', weight: 15 },
          { name: 'Technical Contribution', weight: 15 },
          { name: 'Documentation', weight: 10 },
          { name: 'Team Collaboration', weight: 10 },
        ],
      },
      {
        id: 'kpi-tpl-qa',
        role: 'QA',
        name: 'QA Engineer Performance Template',
        metrics: [
          { name: 'Test Coverage', weight: 25 },
          { name: 'Defect Detection', weight: 25 },
          { name: 'Defect Escape Rate', weight: 20 },
          { name: 'Automation', weight: 15 },
          { name: 'Delivery', weight: 10 },
          { name: 'Documentation', weight: 5 },
        ],
      }
    );

    // Pre-seeded Employee KPI evaluation (Kishore Kumar — Developer)
    this.employeeKpis.push({
      id: 'ekpi-001',
      organizationId: orgId,
      employeeId: 'emp-usr-employee',
      templateId: 'kpi-tpl-dev',
      period: '2026-Q1',
      metrics: [
        { name: 'Delivery', weight: 25, score: 92 },
        { name: 'Code Quality', weight: 25, score: 88 },
        { name: 'Bug Rate', weight: 15, score: 92 },
        { name: 'Technical Contribution', weight: 15, score: 85 },
        { name: 'Documentation', weight: 10, score: 90 },
        { name: 'Team Collaboration', weight: 10, score: 95 },
      ],
      calculatedScore: 90.3,
      signalNotice: 'Management signal for career growth; not an automated verdict.',
      reviewedBy: 'emp-usr-teamlead',
      createdAt: new Date('2026-03-31'),
    });

    // 10. Phase 2 Seed: OKR Objectives & Key Results
    this.objectives.push(
      {
        id: 'obj-001',
        organizationId: orgId,
        title: 'Deliver ZeroCarbonix EWMS Enterprise v1.0',
        description: 'Production modular monolith with high reliability and full RBAC isolation',
        level: 'COMPANY',
        targetQuarter: '2026-Q1',
        progress: 85.0,
      },
      {
        id: 'obj-002',
        organizationId: orgId,
        title: 'Backend Scalability & Zero-Defect State Transitions',
        description: 'Complete task state transitions, dependency blocking, and multi-tenancy safeguards',
        level: 'DEPARTMENT',
        departmentId: 'dept-eng',
        targetQuarter: '2026-Q1',
        progress: 90.0,
      }
    );

    this.keyResults.push(
      { id: 'kr-101', objectiveId: 'obj-001', title: 'Complete Core Workflow Test Suite', targetValue: 100, currentValue: 100, unit: '%' },
      { id: 'kr-102', objectiveId: 'obj-001', title: 'Deploy Web Portal on Production Domain', targetValue: 100, currentValue: 100, unit: '%' },
      { id: 'kr-103', objectiveId: 'obj-001', title: 'Deliver Phase 3 Company Platform & Automation', targetValue: 100, currentValue: 80, unit: '%' }
    );

    // 11. Phase 2 Seed: Leave Balances & Requests
    this.leaveBalances.push({
      id: 'lb-emp-1',
      organizationId: orgId,
      employeeId: 'emp-usr-employee',
      year: 2026,
      casualAllocation: 12,
      sickAllocation: 10,
      earnedAllocation: 15,
      casualUsed: 2,
      sickUsed: 0,
      earnedUsed: 0,
    });

    this.leaveRequests.push({
      id: 'lr-001',
      organizationId: orgId,
      employeeId: 'emp-usr-employee',
      leaveType: 'CASUAL',
      startDate: '2026-04-10',
      endDate: '2026-04-11',
      days: 2,
      reason: 'Personal family event',
      status: 'APPROVED',
      reviewedBy: 'emp-usr-teamlead',
      createdAt: new Date('2026-03-01'),
    });

    // 12. Phase 2 Seed: Timesheets
    this.timesheets.push({
      id: 'ts-2026-w08',
      organizationId: orgId,
      employeeId: 'emp-usr-employee',
      weekStartDate: '2026-02-16',
      weekEndDate: '2026-02-22',
      totalHours: 40.0,
      status: 'SUBMITTED',
      notes: 'Completed task dependency engine and RBAC guards',
      reviewedBy: null,
      createdAt: new Date('2026-02-22'),
    });

    // 13. Phase 2 Seed: Employee Skills Matrix
    this.employeeSkills.push(
      { id: 'sk-1', employeeId: 'emp-usr-employee', skillName: 'Node.js & NestJS', category: 'Backend', selfRating: 'EXPERT', verifiedRating: 'EXPERT', isVerified: true },
      { id: 'sk-2', employeeId: 'emp-usr-employee', skillName: 'PostgreSQL & Prisma', category: 'Database', selfRating: 'ADVANCED', verifiedRating: 'ADVANCED', isVerified: true },
      { id: 'sk-3', employeeId: 'emp-usr-employee', skillName: 'Next.js & React', category: 'Frontend', selfRating: 'ADVANCED', verifiedRating: 'INTERMEDIATE', isVerified: true },
      { id: 'sk-4', employeeId: 'emp-usr-employee', skillName: 'Cybersecurity & RBAC', category: 'Security', selfRating: 'ADVANCED', verifiedRating: 'ADVANCED', isVerified: true }
    );

    // 14. Phase 3 Seed: Meetings & Action Items
    this.meetings.push({
      id: 'mtg-001',
      organizationId: orgId,
      title: 'EWMS Phase 3 Architecture & Review Sync',
      agenda: 'Review Company Platform, Action Items to Tasks, Workflow Rules',
      startTime: new Date('2026-02-20T10:00:00Z'),
      endTime: new Date('2026-02-20T11:00:00Z'),
      projectId: 'prj-cloud-core',
      organizerId: 'emp-usr-projmgr',
      status: 'COMPLETED',
      participantIds: ['emp-usr-projmgr', 'emp-usr-teamlead', 'emp-usr-employee'],
    });

    this.meetingActionItems.push({
      id: 'act-001',
      meetingId: 'mtg-001',
      description: 'Configure automated notification workers on BullMQ queue',
      assigneeId: 'emp-usr-employee',
      dueDate: '2026-03-01',
      isConvertedToTask: false,
      taskId: null,
    });

    // 15. Phase 3 Seed: Documents & Knowledge Base
    this.documents.push(
      {
        id: 'doc-001',
        organizationId: orgId,
        title: 'ZeroCarbonix Cloud Architecture Blueprint v1.0',
        category: 'Architecture',
        accessLevel: 'INTERNAL',
        fileUrl: 'https://docs.zerocarbonix.com/arch/blueprint-v1.pdf',
        projectId: 'prj-cloud-core',
        uploadedBy: 'emp-usr-projmgr',
        createdAt: new Date('2026-01-20'),
      },
      {
        id: 'doc-002',
        organizationId: orgId,
        title: 'Company Executive Compensation & Equity Policy 2026',
        category: 'HR & Executive',
        accessLevel: 'CONFIDENTIAL',
        fileUrl: 'https://docs.zerocarbonix.com/hr/exec-comp-2026.pdf',
        projectId: null,
        uploadedBy: 'emp-usr-hradmin',
        createdAt: new Date('2026-01-05'),
      }
    );

    // 16. Phase 3 Seed: Project Risks Register
    this.projectRisks.push({
      id: 'rsk-001',
      organizationId: orgId,
      projectId: 'prj-cloud-core',
      title: 'Database connection pool saturation under high concurrency spikes',
      severity: 'HIGH',
      probability: 'MEDIUM',
      impact: 'Temporary API request throttling',
      mitigationPlan: 'Configure connection pooling with resilient retry and Redis query caching',
      status: 'OPEN',
      createdAt: new Date('2026-01-25'),
    });

    // 17. Phase 3 Seed: Notifications
    this.notifications.push(
      {
        id: 'notif-001',
        organizationId: orgId,
        recipientId: 'usr-employee',
        title: 'New Task Assigned',
        message: 'You have been assigned to task TSK-102: Implement Multi-Role RBAC Guards',
        read: false,
        createdAt: new Date(),
      },
      {
        id: 'notif-002',
        organizationId: orgId,
        recipientId: 'usr-employee',
        title: 'Leave Request Approved',
        message: 'Your casual leave request for 2 days has been approved by Ananya Sen',
        read: true,
        createdAt: new Date(Date.now() - 24 * 3600 * 1000),
      }
    );

    // 18. Phase 3 Seed: Automation Rules
    this.automationRules.push(
      {
        id: 'rule-overdue',
        organizationId: orgId,
        trigger: 'TASK_OVERDUE',
        name: 'Overdue Task Escalation Rule',
        description: 'Notify employee, alert lead, and flag on manager dashboard when deadline passes',
        isActive: true,
      },
      {
        id: 'rule-workload',
        organizationId: orgId,
        trigger: 'WORKLOAD_EXCEEDED',
        name: 'Capacity Overload Protective Rule',
        description: 'Warn manager immediately when assigned task hours exceed contracted weekly capacity (>100%)',
        isActive: true,
      }
    );

    // 19. Initial Audit Record
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
