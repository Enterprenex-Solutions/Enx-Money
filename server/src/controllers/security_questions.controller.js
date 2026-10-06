const bcrypt = require('bcryptjs');
const db = require('../config/db.config');
const UserModel = require('../models/user.model');
const TokenService = require('../services/token.service');
const { successResponse, errorResponse } = require('../utils/response.util');

const STANDARD_SECURITY_QUESTIONS = [
  { id: 'q1', text: "What is your best friend's name?" },
  { id: 'q2', text: "What is your favourite colour?" },
  { id: 'q3', text: "What was the name of your first school?" },
  { id: 'q4', text: "What was the make of your first car or bike?" },
  { id: 'q5', text: "What city was your mother born in?" },
  { id: 'q6', text: "What was your childhood nickname?" },
];

// In-memory rate limiting store for failed verification attempts: identifier -> { count, lockedUntil }
const _attemptStore = new Map();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

class SecurityQuestionsController {
  /**
   * GET /api/v1/auth/security-questions
   * Returns list of available standard security questions
   */
  static async getCatalog(req, res) {
    return successResponse(res, {
      statusCode: 200,
      message: 'Standard security questions catalog',
      data: {
        questions: STANDARD_SECURITY_QUESTIONS,
      },
    });
  }

  /**
   * POST /api/v1/auth/security-questions/setup
   * Authenticated endpoint to configure 3 security questions and hashed answers
   */
  static async setupQuestions(req, res, next) {
    try {
      const userId = req.user ? req.user.id : null;
      if (!userId) {
        return errorResponse(res, { statusCode: 401, message: 'Authentication required to configure security questions' });
      }

      const { questions } = req.body;
      if (!Array.isArray(questions) || questions.length < 2 || questions.length > 3) {
        return errorResponse(res, {
          statusCode: 400,
          message: 'Please provide 2 or 3 security questions and answers',
        });
      }

      // Verify distinct questions and non-empty answers
      const seenIds = new Set();
      const processedQuestions = [];

      for (const item of questions) {
        const qId = (item.questionId || item.id || '').trim();
        const answer = (item.answer || '').trim();

        if (!qId || !answer) {
          return errorResponse(res, {
            statusCode: 400,
            message: 'All questions must have a valid question identifier and non-empty answer',
          });
        }

        if (seenIds.has(qId)) {
          return errorResponse(res, {
            statusCode: 400,
            message: 'Duplicate questions selected. Please select 3 distinct questions.',
          });
        }
        seenIds.add(qId);

        const standard = STANDARD_SECURITY_QUESTIONS.find(sq => sq.id === qId);
        const questionText = item.questionText || (standard ? standard.text : qId);

        // Normalize answer: trim and lowercase
        const normalizedAnswer = answer.toLowerCase();
        const answerHash = await bcrypt.hash(normalizedAnswer, 10);

        processedQuestions.push({
          questionId: qId,
          questionText,
          answerHash,
        });
      }

      // Persist to user record
      await UserModel.updateUserDetails(userId, {
        securityQuestions: processedQuestions,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Security questions configured successfully',
        data: {
          configuredCount: processedQuestions.length,
          questions: processedQuestions.map(q => ({
            questionId: q.questionId,
            questionText: q.questionText,
          })),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/security-questions/get-for-user
   * Returns user's configured questions (WITHOUT answers or hashes) given email or phone
   */
  static async getForUser(req, res, next) {
    try {
      const { identifier, email } = req.body;
      const lookup = (identifier || email || '').trim();

      if (!lookup) {
        return errorResponse(res, { statusCode: 400, message: 'Email or mobile number is required' });
      }

      const user = await UserModel.findByIdentifier(lookup) || await UserModel.findByEmail(lookup);
      if (!user) {
        return errorResponse(res, { statusCode: 404, message: 'No registered account found with this identifier' });
      }

      const configured = user.securityQuestions || user.security_questions || [];
      if (!Array.isArray(configured) || configured.length === 0) {
        return errorResponse(res, {
          statusCode: 400,
          code: 'NO_SECURITY_QUESTIONS_CONFIGURED',
          message: 'Security questions are not yet configured for this account. Please reset via Email OTP or contact support.',
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'Security questions retrieved',
        data: {
          email: user.email,
          phone: user.phone,
          questions: configured.map(q => ({
            questionId: q.questionId,
            questionText: q.questionText,
          })),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/security-questions/verify
   * Verifies submitted answers against stored bcrypt hashes with rate limiting
   */
  static async verifyAnswers(req, res, next) {
    try {
      const { identifier, email, answers } = req.body;
      const lookup = (identifier || email || '').trim().toLowerCase();

      if (!lookup) {
        return errorResponse(res, { statusCode: 400, message: 'Email or mobile number is required' });
      }

      if (!Array.isArray(answers) || answers.length === 0) {
        return errorResponse(res, { statusCode: 400, message: 'Answers array is required' });
      }

      // Check Rate Limiting
      const now = Date.now();
      const attemptData = _attemptStore.get(lookup) || { count: 0, lockedUntil: 0 };

      if (attemptData.lockedUntil > now) {
        const remainingMinutes = Math.ceil((attemptData.lockedUntil - now) / 60000);
        return errorResponse(res, {
          statusCode: 429,
          code: 'TOO_MANY_FAILED_ATTEMPTS',
          message: `Too many failed attempts. Account recovery locked for ${remainingMinutes} minute(s).`,
        });
      }

      const user = await UserModel.findByIdentifier(lookup) || await UserModel.findByEmail(lookup);
      if (!user) {
        return errorResponse(res, { statusCode: 404, message: 'User not found' });
      }

      const configured = user.securityQuestions || user.security_questions || [];
      if (!Array.isArray(configured) || configured.length === 0) {
        return errorResponse(res, {
          statusCode: 400,
          message: 'No security questions configured for this account',
        });
      }

      // Map configured questions
      const questionMap = new Map();
      for (const q of configured) {
        questionMap.set(q.questionId, q);
      }

      let allCorrect = answers.length === configured.length;

      for (const submitted of answers) {
        const qId = (submitted.questionId || submitted.id || '').trim();
        const rawAnswer = (submitted.answer || '').trim().toLowerCase();

        const stored = questionMap.get(qId);
        if (!stored || !stored.answerHash) {
          allCorrect = false;
          break;
        }

        const isMatch = await bcrypt.compare(rawAnswer, stored.answerHash);
        if (!isMatch) {
          allCorrect = false;
          break;
        }
      }

      if (!allCorrect) {
        attemptData.count += 1;
        if (attemptData.count >= MAX_FAILED_ATTEMPTS) {
          attemptData.lockedUntil = now + LOCKOUT_DURATION_MS;
          _attemptStore.set(lookup, attemptData);
          return errorResponse(res, {
            statusCode: 429,
            code: 'TOO_MANY_FAILED_ATTEMPTS',
            message: 'Too many incorrect answers. Verification locked for 15 minutes.',
          });
        }

        _attemptStore.set(lookup, attemptData);
        const remaining = MAX_FAILED_ATTEMPTS - attemptData.count;
        return errorResponse(res, {
          statusCode: 400,
          code: 'INCORRECT_ANSWERS',
          message: `One or more answers are incorrect. You have ${remaining} attempt(s) remaining.`,
        });
      }

      // Successful verification: clear failed attempts
      _attemptStore.delete(lookup);

      // Generate secure 15-minute reset token
      const resetToken = TokenService.signResetToken(user);

      return successResponse(res, {
        statusCode: 200,
        message: 'Identity verified successfully',
        data: {
          verified: true,
          email: user.email,
          phone: user.phone,
          resetToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = SecurityQuestionsController;
