const express = require('express');
const DashboardController = require('../controllers/dashboard.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(optionalAuth);

// GET /api/v1/dashboard/metrics or /api/dashboard/metrics
router.get('/metrics', DashboardController.getMetrics);
router.get('/', DashboardController.getMetrics);

module.exports = router;
