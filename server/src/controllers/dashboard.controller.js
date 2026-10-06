/**
 * Dashboard Controller
 * Handles aggregated live metrics for ENX Money Dashboard
 */

const TransactionModel = require('../models/transaction.model');
const InvoiceModel = require('../models/invoice.model');
const CustomerModel = require('../models/customer.model');
const InventoryModel = require('../models/inventory.model');
const FinanceProfileModel = require('../models/financeProfile.model');
const db = require('../config/db.config');

class DashboardController {
  static async getMetrics(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;

      // 1. Transactions Inflow / Outflow
      const transactions = await TransactionModel.findAll({
        userId,
        accountType: 'BUSINESS',
      });

      let txCredit = 0;
      let txDebit = 0;
      let txSales = 0;
      let txExpenses = 0;

      transactions.forEach(t => {
        const type = (t.type || '').toUpperCase();
        const amt = Number(t.amount) || 0;
        const cat = (t.category || '').toLowerCase();
        const ref = (t.referenceType || '').toUpperCase();

        if (type === 'CREDIT' || type === 'REVENUE') {
          txCredit += amt;
          if (cat === 'sales' || ref === 'KHATA_SALE') {
            txSales += amt;
          }
        } else if (type === 'DEBIT' || type === 'EXPENSE') {
          txDebit += amt;
          txExpenses += amt;
        }
      });

      // 2. Invoices (GST & Non-GST sales)
      let invoiceSales = 0;
      let invoicesPaid = 0;
      try {
        const invoices = await InvoiceModel.findAll({ userId });
        invoices.forEach(inv => {
          const grand = Number(inv.grandTotal) || 0;
          invoiceSales += grand;
          if (inv.paymentStatus === 'PAID') {
            invoicesPaid += grand;
          } else if (inv.amountPaid) {
            invoicesPaid += Number(inv.amountPaid) || 0;
          }
        });
      } catch (_) {}

      // 3. Customers & Khata Ledger
      let customerReceivable = 0;
      let khataSales = 0;
      let khataPayments = 0;
      try {
        const customerRes = await CustomerModel.findAll({ userId });
        customerReceivable = Number(customerRes.totalReceivable) || 0;

        // Check raw ledger entries
        const _ledgerStore = db.inMemoryStore.khataEntries;
        if (_ledgerStore) {
          for (const entry of _ledgerStore.values()) {
            if (String(entry.userId) === String(userId)) {
              const amt = Number(entry.amount) || 0;
              if (entry.entryType === 'GAVE') {
                khataSales += amt;
              } else if (entry.entryType === 'GOT') {
                khataPayments += amt;
              }
            }
          }
        }
      } catch (_) {}

      // 4. Suppliers & Payables
      let supplierPayable = 0;
      try {
        const suppliers = await InventoryModel.getSuppliers(userId);
        suppliers.forEach(s => {
          supplierPayable += Number(s.outstandingPayable || s.balance || 0);
        });
      } catch (_) {}

      // 5. Bank / Cash Accounts Ledger Total
      let bankLedgerTotal = 0;
      try {
        const accounts = FinanceProfileModel.getAccounts(userId, 'BUSINESS');
        accounts.forEach(acc => {
          bankLedgerTotal += Number(acc.balance) || 0;
        });
      } catch (_) {}

      // 6. Aggregate computations as specified:
      // Sales: Live aggregate of Create Sale / Invoice transactions + Khata sales / credit dues
      const totalSales = Math.max(
        invoiceSales + txSales + khataSales,
        customerReceivable + invoicesPaid,
        invoiceSales,
        txSales,
        customerReceivable
      );

      // Expenses: Live aggregate of expense logs & debits
      const totalExpenses = txExpenses;

      // Total Inflow: Sum of all completed sales, received payments, and customer credits
      const totalInflow = Math.max(
        totalSales + khataPayments,
        txCredit + khataSales,
        totalSales
      );

      // Total Outflow: Sum of all recorded expenses, supplier payments, and debits
      const totalOutflow = totalExpenses + supplierPayable;

      // Net Profit: Sales - Expenses
      const netProfit = totalSales - totalExpenses;

      // Total Business Balance: Formula: Total Inflow - Total Outflow (or live aggregated bank ledger total)
      const netBalance = totalInflow - totalOutflow;
      const totalBusinessBalance = netBalance !== 0 ? netBalance : (bankLedgerTotal > 0 ? bankLedgerTotal : 0);

      return res.status(200).json({
        success: true,
        data: {
          totalBusinessBalance,
          totalInflow,
          totalOutflow,
          sales: totalSales,
          expenses: totalExpenses,
          netProfit,
          totalRevenue: totalInflow,
          totalExpense: totalOutflow,
          outstandingReceivables: customerReceivable,
          outstandingPayables: supplierPayable,
          bankLedgerTotal,
        }
      });
    } catch (error) {
      console.error('[DashboardController] getMetrics error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = DashboardController;
