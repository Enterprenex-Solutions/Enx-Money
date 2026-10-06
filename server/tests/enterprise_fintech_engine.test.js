const request = require('supertest');
const app = require('../src/app');

describe('Enterprise Fintech & Banking Architecture Test Suite (Modules 1 - 6)', () => {
  let aadhaarChallengeId;

  // --- MODULE 1: ONBOARDING & DIGITAL IDENTITY ---
  describe('Module 1: Onboarding & Digital Identity', () => {
    it('GET /api/finance/kyc/status should return current KYC tier and device details', async () => {
      const res = await request(app).get('/api/finance/kyc/status');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('tier');
      expect(res.body.data).toHaveProperty('digitalIdentityNumber');
      expect(res.body.data.deviceBinding).toHaveProperty('deviceId');
    });

    it('POST /api/finance/kyc/aadhaar/send-otp should reject invalid Aadhaar length', async () => {
      const res = await request(app)
        .post('/api/finance/kyc/aadhaar/send-otp')
        .send({ aadhaarNumber: '12345' });
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('POST /api/finance/kyc/aadhaar/send-otp should dispatch 6-digit OTP for valid 12-digit Aadhaar', async () => {
      const res = await request(app)
        .post('/api/finance/kyc/aadhaar/send-otp')
        .send({ aadhaarNumber: '5421 8901 4821' });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('challengeId');
      expect(res.body.data.maskedAadhaar).toBe('•••• •••• 4821');
      aadhaarChallengeId = res.body.data.challengeId;
    });

    it('POST /api/finance/kyc/aadhaar/verify-otp should reject invalid OTP', async () => {
      const res = await request(app)
        .post('/api/finance/kyc/aadhaar/verify-otp')
        .send({ challengeId: aadhaarChallengeId, otp: '999999' });
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('POST /api/finance/kyc/aadhaar/verify-otp should verify valid OTP and update status', async () => {
      const res = await request(app)
        .post('/api/finance/kyc/aadhaar/verify-otp')
        .send({ challengeId: aadhaarChallengeId, otp: '123456' });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isAadhaarVerified).toBe(true);
      expect(res.body.data.aadhaarData).toHaveProperty('fullName');
    });

    it('POST /api/finance/kyc/pan/verify should validate PAN format and verify record', async () => {
      const res = await request(app)
        .post('/api/finance/kyc/pan/verify')
        .send({ panNumber: 'ABCDE1234F', fullName: 'P. Revanth Reddy' });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isPanVerified).toBe(true);
      expect(res.body.data.panNumber).toBe('ABCDE1234F');
    });

    it('POST /api/finance/kyc/digilocker/connect should fast-track Aadhaar & PAN verification', async () => {
      const res = await request(app).post('/api/finance/kyc/digilocker/connect');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isDigilockerConnected).toBe(true);
    });

    it('POST /api/finance/kyc/biometric/bind should bind hardware keys and elevate to Tier 3', async () => {
      const res = await request(app)
        .post('/api/finance/kyc/biometric/bind')
        .send({ deviceSignature: 'SIG_FIDO2_SECURE_HARDWARE', mpin: '1234' });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.tier).toBe('TIER_3_FULL_BIOMETRIC');
      expect(res.body.data.isBiometricBound).toBe(true);
    });
  });

  // --- MODULE 2 & 3: DIGITAL WALLET & MULTI-ASSET CONVERSIONS ---
  describe('Module 2 & 3: Digital Wallet & Multi-Asset Hub', () => {
    it('GET /api/finance/wallet/multi-asset should return consolidated balances across Fiat, CBDC & Gold', async () => {
      const res = await request(app).get('/api/finance/wallet/multi-asset');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('fiat');
      expect(res.body.data).toHaveProperty('cbdc');
      expect(res.body.data).toHaveProperty('digitalAssets');
      expect(res.body.data.totalConsolidatedInr).toBeGreaterThan(0);
    });

    it('POST /api/finance/wallet/add-money should credit funds via deposit methods', async () => {
      const res = await request(app)
        .post('/api/finance/wallet/add-money')
        .send({
          method: 'BANK_UPI_IMPS',
          amount: 5000.00,
          assetType: 'INR',
          sourceDetails: { sourceName: 'HDFC Bank •••• 4821' },
        });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('SETTLED');
      expect(res.body.data.receipt).toHaveProperty('utr');
    });

    it('POST /api/finance/wallet/convert should swap Fiat INR to CBDC Digital Rupee', async () => {
      const res = await request(app)
        .post('/api/finance/wallet/convert')
        .send({ fromAsset: 'INR', toAsset: 'CBDC', amount: 2000.00 });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.amountConverted).toBe(2000.00);
      expect(res.body.data).toHaveProperty('cbdcBalance');
    });

    it('POST /api/finance/wallet/convert should convert Fiat INR to 24K Digital Gold', async () => {
      const res = await request(app)
        .post('/api/finance/wallet/convert')
        .send({ fromAsset: 'INR', toAsset: 'GOLD', amount: 3625.00 });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.goldGrams).toBeGreaterThan(0);
    });
  });

  // --- MODULE 4 & 5: RISK & SETTLEMENT ENGINE ---
  describe('Module 4 & 5: Risk Evaluation & 5-Step Settlement', () => {
    it('POST /api/finance/risk/evaluate should evaluate transaction risk and return trust score', async () => {
      const res = await request(app)
        .post('/api/finance/risk/evaluate')
        .send({ amount: 1500, counterparty: 'merchant@upi' });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('LOW_RISK_APPROVED');
      expect(res.body.data.deviceTrustScore).toBe(98);
    });

    it('POST /api/finance/settlement/execute should reject transaction with invalid MPIN', async () => {
      const res = await request(app)
        .post('/api/finance/settlement/execute')
        .send({
          recipient: 'Aarav Sharma',
          amount: 500,
          assetType: 'INR',
          authMethod: 'MPIN',
          authPin: '9999',
        });
      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Incorrect MPIN');
    });

    it('POST /api/finance/settlement/execute should complete 5-step settlement with valid MPIN', async () => {
      const res = await request(app)
        .post('/api/finance/settlement/execute')
        .send({
          recipient: 'Aarav Sharma',
          recipientVpa: 'aarav@upi',
          amount: 1500.00,
          assetType: 'INR',
          purpose: 'Consulting Fee',
          authMethod: 'MPIN',
          authPin: '1234',
        });
      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('SUCCESS');
      expect(res.body.data.pipelineSteps).toHaveLength(5);
      expect(res.body.data.receipt).toHaveProperty('receiptNumber');
      expect(res.body.data.receipt).toHaveProperty('utr');
    });

    it('GET /api/finance/settlement/transactions should return recorded ledger transactions', async () => {
      const res = await request(app).get('/api/finance/settlement/transactions');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
    });
  });

  // --- MODULE 6: AUDIT & REPORTING DASHBOARD ---
  describe('Module 6: Audit & Reporting Dashboard', () => {
    it('GET /api/finance/audit/records should return financial history, GST and TDS summary', async () => {
      const res = await request(app).get('/api/finance/audit/records');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('records');
      expect(res.body.data).toHaveProperty('summary');
      expect(res.body.data.summary).toHaveProperty('totalGstLiability');
      expect(res.body.data.summary.accountingSyncStatus).toBe('SYNCED_WITH_ERP');
    });

    it('GET /api/finance/audit/export-csv should export CSV audit statement', async () => {
      const res = await request(app).get('/api/finance/audit/export-csv');
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toContain('text/csv');
      expect(res.text).toContain('Transaction ID,UTR,Date,Asset Type');
    });
  });
});
