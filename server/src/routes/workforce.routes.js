/**
 * Enterprenex Solutions — Workforce & Task Management Routes
 * Endpoints for employee authentication, attendance tracking,
 * task assignments, and executive dashboards.
 */

const express = require('express');
const jwt = require('jsonwebtoken');
const WorkforceController = require('../controllers/workforce.controller');
const config = require('../config/env.config');

const router = express.Router();
const JWT_SECRET = config.JWT_SECRET || 'enx_super_secret_jwt_key_lux_fintech_2026_x99a!';

// Optional/Soft JWT middleware for workforce sessions
const parseWorkforceAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      req.workforceUser = jwt.verify(token, JWT_SECRET);
    } catch (_) {}
  }
  next();
};

router.use(parseWorkforceAuth);

// ── Auth & Profile ──────────────────────────────────────────────────────────
router.post('/login', WorkforceController.login);
router.get('/me', WorkforceController.getMe);

// ── Attendance & Punch Clock ────────────────────────────────────────────────
router.post('/attendance/clock-in', WorkforceController.clockIn);
router.post('/attendance/clock-out', WorkforceController.clockOut);
router.get('/attendance/live', WorkforceController.getLiveAttendance);
router.get('/attendance/history', WorkforceController.getAttendanceHistory);

// ── Tasks & Work Assignments ────────────────────────────────────────────────
router.get('/tasks', WorkforceController.listTasks);
router.post('/tasks', WorkforceController.createTask);
router.patch('/tasks/:id/status', WorkforceController.updateTaskStatus);

// ── Directory & Organization ────────────────────────────────────────────────
router.get('/employees', WorkforceController.listEmployees);
router.post('/employees', WorkforceController.createEmployee);
router.get('/overview', WorkforceController.getOverview);

module.exports = router;
