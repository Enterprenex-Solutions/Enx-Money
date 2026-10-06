const express = require('express');
const SettingsController = require('../controllers/settings.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(optionalAuth);

router.get('/', SettingsController.getSettings);
router.put('/profile', SettingsController.updateProfile);
router.put('/business', SettingsController.updateBusiness);
router.put('/personal', SettingsController.updatePersonal);
router.put('/finance', SettingsController.updateFinance);
router.put('/transactions', SettingsController.updateTransactions);
router.put('/gst', SettingsController.updateGst);
router.put('/notifications', SettingsController.updateNotifications);
router.put('/reports', SettingsController.updateReports);
router.put('/security', SettingsController.updateSecurity);
router.put('/application', SettingsController.updateApplication);
router.post('/reset', SettingsController.resetSection);

module.exports = router;
