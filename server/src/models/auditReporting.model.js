const SettlementEngineModel = require('./settlementEngine.model');

class AuditReportingModel {
  /**
   * Module 6: Query Filtered Financial Records & Transaction History
   */
  static getAuditRecords(userId, { assetType, counterparty, startDate, endDate, limit = 50 }) {
    let txns = SettlementEngineModel.getTransactions(userId);

    // If no transactions yet, provide seeded enterprise transactions for audit demonstration
    if (txns.length === 0) {
      txns = [
        {
          id: 'TXN-ENT-001',
          userId,
          utr: 'ENX8392019482',
          senderName: 'P. Revanth Reddy',
          recipientName: 'Infosys Tech Payouts',
          amount: 25000.00,
          assetType: 'INR',
          purpose: 'Vendor Invoice Clearing',
          status: 'SUCCESS',
          timestamp: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
          gstAmount: 4500.00,
          tdsDeducted: 500.00,
        },
        {
          id: 'TXN-ENT-002',
          userId,
          utr: 'ENX8392019889',
          senderName: 'P. Revanth Reddy',
          recipientName: 'RBI Digital Rupee Merchant',
          amount: 1500.00,
          assetType: 'CBDC',
          purpose: 'Retail Grocery Checkout',
          status: 'SUCCESS',
          timestamp: new Date(Date.now() - 12 * 3600 * 1000).toISOString(),
          gstAmount: 75.00,
          tdsDeducted: 0.00,
        },
        {
          id: 'TXN-ENT-003',
          userId,
          utr: 'ENX8392019124',
          senderName: 'P. Revanth Reddy',
          recipientName: 'Augmont Gold Vault',
          amount: 14500.00,
          assetType: 'GOLD',
          purpose: '24K Digital Gold Accumulation',
          status: 'SUCCESS',
          timestamp: new Date(Date.now() - 28 * 3600 * 1000).toISOString(),
          gstAmount: 435.00, // 3% GST on Gold
          tdsDeducted: 0.00,
        },
      ];
    }

    if (assetType && assetType !== 'ALL') {
      txns = txns.filter((t) => (t.assetType || '').toUpperCase() === assetType.toUpperCase());
    }
    if (counterparty) {
      const q = counterparty.toLowerCase();
      txns = txns.filter(
        (t) => (t.recipientName || '').toLowerCase().includes(q) || (t.senderName || '').toLowerCase().includes(q)
      );
    }

    // Calculate Tax & GST Summary
    const totalVolume = txns.reduce((sum, t) => sum + (parseFloat(t.amount) || 0), 0);
    const totalGst = txns.reduce((sum, t) => sum + (parseFloat(t.gstAmount) || (parseFloat(t.amount) * 0.18)), 0);
    const totalTds = txns.reduce((sum, t) => sum + (parseFloat(t.tdsDeducted) || 0), 0);

    return {
      records: txns.slice(0, limit),
      summary: {
        totalRecords: txns.length,
        totalTransactionVolume: totalVolume,
        totalGstLiability: totalGst,
        totalTdsWithheld: totalTds,
        accountingSyncStatus: 'SYNCED_WITH_ERP',
        lastSyncTimestamp: new Date().toISOString(),
      },
    };
  }

  /**
   * Export CSV format statement for regulatory & audit compliance
   */
  static exportCsvStatement(userId) {
    const data = this.getAuditRecords(userId, {});
    let csv = 'Transaction ID,UTR,Date,Asset Type,Sender,Recipient,Amount (INR),GST,Status\n';

    data.records.forEach((r) => {
      csv += `"${r.id}","${r.utr || ''}","${r.timestamp}","${r.assetType}","${r.senderName}","${r.recipientName}",${r.amount},${r.gstAmount || 0},"${r.status}"\n`;
    });

    return csv;
  }
}

module.exports = AuditReportingModel;
