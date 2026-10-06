const TransactionModel = require('../models/transaction.model');

class TransactionsController {
  static async getTransactions(req, res) {
    try {
      const { accountType, type, category } = req.query;
      const list = await TransactionModel.findAll({ accountType, type, category });
      return res.status(200).json({ success: true, data: list });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createTransaction(req, res) {
    try {
      const tx = await TransactionModel.create(req.body);
      return res.status(201).json({ success: true, message: 'Transaction recorded successfully', data: tx });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async transferFunds(req, res) {
    try {
      const { fromMode, toMode, amount, note } = req.body;
      const result = await TransactionModel.transferBetweenModes({ fromMode, toMode, amount, note });
      return res.status(200).json({ success: true, message: 'Funds transferred successfully', data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getConsolidatedSummary(req, res) {
    try {
      const summary = await TransactionModel.getConsolidatedSummary();
      return res.status(200).json({ success: true, data: summary });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = TransactionsController;
