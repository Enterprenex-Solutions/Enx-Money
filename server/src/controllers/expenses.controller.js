const TransactionModel = require('../models/transaction.model');
const FinanceProfileModel = require('../models/financeProfile.model');

class ExpensesController {
  static standardCategories = [
    'Rent & Facility',
    'Salaries & Wages',
    'Utilities & Bills',
    'Raw Materials & Inventory',
    'Vendor & Supplier',
    'Logistics & Shipping',
    'Marketing & Advertising',
    'Office Supplies & Equipment',
    'Legal & Professional Services',
    'Maintenance & Repairs',
    'Travel & Entertainment',
    'Taxes & Licenses',
    'Software & Tech Subscriptions',
    'Insurance',
    'Bank Fees & Charges',
    'Miscellaneous',
  ];

  static async getExpenses(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const {
        search,
        category,
        status,
        supplierId,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        accountId,
        mode = 'BUSINESS',
      } = req.query;

      const filters = {
        userId,
        accountType: mode,
        type: 'DEBIT',
        search,
        category,
        status,
        supplierId,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        accountId,
      };

      const transactions = await TransactionModel.findAll(filters);

      // Return transactions (sorted newest first by default in TransactionModel)
      return res.status(200).json({
        success: true,
        count: transactions.length,
        data: transactions,
      });
    } catch (error) {
      console.error('[ExpensesController] getExpenses error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getExpenseSummary(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const mode = req.query.mode || 'BUSINESS';
      const summary = await TransactionModel.getExpenseSummary(userId, mode);

      return res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      console.error('[ExpensesController] getExpenseSummary error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getExpenseById(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;
      const tx = await TransactionModel.findById(id);

      if (!tx || String(tx.userId) !== String(userId) || tx.type !== 'DEBIT') {
        return res.status(404).json({ success: false, message: 'Expense not found' });
      }

      return res.status(200).json({
        success: true,
        data: tx,
      });
    } catch (error) {
      console.error('[ExpensesController] getExpenseById error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createExpense(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const {
        title,
        note,
        amount,
        category,
        date,
        accountId,
        paymentMode,
        status = 'PAID',
        supplierId,
        supplierName,
        gstRate,
        gstin,
        taxableAmount,
        cgst,
        sgst,
        igst,
        totalGst,
        invoiceNumber,
        receiptUrl,
        mode = 'BUSINESS',
      } = req.body;

      if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
        return res.status(400).json({ success: false, message: 'Valid positive amount is required' });
      }

      if (!category || !category.trim()) {
        return res.status(400).json({ success: false, message: 'Expense category is required' });
      }

      const expenseTitle = (title && title.trim()) || (note && note.trim()) || `${category} Expense`;

      // Calculate GST if gstRate is provided and GST breakdown not given
      let calcTaxable = taxableAmount ? Number(taxableAmount) : null;
      let calcTotalGst = totalGst ? Number(totalGst) : null;
      let calcCgst = cgst ? Number(cgst) : null;
      let calcSgst = sgst ? Number(sgst) : null;
      let calcIgst = igst ? Number(igst) : null;

      const rateNum = gstRate !== undefined && gstRate !== null ? Number(gstRate) : null;
      const amtNum = Number(Number(amount).toFixed(2));

      if (rateNum && rateNum > 0 && calcTaxable === null) {
        calcTaxable = Number((amtNum / (1 + rateNum / 100)).toFixed(2));
        calcTotalGst = Number((amtNum - calcTaxable).toFixed(2));
        calcCgst = Number((calcTotalGst / 2).toFixed(2));
        calcSgst = Number((calcTotalGst - calcCgst).toFixed(2));
      }

      const normalizedStatus = status.toUpperCase();
      const settledStatus = ['PAID', 'SETTLED'].includes(normalizedStatus)
        ? 'SETTLED'
        : normalizedStatus;

      const tx = await TransactionModel.create({
        userId,
        accountType: mode,
        type: 'DEBIT',
        category: category.trim(),
        amount: amtNum,
        accountId: accountId || null,
        paymentMode: paymentMode || 'BANK_TRANSFER',
        date: date || new Date().toISOString(),
        note: expenseTitle,
        referenceType: 'BUSINESS_EXPENSE',
        status: settledStatus,
        supplierId: supplierId || null,
        supplierName: supplierName || null,
        gstRate: rateNum,
        gstin: gstin || null,
        taxableAmount: calcTaxable,
        cgst: calcCgst,
        sgst: calcSgst,
        igst: calcIgst,
        totalGst: calcTotalGst,
        invoiceNumber: invoiceNumber || null,
        receiptUrl: receiptUrl || null,
      });

      return res.status(201).json({
        success: true,
        message: 'Business expense recorded and settled successfully',
        data: {
          ...tx,
          status: settledStatus,
          updatedAccount: accountId && settledStatus === 'SETTLED'
            ? await FinanceProfileModel.getAccountById(accountId, userId)
            : null,
        },
      });
    } catch (error) {
      console.error('[ExpensesController] createExpense error:', error);
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async updateExpense(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;

      const tx = await TransactionModel.findById(id);
      if (!tx || String(tx.userId) !== String(userId) || tx.type !== 'DEBIT') {
        return res.status(404).json({ success: false, message: 'Expense not found' });
      }

      const updates = { ...req.body };
      if (updates.amount !== undefined) {
        if (isNaN(Number(updates.amount)) || Number(updates.amount) <= 0) {
          return res.status(400).json({ success: false, message: 'Valid positive amount is required' });
        }
        updates.amount = Number(Number(updates.amount).toFixed(2));

        const gstFields = [
          'gstRate', 'taxableAmount', 'totalGst',
          'cgst', 'sgst', 'igst'
        ];

        const hasGstUpdates = gstFields.some(
          field => updates[field] !== undefined
        );

        const rate = Number(tx.gstRate);

        if (
          !hasGstUpdates &&
          Number.isFinite(rate) &&
          rate > 0 &&
          Number.isFinite(updates.amount) &&
          updates.amount > 0
        ) {
          updates.taxableAmount = Number(
            (updates.amount / (1 + rate / 100)).toFixed(2)
          );

          updates.totalGst = Number(
            (updates.amount - updates.taxableAmount).toFixed(2)
          );

          if (Number(tx.igst) > 0) {
            updates.igst = updates.totalGst;
            updates.cgst = 0;
            updates.sgst = 0;
          } else {
            updates.igst = 0;
            updates.cgst = Number(
              (updates.totalGst / 2).toFixed(2)
            );
            updates.sgst = Number(
              (updates.totalGst - updates.cgst).toFixed(2)
            );
          }
        }

      }

      if (updates.title && !updates.note) {
        updates.note = updates.title;
      }

      const updatedTx = await TransactionModel.update(id, userId, updates);

      return res.status(200).json({
        success: true,
        message: 'Expense updated successfully',
        data: updatedTx,
      });
    } catch (error) {
      console.error('[ExpensesController] updateExpense error:', error);
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async deleteExpense(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;

      const tx = await TransactionModel.findById(id);
      if (!tx || String(tx.userId) !== String(userId) || tx.type !== 'DEBIT') {
        return res.status(404).json({ success: false, message: 'Expense not found' });
      }

      const deleted = await TransactionModel.delete(id, userId);
      if (!deleted) {
        return res.status(404).json({ success: false, message: 'Expense not found' });
      }

      return res.status(200).json({
        success: true,
        message: 'Expense deleted successfully',
      });
    } catch (error) {
      console.error('[ExpensesController] deleteExpense error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getCategories(req, res) {
    try {
      return res.status(200).json({
        success: true,
        data: ExpensesController.standardCategories,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = ExpensesController;
