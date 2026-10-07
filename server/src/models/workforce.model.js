/**
 * Enterprenex Solutions — Workforce Management & Task Assignment Model
 * Handles:
 * 1. Role-based Employee Profiles (CEO, CTO, CFO, HR, Team Leads, Employees)
 * 2. Daily Attendance & Clock-In / Clock-Out tracking with real-time hours
 * 3. Task Assignment & Kanban Work Delivery Engine
 */

const fs = require('fs');
const path = require('path');
const { generateUuid } = require('../utils/crypto.util');

const STORE_FILE = process.env.NODE_ENV === 'test'
  ? path.join(__dirname, '../../database/enx_workforce_store.test.json')
  : path.join(__dirname, '../../database/enx_workforce_store.json');

class WorkforceModel {
  static _employees = new Map();
  static _attendance = new Map(); // Key: `${employeeId}_${dateString}`
  static _tasks = new Map();      // Key: taskId
  static _initialized = false;

  static _init() {
    if (this._initialized) return;
    this._loadFromDisk();
    if (this._employees.size === 0) {
      this._seedDefaultStaff();
    }
    this._initialized = true;
  }

  static _loadFromDisk() {
    try {
      if (fs.existsSync(STORE_FILE)) {
        const raw = fs.readFileSync(STORE_FILE, 'utf8');
        const data = JSON.parse(raw);
        if (data.employees && Array.isArray(data.employees)) {
          for (const emp of data.employees) {
            this._employees.set(String(emp.id), emp);
          }
        }
        if (data.attendance && Array.isArray(data.attendance)) {
          for (const att of data.attendance) {
            this._attendance.set(`${att.employeeId}_${att.date}`, att);
          }
        }
        if (data.tasks && Array.isArray(data.tasks)) {
          for (const t of data.tasks) {
            this._tasks.set(String(t.id), t);
          }
        }
      }
    } catch (_) {}
  }

  static _saveToDisk() {
    try {
      const dir = path.dirname(STORE_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      const data = {
        employees: Array.from(this._employees.values()),
        attendance: Array.from(this._attendance.values()),
        tasks: Array.from(this._tasks.values()),
        updatedAt: new Date().toISOString()
      };
      fs.writeFileSync(STORE_FILE, JSON.stringify(data, null, 2), 'utf8');
    } catch (_) {}
  }

  static _seedDefaultStaff() {
    const defaultStaff = [
      {
        id: 'EMP-001',
        name: 'Rohit Pawar',
        email: 'rohit@enterprenex.solutions',
        role: 'CEO',
        department: 'EXECUTIVE',
        designation: 'Chief Executive Officer',
        phone: '+91-9226860060',
        status: 'ACTIVE',
        password: 'Admin@123',
        joinedDate: '2025-01-01'
      },
      {
        id: 'EMP-002',
        name: 'Revanth Reddy',
        email: 'revanth.reddy@enterprenex.solutions',
        role: 'CTO',
        department: 'ENGINEERING',
        designation: 'Chief Technology Officer',
        phone: '+91-9440829762',
        status: 'ACTIVE',
        password: 'Admin@123',
        joinedDate: '2025-01-15'
      },
      {
        id: 'EMP-003',
        name: 'Aniket Tambe',
        email: 'aniket@enterprenex.solutions',
        role: 'CFO',
        department: 'FINANCE',
        designation: 'Chief Financial Officer',
        phone: '+91-9876543210',
        status: 'ACTIVE',
        password: 'Admin@123',
        joinedDate: '2025-02-01'
      },
      {
        id: 'EMP-004',
        name: 'Jyothi Sharma',
        email: 'jyothi@enterprenex.solutions',
        role: 'HR',
        department: 'HUMAN_RESOURCES',
        designation: 'Head of Human Resources & People Ops',
        phone: '+91-9811223344',
        status: 'ACTIVE',
        password: 'Admin@123',
        joinedDate: '2025-03-01'
      },
      {
        id: 'EMP-005',
        name: 'Piyush Jadhav',
        email: 'piyush@enterprenex.solutions',
        role: 'LEAD',
        department: 'ENGINEERING',
        designation: 'Lead Full-Stack Engineer',
        phone: '+91-9822334455',
        status: 'ACTIVE',
        password: 'Admin@123',
        joinedDate: '2025-04-01'
      },
      {
        id: 'EMP-006',
        name: 'Kishore Kumar',
        email: 'kishore@enterprenex.solutions',
        role: 'EMPLOYEE',
        department: 'ENGINEERING',
        designation: 'Senior Backend Developer',
        phone: '+91-9900112233',
        status: 'ACTIVE',
        password: 'Admin@123',
        joinedDate: '2025-05-15'
      }
    ];

    for (const s of defaultStaff) {
      this._employees.set(s.id, s);
    }

    // Seed default tasks
    const defaultTasks = [
      {
        id: 'TSK-101',
        title: 'Review Google Play Store Production Bundle & Permissions',
        description: 'Verify 64-bit compliance, target SDK 35, and contact picker runtime permissions before app release.',
        department: 'ENGINEERING',
        priority: 'HIGH',
        status: 'IN_PROGRESS',
        assignedBy: 'EMP-002',
        assignedByName: 'Revanth Reddy (CTO)',
        assignedTo: 'EMP-005',
        assignedToName: 'Piyush Jadhav',
        dueDate: '2026-10-15',
        createdAt: new Date().toISOString(),
        proofUrl: 'https://github.com/Enterprenex-Solutions/Enx-Money',
        workNotes: 'Updated manifest with modern permission scopes and validated flutter test build.'
      },
      {
        id: 'TSK-102',
        title: 'Finalize Q4 Settlement Reports & GST Filing Ledger',
        description: 'Audit monthly merchant payout batches and ensure Jio Payments Bank URN records balance accurately.',
        department: 'FINANCE',
        priority: 'URGENT',
        status: 'TODO',
        assignedBy: 'EMP-001',
        assignedByName: 'Rohit Pawar (CEO)',
        assignedTo: 'EMP-003',
        assignedToName: 'Aniket Tambe',
        dueDate: '2026-10-10',
        createdAt: new Date().toISOString(),
        proofUrl: '',
        workNotes: ''
      },
      {
        id: 'TSK-103',
        title: 'Complete Onboarding & Device Approvals for New Field Staff',
        description: 'Issue official employee IDs, activate email aliases, and verify biometric multi-device auth keys.',
        department: 'HUMAN_RESOURCES',
        priority: 'MEDIUM',
        status: 'DONE',
        assignedBy: 'EMP-001',
        assignedByName: 'Rohit Pawar (CEO)',
        assignedTo: 'EMP-004',
        assignedToName: 'Jyothi Sharma',
        dueDate: '2026-10-05',
        completedAt: new Date().toISOString(),
        createdAt: new Date(Date.now() - 86400000 * 2).toISOString(),
        proofUrl: '',
        workNotes: 'Completed verification for all field operators.'
      }
    ];

    for (const t of defaultTasks) {
      this._tasks.set(t.id, t);
    }

    this._saveToDisk();
  }

  // ── Employees ─────────────────────────────────────────────────────────────
  static findEmployeeByEmail(email) {
    this._init();
    if (!email) return null;
    const clean = email.toLowerCase().trim();
    for (const emp of this._employees.values()) {
      if (emp.email.toLowerCase().trim() === clean) {
        return emp;
      }
    }
    return null;
  }

  static findEmployeeById(id) {
    this._init();
    return this._employees.get(String(id)) || null;
  }

  static listEmployees({ department, role, status } = {}) {
    this._init();
    let list = Array.from(this._employees.values());
    if (department) list = list.filter(e => e.department === department);
    if (role) list = list.filter(e => e.role === role);
    if (status) list = list.filter(e => e.status === status);
    return list;
  }

  static createEmployee(data) {
    this._init();
    const id = `EMP-${String(this._employees.size + 1).padStart(3, '0')}`;
    const newEmp = {
      id,
      name: data.name,
      email: data.email.toLowerCase().trim(),
      role: data.role || 'EMPLOYEE',
      department: data.department || 'OPERATIONS',
      designation: data.designation || 'Specialist',
      phone: data.phone || '',
      status: 'ACTIVE',
      password: data.password || 'Admin@123',
      joinedDate: data.joinedDate || new Date().toISOString().split('T')[0],
      createdAt: new Date().toISOString()
    };
    this._employees.set(id, newEmp);
    this._saveToDisk();
    return newEmp;
  }

  // ── Attendance & Punch Clock ──────────────────────────────────────────────
  static _getDateString(date = new Date()) {
    return date.toISOString().split('T')[0];
  }

  static clockIn(employeeId, { notes = '', ipAddress = '' } = {}) {
    this._init();
    const emp = this.findEmployeeById(employeeId);
    if (!emp) throw new Error('Employee not found');

    const today = this._getDateString();
    const key = `${emp.id}_${today}`;
    const existing = this._attendance.get(key);

    if (existing && existing.clockInTime && !existing.clockOutTime) {
      return {
        alreadyClockedIn: true,
        attendance: existing,
        message: 'You are already clocked in today.'
      };
    }

    const now = new Date();
    const attendanceRecord = existing || {
      id: `ATT-${Date.now()}`,
      employeeId: emp.id,
      employeeName: emp.name,
      department: emp.department,
      date: today,
      clockInTime: now.toISOString(),
      clockOutTime: null,
      totalHours: 0,
      totalMinutes: 0,
      status: 'PRESENT',
      notes: notes,
      ipAddress: ipAddress,
      updatedAt: now.toISOString()
    };

    // Reset clock-in session
    attendanceRecord.clockInTime = now.toISOString();
    attendanceRecord.clockOutTime = null;
    attendanceRecord.status = 'PRESENT';
    if (notes) attendanceRecord.notes = notes;

    this._attendance.set(key, attendanceRecord);
    this._saveToDisk();

    return {
      success: true,
      attendance: attendanceRecord,
      message: `Clocked in successfully at ${now.toLocaleTimeString()}`
    };
  }

  static clockOut(employeeId, { notes = '' } = {}) {
    this._init();
    const emp = this.findEmployeeById(employeeId);
    if (!emp) throw new Error('Employee not found');

    const today = this._getDateString();
    const key = `${emp.id}_${today}`;
    const record = this._attendance.get(key);

    if (!record || !record.clockInTime) {
      throw new Error('No active clock-in found for today. Please clock in first.');
    }

    const now = new Date();
    record.clockOutTime = now.toISOString();

    const start = new Date(record.clockInTime);
    const diffMs = now.getTime() - start.getTime();
    const totalMinutes = Math.max(1, Math.round(diffMs / (1000 * 60)));
    const hours = (totalMinutes / 60).toFixed(2);

    record.totalMinutes = totalMinutes;
    record.totalHours = parseFloat(hours);
    record.status = totalMinutes >= 240 ? 'PRESENT' : 'HALF_DAY';
    if (notes) record.notes = (record.notes ? record.notes + ' | ' : '') + notes;
    record.updatedAt = now.toISOString();

    this._attendance.set(key, record);
    this._saveToDisk();

    return {
      success: true,
      attendance: record,
      message: `Clocked out successfully at ${now.toLocaleTimeString()} (Active: ${Math.floor(totalMinutes / 60)}h ${totalMinutes % 60}m)`
    };
  }

  static getTodayAttendance(employeeId) {
    this._init();
    const today = this._getDateString();
    return this._attendance.get(`${employeeId}_${today}`) || null;
  }

  static getAttendanceRecords({ date, department, employeeId } = {}) {
    this._init();
    let records = Array.from(this._attendance.values());
    if (date) records = records.filter(r => r.date === date);
    if (department) records = records.filter(r => r.department === department);
    if (employeeId) records = records.filter(r => r.employeeId === employeeId);
    return records.sort((a, b) => new Date(b.date) - new Date(a.date));
  }

  static getLiveCompanyStatus() {
    this._init();
    const today = this._getDateString();
    const employees = this.listEmployees({ status: 'ACTIVE' });

    return employees.map(emp => {
      const att = this._attendance.get(`${emp.id}_${today}`);
      let status = 'NOT_CHECKED_IN';
      let activeMinutes = 0;

      if (att) {
        if (att.clockInTime && !att.clockOutTime) {
          status = 'WORKING';
          activeMinutes = Math.round((Date.now() - new Date(att.clockInTime).getTime()) / 60000);
        } else if (att.clockOutTime) {
          status = 'CLOCKED_OUT';
          activeMinutes = att.totalMinutes || 0;
        }
      }

      return {
        id: emp.id,
        name: emp.name,
        email: emp.email,
        role: emp.role,
        department: emp.department,
        designation: emp.designation,
        workStatus: status, // WORKING | CLOCKED_OUT | NOT_CHECKED_IN
        clockInTime: att ? att.clockInTime : null,
        clockOutTime: att ? att.clockOutTime : null,
        activeMinutes,
        activeHoursFormatted: `${Math.floor(activeMinutes / 60)}h ${activeMinutes % 60}m`,
        date: today
      };
    });
  }

  // ── Tasks & Work Assignments ──────────────────────────────────────────────
  static createTask(data) {
    this._init();
    const id = `TSK-${String(this._tasks.size + 101)}`;
    const assignee = this.findEmployeeById(data.assignedTo);
    const assigner = this.findEmployeeById(data.assignedBy);

    const newTask = {
      id,
      title: data.title,
      description: data.description || '',
      department: data.department || (assignee ? assignee.department : 'ENGINEERING'),
      priority: data.priority || 'MEDIUM', // LOW | MEDIUM | HIGH | URGENT
      status: 'TODO',                      // TODO | IN_PROGRESS | REVIEW | DONE
      assignedBy: data.assignedBy,
      assignedByName: assigner ? `${assigner.name} (${assigner.role})` : 'Leadership',
      assignedTo: data.assignedTo,
      assignedToName: assignee ? assignee.name : 'Unassigned',
      dueDate: data.dueDate || new Date(Date.now() + 86400000 * 3).toISOString().split('T')[0],
      createdAt: new Date().toISOString(),
      completedAt: null,
      proofUrl: data.proofUrl || '',
      workNotes: ''
    };

    this._tasks.set(id, newTask);
    this._saveToDisk();
    return newTask;
  }

  static updateTaskStatus(taskId, { status, workNotes, proofUrl, updatedBy }) {
    this._init();
    const task = this._tasks.get(String(taskId));
    if (!task) throw new Error('Task not found');

    if (status) task.status = status;
    if (workNotes !== undefined) task.workNotes = workNotes;
    if (proofUrl !== undefined) task.proofUrl = proofUrl;
    if (status === 'DONE' && !task.completedAt) {
      task.completedAt = new Date().toISOString();
    }
    task.updatedAt = new Date().toISOString();
    task.lastUpdatedBy = updatedBy;

    this._tasks.set(String(taskId), task);
    this._saveToDisk();
    return task;
  }

  static listTasks({ assignedTo, assignedBy, department, status, priority } = {}) {
    this._init();
    let tasks = Array.from(this._tasks.values());
    if (assignedTo) tasks = tasks.filter(t => t.assignedTo === assignedTo);
    if (assignedBy) tasks = tasks.filter(t => t.assignedBy === assignedBy);
    if (department) tasks = tasks.filter(t => t.department === department);
    if (status) tasks = tasks.filter(t => t.status === status);
    if (priority) tasks = tasks.filter(t => t.priority === priority);
    return tasks.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  static getTaskById(taskId) {
    this._init();
    return this._tasks.get(String(taskId)) || null;
  }

  static deleteTask(taskId) {
    this._init();
    const exists = this._tasks.has(String(taskId));
    if (exists) {
      this._tasks.delete(String(taskId));
      this._saveToDisk();
    }
    return exists;
  }

  // ── Executive Statistics ──────────────────────────────────────────────────
  static getOrgOverview() {
    this._init();
    const employees = Array.from(this._employees.values());
    const tasks = Array.from(this._tasks.values());
    const live = this.getLiveCompanyStatus();

    const onlineCount = live.filter(e => e.workStatus === 'WORKING').length;
    const completedTasks = tasks.filter(t => t.status === 'DONE').length;
    const activeTasks = tasks.filter(t => t.status === 'IN_PROGRESS' || t.status === 'TODO').length;
    const urgentTasks = tasks.filter(t => t.priority === 'URGENT' && t.status !== 'DONE').length;

    return {
      totalStaff: employees.length,
      onlineNow: onlineCount,
      clockedOutToday: live.filter(e => e.workStatus === 'CLOCKED_OUT').length,
      absentToday: live.filter(e => e.workStatus === 'NOT_CHECKED_IN').length,
      totalTasks: tasks.length,
      activeTasks,
      completedTasks,
      urgentTasks,
      productivityPercentage: tasks.length > 0 ? Math.round((completedTasks / tasks.length) * 100) : 100,
      departments: ['EXECUTIVE', 'ENGINEERING', 'FINANCE', 'HUMAN_RESOURCES', 'OPERATIONS']
    };
  }

  static _resetForTesting() {
    this._attendance.clear();
    this._tasks.clear();
    this._employees.clear();
    this._initialized = false;
    this._init();
  }
}

module.exports = WorkforceModel;
