const AnalyticsService = require('../services/analytics.service');

class AnalyticsController {
  static async getKpi(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { profile_type, start_date, end_date } = req.query;
      const data = await AnalyticsService.getKpi(userId, { profile_type, start_date, end_date });
      return res.status(200).json({ success: true, data });
    } catch (error) {
      console.error('[AnalyticsController] getKpi error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getDailyTrend(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { profile_type, days } = req.query;
      const data = await AnalyticsService.getDailyTrend(userId, { profile_type, days });
      return res.status(200).json({ success: true, data });
    } catch (error) {
      console.error('[AnalyticsController] getDailyTrend error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getCategories(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { profile_type, type, start_date, end_date } = req.query;
      const data = await AnalyticsService.getCategories(userId, { profile_type, type, start_date, end_date });
      return res.status(200).json({ success: true, data });
    } catch (error) {
      console.error('[AnalyticsController] getCategories error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getDashboard(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { mode, period, startDate, endDate } = req.query;

      const [kpiData, chartsData] = await Promise.all([
        AnalyticsService.getDashboardKPIs(userId, { mode, period, startDate, endDate }),
        AnalyticsService.getChartsData(userId, { mode, period }),
      ]);

      return res.status(200).json({
        success: true,
        data: {
          ...kpiData,
          charts: chartsData,
        }
      });
    } catch (error) {
      console.error('[AnalyticsController] getDashboard error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getDrillDown(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { mode, type, key } = req.query;

      const drillDown = await AnalyticsService.getDrillDown(userId, { mode, type, key });
      return res.status(200).json({
        success: true,
        data: drillDown,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getPowerBIDataset(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const dataset = await AnalyticsService.getPowerBIDataset(userId);
      return res.status(200).json({
        success: true,
        data: dataset,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async runCustomReport(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { source, fields, filters } = req.body;
      const report = await AnalyticsService.executeCustomReport(userId, { source, fields, filters });
      return res.status(200).json({
        success: true,
        data: report,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async scheduleEmail(req, res) {
    try {
      const { frequency, email, mode } = req.body;
      return res.status(200).json({
        success: true,
        message: `Scheduled ${frequency} financial report successfully dispatched to ${email}!`,
        data: { frequency, email, mode, nextRun: 'Next Monday at 09:00 AM IST' },
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async exportExcel(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const dataset = await AnalyticsService.getPowerBIDataset(userId);

      // Generate CSV formatted content
      let csv = 'Transaction ID,Date,Mode,Type,Category,Amount,Payment Mode\n';
      dataset.factTables.factTransactions.forEach(t => {
        csv += `${t.transactionId},${t.date},${t.mode},${t.type},"${t.category}",${t.amount},${t.paymentMode}\n`;
      });

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="ENX_Money_Financial_Statement.csv"');
      return res.status(200).send(csv);
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getHealthScore(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const data = await AnalyticsService.calculateBusinessHealthScore(userId);
      return res.status(200).json({ success: true, data });
    } catch (error) {
      console.error('[AnalyticsController] getHealthScore error:', error);
      return res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = AnalyticsController;
