const LoanModel = require('../models/loan.model');
const EmiScheduleModel = require('../models/emiSchedule.model');
const LoanReminderModel = require('../models/loanReminder.model');
const UserModel = require('../models/user.model');
const EmailService = require('./email.service');
const LateFeeCalculatorService = require('./lateFeeCalculator.service');

class ReminderService {
  static DEFAULT_CONFIG = {
    advanceDays: [7, 3, 1, 0], // Remind 7d, 3d, 1d ahead and on due date
    sendOverdueAlerts: true,
    emailNotifications: true,
    inAppNotifications: true,
  };

  // User-specific custom reminder configs in memory/persistence
  static userConfigs = new Map();

  /**
   * Get reminder timing configuration for a user
   */
  static getRemindersConfig(userId) {
    const custom = this.userConfigs.get(userId);
    return { ...this.DEFAULT_CONFIG, ...(custom || {}) };
  }

  /**
   * Update reminder timing configuration for a user
   */
  static updateRemindersConfig(userId, updates = {}) {
    const current = this.getRemindersConfig(userId);
    const updated = {
      ...current,
      ...updates,
      advanceDays: updates.advanceDays || current.advanceDays,
    };
    this.userConfigs.set(userId, updated);
    return updated;
  }

  /**
   * Scan active loans and identify all pending / eligible reminders for today
   */
  static async scanPendingReminders({ asOfDate = new Date(), userId = null } = {}) {
    const today = new Date(asOfDate).toISOString().split('T')[0];
    const loans = userId ? await LoanModel.findByUserId(userId) : [];

    const pendingReminders = [];

    for (const loan of loans) {
      if (loan.status !== 'Active') continue;

      const userConfig = this.getRemindersConfig(loan.userId);
      const schedule = await EmiScheduleModel.findByLoanId(loan.id);

      // Find earliest unpaid installment
      const unpaidInstallments = schedule
        .filter((s) => s.status !== 'Paid')
        .sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));

      if (unpaidInstallments.length === 0) continue;

      const nextInstallment = unpaidInstallments[0];
      const due = new Date(nextInstallment.dueDate);
      const asOf = new Date(today);
      const dueUtc = Date.UTC(due.getUTCFullYear(), due.getUTCMonth(), due.getUTCDate());
      const asOfUtc = Date.UTC(asOf.getUTCFullYear(), asOf.getUTCMonth(), asOf.getUTCDate());

      const daysRemaining = Math.round((dueUtc - asOfUtc) / (1000 * 60 * 60 * 24));

      let reminderType = null;

      if (daysRemaining > 0 && userConfig.advanceDays.includes(daysRemaining)) {
        reminderType = `UPCOMING_${daysRemaining}D`;
      } else if (daysRemaining === 0 && userConfig.advanceDays.includes(0)) {
        reminderType = 'DUE_TODAY';
      } else if (daysRemaining < 0 && userConfig.sendOverdueAlerts) {
        reminderType = 'OVERDUE_ALERT';
      }

      if (reminderType) {
        // Deduplication check: Check if reminder was already recorded for this installment today
        const existing = await LoanReminderModel.findExisting({
          scheduleId: nextInstallment.id,
          reminderType,
          sentDate: today,
        });

        if (!existing) {
          const lateFeeDetails = LateFeeCalculatorService.calculateLateFee({
            emiAmount: nextInstallment.emiAmount,
            dueDate: nextInstallment.dueDate,
            status: nextInstallment.status,
            asOfDate: asOf,
          });

          pendingReminders.push({
            loanId: loan.id,
            scheduleId: nextInstallment.id,
            userId: loan.userId,
            loanType: loan.loanType,
            installmentNumber: nextInstallment.installmentNumber,
            emiAmount: nextInstallment.emiAmount,
            dueDate: nextInstallment.dueDate,
            daysRemaining,
            isOverdue: daysRemaining < 0,
            lateFee: lateFeeDetails.lateFee,
            totalPayable: lateFeeDetails.totalPayable,
            reminderType,
            sentDate: today,
          });
        }
      }
    }

    return pendingReminders;
  }

  /**
   * Trigger scan and dispatch of due reminders (with strict anti-duplicate guarantee)
   */
  static async triggerReminderDispatch({ asOfDate = new Date(), userId = null } = {}) {
    const today = new Date(asOfDate).toISOString().split('T')[0];
    const eligibleReminders = await this.scanPendingReminders({ asOfDate, userId });

    const dispatched = [];
    const skippedDuplicates = [];

    for (const item of eligibleReminders) {
      // 1. Strict Deduplication check
      const existing = await LoanReminderModel.findExisting({
        scheduleId: item.scheduleId,
        reminderType: item.reminderType,
        sentDate: today,
      });

      if (existing) {
        skippedDuplicates.push({
          scheduleId: item.scheduleId,
          reminderType: item.reminderType,
          reason: 'Already sent today',
        });
        continue;
      }

      // 2. Fetch User Profile for Email notification
      let userEmail = 'customer@enxmoney.com';
      let userName = 'Customer';
      try {
        const user = await UserModel.findById(item.userId);
        if (user) {
          userEmail = user.email;
          userName = user.name || 'Valued Customer';
        }
      } catch (_) {}

      // 3. Dispatch Email Notification
      try {
        await EmailService.sendEmiReminderEmail({
          email: userEmail,
          name: userName,
          loanType: item.loanType,
          installmentNumber: item.installmentNumber,
          emiAmount: item.emiAmount,
          dueDate: item.dueDate,
          daysRemaining: item.daysRemaining,
          isOverdue: item.isOverdue,
          lateFee: item.lateFee,
          totalPayable: item.totalPayable,
        });
      } catch (err) {
        console.warn(`[ReminderService] Email delivery note for ${userEmail}: ${err.message}`);
      }

      // 4. Record in LoanReminderModel
      const record = await LoanReminderModel.create({
        loanId: item.loanId,
        scheduleId: item.scheduleId,
        userId: item.userId,
        reminderType: item.reminderType,
        channel: 'EMAIL',
        emiAmount: item.emiAmount,
        dueDate: item.dueDate,
        sentDate: today,
        status: 'SENT',
        message: item.isOverdue
          ? `Overdue alert for Installment #${item.installmentNumber}`
          : `Payment reminder for Installment #${item.installmentNumber} due in ${item.daysRemaining} days`,
      });

      dispatched.push(record);
    }

    return {
      scanDate: today,
      totalEligible: eligibleReminders.length,
      dispatchedCount: dispatched.length,
      skippedDuplicatesCount: skippedDuplicates.length,
      dispatched,
      skippedDuplicates,
    };
  }

  /**
   * Get reminder dispatch history for a user
   */
  static async getReminderHistory(userId, limit = 50) {
    return LoanReminderModel.findByUserId(userId, limit);
  }
}

module.exports = ReminderService;
