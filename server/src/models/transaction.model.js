/**
 * Transactions & Dual-Mode Finance Store & Model
 * Implements Feature 2 & Feature 5 of Functional Specification Document
 */

const db = require('../config/db.config');
const FinanceProfileModel = require('./financeProfile.model');

const _transactionsStore = db.inMemoryStore.transactions;
const _recurringStore = new Map();
const _reconciliationStore = new Map();

// 1. Seed Initial Realistic Transactions
const seedTransactions = [
  // Business Transactions
  {
    id: 'tx_b01',
    userId: 1,
    accountType: 'BUSINESS',
    type: 'CREDIT',
    category: 'Sales',
    amount: 30000.00,
    paymentMode: 'BANK_TRANSFER',
    accountId: 'acc_b02',
    accountName: 'HDFC Current A/c',
    date: '2026-08-25',
    time: '10:30 AM',
    note: 'Wholesale Fabric Invoice Settlement',
    referenceType: 'SALES_INVOICE',
    referenceId: 'INV/2026-27/0001',
    reconciled: true,
    createdAt: '2026-08-25T10:30:00.000Z',
  },
  {
    id: 'tx_b02',
    userId: 1,
    accountType: 'BUSINESS',
    type: 'DEBIT',
    category: 'Rent',
    amount: 12000.00,
    paymentMode: 'BANK_TRANSFER',
    accountId: 'acc_b02',
    accountName: 'HDFC Current A/c',
    date: '2026-08-28',
    time: '11:15 AM',
    note: 'Commercial Showroom Rent August',
    referenceType: 'EXPENSE',
    referenceId: 'RENT-AUG',
    reconciled: true,
    createdAt: '2026-08-28T11:15:00.000Z',
  },
  {
    id: 'tx_b03',
    userId: 1,
    accountType: 'BUSINESS',
    type: 'CREDIT',
    category: 'Sales',
    amount: 15000.00,
    paymentMode: 'UPI',
    accountId: 'acc_b02',
    accountName: 'HDFC Current A/c',
    date: '2026-09-01',
    time: '09:45 AM',
    note: 'Retail Counter Sales Settlement',
    referenceType: 'RETAIL_SALE',
    referenceId: 'POS-8821',
    reconciled: false,
    createdAt: '2026-09-01T09:45:00.000Z',
  },
  {
    id: 'tx_b04',
    userId: 1,
    accountType: 'BUSINESS',
    type: 'DEBIT',
    category: 'Utility',
    amount: 3500.00,
    paymentMode: 'UPI',
    accountId: 'acc_b02',
    accountName: 'HDFC Current A/c',
    date: '2026-09-01',
    time: '02:30 PM',
    note: 'Electricity Bill TSSPDCL',
    referenceType: 'BILL',
    referenceId: 'ELEC-SEP',
    reconciled: false,
    createdAt: '2026-09-01T14:30:00.000Z',
  },

  // Personal Transactions
  {
    id: 'tx_p01',
    userId: 1,
    accountType: 'PERSONAL',
    type: 'CREDIT',
    category: 'Salary Received',
    amount: 65000.00,
    paymentMode: 'BANK_TRANSFER',
    accountId: 'acc_p01',
    accountName: 'ICICI Savings A/c',
    date: '2026-08-01',
    time: '09:00 AM',
    note: 'Monthly Salary Credit',
    referenceType: 'SALARY',
    referenceId: '',
    reconciled: true,
    createdAt: '2026-08-01T09:00:00.000Z',
  },
  {
    id: 'tx_p02',
    userId: 1,
    accountType: 'PERSONAL',
    type: 'DEBIT',
    category: 'Groceries',
    amount: 4500.00,
    paymentMode: 'UPI',
    accountId: 'acc_p02',
    accountName: 'Personal GPay',
    date: '2026-08-15',
    time: '06:20 PM',
    note: 'Supermarket weekly groceries',
    referenceType: 'PERSONAL_EXPENSE',
    referenceId: '',
    reconciled: true,
    createdAt: '2026-08-15T18:20:00.000Z',
  },
  {
    id: 'tx_p03',
    userId: 1,
    accountType: 'PERSONAL',
    type: 'DEBIT',
    category: 'EMI',
    amount: 11122.00,
    paymentMode: 'BANK_TRANSFER',
    accountId: 'acc_p01',
    accountName: 'ICICI Savings A/c',
    date: '2026-08-20',
    time: '12:00 PM',
    note: 'Business Expansion Loan Monthly EMI',
    referenceType: 'LOAN_EMI',
    referenceId: 'loan_001',
    reconciled: true,
    createdAt: '2026-08-20T12:00:00.000Z',
  }
];

// 2. Seed Initial Recurring Transactions (Test environment only)
const seedRecurring = [
  {
    id: 'rec_001',
    name: 'Showroom Commercial Rent',
    accountType: 'BUSINESS',
    type: 'DEBIT',
    amount: 12000.00,
    category: 'Rent',
    accountId: 'acc_b02',
    paymentMode: 'BANK_TRANSFER',
    frequency: 'MONTHLY',
    startDate: '2026-08-01',
    nextRunDate: '2026-09-28',
    active: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'rec_002',
    name: 'Broadband Internet Lease',
    accountType: 'BUSINESS',
    type: 'DEBIT',
    amount: 1500.00,
    category: 'Utility',
    accountId: 'acc_b02',
    paymentMode: 'UPI',
    frequency: 'MONTHLY',
    startDate: '2026-08-05',
    nextRunDate: '2026-09-05',
    active: true,
    createdAt: new Date().toISOString(),
  }
];

if (process.env.NODE_ENV === 'test') {
  for (const tx of seedTransactions) {
    _transactionsStore.set(tx.id, tx);
  }

  for (const r of seedRecurring) {
    _recurringStore.set(r.id, r);
  }
}

class TransactionModel {
  /**
   * List Transactions with Multidimensional Filters & Search
   */
  static async findAll({
    userId,
    accountType,
    type,
    category,
    paymentMode,
    accountId,
    search,
    minAmount,
    maxAmount,
    startDate,
    endDate,
    status,
    supplierId,
  } = {}) {
    let list = Array.from(_transactionsStore.values());
    if (userId) {
      list = list.filter(tx => String(tx.userId) === String(userId));
    } else if (process.env.NODE_ENV !== 'test') {
      return [];
    }

    if (accountType && accountType !== 'ALL' && accountType !== 'CONSOLIDATED') {
      list = list.filter(tx => tx.accountType === accountType.toUpperCase());
    }
    if (type && type !== 'ALL') {
      list = list.filter(tx => tx.type === type.toUpperCase());
    }
    if (category && category !== 'ALL') {
      list = list.filter(tx => (tx.category || '').toLowerCase() === category.toLowerCase());
    }
    if (status && status !== 'ALL') {
      list = list.filter(tx => (tx.status || 'PAID').toUpperCase() === status.toUpperCase());
    }
    if (supplierId && supplierId !== 'ALL') {
      list = list.filter(tx => String(tx.supplierId) === String(supplierId));
    }
    if (paymentMode && paymentMode !== 'ALL') {
      list = list.filter(tx => tx.paymentMode.toUpperCase() === paymentMode.toUpperCase());
    }
    if (accountId && accountId !== 'ALL') {
      list = list.filter(tx => tx.accountId === accountId);
    }
    if (minAmount) {
      list = list.filter(tx => tx.amount >= Number(minAmount));
    }
    if (maxAmount) {
      list = list.filter(tx => tx.amount <= Number(maxAmount));
    }
    if (startDate) {
      list = list.filter(tx => tx.date >= startDate);
    }
    if (endDate) {
      list = list.filter(tx => tx.date <= endDate);
    }
    if (search) {
      const q = search.toLowerCase().trim();
      list = list.filter(tx =>
        (tx.note && tx.note.toLowerCase().includes(q)) ||
        (tx.category && tx.category.toLowerCase().includes(q)) ||
        (tx.referenceId && tx.referenceId.toLowerCase().includes(q)) ||
        (tx.accountName && tx.accountName.toLowerCase().includes(q))
      );
    }

    list.sort((a, b) => new Date(b.date + 'T' + (b.time || '00:00')) - new Date(a.date + 'T' + (a.time || '00:00')));
    return list;
  }

  static async findById(id) {
    return _transactionsStore.get(id) || null;
  }

  /**
   * Create New Financial Transaction with Account Balance Sync
   */
  static async create(data) {
    const amount = Number(data.amount);
    if (isNaN(amount) || amount <= 0) {
      throw new Error('Transaction amount must be a valid number greater than zero.');
    }

    const id = `tx_${Date.now()}_${Math.random().toString(36).slice(-4)}`;
    const mode = (data.accountType || data.mode || 'BUSINESS').toUpperCase();
    const type = (data.type || 'CREDIT').toUpperCase();

    let accountName = data.accountName || '';
    if (data.accountId) {
      const acc = await FinanceProfileModel.getAccountById(data.accountId);
      if (acc) accountName = acc.name;
    }

    const now = new Date();
    const status = (data.status || 'PAID').toUpperCase();

    if (data.accountId) {
      const acc = await FinanceProfileModel.getAccountById(data.accountId, data.userId || 1);
      if (acc) accountName = acc.accountName || acc.name || accountName;
    }

    // Sync account balance if paid
    if (status === 'PAID' && data.accountId) {
      try {
        if (type === 'DEBIT') {
          await FinanceProfileModel.updateAccountBalance(data.accountId, -Number(amount.toFixed(2)));
        } else if (type === 'CREDIT') {
          await FinanceProfileModel.updateAccountBalance(data.accountId, Number(amount.toFixed(2)));
        }
      } catch (_) {}
    }

    const tx = {
      id,
      userId: data.userId || 1,
      accountType: mode,
      type,
      category: data.category || (type === 'CREDIT' ? 'Sales' : 'Miscellaneous'),
      amount: Number(amount.toFixed(2)),
      paymentMode: (data.paymentMode || 'CASH').toUpperCase(),
      accountId: data.accountId || null,
      accountName: accountName || (data.accountId ? 'Business Account' : 'Direct Cash'),
      date: data.date || now.toISOString().split('T')[0],
      time: data.time || now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
      note: data.note || data.title || '',
      referenceType: data.referenceType || (type === 'DEBIT' ? 'BUSINESS_EXPENSE' : 'MANUAL_ENTRY'),
      referenceId: data.referenceId || data.invoiceNumber || '',
      supplierId: data.supplierId || null,
      supplierName: data.supplierName || null,
      gstRate: Number(data.gstRate) || 0,
      gstin: data.gstin ? data.gstin.trim().toUpperCase() : '',
      taxableAmount: Number(data.taxableAmount) || 0,
      cgst: Number(data.cgst) || 0,
      sgst: Number(data.sgst) || 0,
      igst: Number(data.igst) || 0,
      totalGst: Number(data.totalGst) || 0,
      invoiceNumber: data.invoiceNumber || '',
      receiptUrl: data.receiptUrl || '',
      status,
      reconciled: Boolean(data.reconciled),
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    };

    _transactionsStore.set(id, tx);
    db.saveResilienceStore();
    return tx;
  }

  /**
   * Update Financial Transaction / Expense with balance reconciliation
   */
  static async update(id, userId, updates = {}) {
    const tx = _transactionsStore.get(id);
    if (!tx || (userId && String(tx.userId) !== String(userId))) {
      return null;
    }

    const oldAmount = Number(tx.amount) || 0;
    const oldAccountId = tx.accountId;
    const oldStatus = tx.status || 'PAID';

    const newAmount = updates.amount !== undefined ? Number(updates.amount) : oldAmount;
    const newAccountId = updates.accountId !== undefined ? updates.accountId : oldAccountId;
    const newStatus = updates.status !== undefined ? updates.status.toUpperCase() : oldStatus;

    // Account Balance Reconciliation if this is a DEBIT transaction
    if (tx.type === 'DEBIT') {
      try {
        if (oldStatus === 'PAID' && oldAccountId) {
          await FinanceProfileModel.updateAccountBalance(oldAccountId, oldAmount);
        }
        if (newStatus === 'PAID' && newAccountId) {
          await FinanceProfileModel.updateAccountBalance(newAccountId, -newAmount);
        }
      } catch (_) {}
    }

    let accountName = tx.accountName;
    if (newAccountId && newAccountId !== oldAccountId) {
      const acc = await FinanceProfileModel.getAccountById(newAccountId, userId);
      if (acc) accountName = acc.accountName || acc.name || accountName;
    }

    const updated = {
      ...tx,
      note: updates.note !== undefined ? updates.note : (updates.title !== undefined ? updates.title : tx.note),
      category: updates.category !== undefined ? updates.category : tx.category,
      amount: Number(newAmount.toFixed(2)),
      paymentMode: updates.paymentMode ? updates.paymentMode.toUpperCase() : tx.paymentMode,
      accountId: newAccountId,
      accountName,
      date: updates.date || tx.date,
      time: updates.time || tx.time,
      supplierId: updates.supplierId !== undefined ? updates.supplierId : tx.supplierId,
      supplierName: updates.supplierName !== undefined ? updates.supplierName : tx.supplierName,
      gstRate: updates.gstRate !== undefined ? Number(updates.gstRate) : tx.gstRate,
      gstin: updates.gstin !== undefined ? updates.gstin.trim().toUpperCase() : tx.gstin,
      taxableAmount: updates.taxableAmount !== undefined ? Number(updates.taxableAmount) : tx.taxableAmount,
      cgst: updates.cgst !== undefined ? Number(updates.cgst) : tx.cgst,
      sgst: updates.sgst !== undefined ? Number(updates.sgst) : tx.sgst,
      igst: updates.igst !== undefined ? Number(updates.igst) : tx.igst,
      totalGst: updates.totalGst !== undefined ? Number(updates.totalGst) : tx.totalGst,
      invoiceNumber: updates.invoiceNumber !== undefined ? updates.invoiceNumber : tx.invoiceNumber,
      receiptUrl: updates.receiptUrl !== undefined ? updates.receiptUrl : tx.receiptUrl,
      status: newStatus,
      updatedAt: new Date().toISOString(),
    };

    _transactionsStore.set(id, updated);
    db.saveResilienceStore();
    return updated;
  }

  /**
   * Delete Transaction / Expense with balance reversal
   */
  static async delete(id, userId) {
    const tx = _transactionsStore.get(id);
    if (!tx || (userId && String(tx.userId) !== String(userId))) {
      return false;
    }

    if (tx.type === 'DEBIT' && (tx.status === 'PAID' || !tx.status) && tx.accountId) {
      try {
        await FinanceProfileModel.updateAccountBalance(tx.accountId, Number(tx.amount));
      } catch (_) {}
    } else if (tx.type === 'CREDIT' && (tx.status === 'PAID' || !tx.status) && tx.accountId) {
      try {
        await FinanceProfileModel.updateAccountBalance(tx.accountId, -Number(tx.amount));
      } catch (_) {}
    }

    _transactionsStore.delete(id);
    db.saveResilienceStore();
    return true;
  }

  /**
   * Get Business Expenses KPI Summary
   */
  static async getExpenseSummary(userId = 1, mode = 'BUSINESS') {
    const cleanMode = (mode || 'BUSINESS').toUpperCase();
    const allExpenses = await this.findAll({
      userId,
      accountType: cleanMode,
      type: 'DEBIT',
    });

    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const currentMonthPrefix = todayStr.slice(0, 7);

    let totalExpense = 0;
    let thisMonthExpense = 0;
    let todayExpense = 0;
    let pendingExpense = 0;

    allExpenses.forEach(exp => {
      const amt = Number(exp.amount) || 0;
      const expDate = (exp.date || '').split('T')[0];

      totalExpense += amt;
      if (expDate.startsWith(currentMonthPrefix)) {
        thisMonthExpense += amt;
      }
      if (expDate === todayStr) {
        todayExpense += amt;
      }
      if (exp.status === 'UNPAID' || exp.status === 'PENDING') {
        pendingExpense += amt;
      }
    });

    return {
      totalExpense: Number(totalExpense.toFixed(2)),
      totalExpenses: Number(totalExpense.toFixed(2)),
      thisMonthExpense: Number(thisMonthExpense.toFixed(2)),
      thisMonthExpenses: Number(thisMonthExpense.toFixed(2)),
      todayExpense: Number(todayExpense.toFixed(2)),
      todayExpenses: Number(todayExpense.toFixed(2)),
      pendingExpense: Number(pendingExpense.toFixed(2)),
      pendingExpenses: Number(pendingExpense.toFixed(2)),
      count: allExpenses.length,
      expenseCount: allExpenses.length,
      currency: 'INR',
    };
  }

  /**
   * Daily Book Engine with Running Balance Calculation
   */
  static async getDailyBook({ userId = 1, mode = 'BUSINESS', date } = {}) {
    const targetDate = date || new Date().toISOString().split('T')[0];
    const cleanMode = (mode || 'BUSINESS').toUpperCase();

    // 1. Calculate opening balance (all transactions before targetDate)
    const priorTransactions = await this.findAll({
      userId,
      accountType: cleanMode,
      endDate: new Date(new Date(targetDate).setDate(new Date(targetDate).getDate() - 1)).toISOString().split('T')[0],
    });

    let openingBalance = 0;
    priorTransactions.forEach(t => {
      if (t.type === 'CREDIT') openingBalance += t.amount;
      else if (t.type === 'DEBIT') openingBalance -= t.amount;
    });

    // 2. Get target date transactions
    const dayTransactions = (await this.findAll({
      userId,
      accountType: cleanMode,
      startDate: targetDate,
      endDate: targetDate,
    })).reverse(); // chronological order for running balance

    let runningBalance = openingBalance;
    let totalCredit = 0;
    let totalDebit = 0;

    const items = dayTransactions.map(tx => {
      if (tx.type === 'CREDIT') {
        runningBalance += tx.amount;
        totalCredit += tx.amount;
      } else if (tx.type === 'DEBIT') {
        runningBalance -= tx.amount;
        totalDebit += tx.amount;
      }

      return {
        ...tx,
        runningBalance: Number(runningBalance.toFixed(2)),
      };
    });

    return {
      date: targetDate,
      mode: cleanMode,
      openingBalance: Number(openingBalance.toFixed(2)),
      totalCredit: Number(totalCredit.toFixed(2)),
      totalDebit: Number(totalDebit.toFixed(2)),
      netChange: Number((totalCredit - totalDebit).toFixed(2)),
      closingBalance: Number(runningBalance.toFixed(2)),
      transactions: items.reverse(), // latest first for display
    };
  }

  /**
   * Weekly Report (Monday -> Sunday)
   */
  static async getWeeklyReport({ userId = 1, mode = 'BUSINESS' } = {}) {
    const cleanMode = (mode || 'BUSINESS').toUpperCase();
    const now = new Date();
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1); // adjust when day is sunday
    const monday = new Date(now.setDate(diff));
    const sunday = new Date(now.setDate(diff + 6));

    const startDate = monday.toISOString().split('T')[0];
    const endDate = sunday.toISOString().split('T')[0];

    const weekTx = await this.findAll({
      userId,
      accountType: cleanMode,
      startDate,
      endDate,
    });

    let totalCredit = 0;
    let totalDebit = 0;
    const dailyMap = {};

    weekTx.forEach(t => {
      if (t.type === 'CREDIT') totalCredit += t.amount;
      else if (t.type === 'DEBIT') totalDebit += t.amount;

      if (!dailyMap[t.date]) dailyMap[t.date] = { credit: 0, debit: 0 };
      if (t.type === 'CREDIT') dailyMap[t.date].credit += t.amount;
      else dailyMap[t.date].debit += t.amount;
    });

    return {
      week: `${startDate} → ${endDate}`,
      mode: cleanMode,
      totalCredit: Number(totalCredit.toFixed(2)),
      totalDebit: Number(totalDebit.toFixed(2)),
      net: Number((totalCredit - totalDebit).toFixed(2)),
      transactionCount: weekTx.length,
      dailyBreakdown: dailyMap,
    };
  }

  /**
   * Monthly Report with Day-wise Trend & Category Breakdown
   */
  static async getMonthlyReport({ userId = 1, mode = 'BUSINESS', month } = {}) {
    const cleanMode = (mode || 'BUSINESS').toUpperCase();
    const targetMonth = month || new Date().toISOString().slice(0, 7); // 'YYYY-MM'

    const all = Array.from(_transactionsStore.values()).filter(t => {
      const matchMode = cleanMode === 'CONSOLIDATED' || t.accountType === cleanMode;
      const matchMonth = t.date.startsWith(targetMonth);
      return matchMode && matchMonth;
    });

    let totalCredit = 0;
    let totalDebit = 0;
    const categoriesMap = {};
    const paymentModeMap = {};
    const dailyTrendMap = {};

    all.forEach(t => {
      if (t.type === 'CREDIT') totalCredit += t.amount;
      else if (t.type === 'DEBIT') {
        totalDebit += t.amount;
        categoriesMap[t.category] = (categoriesMap[t.category] || 0) + t.amount;
      }

      paymentModeMap[t.paymentMode] = (paymentModeMap[t.paymentMode] || 0) + t.amount;

      if (!dailyTrendMap[t.date]) dailyTrendMap[t.date] = { date: t.date, credit: 0, debit: 0 };
      if (t.type === 'CREDIT') dailyTrendMap[t.date].credit += t.amount;
      else dailyTrendMap[t.date].debit += t.amount;
    });

    const categoryBreakdown = Object.keys(categoriesMap).map(cat => ({
      category: cat,
      amount: Number(categoriesMap[cat].toFixed(2)),
      percentage: totalDebit > 0 ? Number(((categoriesMap[cat] / totalDebit) * 100).toFixed(1)) : 0,
    })).sort((a, b) => b.amount - a.amount);

    return {
      month: targetMonth,
      mode: cleanMode,
      totalCredit: Number(totalCredit.toFixed(2)),
      totalDebit: Number(totalDebit.toFixed(2)),
      netProfit: Number((totalCredit - totalDebit).toFixed(2)),
      transactionCount: all.length,
      categoryBreakdown,
      paymentModeSummary: paymentModeMap,
      dailyTrend: Object.values(dailyTrendMap).sort((a, b) => a.date.localeCompare(b.date)),
    };
  }

  /**
   * Get Live Ledger Summary across accounts & transactions
   */
  static async getLedgerSummary(userId = 1, mode = 'PERSONAL') {
    const cleanMode = (mode || 'PERSONAL').toUpperCase();
    const transactions = await this.findAll({
      userId,
      accountType: cleanMode,
    });

    let totalInflow = 0;
    let totalOutflow = 0;

    transactions.forEach(t => {
      const amt = Number(t.amount) || 0;
      if (t.type === 'CREDIT') totalInflow += amt;
      else if (t.type === 'DEBIT') totalOutflow += amt;
    });

    const accounts = await FinanceProfileModel.getAccounts(userId, cleanMode);
    const totalBalance = accounts.reduce((sum, a) => sum + (Number(a.balance) || 0), 0);
    const netSavings = totalInflow - totalOutflow;
    const savingsRate = totalInflow > 0 ? (netSavings / totalInflow) * 100 : 0;

    return {
      mode: cleanMode,
      totalBalance: Number(totalBalance.toFixed(2)),
      totalInflow: Number(totalInflow.toFixed(2)),
      totalOutflow: Number(totalOutflow.toFixed(2)),
      netSavings: Number(netSavings.toFixed(2)),
      savingsRate: Number(savingsRate.toFixed(1)),
      accountCount: accounts.length,
      transactionCount: transactions.length,
      recentTransactions: transactions.slice(0, 10),
      accounts,
    };
  }

  /**
   * Expense Checking Engine
   */
  static async getExpenseChecking({ userId = 1, mode = 'BUSINESS' } = {}) {
    const cleanMode = (mode || 'BUSINESS').toUpperCase();
    const debits = Array.from(_transactionsStore.values()).filter(t => {
      const matchMode = cleanMode === 'CONSOLIDATED' || t.accountType === cleanMode;
      return matchMode && t.type === 'DEBIT';
    });

    const totalExpense = debits.reduce((sum, t) => sum + t.amount, 0);

    const catMap = {};
    let largestExpense = { amount: 0, category: 'None', note: 'None', date: '' };

    debits.forEach(t => {
      catMap[t.category] = (catMap[t.category] || 0) + t.amount;
      if (t.amount > largestExpense.amount) {
        largestExpense = { amount: t.amount, category: t.category, note: t.note, date: t.date };
      }
    });

    let topCategory = { category: 'None', amount: 0, percentage: 0 };
    Object.keys(catMap).forEach(cat => {
      if (catMap[cat] > topCategory.amount) {
        topCategory = {
          category: cat,
          amount: Number(catMap[cat].toFixed(2)),
          percentage: totalExpense > 0 ? Number(((catMap[cat] / totalExpense) * 100).toFixed(1)) : 0,
        };
      }
    });

    return {
      mode: cleanMode,
      totalExpense: Number(totalExpense.toFixed(2)),
      topCategory,
      largestExpense,
      totalTransactions: debits.length,
    };
  }

  /**
   * Recurring Transactions
   */
  static async getRecurringList({ mode = 'BUSINESS' } = {}) {
    let list = Array.from(_recurringStore.values());
    if (mode && mode !== 'ALL') {
      list = list.filter(r => r.accountType === mode.toUpperCase());
    }
    return list;
  }

  static async createRecurring(data) {
    const id = `rec_${Date.now()}`;
    const item = {
      id,
      name: data.name.trim(),
      accountType: (data.accountType || data.mode || 'BUSINESS').toUpperCase(),
      type: (data.type || 'DEBIT').toUpperCase(),
      amount: Number(data.amount) || 0,
      category: data.category || 'Rent',
      accountId: data.accountId || 'acc_b02',
      paymentMode: (data.paymentMode || 'BANK_TRANSFER').toUpperCase(),
      frequency: (data.frequency || 'MONTHLY').toUpperCase(),
      startDate: data.startDate || new Date().toISOString().split('T')[0],
      nextRunDate: data.nextRunDate || data.startDate || new Date().toISOString().split('T')[0],
      active: true,
      createdAt: new Date().toISOString(),
    };

    _recurringStore.set(id, item);
    return item;
  }

  /**
   * Bank & Cash Balance Reconciliation
   */
  static async reconcileAccount({ accountId = 'acc_b02', actualBalance = 0, reconciliationDate, note } = {}) {
    const acc = await FinanceProfileModel.getAccountById(accountId);
    const appBalance = acc ? Number(acc.balance) : 145000.00;
    const actual = Number(actualBalance);
    const difference = Number((appBalance - actual).toFixed(2));
    const status = Math.abs(difference) < 0.01 ? 'Matched' : 'Mismatch';

    const record = {
      id: `rec_audit_${Date.now()}`,
      accountId,
      accountName: acc ? acc.name : 'Primary Account',
      reconciliationDate: reconciliationDate || new Date().toISOString().split('T')[0],
      appBalance,
      actualBalance: actual,
      difference,
      status,
      note: note || '',
      reconciledAt: new Date().toISOString(),
    };

    _reconciliationStore.set(record.id, record);
    return record;
  }

  /**
   * Consolidated Net Worth Calculation
   */
  static async getConsolidatedNetWorth(userId) {
    const businessAccounts = await FinanceProfileModel.getAccounts('BUSINESS');
    const personalAccounts = await FinanceProfileModel.getAccounts('PERSONAL');

    const businessLiquid = businessAccounts.reduce((sum, a) => sum + (Number(a.balance) || 0), 0);
    const personalLiquid = personalAccounts.reduce((sum, a) => sum + (Number(a.balance) || 0), 0);

    return {
      userId,
      businessNetWorth: businessLiquid,
      personalNetWorth: personalLiquid,
      totalNetWorth: businessLiquid + personalLiquid,
      currency: 'INR',
      updatedAt: new Date().toISOString(),
    };
  }
}

module.exports = TransactionModel;
