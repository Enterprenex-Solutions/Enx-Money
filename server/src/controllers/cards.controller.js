const CardModel = require('../models/card.model');
const UserModel = require('../models/user.model');
const { successResponse, errorResponse } = require('../utils/response.util');

class CardsController {
  /**
   * GET /api/cards/me or /api/cards
   * Returns only the authenticated user's cards
   */
  static async getMyCards(req, res, next) {
    try {
      const userId = req.user.id;
      let cards = await CardModel.findByUserId(userId);

      // If user is freshly registered and has no cards, we return empty list []
      // or optionally auto-issue their primary card based on user preference
      return successResponse(res, {
        statusCode: 200,
        message: cards.length > 0 ? 'Cards retrieved successfully' : 'No cards found for current user',
        data: {
          cards,
          count: cards.length,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/cards
   * Issues a new card for the authenticated user
   */
  static async createCard(req, res, next) {
    try {
      const userId = req.user.id;
      const { cardTier, network, limit, balance, cardHolderName } = req.body;

      // Determine holder name from request or authenticated user's profile
      let name = cardHolderName || req.user.name;
      if (!name || name === 'ENX User') {
        const user = await UserModel.findById(userId);
        if (user && user.name) {
          name = user.name;
        }
      }

      const card = await CardModel.createCard({
        userId,
        cardHolderName: name,
        cardTier: cardTier || 'Black Metal',
        network: network || 'Visa',
        limit: limit || 500000.00,
        balance: balance || 150000.00,
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'New card issued successfully',
        data: { card },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/cards/:id/freeze
   * Toggle freeze status for the card (verifies ownership)
   */
  static async toggleFreeze(req, res, next) {
    try {
      const userId = req.user.id;
      const cardId = req.params.id;

      const updatedCard = await CardModel.toggleFreeze(cardId, userId);
      if (!updatedCard) {
        return errorResponse(res, {
          statusCode: 404,
          message: 'Card not found or you do not have permission to modify this card.',
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: `Card ${updatedCard.isFrozen ? 'frozen' : 'unfrozen'} successfully`,
        data: { card: updatedCard },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/cards/:id/controls
   * Update contactless or international usage controls
   */
  static async updateControls(req, res, next) {
    try {
      const userId = req.user.id;
      const cardId = req.params.id;
      const { isContactlessActive, isInternationalActive } = req.body;

      const updatedCard = await CardModel.updateControls(cardId, userId, {
        isContactlessActive,
        isInternationalActive,
      });

      if (!updatedCard) {
        return errorResponse(res, {
          statusCode: 404,
          message: 'Card not found or you do not have permission to modify this card.',
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Card controls updated successfully',
        data: { card: updatedCard },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = CardsController;
