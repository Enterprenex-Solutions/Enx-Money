const express = require('express');
const ComplianceController = require('../controllers/compliance.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

const router = express.Router();

// Public overview & status
router.get('/overview', ComplianceController.getOverview);

// Protected compliance endpoints
router.get('/events', authenticateToken, ComplianceController.getEvents);
router.post('/events', authenticateToken, ComplianceController.logEvent);
router.get('/lineage', authenticateToken, ComplianceController.getLineage);
router.get('/access-matrix', authenticateToken, ComplianceController.getAccessMatrix);
router.get('/consent', authenticateToken, ComplianceController.getConsentRegister);
router.get('/retention', authenticateToken, ComplianceController.getRetentionPolicies);
router.post('/retention/purge', authenticateToken, ComplianceController.triggerPurge);
router.get('/model-governance', authenticateToken, ComplianceController.getModelGovernance);
router.get('/register', authenticateToken, ComplianceController.getComplianceRegister);
router.get('/signoff', authenticateToken, ComplianceController.getSignOffChecklist);

module.exports = router;
