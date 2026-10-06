const TransactionModel = require('../models/transaction.model');

class TransactionController {
  static async getTransactions(req, res) {
    try {
      const {
        accountType,
        mode,
        type,
        category,
        paymentMode,
        accountId,
        search,
        minAmount,
        maxAmount,
        startDate,
        endDate,
      } = req.query;

      const userId = req.user ? req.user.id : 1;
      const transactions = await TransactionModel.findAll({
        userId,
        accountType: accountType || mode,
        type,
        category,
        paymentMode,
        accountId,
        search,
        minAmount,
        maxAmount,
        startDate,
        endDate,
      });

      return res.status(200).json({
        success: true,
        data: transactions,
      });
    } catch (error) {
      console.error('[TransactionController] getTransactions error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createTransaction(req, res) {
    try {
      const { accountType, mode, type, category, amount, paymentMode, accountId, date, note, referenceId } = req.body;

      if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
        return res.status(400).json({ success: false, message: 'Valid positive amount is required.' });
      }

      const userId = req.user ? req.user.id : 1;
      const tx = await TransactionModel.create({
        userId,
        accountType: accountType || mode,
        type,
        category,
        amount,
        paymentMode,
        accountId,
        date,
        note,
        referenceId,
      });

      return res.status(201).json({
        success: true,
        message: 'Transaction recorded successfully',
        data: tx,
      });
    } catch (error) {
      console.error('[TransactionController] createTransaction error:', error);
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async getDailyBook(req, res) {
    try {
      const { mode, date } = req.query;
      const userId = req.user ? req.user.id : 1;
      const dailyBook = await TransactionModel.getDailyBook({ userId, mode, date });
      return res.status(200).json({
        success: true,
        data: dailyBook,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getWeeklyReport(req, res) {
    try {
      const { mode } = req.query;
      const weekly = await TransactionModel.getWeeklyReport({ mode });
      return res.status(200).json({
        success: true,
        data: weekly,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getMonthlyReport(req, res) {
    try {
      const { mode, month } = req.query;
      const monthly = await TransactionModel.getMonthlyReport({ mode, month });
      return res.status(200).json({
        success: true,
        data: monthly,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getExpenseChecking(req, res) {
    try {
      const { mode } = req.query;
      const checking = await TransactionModel.getExpenseChecking({ mode });
      return res.status(200).json({
        success: true,
        data: checking,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getRecurring(req, res) {
    try {
      const { mode } = req.query;
      const recurring = await TransactionModel.getRecurringList({ mode });
      return res.status(200).json({
        success: true,
        data: recurring,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createRecurring(req, res) {
    try {
      const item = await TransactionModel.createRecurring(req.body);
      return res.status(201).json({
        success: true,
        message: 'Recurring schedule registered successfully',
        data: item,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async reconcile(req, res) {
    try {
      const result = await TransactionModel.reconcileAccount(req.body);
      return res.status(200).json({
        success: true,
        message: result.status === 'Matched' ? 'Account balances match perfectly! ✅' : 'Reconciliation variance identified ⚠️',
        data: result,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }
}

module.exports = TransactionController;
