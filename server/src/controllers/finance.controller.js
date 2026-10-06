const FinanceProfileModel = require('../models/financeProfile.model');
const FundTransferService = require('../services/fundTransfer.service');
const TransactionModel = require('../models/transaction.model');
const KycIdentityModel = require('../models/kycIdentity.model');
const MultiAssetWalletModel = require('../models/multiAssetWallet.model');
const SettlementEngineModel = require('../models/settlementEngine.model');
const AuditReportingModel = require('../models/auditReporting.model');
const SetuKycService = require('../services/setuKyc.service');
const UserModel = require('../models/user.model');

class FinanceController {
  // Profiles
  static async getProfiles(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const business = await FinanceProfileModel.getBusinessProfile(userId);
      const personal = await FinanceProfileModel.getPersonalProfile(userId);

      return res.status(200).json({
        success: true,
        data: { business, personal },
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async updateBusinessProfile(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const profile = await FinanceProfileModel.saveBusinessProfile(userId, req.body);
      return res.status(200).json({
        success: true,
        message: 'Business profile updated successfully',
        data: profile,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async updatePersonalProfile(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const profile = await FinanceProfileModel.savePersonalProfile(userId, req.body);
      return res.status(200).json({
        success: true,
        message: 'Personal profile updated successfully',
        data: profile,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // Financial Accounts
  static async getAccounts(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { mode = 'ALL' } = req.query;
      const accounts = await FinanceProfileModel.getAccounts(userId, mode);

      const totalBalance = accounts.reduce((sum, a) => sum + (a.isAsset ? a.balance : a.balance), 0);

      return res.status(200).json({
        success: true,
        data: {
          mode: mode.toUpperCase(),
          totalBalance: Number(totalBalance.toFixed(2)),
          count: accounts.length,
          accounts,
        },
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createAccount(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const account = await FinanceProfileModel.createAccount(userId, req.body);
      return res.status(201).json({
        success: true,
        message: `${account.mode} account created successfully`,
        data: account,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // Categories
  static async getCategories(req, res) {
    try {
      const { mode = 'ALL' } = req.query;
      const categories = await FinanceProfileModel.getCategories(mode);
      return res.status(200).json({
        success: true,
        data: categories,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // Ledgers
  static async getLedger(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { mode = 'BUSINESS' } = req.query;
      const summary = await TransactionModel.getLedgerSummary(userId, mode);
      return res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // Cross-Mode Fund Transfers
  static async transferFunds(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { fromMode, toMode, fromAccountId, toAccountId, amount, reason, notes } = req.body;

      const result = await FundTransferService.executeTransfer({
        userId,
        fromMode,
        toMode,
        fromAccountId,
        toAccountId,
        amount,
        reason,
        notes,
      });

      return res.status(200).json({
        success: true,
        message: `Fund transfer of ₹${Number(amount).toLocaleString('en-IN')} completed successfully!`,
        data: result,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async getTransfers(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { mode, search } = req.query;
      const transfers = await FundTransferService.getTransferHistory(userId, { mode, search });
      return res.status(200).json({
        success: true,
        data: transfers,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getAuditLogs(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const logs = await FundTransferService.getAuditLogs(userId);
      return res.status(200).json({
        success: true,
        data: logs,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // Consolidated Net-Worth
  static async getConsolidatedNetWorth(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const netWorth = await TransactionModel.getConsolidatedNetWorth(userId);
      return res.status(200).json({
        success: true,
        data: netWorth,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // Goals
  static async getGoals(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const goals = await FinanceProfileModel.getGoals(userId);
      return res.status(200).json({
        success: true,
        data: goals,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createGoal(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const goal = await FinanceProfileModel.createGoal(userId, req.body);
      return res.status(201).json({
        success: true,
        message: 'Goal created successfully',
        data: goal,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async updateGoal(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;
      const goal = await FinanceProfileModel.updateGoal(id, userId, req.body);
      if (!goal) {
        return res.status(404).json({ success: false, message: 'Goal not found' });
      }
      return res.status(200).json({
        success: true,
        message: 'Goal updated successfully',
        data: goal,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async deleteGoal(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;
      const success = await FinanceProfileModel.deleteGoal(id, userId);
      if (!success) {
        return res.status(404).json({ success: false, message: 'Goal not found' });
      }
      return res.status(200).json({
        success: true,
        message: 'Goal deleted successfully',
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // Budgets
  static async getBudgets(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const budgets = await FinanceProfileModel.getBudgets(userId);
      return res.status(200).json({
        success: true,
        data: budgets,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createOrUpdateBudget(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const budget = await FinanceProfileModel.createOrUpdateBudget(userId, req.body);
      return res.status(200).json({
        success: true,
        message: 'Budget saved successfully',
        data: budget,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async deleteBudget(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;
      const success = await FinanceProfileModel.deleteBudget(id, userId);
      if (!success) {
        return res.status(404).json({ success: false, message: 'Budget not found' });
      }
      return res.status(200).json({
        success: true,
        message: 'Budget deleted successfully',
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // ==========================================
  // UPI BANK LINKING & 2FA OTP CONTROLLER
  // ==========================================

  static async initiateUpiLink(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const result = await FinanceProfileModel.initiateUpiLink(userId, req.body);
      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async verifyUpiOtp(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const result = await FinanceProfileModel.verifyUpiOtp(userId, req.body);
      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async confirmUpiAccount(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const account = await FinanceProfileModel.confirmUpiAccount(userId, req.body);
      return res.status(201).json({
        success: true,
        message: 'UPI account linked successfully',
        data: account,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async setupUpiPin(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { accountId } = req.body;
      const result = await FinanceProfileModel.setupUpiPin(userId, accountId, req.body);
      return res.status(200).json({
        success: true,
        message: result.message,
        data: result,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // ==========================================
  // AUTOPAY RECURRING MANDATES CONTROLLER
  // ==========================================

  static async getMandates(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const mandates = await FinanceProfileModel.getMandates(userId);
      return res.status(200).json({
        success: true,
        data: mandates,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createMandate(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const mandate = await FinanceProfileModel.createMandate(userId, req.body);
      return res.status(201).json({
        success: true,
        message: 'AutoPay mandate registered successfully',
        data: mandate,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async updateMandateStatus(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;
      const { status } = req.body;
      const mandate = await FinanceProfileModel.updateMandateStatus(userId, id, status);
      return res.status(200).json({
        success: true,
        message: `Mandate status updated to ${status}`,
        data: mandate,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async deleteMandate(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { id } = req.params;
      const success = await FinanceProfileModel.deleteMandate(userId, id);
      if (!success) {
        return res.status(404).json({ success: false, message: 'Mandate not found' });
      }
      return res.status(200).json({
        success: true,
        message: 'AutoPay mandate revoked successfully',
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // Real-time IFSC branch lookup
  static async lookupIfsc(req, res) {
    try {
      const { code } = req.params;
      const details = await FinanceProfileModel.lookupIfsc(code);
      return res.status(200).json({ success: true, data: details });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // Real-Time Penny Drop & Account Lookup
  static async verifyPennyDrop(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const verification = await FinanceProfileModel.verifyPennyDrop(userId, req.body);
      return res.status(200).json({
        success: true,
        message: 'Account verified successfully via Penny Drop (RazorpayX)',
        data: verification,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // Account Linking SMS OTP
  static async sendAccountLinkingOtp(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const challenge = await FinanceProfileModel.sendAccountLinkingOtp(userId, req.body);
      return res.status(200).json({
        success: true,
        message: '6-digit verification code sent to bank-registered mobile number',
        data: challenge,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // Verify OTP and link account
  static async verifyAndLinkBankAccount(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const account = await FinanceProfileModel.verifyAndLinkBankAccount(userId, req.body);
      return res.status(201).json({
        success: true,
        message: 'Bank account verified and linked successfully',
        data: account,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // --- MODULE 1: ONBOARDING & DIGITAL IDENTITY ---
  static async getKycStatus(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      let userName = req.user ? (req.user.name || req.user.fullName) : null;
      if (!userName && req.user) {
        const fullUser = await UserModel.findById(userId);
        if (fullUser) userName = fullUser.name;
      }
      const deviceId = req.headers['x-device-model'] || req.headers['x-device-name'] || req.headers['x-device-id'] || null;
      const kyc = KycIdentityModel.getKycStatus(userId, userName, deviceId);
      return res.status(200).json({ success: true, data: kyc });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async initiateAadhaarOtp(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { aadhaarNumber } = req.body;
      const setuResult = await SetuKycService.initiateAadhaarOtp(aadhaarNumber);
      const challenge = KycIdentityModel.initiateAadhaarOtp(userId, aadhaarNumber, setuResult.requestId);
      return res.status(200).json({
        success: true,
        data: {
          ...challenge,
          isLiveSetu: setuResult.isLiveSetu,
          message: setuResult.message || challenge.message,
        },
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async verifyAadhaarOtp(req, res) {
    try {
      const { challengeId, otp } = req.body;
      const setuVerification = await SetuKycService.verifyAadhaarOtp(challengeId, otp);
      const kyc = KycIdentityModel.verifyAadhaarOtp(challengeId, otp, setuVerification.aadhaarData);
      return res.status(200).json({
        success: true,
        message: 'Aadhaar e-KYC verified successfully with UIDAI',
        data: kyc,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async verifyPan(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { panNumber, fullName } = req.body;
      const kyc = KycIdentityModel.verifyPan(userId, panNumber, fullName);
      return res.status(200).json({ success: true, message: 'PAN verified successfully via NSDL', data: kyc });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async connectDigiLocker(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const kyc = KycIdentityModel.connectDigiLocker(userId);
      return res.status(200).json({ success: true, message: 'DigiLocker documents linked successfully', data: kyc });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async bindBiometrics(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { deviceSignature, mpin } = req.body;
      const kyc = KycIdentityModel.bindBiometrics(userId, deviceSignature, mpin);
      return res.status(200).json({ success: true, message: 'Biometric & device bound successfully', data: kyc });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // --- MODULE 2 & 3: MULTI-ASSET WALLET & CONVERSIONS ---
  static async getMultiAssetWallet(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const wallet = MultiAssetWalletModel.getWallet(userId);
      return res.status(200).json({ success: true, data: wallet });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async addMoney(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const result = MultiAssetWalletModel.addMoney(userId, req.body);
      return res.status(200).json({ success: true, message: 'Funds credited to wallet successfully', data: result });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async convertAssets(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const result = MultiAssetWalletModel.convertAssets(userId, req.body);
      return res.status(200).json({ success: true, message: 'Asset conversion executed instantly', data: result });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  // --- MODULE 4 & 5: RISK EVALUATION & SETTLEMENT ENGINE ---
  static async evaluateRisk(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const risk = SettlementEngineModel.evaluateRisk({ userId, ...req.body });
      return res.status(200).json({ success: true, data: risk });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async executeSettlement(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const result = SettlementEngineModel.executeSettlement(userId, req.body);
      return res.status(201).json({ success: true, message: 'Settlement completed and recorded in ledger', data: result });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async getSettlementTransactions(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const txns = SettlementEngineModel.getTransactions(userId);
      return res.status(200).json({ success: true, data: txns });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // --- MODULE 6: AUDIT & REPORTING ---
  static async getAuditRecords(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const records = AuditReportingModel.getAuditRecords(userId, req.query);
      return res.status(200).json({ success: true, data: records });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async exportAuditCsv(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const csv = AuditReportingModel.exportCsvStatement(userId);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="ENX_Audit_Statement.csv"');
      return res.status(200).send(csv);
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  // ==========================================
  // UPI CUSTOM HANDLES & ALIAS CONTROLLER
  // ==========================================

  static async checkHandleAvailability(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { vpa, prefix, suffix } = req.query;
      const rawVpa = vpa || (prefix ? `${prefix}${suffix || '@enxmoney'}` : '');
      const result = await FinanceProfileModel.checkHandleAvailability(userId, rawVpa);
      return res.status(200).json(result);
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async getUpiHandles(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const result = await FinanceProfileModel.getUpiHandles(userId);
      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createCustomHandle(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const handle = await FinanceProfileModel.createCustomHandle(userId, req.body);
      return res.status(201).json({
        success: true,
        message: 'Custom UPI handle created and linked successfully',
        data: handle,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async setPrimaryHandle(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const handleId = req.params.id || req.body.handleId;
      const handle = await FinanceProfileModel.setPrimaryHandle(userId, handleId);
      return res.status(200).json({
        success: true,
        message: `Primary handle set to ${handle.vpa}`,
        data: handle,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async toggleHandleStatus(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const handleId = req.params.id || req.body.handleId;
      const { isActive } = req.body;
      const handle = await FinanceProfileModel.toggleHandleStatus(userId, handleId, isActive);
      return res.status(200).json({
        success: true,
        message: `Handle status updated to ${handle.isActive ? 'Active' : 'Inactive'}`,
        data: handle,
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  static async deleteHandle(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const handleId = req.params.id || req.body.handleId;
      await FinanceProfileModel.deleteHandle(userId, handleId);
      return res.status(200).json({
        success: true,
        message: 'UPI handle deleted successfully',
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }
}

module.exports = FinanceController;

