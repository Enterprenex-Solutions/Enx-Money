/**
 * Unified Analytics, Aggregation Engine & Power BI Data Service
 * Implements Feature 3 of Functional Specification Document
 */

const TransactionModel = require('../models/transaction.model');
const InvoiceModel = require('../models/invoice.model');
const CustomerModel = require('../models/customer.model');
const InventoryModel = require('../models/inventory.model');
const LoanModel = require('../models/loan.model');
const FinanceProfileModel = require('../models/financeProfile.model');

class AnalyticsService {
  /**
   * Helper to parse and calculate date boundaries
   */
  static getDateBoundaries(period = 'THIS_MONTH', customStart = null, customEnd = null) {
    const now = new Date();
    let startDate = new Date();
    let endDate = new Date();

    const periodClean = (period || 'THIS_MONTH').toUpperCase();

    if (periodClean === 'TODAY') {
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    } else if (periodClean === 'THIS_WEEK') {
      const day = now.getDay();
      const diff = now.getDate() - day + (day === 0 ? -6 : 1); // Monday
      startDate = new Date(now.setDate(diff));
      startDate.setHours(0, 0, 0, 0);
      endDate = new Date(startDate);
      endDate.setDate(startDate.getDate() + 6);
      endDate.setHours(23, 59, 59);
    } else if (periodClean === 'THIS_MONTH') {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    } else if (periodClean === 'FINANCIAL_YEAR') {
      // Indian Financial Year: April 1 to March 31
      const currentYear = now.getFullYear();
      const currentMonth = now.getMonth(); // 0-indexed (3 = April)
      const fyStartYear = currentMonth >= 3 ? currentYear : currentYear - 1;
      startDate = new Date(fyStartYear, 3, 1); // April 1
      endDate = new Date(fyStartYear + 1, 2, 31, 23, 59, 59); // March 31
    } else if (periodClean === 'CUSTOM' && customStart && customEnd) {
      startDate = new Date(customStart);
      startDate.setHours(0, 0, 0, 0);
      endDate = new Date(customEnd);
      endDate.setHours(23, 59, 59);
    } else {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    }

    return {
      period: periodClean,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
    };
  }

  /**
   * Exact 7-KPI Summary from Anjali's branch
   * GET /api/v1/analytics/kpi
   */
  static async getKpi(userId = 1, { profile_type = 'business', start_date, end_date } = {}) {
    const boundaries = this.getDateBoundaries(
      (start_date && end_date) ? 'CUSTOM' : 'THIS_MONTH',
      start_date,
      end_date
    );

    // 1. Transactions Inflow / Outflow
    const transactions = await TransactionModel.findAll({
      userId,
      accountType: profile_type ? profile_type.toUpperCase() : 'ALL',
      startDate: boundaries.startDate,
      endDate: boundaries.endDate,
    });

    let totalRevenue = 0;
    let totalExpense = 0;
    transactions.forEach(t => {
      const type = (t.type || '').toUpperCase();
      if ((type === 'CREDIT' || type === 'REVENUE') && t.referenceType !== 'KHATA_PAYMENT') {
        totalRevenue += Number(t.amount) || 0;
      } else if (type === 'DEBIT' || type === 'EXPENSE') {
        totalExpense += Number(t.amount) || 0;
      }
    });

    const isPersonal = (profile_type || '').toLowerCase() === 'personal';

    // 2. Receivables from customers (strictly business)
    let outstandingReceivables = 0;
    if (!isPersonal) {
      const customerRes = await CustomerModel.findAll({ userId });
      outstandingReceivables = Number(customerRes.totalReceivable) || 0;
    }

    // Invoices are strictly business revenue
    if (!isPersonal) {
      const invoices = await InvoiceModel.findAll({ userId });
      invoices.forEach(inv => {
        if (inv.status === 'PAID' || inv.paymentStatus === 'PAID') {
          totalRevenue += Number(inv.grandTotal) || 0;
        } else if (inv.amountPaid) {
          totalRevenue += Number(inv.amountPaid) || 0;
        }
      });
      // If no paid invoices recorded yet but customer credit sales exist, reflect in revenue
      if (totalRevenue === 0 && outstandingReceivables > 0) {
        totalRevenue = outstandingReceivables;
      }
    }

    const netProfit = totalRevenue - totalExpense;

    // 3. Payables to suppliers (strictly business, isolated by userId)
    let outstandingPayables = 0;
    if (!isPersonal) {
      try {
        const suppliers = await InventoryModel.getSuppliers(userId);
        suppliers.forEach(s => {
          outstandingPayables += Number(s.outstandingPayable ?? s.currentBalance ?? s.current_balance ?? s.openingBalance ?? s.balance ?? 0);
        });
      } catch (_) {}
    }

    // 4. GST Payable from invoices (strictly business)
    let gstPayable = 0;
    if (!isPersonal) {
      try {
        const invoices = await InvoiceModel.findAll({ userId });
        invoices.forEach(inv => {
          gstPayable += (Number(inv.cgstTotal) || 0) + (Number(inv.sgstTotal) || 0) + (Number(inv.igstTotal) || 0);
        });
      } catch (_) {}
    }

    // 5. EMI Due This Month from Loans (strictly business loans)
    let emiDueThisMonth = 0;
    if (!isPersonal) {
      try {
        const loans = await LoanModel.findAll({ userId, status: 'Active' });
        loans.forEach(loan => {
          emiDueThisMonth += Number(loan.emiAmount) || 0;
        });
      } catch (_) {}
    }

    // 6. Purchases & Collection Rate
    let totalPurchases = 0;
    if (!isPersonal) {
      transactions.forEach(t => {
        const type = (t.type || '').toUpperCase();
        const cat = (t.category || '').toLowerCase();
        if ((type === 'DEBIT' || type === 'EXPENSE') && (cat.includes('purchase') || cat.includes('supplier'))) {
          totalPurchases += Number(t.amount) || 0;
        }
      });
    }
    const collected = totalRevenue > outstandingReceivables ? (totalRevenue - outstandingReceivables) : 0;
    const collectionRate = (!isPersonal && totalRevenue > 0) ? Number(((collected / totalRevenue) * 100).toFixed(1)) : 0;

    // 7. Inventory Valuation (strictly business, isolated by userId)
    let inventoryValuation = 0;
    if (!isPersonal) {
      try {
        const invSummary = await InventoryModel.getInventorySummary(userId);
        inventoryValuation = Number(invSummary.total_inventory_valuation) || 0;
      } catch (_) {}
    }

    return {
      totalRevenue: Number(totalRevenue.toFixed(2)),
      totalSales: Number(totalRevenue.toFixed(2)),
      totalPurchases: Number(totalPurchases.toFixed(2)),
      totalExpense: Number(totalExpense.toFixed(2)),
      netProfit: Number(netProfit.toFixed(2)),
      outstandingReceivables: Number(outstandingReceivables.toFixed(2)),
      outstandingPayables: Number(outstandingPayables.toFixed(2)),
      collectionRate,
      gstPayable: Number(gstPayable.toFixed(2)),
      emiDueThisMonth: Number(emiDueThisMonth.toFixed(2)),
      inventoryValue: Number(inventoryValuation.toFixed(2)),
      total_inventory_valuation: Number(inventoryValuation.toFixed(2)),
    };
  }

  /**
   * Daily Trend for charts from Anjali's branch
   * GET /api/v1/analytics/daily-trend
   */
  static async getDailyTrend(userId = 1, { profile_type = 'business', days = 7 } = {}) {
    const transactions = await TransactionModel.findAll({
      userId,
      accountType: profile_type ? profile_type.toUpperCase() : 'ALL',
    });

    const trendMap = new Map();
    const numDays = parseInt(days) || 7;
    const now = new Date();

    for (let i = numDays - 1; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(now.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      trendMap.set(dateStr, { date: dateStr, revenue: 0, expense: 0 });
    }

    transactions.forEach(t => {
      const tDate = (t.date || '').split('T')[0];
      if (trendMap.has(tDate)) {
        const entry = trendMap.get(tDate);
        const type = (t.type || '').toUpperCase();
        if (type === 'CREDIT' || type === 'REVENUE') entry.revenue += Number(t.amount) || 0;
        else if (type === 'DEBIT' || type === 'EXPENSE') entry.expense += Number(t.amount) || 0;
      }
    });

    const trend = Array.from(trendMap.values());
    const totalRevenueInPeriod = trend.reduce((s, r) => s + r.revenue, 0);
    const totalExpenseInPeriod = trend.reduce((s, r) => s + r.expense, 0);

    return {
      trend,
      totalRevenueInPeriod: Number(totalRevenueInPeriod.toFixed(2)),
      totalExpenseInPeriod: Number(totalExpenseInPeriod.toFixed(2)),
    };
  }

  /**
   * Categories Breakdown for Pie Chart from Anjali's branch
   * GET /api/v1/analytics/categories
   */
  static async getCategories(userId = 1, { profile_type = 'business', type = 'expense', start_date, end_date } = {}) {
    const isExpense = type.toLowerCase() === 'expense';
    const transactions = await TransactionModel.findAll({
      userId,
      accountType: profile_type ? profile_type.toUpperCase() : 'ALL',
      type: isExpense ? 'DEBIT' : 'CREDIT',
    });

    const catMap = {};
    let total = 0;

    transactions.forEach(t => {
      const cat = t.category || 'General';
      const amt = Number(t.amount) || 0;
      catMap[cat] = (catMap[cat] || 0) + amt;
      total += amt;
    });

    const categories = Object.keys(catMap).map(category => {
      const amount = Number(catMap[category].toFixed(2));
      const percentage = total > 0 ? Number(((amount / total) * 100).toFixed(1)) : 0;
      return { category, amount, percentage };
    }).sort((a, b) => b.amount - a.amount);

    return {
      categories,
      totalAmount: Number(total.toFixed(2)),
    };
  }

  /**
   * Get Unified Dashboard KPIs
   */
  static async getDashboardKPIs(userId = 1, { mode = 'BUSINESS', period = 'THIS_MONTH', startDate, endDate } = {}) {
    const boundaries = this.getDateBoundaries(period, startDate, endDate);
    const cleanMode = (mode || 'BUSINESS').toUpperCase();

    // 1. Fetch Mode Transactions
    const transactions = await TransactionModel.findAll({
      userId,
      accountType: cleanMode === 'CONSOLIDATED' ? 'ALL' : cleanMode,
    });

    let totalRevenue = 0;
    let totalExpense = 0;

    transactions.forEach(t => {
      if (t.type === 'CREDIT') totalRevenue += Number(t.amount) || 0;
      else if (t.type === 'DEBIT') totalExpense += Number(t.amount) || 0;
    });

    const netProfit = totalRevenue - totalExpense;

    // 2. Outstanding Receivables from Customers
    const customerSummary = await CustomerModel.findAll({ userId });
    const outstandingReceivables = customerSummary.totalReceivable || 0;

    // 3. Outstanding Payables (Suppliers)
    const suppliers = await InventoryModel.getSuppliers(userId);
    let outstandingPayables = 0;
    if (Array.isArray(suppliers)) {
      suppliers.forEach(s => {
        outstandingPayables += Number(s.outstandingPayable ?? s.currentBalance ?? s.current_balance ?? s.openingBalance ?? s.balance ?? 0);
      });
    }

    // 4. GST Payable from Invoices (Exact Section 3 Formula)
    const invoices = await InvoiceModel.findAll({ userId });
    let gstPayable = 0;
    invoices.forEach(inv => {
      gstPayable += (Number(inv.cgstTotal) || 0) + (Number(inv.sgstTotal) || 0) + (Number(inv.igstTotal) || 0);
    });

    // 5. EMI Due This Month from Loans
    let emiDueThisMonth = 0;
    try {
      const activeLoans = await LoanModel.findAll({ userId, status: 'Active' });
      if (Array.isArray(activeLoans)) {
        activeLoans.forEach(l => {
          emiDueThisMonth += Number(l.emiAmount) || 0;
        });
      }
    } catch (_) {
      emiDueThisMonth = 0;
    }

    // 6. Inventory Valuation (Decimal precision via paise)
    let totalValuationPaise = 0n;
    if (cleanMode !== 'PERSONAL') {
      const inventory = await InventoryModel.findAll({ userId });
      inventory.forEach(item => {
        const stock = Math.max(0, parseInt(item.currentStock, 10) || 0);
        const cost = Math.max(0, parseFloat(item.costPrice) || 0);
        totalValuationPaise += BigInt(stock) * BigInt(Math.round(cost * 100));
      });
    }
    const inventoryValue = Number(totalValuationPaise) / 100;

    return {
      mode: cleanMode,
      dateRange: boundaries,
      kpis: {
        totalRevenue: Number(totalRevenue.toFixed(2)),
        totalExpense: Number(totalExpense.toFixed(2)),
        netProfit: Number(netProfit.toFixed(2)),
        outstandingReceivables: Number(outstandingReceivables.toFixed(2)),
        outstandingPayables: Number(outstandingPayables.toFixed(2)),
        gstPayable: Number(gstPayable.toFixed(2)),
        emiDueThisMonth: Number(emiDueThisMonth.toFixed(2)),
        inventoryValue: Number(inventoryValue.toFixed(2)),
        total_inventory_valuation: Number(inventoryValue.toFixed(2)),
      }
    };
  }

  /**
   * Get Chart Datasets (Real Database Data Calculation)
   */
  static async getChartsData(userId = 1, { mode = 'BUSINESS', period = 'THIS_MONTH' } = {}) {
    const cleanMode = (mode || 'BUSINESS').toUpperCase();
    const transactions = await TransactionModel.findAll({
      userId,
      accountType: cleanMode === 'CONSOLIDATED' ? 'ALL' : cleanMode,
    });
    const invoices = await InvoiceModel.findAll({ userId });
    const customers = await CustomerModel.findAll({ userId });
    const suppliers = await InventoryModel.getSuppliers(userId);
    const products = await InventoryModel.findAll({ userId });

    // 1. Compute 6-Month Monthly Trends (Sales, Purchases, Expenses, Profit)
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const now = new Date();
    const monthlyMap = new Map();

    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      const label = `${monthNames[d.getMonth()]} ${d.getFullYear()}`;
      monthlyMap.set(key, {
        key,
        month: label,
        shortMonth: monthNames[d.getMonth()],
        sales: 0,
        purchases: 0,
        expense: 0,
        profit: 0,
      });
    }

    // Process transactions into monthly bins
    transactions.forEach(t => {
      const tDate = t.date ? new Date(t.date) : new Date(t.createdAt || Date.now());
      const key = `${tDate.getFullYear()}-${String(tDate.getMonth() + 1).padStart(2, '0')}`;
      const amt = Number(t.amount) || 0;
      const type = (t.type || '').toUpperCase();
      const cat = (t.category || '').toLowerCase();

      if (monthlyMap.has(key)) {
        const item = monthlyMap.get(key);
        if (type === 'CREDIT' || type === 'REVENUE') {
          if (t.referenceType !== 'KHATA_PAYMENT') {
            item.sales += amt;
          }
        } else if (type === 'DEBIT' || type === 'EXPENSE') {
          item.expense += amt;
          if (cat.includes('purchase') || cat.includes('supplier')) {
            item.purchases += amt;
          }
        }
      }
    });

    // Also include paid invoices in sales
    invoices.forEach(inv => {
      if (inv.status === 'PAID') {
        const iDate = inv.invoiceDate ? new Date(inv.invoiceDate) : new Date(inv.createdAt || Date.now());
        const key = `${iDate.getFullYear()}-${String(iDate.getMonth() + 1).padStart(2, '0')}`;
        const amt = Number(inv.grandTotal) || 0;
        if (monthlyMap.has(key)) {
          monthlyMap.get(key).sales += amt;
        }
      }
    });

    // Calculate profit for each month
    const monthlyTrends = Array.from(monthlyMap.values()).map(m => ({
      ...m,
      sales: Number(m.sales.toFixed(2)),
      purchases: Number(m.purchases.toFixed(2)),
      expense: Number(m.expense.toFixed(2)),
      profit: Number((m.sales - m.expense).toFixed(2)),
    }));

    // 2. Real Totals for Sales vs Purchase
    let totalSales = 0;
    let totalPurchases = 0;
    let totalExpenses = 0;

    monthlyTrends.forEach(m => {
      totalSales += m.sales;
      totalPurchases += m.purchases;
      totalExpenses += m.expense;
    });

    // 3. Real Expense Categories (Donut / Breakdown) - NO hardcoded fallback values
    const categoryTotals = {};
    transactions.filter(t => t.type === 'DEBIT' || t.type === 'EXPENSE').forEach(t => {
      const cat = t.category || 'General Expense';
      categoryTotals[cat] = (categoryTotals[cat] || 0) + Number(t.amount);
    });

    const expenseCategories = Object.keys(categoryTotals).map(cat => ({
      category: cat,
      amount: Number(categoryTotals[cat].toFixed(2)),
    })).sort((a, b) => b.amount - a.amount);

    // 4. Receivables vs Payables
    const totalReceivable = Number(customers.totalReceivable) || 0;
    let totalPayable = 0;
    if (Array.isArray(suppliers)) {
      suppliers.forEach(s => {
        totalPayable += Number(s.outstandingPayable ?? s.currentBalance ?? s.current_balance ?? s.openingBalance ?? s.balance ?? 0);
      });
    }

    // 5. Stock / Inventory Health
    let totalProducts = 0;
    let lowStockCount = 0;
    let outOfStockCount = 0;
    let totalStockValuation = 0;

    if (Array.isArray(products)) {
      totalProducts = products.length;
      products.forEach(p => {
        const stock = Number(p.currentStock) || 0;
        const reorder = Number(p.reorderLevel) || 5;
        const cost = Number(p.costPrice) || 0;
        totalStockValuation += stock * cost;
        if (stock <= 0) outOfStockCount++;
        else if (stock <= reorder) lowStockCount++;
      });
    }

    // 6. 4-Week Cash Flow Trend from actual transactions
    const cashFlowTrend = [];
    for (let w = 3; w >= 0; w--) {
      const startDay = new Date(now);
      startDay.setDate(now.getDate() - ((w + 1) * 7));
      const endDay = new Date(now);
      endDay.setDate(now.getDate() - (w * 7));

      let credits = 0;
      let debits = 0;
      transactions.forEach(t => {
        const d = new Date(t.date || t.createdAt);
        if (d >= startDay && d <= endDay) {
          if (t.type === 'CREDIT') credits += Number(t.amount) || 0;
          else if (t.type === 'DEBIT') debits += Number(t.amount) || 0;
        }
      });
      cashFlowTrend.push({
        period: `Week ${4 - w}`,
        credits: Number(credits.toFixed(2)),
        debits: Number(debits.toFixed(2)),
        net: Number((credits - debits).toFixed(2)),
      });
    }

    return {
      salesByMonth: monthlyTrends,
      monthlySales: monthlyTrends,
      monthlyTrends,
      cashFlowTrend,
      expenseCategories,
      salesVsPurchase: {
        totalSales: Number(totalSales.toFixed(2)),
        totalPurchases: Number(totalPurchases.toFixed(2)),
      },
      receivablesVsPayables: {
        receivables: Number(totalReceivable.toFixed(2)),
        payables: Number(totalPayable.toFixed(2)),
      },
      stockHealth: {
        totalProducts,
        lowStockCount,
        outOfStockCount,
        totalStockValuation: Number(totalStockValuation.toFixed(2)),
      },
    };
  }

  /**
   * Drill-Down: Returns underlying granular transactional items
   */
  static async getDrillDown(userId = 1, { mode = 'BUSINESS', type = 'category', key } = {}) {
    const cleanMode = (mode || 'BUSINESS').toUpperCase();
    const transactions = await TransactionModel.findAll({
      userId,
      accountType: cleanMode === 'CONSOLIDATED' ? 'ALL' : cleanMode,
    });

    let records = [];

    if (type === 'category' && key) {
      records = transactions.filter(t => t.category.toLowerCase() === key.toLowerCase());
    } else if (type === 'sales') {
      records = transactions.filter(t => t.type === 'CREDIT');
    } else if (type === 'expenses') {
      records = transactions.filter(t => t.type === 'DEBIT');
    } else {
      records = transactions.slice(0, 10);
    }

    return {
      type,
      key,
      count: records.length,
      records,
    };
  }

  /**
   * Power BI Star Schema Datasets
   */
  static async getPowerBIDataset(userId = 1) {
    const transactions = await TransactionModel.findAll({ userId, accountType: 'ALL' });
    const invoices = await InvoiceModel.findAll({ userId });
    const inventory = await InventoryModel.findAll({ userId });
    const customers = (await CustomerModel.findAll({ userId })).customers || [];

    return {
      modelName: 'ENX_Money_Analytical_Warehouse',
      generatedAt: new Date().toISOString(),
      factTables: {
        factTransactions: transactions.map(t => ({
          transactionId: t.id,
          date: t.date,
          mode: t.accountType,
          type: t.type,
          category: t.category,
          amount: t.amount,
          paymentMode: t.paymentMode,
        })),
        factInvoices: invoices.map(i => ({
          invoiceId: i.id,
          invoiceNumber: i.invoiceNumber,
          date: i.invoiceDate,
          taxableTotal: i.taxableTotal,
          cgst: i.cgstTotal,
          sgst: i.sgstTotal,
          igst: i.igstTotal,
          grandTotal: i.grandTotal,
          status: i.paymentStatus,
        })),
        factInventory: inventory.map(item => ({
          sku: item.sku,
          name: item.name,
          currentStock: item.currentStock,
          costPrice: item.costPrice,
          sellingPrice: item.sellingPrice,
          valuation: item.currentStock * item.costPrice,
        })),
      },
      dimensionTables: {
        dimCustomers: customers.map(c => ({
          customerId: c.id,
          name: c.name,
          district: c.district,
          state: c.state,
          pincode: c.pincode,
          balance: c.currentBalance,
        })),
      },
      measures: [
        'Total Revenue = SUM(factTransactions[amount]) WHERE type="CREDIT"',
        'Total Expense = SUM(factTransactions[amount]) WHERE type="DEBIT"',
        'Net Profit = [Total Revenue] - [Total Expense]',
        'GST Payable = SUM(factInvoices[cgst]) + SUM(factInvoices[sgst]) + SUM(factInvoices[igst])',
      ]
    };
  }

  /**
   * Custom Report Builder Executor
   */
  static async executeCustomReport(userId = 1, { source = 'Transactions', fields = [], filters = {} }) {
    const transactions = await TransactionModel.findAll({ userId, accountType: 'ALL' });

    let data = transactions;
    if (filters.mode && filters.mode !== 'ALL') {
      data = data.filter(t => t.accountType === filters.mode.toUpperCase());
    }
    if (filters.type && filters.type !== 'ALL') {
      data = data.filter(t => t.type === filters.type.toUpperCase());
    }

    return {
      reportTitle: `Custom ${source} Report`,
      totalRecords: data.length,
      fields,
      records: data,
    };
  }

  /**
   * Business Health Score Algorithm (0-100)
   * Evaluates profitability, collection rate, expense ratio, debt coverage, and customer activity
   */
  static async calculateBusinessHealthScore(userId = 1) {
    const [kpi, customerSummary, transactions, invoices, loans] = await Promise.all([
      this.getKpi(userId, { profile_type: 'business' }),
      CustomerModel.findAll({ userId }),
      TransactionModel.findAll({ userId, accountType: 'ALL' }),
      InvoiceModel.findAll({ userId }),
      LoanModel.findAll({ userId, status: 'Active' }).catch(() => []),
    ]);

    const totalRevenue = kpi.totalRevenue || 0;
    const totalExpense = kpi.totalExpense || 0;
    const netProfit = kpi.netProfit || 0;
    const receivables = kpi.outstandingReceivables || 0;
    const payables = kpi.outstandingPayables || 0;
    const totalCustomers = customerSummary.totalCount || (customerSummary.customers ? customerSummary.customers.length : 0);

    // A business must have recorded operational revenue or expense activity to generate a financial health score.
    // If there is zero revenue and zero expense, or no transactions/invoices, return INSUFFICIENT DATA.
    const hasOperationalActivity = (totalRevenue > 0 || totalExpense > 0) &&
      ((transactions && transactions.length > 0) || (invoices && invoices.length > 0));

    if (!hasOperationalActivity) {
      return {
        score: 0,
        status: 'INSUFFICIENT DATA',
        statusColor: '#9E9E9E',
        hasSufficientData: false,
        breakdown: {
          profitability: { score: 0, max: 25, profitMargin: 0 },
          collections: { score: 0, max: 25, totalReceivable: receivables },
          expenseControl: { score: 0, max: 20, expenseRatio: 0 },
          liabilityCoverage: { score: 0, max: 15, totalLiabilities: payables + (kpi.emiDueThisMonth || 0) },
          customerActivity: { score: 0, max: 15, activeCustomers: totalCustomers },
        },
        actionableTips: [
          'Record business sales, GST invoices, or operating expenses to unlock your AI Business Health Score.',
          receivables > 0 ? `Follow up on ₹${receivables.toFixed(2)} in receivables to collect pending cash flow.` : 'Generate your first GST invoice or track a sale to begin profit margin tracking.',
          'Add your supplier payables or inventory stock to evaluate liability coverage.',
        ],
        calculatedAt: new Date().toISOString(),
      };
    }

    // 1. Profit Margin Score (0 to 25 pts)
    const profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) : 0;
    let profitScore = 10;
    if (profitMargin >= 0.30) profitScore = 25;
    else if (profitMargin >= 0.20) profitScore = 20;
    else if (profitMargin >= 0.10) profitScore = 15;
    else if (profitMargin >= 0) profitScore = 10;
    else profitScore = Math.max(0, Math.round(10 + (profitMargin * 20)));

    // 2. Collection & Receivables Health (0 to 25 pts)
    const aging = customerSummary.customers ? customerSummary.customers.reduce((acc, c) => {
      const a = c.aging || {};
      acc.days0_30 += (a.days0To30 || a.days0_30 || 0);
      acc.days60Plus += (a.days61To90 || a.days61_90 || 0) + (a.days90Plus || a.days90_plus || 0);
      return acc;
    }, { days0_30: 0, days60Plus: 0 }) : { days0_30: 0, days60Plus: 0 };

    let collectionScore = 20;
    if (receivables === 0) {
      collectionScore = 25;
    } else {
      const overdueRatio = aging.days60Plus / (receivables || 1);
      if (overdueRatio < 0.15) collectionScore = 25;
      else if (overdueRatio < 0.30) collectionScore = 20;
      else if (overdueRatio < 0.50) collectionScore = 14;
      else collectionScore = 8;
    }

    // 3. Expense Control Ratio (0 to 20 pts)
    const expenseRatio = totalRevenue > 0 ? (totalExpense / totalRevenue) : (totalExpense > 0 ? 1.0 : 0.5);
    let expenseScore = 12;
    if (expenseRatio <= 0.60) expenseScore = 20;
    else if (expenseRatio <= 0.75) expenseScore = 16;
    else if (expenseRatio <= 0.90) expenseScore = 12;
    else if (expenseRatio <= 1.00) expenseScore = 8;
    else expenseScore = 4;

    // 4. Debt & Liability Coverage (0 to 15 pts)
    let debtScore = 15;
    const totalLiabilities = payables + (kpi.emiDueThisMonth || 0);
    if (totalLiabilities > 0) {
      const coverageRatio = (totalRevenue - totalExpense) / totalLiabilities;
      if (coverageRatio >= 2.0) debtScore = 15;
      else if (coverageRatio >= 1.0) debtScore = 12;
      else if (coverageRatio >= 0.5) debtScore = 9;
      else debtScore = 6;
    }

    // 5. Customer Diversification & Activity (0 to 15 pts)
    let customerScore = 10;
    if (totalCustomers >= 5) customerScore = 15;
    else if (totalCustomers >= 3) customerScore = 12;
    else if (totalCustomers >= 1) customerScore = 9;
    else customerScore = 5;

    const totalScore = Math.min(100, Math.max(0, profitScore + collectionScore + expenseScore + debtScore + customerScore));

    let status = 'HEALTHY';
    let statusColor = '#00BCD4';
    if (totalScore >= 80) {
      status = 'EXCELLENT';
      statusColor = '#00E676';
    } else if (totalScore >= 65) {
      status = 'HEALTHY';
      statusColor = '#00BCD4';
    } else if (totalScore >= 50) {
      status = 'NEEDS ATTENTION';
      statusColor = '#FFB300';
    } else {
      status = 'CRITICAL';
      statusColor = '#FF5252';
    }

    const tips = [];
    if (receivables > 0) tips.push(`Follow up on ₹${receivables.toFixed(2)} in receivables to boost cash flow.`);
    if (expenseRatio > 0.75) tips.push(`Expense ratio is ${(expenseRatio * 100).toFixed(0)}%. Target below 70% to improve margins.`);
    if (profitMargin < 0.15) tips.push(`Profit margin is ${(profitMargin * 100).toFixed(1)}%. Review product pricing and reduce overheads.`);
    if (totalCustomers < 5) tips.push(`Onboard new business customers to diversify revenue streams.`);
    if (tips.length === 0) tips.push(`Business operations and financial health metrics are in pristine condition!`);

    return {
      score: totalScore,
      status,
      statusColor,
      breakdown: {
        profitability: { score: profitScore, max: 25, profitMargin: Number((profitMargin * 100).toFixed(1)) },
        collections: { score: collectionScore, max: 25, totalReceivable: receivables },
        expenseControl: { score: expenseScore, max: 20, expenseRatio: Number((expenseRatio * 100).toFixed(1)) },
        liabilityCoverage: { score: debtScore, max: 15, totalLiabilities },
        customerActivity: { score: customerScore, max: 15, activeCustomers: totalCustomers },
      },
      actionableTips: tips,
      calculatedAt: new Date().toISOString(),
    };
  }
}

module.exports = AnalyticsService;
