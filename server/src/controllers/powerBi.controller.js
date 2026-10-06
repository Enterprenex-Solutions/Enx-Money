const { query, isConnected } = require('../config/db.config');
const TransactionModel = require('../models/transaction.model');
const CustomerModel = require('../models/customer.model');

const POWER_BI_SCHEMA = {
  name: 'ENX_Money_Financial_Warehouse',
  tables: [
    {
      name: 'Transactions',
      columns: [
        { name: 'TransactionID', dataType: 'string' },
        { name: 'Date', dataType: 'DateTime' },
        { name: 'ProfileType', dataType: 'string' },
        { name: 'TransactionType', dataType: 'string' },
        { name: 'Title', dataType: 'string' },
        { name: 'Category', dataType: 'string' },
        { name: 'AmountINR', dataType: 'Double' },
        { name: 'PaymentMode', dataType: 'string' },
        { name: 'GstRatePercent', dataType: 'Double' },
        { name: 'GstAmountINR', dataType: 'Double' },
        { name: 'InvoiceNumber', dataType: 'string' },
        { name: 'IsCleared', dataType: 'Int64' },
      ],
    },
  ],
};

let syncState = {
  lastSyncAt: null,
  lastStatus: 'Idle (Backend Scheduled)',
  totalPushedRows: 0,
  datasetName: POWER_BI_SCHEMA.name,
};

function safeDivide(num, den, fallback = 0.0) {
  if (!den || isNaN(den) || isNaN(num) || den === 0) return fallback;
  const res = num / den;
  return isFinite(res) ? parseFloat(res.toFixed(2)) : fallback;
}

class PowerBiController {
  /**
   * GET /api/v1/powerbi/schema
   */
  static getSchema(req, res) {
    res.json({
      success: true,
      schema: POWER_BI_SCHEMA,
    });
  }

  /**
   * GET /api/v1/powerbi/payload
   */
  static async getPayload(req, res, next) {
    try {
      const uid = req.user?.id || 1;
      const { profile_type = 'business', date_filter = 'all' } = req.query;

      let txRows = [];
      if (isConnected()) {
        try {
          let profileClause = '';
          const params = [uid];
          if (profile_type && profile_type !== 'all') {
            profileClause = ' AND profile_type = ?';
            params.push(profile_type);
          }
          txRows = await query(
            `SELECT * FROM transactions WHERE user_id = ? ${profileClause} ORDER BY date DESC LIMIT 500`,
            params
          );
        } catch {
          txRows = [];
        }
      }

      if (txRows.length === 0) {
        const inMemoryTx = await TransactionModel.findAll({ userId: uid, accountType: 'ALL' });
        txRows = inMemoryTx.map(t => ({
          id: t.id,
          date: t.date,
          profile_type: t.accountType?.toLowerCase() || 'business',
          type: t.type === 'CREDIT' ? 'revenue' : 'expense',
          title: t.category || 'Transaction',
          category: t.category || 'General',
          amount: t.amount,
          payment_mode: t.paymentMode || 'cash',
          gst_rate: 18,
          invoice_number: t.invoiceNumber || '',
          is_cleared: 1,
        }));
      }

      let totalRev = 0;
      let totalExp = 0;
      let totalRecv = 0;
      let totalPay = 0;
      let totalGst = 0;

      for (const t of txRows) {
        const amt = parseFloat(t.amount || 0);
        if (t.type === 'revenue' || t.type === 'CREDIT') {
          totalRev += amt;
          totalGst += (amt * (parseFloat(t.gst_rate || 0) / 100));
        } else if (t.type === 'expense' || t.type === 'DEBIT') {
          totalExp += amt;
        } else if (t.type === 'receivable') {
          totalRecv += amt;
        } else if (t.type === 'payable') {
          totalPay += amt;
        }
      }

      const netProfit = parseFloat((totalRev - totalExp).toFixed(2));
      const profitMargin = safeDivide(netProfit * 100, totalRev);

      let totalCustomers = 0;
      let activeCustomers = 0;
      try {
        const custList = (await CustomerModel.findAll({ userId: uid })).customers || [];
        totalCustomers = custList.length;
        activeCustomers = custList.filter(c => c.status !== 'INACTIVE').length;
      } catch {}

      const nowIso = new Date().toISOString();

      const formattedRows = txRows.map((t) => ({
        TransactionID: String(t.id),
        Date: new Date(t.date || Date.now()).toISOString(),
        ProfileType: t.profile_type || 'business',
        TransactionType: t.type || 'revenue',
        Title: t.title || 'Transaction',
        Category: t.category || 'General',
        AmountINR: parseFloat(t.amount || 0),
        PaymentMode: t.payment_mode || 'bank_transfer',
        GstRatePercent: parseFloat(t.gst_rate || 0),
        GstAmountINR: parseFloat(((t.amount || 0) * (t.gst_rate || 0) / 100).toFixed(2)),
        InvoiceNumber: t.invoice_number || '',
        IsCleared: t.is_cleared ? 1 : 0,
      }));

      const kpiSummary = {
        Profile: profile_type,
        DateFilter: date_filter,
        TotalRevenue: totalRev,
        TotalExpense: totalExp,
        NetProfit: netProfit,
        ProfitMargin: profitMargin,
        CashInflow: totalRev,
        CashOutflow: totalExp,
        CollectionRate: safeDivide(totalRev, totalRev + totalRecv) * 100,
        TotalCustomers: totalCustomers,
        ActiveCustomers: activeCustomers,
        AverageOrderValue: safeDivide(totalRev, txRows.filter(t => t.type === 'revenue').length || 1),
        OutstandingReceivables: totalRecv,
        OutstandingPayables: totalPay,
        GstPayable: parseFloat(totalGst.toFixed(2)),
        EmiDueThisMonth: 0,
        LastUpdated: nowIso,
      };

      res.json({
        success: true,
        data: {
          dataset: POWER_BI_SCHEMA.name,
          generatedAt: nowIso,
          kpiSummary,
          rows: formattedRows,
          rowCount: formattedRows.length,
        },
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/powerbi/sync
   */
  static async syncToPowerBi(req, res, next) {
    try {
      const endpointUrl = req.body?.endpointUrl || process.env.POWERBI_PUSH_URL;
      const apiKey = req.body?.apiKey || process.env.POWERBI_API_KEY;
      const uid = req.user?.id || 1;

      const txList = await TransactionModel.findAll({ userId: uid, accountType: 'ALL' });
      const formattedRows = txList.map((t) => ({
        TransactionID: String(t.id),
        Date: new Date(t.date || Date.now()).toISOString(),
        ProfileType: t.accountType?.toLowerCase() || 'business',
        TransactionType: t.type === 'CREDIT' ? 'revenue' : 'expense',
        Title: t.category || 'Transaction',
        Category: t.category || 'General',
        AmountINR: parseFloat(t.amount || 0),
        PaymentMode: t.paymentMode || 'bank_transfer',
        GstRatePercent: 18.0,
        GstAmountINR: parseFloat(((t.amount || 0) * 0.18).toFixed(2)),
        InvoiceNumber: t.invoiceNumber || '',
        IsCleared: 1,
      }));

      if (endpointUrl) {
        const headers = { 'Content-Type': 'application/json' };
        if (apiKey) {
          headers['Authorization'] = apiKey.startsWith('Bearer ') ? apiKey : `Bearer ${apiKey}`;
        }

        const response = await fetch(endpointUrl, {
          method: 'POST',
          headers,
          body: JSON.stringify({ rows: formattedRows }),
        });

        syncState = {
          lastSyncAt: new Date().toISOString(),
          lastStatus: response.ok ? 'Success (200 OK)' : `Failed (${response.status})`,
          totalPushedRows: formattedRows.length,
          datasetName: POWER_BI_SCHEMA.name,
        };

        return res.json({
          success: response.ok,
          status: response.status,
          message: response.ok
            ? 'Backend successfully synced transactions to Power BI dataset'
            : 'Power BI endpoint responded with an error',
          rowsPushed: formattedRows.length,
          timestamp: syncState.lastSyncAt,
        });
      }

      syncState = {
        lastSyncAt: new Date().toISOString(),
        lastStatus: 'Payload Prepared (No remote URL configured)',
        totalPushedRows: formattedRows.length,
        datasetName: POWER_BI_SCHEMA.name,
      };

      res.json({
        success: true,
        message: 'Power BI backend dataset generated and ready. Configure POWERBI_PUSH_URL in server environment for auto-streaming.',
        rowsPrepared: formattedRows.length,
        timestamp: syncState.lastSyncAt,
        schema: POWER_BI_SCHEMA.name,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/powerbi/status
   */
  static getStatus(req, res) {
    res.json({
      success: true,
      data: {
        ...syncState,
        configuredEndpoint: process.env.POWERBI_PUSH_URL ? 'Configured (Active)' : 'Not Set',
        autoSyncEnabled: true,
        backendEngine: 'ENX Money Backend Power BI ETL Service',
      },
    });
  }
}

module.exports = PowerBiController;
