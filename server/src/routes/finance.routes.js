const express = require('express');
const FinanceController = require('../controllers/finance.controller');

const router = express.Router();

// Profiles
router.get('/profile', FinanceController.getProfiles);
router.put('/business/profile', FinanceController.updateBusinessProfile);
router.put('/personal/profile', FinanceController.updatePersonalProfile);

// Accounts
router.get('/accounts', FinanceController.getAccounts);
router.post('/accounts', FinanceController.createAccount);

// Categories
router.get('/categories', FinanceController.getCategories);

// Ledgers
router.get('/ledger', FinanceController.getLedger);

// Cross-Mode Fund Transfers & Auditing
router.post('/transfers', FinanceController.transferFunds);
router.get('/transfers', FinanceController.getTransfers);
router.get('/audit-logs', FinanceController.getAuditLogs);

// Consolidated Net Worth
router.get('/consolidated', FinanceController.getConsolidatedNetWorth);
router.get('/net-worth', FinanceController.getConsolidatedNetWorth);

// Goals
router.get('/goals', FinanceController.getGoals);
router.post('/goals', FinanceController.createGoal);
router.put('/goals/:id', FinanceController.updateGoal);
router.delete('/goals/:id', FinanceController.deleteGoal);

// Budgets
router.get('/budgets', FinanceController.getBudgets);
router.post('/budgets', FinanceController.createOrUpdateBudget);
router.delete('/budgets/:id', FinanceController.deleteBudget);

// UPI Bank Linking & 2FA OTP
router.post('/upi/initiate-link', FinanceController.initiateUpiLink);
router.post('/upi/verify-otp', FinanceController.verifyUpiOtp);
router.post('/upi/confirm-link', FinanceController.confirmUpiAccount);
router.post('/upi/setup-pin', FinanceController.setupUpiPin);

// Manage UPI IDs & Custom Handles
router.get('/upi/check-handle', FinanceController.checkHandleAvailability);
router.get('/upi/handles', FinanceController.getUpiHandles);
router.post('/upi/create-handle', FinanceController.createCustomHandle);
router.patch('/upi/handles/:id/primary', FinanceController.setPrimaryHandle);
router.post('/upi/handles/:id/primary', FinanceController.setPrimaryHandle);
router.patch('/upi/handles/:id/status', FinanceController.toggleHandleStatus);
router.post('/upi/handles/:id/status', FinanceController.toggleHandleStatus);
router.delete('/upi/handles/:id', FinanceController.deleteHandle);

// AutoPay Recurring Mandates
router.get('/mandates', FinanceController.getMandates);
router.post('/mandates', FinanceController.createMandate);
router.patch('/mandates/:id/status', FinanceController.updateMandateStatus);
router.delete('/mandates/:id', FinanceController.deleteMandate);

// Real-Time Penny Drop & Account Verification OTP
router.get('/bank-account/ifsc/:code', FinanceController.lookupIfsc);
router.post('/bank-account/verify', FinanceController.verifyPennyDrop);
router.post('/bank-account/send-otp', FinanceController.sendAccountLinkingOtp);
router.post('/bank-account/verify-and-link', FinanceController.verifyAndLinkBankAccount);

// MODULE 1: ONBOARDING & DIGITAL IDENTITY
router.get('/kyc/status', FinanceController.getKycStatus);
router.post('/kyc/aadhaar/send-otp', FinanceController.initiateAadhaarOtp);
router.post('/kyc/aadhaar/verify-otp', FinanceController.verifyAadhaarOtp);
router.post('/kyc/pan/verify', FinanceController.verifyPan);
router.post('/kyc/digilocker/connect', FinanceController.connectDigiLocker);
router.post('/kyc/biometric/bind', FinanceController.bindBiometrics);

// MODULE 2 & 3: DIGITAL WALLET & MULTI-ASSET ACCOUNTS
router.get('/wallet/multi-asset', FinanceController.getMultiAssetWallet);
router.post('/wallet/add-money', FinanceController.addMoney);
router.post('/wallet/convert', FinanceController.convertAssets);

// MODULE 4 & 5: RISK EVALUATION & SETTLEMENT ENGINE
router.post('/risk/evaluate', FinanceController.evaluateRisk);
router.post('/settlement/execute', FinanceController.executeSettlement);
router.get('/settlement/transactions', FinanceController.getSettlementTransactions);

// MODULE 6: AUDIT & REPORTING DASHBOARD
router.get('/audit/records', FinanceController.getAuditRecords);
router.get('/audit/export-csv', FinanceController.exportAuditCsv);

module.exports = router;

