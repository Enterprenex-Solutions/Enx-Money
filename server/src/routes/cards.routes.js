const express = require('express');
const CardsController = require('../controllers/cards.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

const router = express.Router();

// All card routes require authentication (JWT Bearer token)
router.use(authenticateToken);

// GET /api/cards/me & GET /api/cards
router.get('/me', CardsController.getMyCards);
router.get('/', CardsController.getMyCards);

// POST /api/cards (issue new card for current user)
router.post('/', CardsController.createCard);

// PATCH /api/cards/:id/freeze
router.patch('/:id/freeze', CardsController.toggleFreeze);

// PATCH /api/cards/:id/controls
router.patch('/:id/controls', CardsController.updateControls);

module.exports = router;
