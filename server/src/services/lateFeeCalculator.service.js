/**
 * Reusable & Configurable Late Fee Calculation Engine
 * Supports: Fixed fee, Percentage-based fee, Daily penalty, Grace periods, and Maximum caps
 */
class LateFeeCalculatorService {
  static DEFAULT_CONFIG = {
    strategy: 'HYBRID', // 'FIXED', 'PERCENTAGE', 'DAILY', 'HYBRID'
    fixedFee: 250.0, // Fixed initial late fee in INR
    percentageRate: 2.0, // Percentage rate of EMI (e.g. 2%)
    dailyPenaltyAmount: 25.0, // Daily penalty per day overdue
    gracePeriodDays: 3, // Grace period days after due date before penalties apply
    maxCapAmount: 3000.0, // Absolute maximum late fee cap
    maxCapPercentage: 20.0, // Maximum cap as % of EMI
  };

  /**
   * Helper to round numbers to 2 decimal places
   */
  static round(val) {
    if (isNaN(val) || !isFinite(val)) return 0.0;
    return Math.round((val + Number.EPSILON) * 100) / 100;
  }

  /**
   * Calculate days overdue given a due date and an optional calculation date (defaults to today)
   */
  static getDaysOverdue(dueDate, asOfDate = new Date()) {
    const due = new Date(dueDate);
    const asOf = new Date(asOfDate);

    // Normalize to midnight UTC for calendar date comparison
    const dueUtc = Date.UTC(due.getUTCFullYear(), due.getUTCMonth(), due.getUTCDate());
    const asOfUtc = Date.UTC(asOf.getUTCFullYear(), asOf.getUTCMonth(), asOf.getUTCDate());

    const diffMs = asOfUtc - dueUtc;
    const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    return Math.max(0, days);
  }

  /**
   * Calculate dynamic late fee for an installment
   *
   * @param {Object} params
   * @param {number} params.emiAmount - Original EMI amount
   * @param {string|Date} params.dueDate - Installment due date
   * @param {string} [params.status='Pending'] - Installment status ('Paid', 'Pending', 'Overdue')
   * @param {Date} [params.asOfDate] - Calculation date (defaults to now)
   * @param {Object} [params.customConfig] - Optional override config
   * @returns {Object} Late fee breakdown
   */
  static calculateLateFee({
    emiAmount,
    dueDate,
    status = 'Pending',
    asOfDate = new Date(),
    customConfig = {},
  }) {
    const config = { ...this.DEFAULT_CONFIG, ...customConfig };
    const originalEmi = this.round(parseFloat(emiAmount) || 0);

    // 1. If already paid, late fee is either what was recorded or zero
    if (status === 'Paid') {
      return {
        originalEmi,
        daysOverdue: 0,
        gracePeriodDays: config.gracePeriodDays,
        isOverdue: false,
        fixedLateFee: 0.0,
        percentageLateFee: 0.0,
        dailyPenalty: 0.0,
        lateFee: 0.0,
        totalPayable: originalEmi,
        ruleApplied: 'Installment is already settled.',
      };
    }

    const daysOverdue = this.getDaysOverdue(dueDate, asOfDate);

    // 2. If not past due date or within grace period
    if (daysOverdue <= 0) {
      return {
        originalEmi,
        daysOverdue: 0,
        gracePeriodDays: config.gracePeriodDays,
        isOverdue: false,
        fixedLateFee: 0.0,
        percentageLateFee: 0.0,
        dailyPenalty: 0.0,
        lateFee: 0.0,
        totalPayable: originalEmi,
        ruleApplied: 'Installment is not overdue.',
      };
    }

    if (daysOverdue <= config.gracePeriodDays) {
      return {
        originalEmi,
        daysOverdue,
        gracePeriodDays: config.gracePeriodDays,
        isOverdue: true,
        inGracePeriod: true,
        fixedLateFee: 0.0,
        percentageLateFee: 0.0,
        dailyPenalty: 0.0,
        lateFee: 0.0,
        totalPayable: originalEmi,
        ruleApplied: `Within grace period of ${config.gracePeriodDays} days. No late fee assessed.`,
      };
    }

    // Effective billable overdue days past grace period
    const billableDays = daysOverdue - config.gracePeriodDays;

    let fixedFee = 0.0;
    let percentageFee = 0.0;
    let dailyPenalty = 0.0;

    switch (config.strategy) {
      case 'FIXED':
        fixedFee = config.fixedFee;
        break;

      case 'PERCENTAGE':
        percentageFee = (originalEmi * config.percentageRate) / 100.0;
        break;

      case 'DAILY':
        dailyPenalty = billableDays * config.dailyPenaltyAmount;
        break;

      case 'HYBRID':
      default:
        // Base flat penalty + daily rate past grace period
        fixedFee = config.fixedFee;
        percentageFee = (originalEmi * config.percentageRate) / 100.0;
        dailyPenalty = billableDays * config.dailyPenaltyAmount;
        break;
    }

    let totalComputedLateFee = fixedFee + percentageFee + dailyPenalty;

    // Apply Maximum Caps if configured
    const maxAllowedPercentage = (originalEmi * config.maxCapPercentage) / 100.0;
    const effectiveCap = Math.min(config.maxCapAmount, maxAllowedPercentage);

    if (totalComputedLateFee > effectiveCap) {
      totalComputedLateFee = effectiveCap;
    }

    totalComputedLateFee = this.round(totalComputedLateFee);
    const totalPayable = this.round(originalEmi + totalComputedLateFee);

    return {
      originalEmi,
      daysOverdue,
      gracePeriodDays: config.gracePeriodDays,
      billableDays,
      isOverdue: true,
      inGracePeriod: false,
      fixedLateFee: this.round(fixedFee),
      percentageLateFee: this.round(percentageFee),
      dailyPenalty: this.round(dailyPenalty),
      lateFee: totalComputedLateFee,
      totalPayable,
      ruleApplied: `${config.strategy} late fee: Flat ₹${config.fixedFee} + ${config.percentageRate}% + ₹${config.dailyPenaltyAmount}/day after ${config.gracePeriodDays} days grace period (Capped at ₹${effectiveCap}).`,
    };
  }
}

module.exports = LateFeeCalculatorService;
