/**
 * Atomic Fund Transfer Service & Audit Logging
 * Implements Sections 16-22 of Feature 2 Specification
 */

const FinanceProfileModel = require('../models/financeProfile.model');
const TransactionModel = require('../models/transaction.model');

const _transfersStore = new Map();
const _auditLogsStore = new Map();

// Seed sample past transfer for demo
const seedTransfer = {
  id: 'trf_000001',
  transferCode: 'TRF-000001',
  userId: 1,
  fromMode: 'BUSINESS',
  fromAccountId: 'acc_b02',
  fromAccountName: 'HDFC Current Account',
  toMode: 'PERSONAL',
  toAccountId: 'acc_p01',
  toAccountName: 'SBI Savings Account',
  amount: 20000.00,
  reason: "Owner's Drawing",
  notes: 'Monthly living expenses withdrawal',
  status: 'COMPLETED',
  createdAt: '2026-08-13T10:30:00.000Z',
};

_transfersStore.set(seedTransfer.id, seedTransfer);

_auditLogsStore.set('aud_001', {
  id: 'aud_001',
  transferId: seedTransfer.id,
  transferCode: seedTransfer.transferCode,
  userId: 1,
  action: 'BUSINESS_ACCOUNT_DEBITED',
  mode: 'BUSINESS',
  accountId: seedTransfer.fromAccountId,
  accountName: seedTransfer.fromAccountName,
  amount: 20000.00,
  reason: "Owner's Drawing",
  timestamp: seedTransfer.createdAt,
});

_auditLogsStore.set('aud_002', {
  id: 'aud_002',
  transferId: seedTransfer.id,
  transferCode: seedTransfer.transferCode,
  userId: 1,
  action: 'PERSONAL_ACCOUNT_CREDITED',
  mode: 'PERSONAL',
  accountId: seedTransfer.toAccountId,
  accountName: seedTransfer.toAccountName,
  amount: 20000.00,
  reason: "Owner's Drawing",
  timestamp: seedTransfer.createdAt,
});

class FundTransferService {
  /**
   * Execute atomic Cross-Mode Transfer (Business <-> Personal)
   */
  static async executeTransfer({
    userId = 1,
    fromMode,
    toMode,
    fromAccountId,
    toAccountId,
    amount,
    reason,
    notes = '',
  }) {
    const numAmount = Number(amount);

    // 1. Validation Checks
    if (isNaN(numAmount) || numAmount <= 0) {
      throw new Error('Transfer amount must be a positive number greater than 0.');
    }

    const cleanFromMode = (fromMode || '').toUpperCase();
    const cleanToMode = (toMode || '').toUpperCase();

    if (!['BUSINESS', 'PERSONAL'].includes(cleanFromMode) || !['BUSINESS', 'PERSONAL'].includes(cleanToMode)) {
      throw new Error("Mode must be either 'BUSINESS' or 'PERSONAL'.");
    }

    if (cleanFromMode === cleanToMode) {
      throw new Error('Cross-mode fund transfers must be between different modes (Business ↔ Personal).');
    }

    // 2. Fetch and verify account ownership and mode
    const fromAccount = await FinanceProfileModel.getAccountById(fromAccountId, userId);
    if (!fromAccount) {
      throw new Error('Source account not found or does not belong to you.');
    }
    if (fromAccount.mode !== cleanFromMode) {
      throw new Error(`Source account '${fromAccount.accountName}' does not belong to ${cleanFromMode} mode.`);
    }

    const toAccount = await FinanceProfileModel.getAccountById(toAccountId, userId);
    if (!toAccount) {
      throw new Error('Destination account not found or does not belong to you.');
    }
    if (toAccount.mode !== cleanToMode) {
      throw new Error(`Destination account '${toAccount.accountName}' does not belong to ${cleanToMode} mode.`);
    }

    // Check balance for asset accounts
    if (fromAccount.isAsset && fromAccount.balance < numAmount) {
      throw new Error(`Insufficient balance in source account '${fromAccount.accountName}'. Available: ₹${fromAccount.balance.toLocaleString('en-IN')}`);
    }

    // Determine default reason
    let transferReason = reason ? reason.trim() : '';
    if (!transferReason) {
      transferReason = cleanFromMode === 'BUSINESS' ? "Owner's Drawing" : "Owner Contribution / Capital Injection";
    }

    const transferId = `trf_${Date.now()}`;
    const seq = _transfersStore.size + 1;
    const transferCode = `TRF-${String(seq).padStart(6, '0')}`;
    const transferDate = new Date().toISOString();

    // 3. Atomic Execution with Try / Catch Rollback
    let debitTxId = null;
    let creditTxId = null;

    try {
      // Step A: Debit source account balance
      await FinanceProfileModel.updateAccountBalance(fromAccountId, -numAmount);

      // Step B: Credit destination account balance
      await FinanceProfileModel.updateAccountBalance(toAccountId, numAmount);

      // Step C: Record transaction in Source Ledger
      const debitTx = await TransactionModel.create({
        userId,
        accountType: cleanFromMode,
        type: 'DEBIT',
        category: transferReason,
        amount: numAmount,
        paymentMode: fromAccount.accountType.toUpperCase(),
        date: transferDate.split('T')[0],
        note: `Cross-mode transfer to ${toAccount.accountName} (${cleanToMode}): ${notes}`,
        referenceId: transferCode,
      });
      debitTxId = debitTx.id;

      // Step D: Record transaction in Destination Ledger
      const creditTx = await TransactionModel.create({
        userId,
        accountType: cleanToMode,
        type: 'CREDIT',
        category: transferReason,
        amount: numAmount,
        paymentMode: toAccount.accountType.toUpperCase(),
        date: transferDate.split('T')[0],
        note: `Cross-mode transfer from ${fromAccount.accountName} (${cleanFromMode}): ${notes}`,
        referenceId: transferCode,
      });
      creditTxId = creditTx.id;

      // Step E: Create immutable transfer record
      const transferRecord = {
        id: transferId,
        transferCode,
        userId,
        fromMode: cleanFromMode,
        fromAccountId,
        fromAccountName: fromAccount.accountName,
        toMode: cleanToMode,
        toAccountId,
        toAccountName: toAccount.accountName,
        amount: numAmount,
        reason: transferReason,
        notes,
        status: 'COMPLETED',
        debitTxId,
        creditTxId,
        createdAt: transferDate,
      };

      _transfersStore.set(transferId, transferRecord);

      // Step F: Create Dual Audit Logs
      const auditLog1 = {
        id: `aud_${Date.now()}_1`,
        transferId,
        transferCode,
        userId,
        action: `${cleanFromMode}_ACCOUNT_DEBITED`,
        mode: cleanFromMode,
        accountId: fromAccountId,
        accountName: fromAccount.accountName,
        amount: numAmount,
        reason: transferReason,
        timestamp: transferDate,
      };

      const auditLog2 = {
        id: `aud_${Date.now()}_2`,
        transferId,
        transferCode,
        userId,
        action: `${cleanToMode}_ACCOUNT_CREDITED`,
        mode: cleanToMode,
        accountId: toAccountId,
        accountName: toAccount.accountName,
        amount: numAmount,
        reason: transferReason,
        timestamp: transferDate,
      };

      _auditLogsStore.set(auditLog1.id, auditLog1);
      _auditLogsStore.set(auditLog2.id, auditLog2);

      return {
        transfer: transferRecord,
        sourceBalanceAfter: fromAccount.balance,
        destinationBalanceAfter: toAccount.balance,
        auditLogs: [auditLog1, auditLog2],
      };
    } catch (err) {
      // Rollback balances if any step failed
      try {
        await FinanceProfileModel.updateAccountBalance(fromAccountId, numAmount);
        await FinanceProfileModel.updateAccountBalance(toAccountId, -numAmount);
      } catch (_) {}

      throw new Error(`Transfer failed and was rolled back: ${err.message}`);
    }
  }

  /**
   * Get all cross-mode transfer history for user
   */
  static async getTransferHistory(userId = 1, { mode, search } = {}) {
    let list = Array.from(_transfersStore.values()).filter(t => t.userId === userId);

    if (mode && mode !== 'ALL') {
      const cleanMode = mode.toUpperCase();
      list = list.filter(t => t.fromMode === cleanMode || t.toMode === cleanMode);
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter(t =>
        t.transferCode.toLowerCase().includes(q) ||
        t.fromAccountName.toLowerCase().includes(q) ||
        t.toAccountName.toLowerCase().includes(q) ||
        t.reason.toLowerCase().includes(q)
      );
    }

    list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return list;
  }

  /**
   * Get Audit Logs
   */
  static async getAuditLogs(userId = 1) {
    const list = Array.from(_auditLogsStore.values()).filter(a => a.userId === userId);
    list.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    return list;
  }
}

module.exports = FundTransferService;
