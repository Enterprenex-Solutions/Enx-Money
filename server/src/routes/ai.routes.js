const express = require('express');
const AIController = require('../controllers/ai.controller');
const { optionalAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(optionalAuth);

router.post('/chat', AIController.sendMessage);
router.get('/history', AIController.getHistory);
router.delete('/history', AIController.clearHistory);

module.exports = router;
