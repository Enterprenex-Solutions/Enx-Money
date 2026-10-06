const request = require('supertest');
const app = require('../src/app');
const KycRecordModel = require('../src/models/kycRecord.model');
const KycProviderService = require('../src/services/kycProvider.service');

describe('Real Production-Ready KYC Verification Flow', () => {
  beforeEach(() => {
    KycRecordModel.resetForTesting();
  });

  describe('1. GET /api/kyc/status', () => {
    it('returns default NOT_VERIFIED status for a new user without hardcoding', async () => {
      const res = await request(app).get('/api/kyc/status?userId=test_user_101');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.kycStatus).toBe('NOT_VERIFIED');
      expect(res.body.data.digilockerStatus).toBe('NOT_STARTED');
      expect(res.body.data.aadhaarStatus).toBe('NOT_VERIFIED');
      expect(res.body.data.panStatus).toBe('NOT_VERIFIED');
      expect(res.body.data.enxId).toMatch(/^ENX-ID-\d{4}-\d{4}$/);
    });
  });

  describe('2. POST /api/kyc/start', () => {
    it('initiates an authorized KYC session and returns valid state and session info', async () => {
      const res = await request(app)
        .post('/api/kyc/start')
        .send({ userId: 'test_user_101' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.state).toBeDefined();
      expect(typeof res.body.state).toBe('string');
      expect(res.body.data.kycStatus).toBe('IN_PROGRESS');
      expect(res.body.data.digilockerStatus).toBe('IN_PROGRESS');

      // Check session was stored
      const session = KycRecordModel.getOAuthSession(res.body.state);
      expect(session).toBeDefined();
      expect(session.userId).toBe('test_user_101');
    });

    it('returns isAlreadyVerified when user has already completed KYC', async () => {
      KycRecordModel.updateRecord('verified_user_99', {
        kycStatus: 'VERIFIED',
        digilockerStatus: 'LINKED',
        verifiedName: 'Rajesh Kumar',
      });

      const res = await request(app)
        .post('/api/kyc/start')
        .send({ userId: 'verified_user_99' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.isAlreadyVerified).toBe(true);
      expect(res.body.data.kycStatus).toBe('VERIFIED');
    });
  });

  describe('3. GET & POST /api/kyc/digilocker/callback', () => {
    it('handles user cancellation with an informative HTML page and updates status to FAILED', async () => {
      const { state } = KycRecordModel.createOAuthSession('test_user_cancel');

      const res = await request(app)
        .get(`/api/kyc/digilocker/callback?error=access_denied&error_description=User%20denied%20consent&state=${state}`);

      expect(res.status).toBe(400);
      expect(res.text).toContain('Authorization Cancelled');
      expect(res.text).toContain('User denied consent');

      const record = KycRecordModel.getRecord('test_user_cancel');
      expect(record.kycStatus).toBe('FAILED');
      expect(record.digilockerStatus).toBe('FAILED');
      expect(record.failureReason).toContain('User denied consent');
    });

    it('rejects invalid or non-existent OAuth state', async () => {
      const res = await request(app)
        .get('/api/kyc/digilocker/callback?code=mock_code&state=fake_non_existent_state');

      expect(res.status).toBe(400);
      expect(res.text).toContain('Session Expired');
    });

    it('rejects expired OAuth sessions', async () => {
      const { state } = KycRecordModel.createOAuthSession('test_user_expired');
      const session = KycRecordModel.getOAuthSession(state);
      session.expiresAt = Date.now() - 1000; // Force expired

      const res = await request(app)
        .get(`/api/kyc/digilocker/callback?code=mock_code&state=${state}`);

      expect(res.status).toBe(400);
      expect(res.text).toContain('Session Expired');
    });

    it('successfully processes authenticated token exchange and verifies user', async () => {
      const { state } = KycRecordModel.createOAuthSession('test_user_success');

      // Mock provider token exchange response
      jest.spyOn(KycProviderService, 'handleDigilockerCallback').mockResolvedValueOnce({
        provider: 'DIGILOCKER_MERI_PEHCHAAN',
        verified: true,
        verifiedName: 'Anil Sharma',
        verifiedDob: '1990-05-12',
        verifiedMobile: '••••••8842',
        maskedAadhaar: '•••• •••• 9812',
        panNumber: 'ABCDE1234F',
        panLast4: '1234F',
        digilockerId: 'dl_usr_88192',
        timestamp: new Date().toISOString(),
      });

      const res = await request(app)
        .get(`/api/kyc/digilocker/callback?code=auth_code_12345&state=${state}`);

      expect(res.status).toBe(200);
      expect(res.text).toContain('KYC Verified Successfully');

      const record = KycRecordModel.getRecord('test_user_success');
      expect(record.kycStatus).toBe('VERIFIED');
      expect(record.digilockerStatus).toBe('LINKED');
      expect(record.aadhaarStatus).toBe('VERIFIED');
      expect(record.panStatus).toBe('VERIFIED');
      expect(record.verifiedName).toBe('Anil Sharma');
      expect(record.maskedAadhaar).toBe('•••• •••• 9812');
      expect(record.panLast4).toBe('1234F');
    });
  });

  describe('4. Aadhaar Verification Endpoints', () => {
    it('validates 12-digit Aadhaar format', async () => {
      const res = await request(app)
        .post('/api/kyc/aadhaar/start')
        .send({ aadhaarNumber: '1234' });

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('12 numeric digits');
    });

    it('handles missing provider credentials safely without fake success', async () => {
      const res = await request(app)
        .post('/api/kyc/aadhaar/start')
        .send({ aadhaarNumber: '123456789012' });

      // When Setu keys are not set, it must return 503 with exact missing requirements
      expect(res.status).toBe(503);
      expect(res.body.error).toBe('PROVIDER_CREDENTIALS_MISSING');
      expect(res.body.requiredCredentials).toContain('SETU_CLIENT_ID');
    });

    it('successfully processes OTP verification when provider validates', async () => {
      jest.spyOn(KycProviderService, 'verifyAadhaarOtp').mockResolvedValueOnce({
        verified: true,
        verifiedName: 'Kavita Patel',
        verifiedDob: '1995-11-20',
        maskedAadhaar: '•••• •••• 5678',
      });

      const res = await request(app)
        .post('/api/kyc/aadhaar/verify')
        .send({ requestId: 'req_valid_123', otp: '456789' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.aadhaarStatus).toBe('VERIFIED');
      expect(res.body.data.verifiedName).toBe('Kavita Patel');
      expect(res.body.data.maskedAadhaar).toBe('•••• •••• 5678');
    });
  });

  describe('5. PAN Verification Endpoints', () => {
    it('validates PAN alphanumeric format', async () => {
      const res = await request(app)
        .post('/api/kyc/pan/verify')
        .send({ panNumber: 'INVALID_PAN' });

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('10 alphanumeric');
    });

    it('returns structured provider missing error if PAN API keys are absent', async () => {
      const res = await request(app)
        .post('/api/kyc/pan/verify')
        .send({ panNumber: 'ABCDE1234F' });

      expect(res.status).toBe(503);
      expect(res.body.error).toBe('PAN_PROVIDER_MISSING');
    });

    it('successfully processes PAN verification when provider returns active status', async () => {
      jest.spyOn(KycProviderService, 'verifyPan').mockResolvedValueOnce({
        isConfigured: true,
        verified: true,
        panNumber: 'ABCDE1234F',
        panLast4: '1234F',
        registeredName: 'Sunil Verma',
        status: 'ACTIVE_AND_VERIFIED',
      });

      const res = await request(app)
        .post('/api/kyc/pan/verify')
        .send({ panNumber: 'ABCDE1234F', fullName: 'Sunil Verma' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.panStatus).toBe('VERIFIED');
      expect(res.body.data.panLast4).toBe('1234F');
    });
  });

  describe('6. GET /api/kyc/documents', () => {
    it('returns empty documents list when no documents verified', async () => {
      const res = await request(app).get('/api/kyc/documents?userId=new_user_doc');
      expect(res.status).toBe(200);
      expect(res.body.data.documents).toEqual([]);
      expect(res.body.data.totalVerified).toBe(0);
    });

    it('returns verified document references when verified without exposing secrets', async () => {
      KycRecordModel.updateRecord('doc_user_1', {
        kycStatus: 'VERIFIED',
        digilockerStatus: 'LINKED',
        aadhaarStatus: 'VERIFIED',
        maskedAadhaar: '•••• •••• 9999',
        panStatus: 'VERIFIED',
        panLast4: '8888',
      });

      const res = await request(app).get('/api/kyc/documents?userId=doc_user_1');
      expect(res.status).toBe(200);
      expect(res.body.data.totalVerified).toBe(3);
      expect(res.body.data.documents.some((d) => d.type === 'AADHAAR')).toBe(true);
      expect(res.body.data.documents.some((d) => d.type === 'PAN')).toBe(true);
      expect(res.body.data.documents.some((d) => d.type === 'DIGILOCKER_CERTIFICATE')).toBe(true);

      // Verify no sensitive tokens or secrets exist in response
      const jsonStr = JSON.stringify(res.body);
      expect(jsonStr).not.toContain('access_token');
      expect(jsonStr).not.toContain('client_secret');
    });
  });

  describe('7. Setu Sandbox Engine Simulation', () => {
    beforeAll(() => {
      process.env.TEST_WITH_SETU_SANDBOX = 'true';
    });
    afterAll(() => {
      delete process.env.TEST_WITH_SETU_SANDBOX;
    });

    it('initiates Aadhaar OTP with 12-digit number and returns sandbox OTP', async () => {
      const res = await request(app)
        .post('/api/kyc/aadhaar/start')
        .send({ aadhaarNumber: '779875684159' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('OTP_SENT');
      expect(res.body.data.maskedAadhaar).toBe('•••• •••• 4159');
      expect(res.body.data.testOtp).toBe('123456');
    });

    it('verifies Aadhaar with test OTP 123456', async () => {
      const startRes = await request(app)
        .post('/api/kyc/aadhaar/start')
        .send({ aadhaarNumber: '779875684159' });

      const verifyRes = await request(app)
        .post('/api/kyc/aadhaar/verify')
        .send({ requestId: startRes.body.data.requestId, otp: '123456' });

      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.success).toBe(true);
      expect(verifyRes.body.data.aadhaarStatus).toBe('VERIFIED');
    });

    it('verifies valid PAN ABCDE1234A in sandbox mode', async () => {
      const res = await request(app)
        .post('/api/kyc/pan/verify')
        .send({ panNumber: 'ABCDE1234A', fullName: 'Revanth' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.panStatus).toBe('VERIFIED');
    });

    it('rejects invalid PAN ABCDE1234B in sandbox mode', async () => {
      const res = await request(app)
        .post('/api/kyc/pan/verify')
        .send({ panNumber: 'ABCDE1234B' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toContain('PAN is invalid');
    });
  });

  describe('8. Free & Fast Route (Manual KYC for Launch)', () => {
    it('validates PAN alphanumeric format on manual submission', async () => {
      const res = await request(app)
        .post('/api/kyc/submit-manual')
        .send({ userId: 'merchant_101', panNumber: 'BADPAN' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toContain('Invalid PAN format');
    });

    it('successfully submits manual KYC with valid PAN and provides provisional Tier-1 access', async () => {
      const res = await request(app)
        .post('/api/kyc/submit-manual')
        .send({
          userId: 'merchant_102',
          panNumber: 'ABCDE1234F',
          businessName: 'Krishna General Store',
          applicantName: 'Krishna Sharma',
          documentType: 'PAN_CARD',
          phone: '+919876543210',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.mode).toBe('MANUAL_KYC_PROVISIONAL');
      expect(res.body.data.panStatus).toBe('SUBMITTED');
      expect(res.body.data.manualKycStatus).toBe('PENDING_REVIEW');
      expect(res.body.data.panLast4).toBe('234F');
      expect(res.body.data.businessName).toBe('Krishna General Store');
    });

    it('allows admin to fetch KYC requests list and approve a merchant', async () => {
      // First submit
      await request(app)
        .post('/api/kyc/submit-manual')
        .send({
          userId: 'merchant_103',
          panNumber: 'HFQPP5773D',
          businessName: 'Rohit Enterprises',
          applicantName: 'Rohit Samadhan Pawar',
        });

      // Admin gets list
      const listRes = await request(app).get('/api/kyc/admin/requests');
      expect(listRes.status).toBe(200);
      expect(listRes.body.success).toBe(true);
      expect(listRes.body.summary.pending).toBeGreaterThanOrEqual(1);

      // Admin approves
      const approveRes = await request(app)
        .post('/api/kyc/admin/approve')
        .send({ userId: 'merchant_103' });

      expect(approveRes.status).toBe(200);
      expect(approveRes.body.success).toBe(true);
      expect(approveRes.body.data.kycStatus).toBe('VERIFIED');
      expect(approveRes.body.data.tier).toBe('TIER_2_UNLIMITED');
    });

    it('allows admin to reject with reason and auto-approve all', async () => {
      await request(app)
        .post('/api/kyc/submit-manual')
        .send({
          userId: 'merchant_104',
          panNumber: 'XYZAB5678C',
          businessName: 'Test Kirana',
        });

      // Reject
      const rejectRes = await request(app)
        .post('/api/kyc/admin/reject')
        .send({ userId: 'merchant_104', reason: 'Photo blurred' });

      expect(rejectRes.status).toBe(200);
      expect(rejectRes.body.data.kycStatus).toBe('FAILED');
      expect(rejectRes.body.data.rejectionReason).toBe('Photo blurred');

      // Submit another and auto-approve all
      await request(app)
        .post('/api/kyc/submit-manual')
        .send({
          userId: 'merchant_105',
          panNumber: 'ABCDE9999Z',
          businessName: 'Speed Mart',
        });

      const autoRes = await request(app)
        .post('/api/kyc/admin/auto-approve-all')
        .send({});

      expect(autoRes.status).toBe(200);
      expect(autoRes.body.success).toBe(true);
      expect(autoRes.body.approvedCount).toBeGreaterThanOrEqual(1);
    });
  });
});

