const AiService = require('../services/ai.service');
const { successResponse } = require('../utils/response.util');

class AIController {
  static async sendMessage(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const { message, language, history, provider } = req.body;

      if (!message || typeof message !== 'string' || !message.trim()) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_REQUEST_BODY',
          message: 'A valid message string is required',
        });
      }

      const result = await AiService.chat({
        userId,
        message: message.trim(),
        history: Array.isArray(history) ? history : [],
        language: language || 'en',
        provider: provider || 'auto',
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'AI response generated successfully',
        data: result,
      });
    } catch (error) {
      const statusCode = error.statusCode || 500;
      const errorCode = error.code || 'AI_SERVICE_ERROR';
      const userMessage = error.userMessage || 'AI service is temporarily unavailable. Please try again.';

      // Sanitized server error log - never leak secret keys or tokens
      console.error(`[AIController] Error (${errorCode}):`, error.message);

      return res.status(statusCode).json({
        success: false,
        error: errorCode,
        message: userMessage,
      });
    }
  }

  static async getHistory(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const history = AiService.getHistory(userId);

      return successResponse(res, {
        statusCode: 200,
        message: 'Chat history retrieved successfully',
        data: history,
      });
    } catch (error) {
      next(error);
    }
  }

  static async clearHistory(req, res, next) {
    try {
      const userId = req.user ? req.user.id : 'default_user';
      const cleared = AiService.clearHistory(userId);

      return successResponse(res, {
        statusCode: 200,
        message: 'Chat history cleared successfully',
        data: { cleared },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AIController;
