const express = require('express');
const PowerBiController = require('../controllers/powerBi.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/schema', PowerBiController.getSchema);
router.get('/payload', authenticateToken, PowerBiController.getPayload);
router.post('/sync', authenticateToken, PowerBiController.syncToPowerBi);
router.get('/status', PowerBiController.getStatus);

module.exports = router;
