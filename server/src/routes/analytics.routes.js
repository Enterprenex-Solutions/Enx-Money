const express = require('express');
const AnalyticsController = require('../controllers/analytics.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(optionalAuth);

// Anjali Branch & Data Analysis Core Endpoints
router.get('/kpi', AnalyticsController.getKpi);
router.get('/daily-trend', AnalyticsController.getDailyTrend);
router.get('/categories', AnalyticsController.getCategories);
router.get('/health-score', AnalyticsController.getHealthScore);
router.get('/business-health-score', AnalyticsController.getHealthScore);

router.get('/dashboard', AnalyticsController.getDashboard);
router.get('/overview', AnalyticsController.getDashboard);
router.get('/drill-down', AnalyticsController.getDrillDown);
router.get('/powerbi-dataset', AnalyticsController.getPowerBIDataset);
router.post('/custom-report', AnalyticsController.runCustomReport);
router.post('/schedule-email', AnalyticsController.scheduleEmail);
router.get('/export/excel', AnalyticsController.exportExcel);

module.exports = router;
