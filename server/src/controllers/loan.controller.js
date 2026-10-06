const LoanService = require('../services/loan.service');
const EmiCalculatorService = require('../services/emiCalculator.service');
const ReminderService = require('../services/reminder.service');
const { successResponse, errorResponse } = require('../utils/response.util');

class LoanController {
  /**
   * POST /api/loans
   * Create a new loan and automatically generate & persist its amortization schedule
   */
  static async createLoan(req, res, next) {
    try {
      const {
        loanType,
        principalAmount,
        interestRate,
        tenureMonths,
        startDate,
        interestType,
      } = req.body;

      const result = await LoanService.createLoan({
        userId: req.user.id,
        loanType,
        principalAmount,
        interestRate,
        tenureMonths,
        startDate,
        interestType,
      });

      return successResponse(res, {
        statusCode: 201,
        message: 'Loan created and amortization schedule generated successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/loans
   * List all loans for the logged-in user with summary analytics
   */
  static async getLoans(req, res, next) {
    try {
      const { status } = req.query;
      const result = await LoanService.getLoansByUserId(req.user.id, { status });

      return successResponse(res, {
        statusCode: 200,
        message: 'Loans retrieved successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/loans/:id
   * Get full loan detail, amortization schedule, payment logs, and payoff stats
   */
  static async getLoanById(req, res, next) {
    try {
      const result = await LoanService.getLoanDetails(req.params.id, req.user.id);

      return successResponse(res, {
        statusCode: 200,
        message: 'Loan details retrieved successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * PUT /api/loans/:id
   * Update loan details or recalculate terms
   */
  static async updateLoan(req, res, next) {
    try {
      const result = await LoanService.updateLoan(req.params.id, req.user.id, req.body);

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * DELETE /api/loans/:id
   * Delete or archive a loan
   */
  static async deleteLoan(req, res, next) {
    try {
      const result = await LoanService.deleteLoan(req.params.id, req.user.id);

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: null,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/loans/:id/schedule
   * Retrieve amortization schedule for a loan
   */
  static async getSchedule(req, res, next) {
    try {
      const result = await LoanService.getAmortizationSchedule(req.params.id, req.user.id);

      return successResponse(res, {
        statusCode: 200,
        message: 'Amortization schedule retrieved successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/loans/schedules/upcoming or GET /api/loans/:id/schedules/upcoming
   * Retrieve upcoming EMI installments
   */
  static async getUpcomingEmis(req, res, next) {
    try {
      const loanId = req.params.id || null;
      const daysAhead = req.query.days ? parseInt(req.query.days, 10) : 30;

      const result = await LoanService.getUpcomingEmis({
        userId: req.user.id,
        loanId,
        daysAhead,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Upcoming EMIs retrieved successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/loans/schedules/overdue or GET /api/loans/:id/schedules/overdue
   * Retrieve overdue EMI installments
   */
  static async getOverdueEmis(req, res, next) {
    try {
      const loanId = req.params.id || null;

      const result = await LoanService.getOverdueEmis({
        userId: req.user.id,
        loanId,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Overdue EMIs retrieved successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/:id/payments
   * Mark an EMI installment as paid & log payment record
   */
  static async markEmiAsPaid(req, res, next) {
    try {
      const { scheduleId, amount, paymentDate, paymentType, lateFee, notes } = req.body;

      const result = await LoanService.markEmiAsPaid({
        loanId: req.params.id,
        scheduleId,
        userId: req.user.id,
        amount,
        paymentDate,
        paymentType,
        lateFee,
        notes,
      });

      return successResponse(res, {
        statusCode: 201,
        message: result.message,
        data: {
          payment: result.payment,
          scheduleItem: result.scheduleItem,
          loanSummary: result.loanSummary,
        },
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * PUT /api/loans/payments/:paymentId
   * Update an existing payment record
   */
  static async updatePayment(req, res, next) {
    try {
      const result = await LoanService.updatePayment(req.params.paymentId, req.user.id, req.body);

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result.payment,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      if (error.statusCode === 403) {
        return errorResponse(res, {
          statusCode: 403,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/loans/:id/payments
   * Retrieve payment history for a loan
   */
  static async getPaymentHistory(req, res, next) {
    try {
      const result = await LoanService.getPaymentHistory(req.params.id, req.user.id);

      return successResponse(res, {
        statusCode: 200,
        message: 'Payment history retrieved successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/loans/:id/summary
   * Retrieve loan summary metrics: Principal, EMI, Outstanding, Interest Paid, Principal Paid, Next EMI, Counts
   */
  static async getLoanSummary(req, res, next) {
    try {
      const result = await LoanService.getLoanSummary(req.params.id, req.user.id);

      return successResponse(res, {
        statusCode: 200,
        message: 'Loan summary retrieved successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/:id/regenerate-schedule
   */
  static async regenerateSchedule(req, res, next) {
    try {
      const result = await LoanService.regenerateSchedule(
        req.params.id,
        req.user.id,
        req.body || {}
      );

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: {
          loan: result.loan,
          schedule: result.schedule,
        },
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/calculate
   */
  static async calculateEmi(req, res, next) {
    try {
      const {
        principalAmount,
        interestRate,
        tenureMonths,
        interestType = 'Reducing',
        compareWithFlat = false,
      } = req.body;

      const calculation = EmiCalculatorService.calculateEmi({
        principal: principalAmount,
        annualInterestRate: interestRate,
        tenureMonths,
        interestType,
      });

      let comparison = null;
      if (compareWithFlat) {
        comparison = EmiCalculatorService.compareFlatVsReducing({
          principal: principalAmount,
          annualInterestRate: interestRate,
          tenureMonths,
        });
      }

      return successResponse(res, {
        statusCode: 200,
        message: 'EMI calculated successfully',
        data: {
          calculation,
          comparison,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/loans/preview-schedule
   */
  static async previewSchedule(req, res, next) {
    try {
      const {
        principalAmount,
        interestRate,
        tenureMonths,
        startDate,
        interestType,
      } = req.body;

      const result = LoanService.previewSchedule({
        principalAmount,
        interestRate,
        tenureMonths,
        startDate,
        interestType,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Amortization schedule preview generated successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/loans/:id/schedules/:scheduleId/late-fee
   * Calculate dynamic late fee breakdown for an installment
   */
  static async getScheduleLateFee(req, res, next) {
    try {
      const { id: loanId, scheduleId } = req.params;
      const { asOfDate } = req.query;

      const result = await LoanService.getScheduleLateFee(
        loanId,
        scheduleId,
        req.user.id,
        asOfDate ? new Date(asOfDate) : new Date()
      );

      return successResponse(res, {
        statusCode: 200,
        message: 'Late fee calculated successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode === 404) {
        return errorResponse(res, {
          statusCode: 404,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/:id/prepayment/simulate
   */
  static async simulatePrepayment(req, res, next) {
    try {
      const { prepaymentAmount, strategy } = req.body;
      const result = await LoanService.simulatePrepayment(req.params.id, req.user.id, {
        prepaymentAmount,
        strategy,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Prepayment impact simulated successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode) {
        return errorResponse(res, {
          statusCode: error.statusCode,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/:id/foreclosure/simulate
   */
  static async simulateForeclosure(req, res, next) {
    try {
      const { foreclosureChargeRate } = req.body;
      const result = await LoanService.simulateForeclosure(req.params.id, req.user.id, {
        foreclosureChargeRate,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Foreclosure calculation simulated successfully',
        data: result,
      });
    } catch (error) {
      if (error.statusCode) {
        return errorResponse(res, {
          statusCode: error.statusCode,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/:id/prepayment/apply
   */
  static async applyPrepayment(req, res, next) {
    try {
      const { prepaymentAmount, strategy, paymentDate, notes } = req.body;
      const result = await LoanService.applyPrepayment(req.params.id, req.user.id, {
        prepaymentAmount,
        strategy,
        paymentDate,
        notes,
      });

      return successResponse(res, {
        statusCode: 201,
        message: result.message,
        data: result,
      });
    } catch (error) {
      if (error.statusCode) {
        return errorResponse(res, {
          statusCode: error.statusCode,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /api/loans/:id/foreclosure/apply
   */
  static async applyForeclosure(req, res, next) {
    try {
      const { foreclosureChargeRate, paymentDate, notes } = req.body;
      const result = await LoanService.applyForeclosure(req.params.id, req.user.id, {
        foreclosureChargeRate,
        paymentDate,
        notes,
      });

      return successResponse(res, {
        statusCode: 200,
        message: result.message,
        data: result,
      });
    } catch (error) {
      if (error.statusCode) {
        return errorResponse(res, {
          statusCode: error.statusCode,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/loans/reminders/config
   */
  static async getRemindersConfig(req, res, next) {
    try {
      const config = ReminderService.getRemindersConfig(req.user.id);
      return successResponse(res, {
        statusCode: 200,
        message: 'Reminder configuration retrieved successfully',
        data: config,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/loans/reminders/config
   */
  static async updateRemindersConfig(req, res, next) {
    try {
      const updated = ReminderService.updateRemindersConfig(req.user.id, req.body);
      return successResponse(res, {
        statusCode: 200,
        message: 'Reminder configuration updated successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/loans/reminders/pending
   */
  static async getPendingReminders(req, res, next) {
    try {
      const { asOfDate } = req.query;
      const pending = await ReminderService.scanPendingReminders({
        asOfDate: asOfDate ? new Date(asOfDate) : new Date(),
        userId: req.user.id,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Pending reminders retrieved successfully',
        data: {
          count: pending.length,
          reminders: pending,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/loans/reminders/trigger-check
   */
  static async triggerReminderCheck(req, res, next) {
    try {
      const { asOfDate } = req.body;
      const result = await ReminderService.triggerReminderDispatch({
        asOfDate: asOfDate ? new Date(asOfDate) : new Date(),
        userId: req.user.id,
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Reminder check and dispatch executed successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/loans/reminders/history
   */
  static async getReminderHistory(req, res, next) {
    try {
      const history = await ReminderService.getReminderHistory(req.user.id);
      return successResponse(res, {
        statusCode: 200,
        message: 'Reminder history retrieved successfully',
        data: {
          count: history.length,
          history,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = LoanController;
