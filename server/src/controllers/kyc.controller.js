/**
 * ENX Money — Real KYC Controller
 * Handles official DigiLocker OAuth 2.0 flow, Aadhaar OKYC, and PAN verification.
 * Strictly avoids fake OTPs, hardcoded demo data, or mock verification success.
 */
const KycRecordModel = require('../models/kycRecord.model');
const KycProviderService = require('../services/kycProvider.service');

class KycController {
  /**
   * POST /api/kyc/start
   * Starts an authorized DigiLocker / Setu KYC session
   */
  static async startKyc(req, res) {
    try {
      const userId = req.user ? req.user.id : (req.body.userId || '1');
      const record = KycRecordModel.getRecord(userId, req.user);

      // Check if already fully verified
      if (record.kycStatus === 'VERIFIED') {
        return res.status(200).json({
          success: true,
          message: 'User KYC is already verified and active.',
          isAlreadyVerified: true,
          data: record,
        });
      }

      // Generate secure OAuth session
      const { state, expiresAt } = KycRecordModel.createOAuthSession(userId, req.body.redirectUri);

      // Build official provider authorization URL
      const providerData = KycProviderService.buildAuthorizationUrl(state, req.body.redirectUri);

      // Update record to IN_PROGRESS
      KycRecordModel.updateRecord(userId, {
        kycStatus: 'IN_PROGRESS',
        digilockerStatus: 'IN_PROGRESS',
        failureReason: null,
      });

      if (!providerData.isConfigured) {
        return res.status(200).json({
          success: true,
          isConfigured: false,
          state,
          provider: providerData.provider,
          message: providerData.message,
          requiredCredentials: providerData.requiredCredentials,
          setupGuide: providerData.setupGuide,
          data: KycRecordModel.getRecord(userId),
        });
      }

      return res.status(200).json({
        success: true,
        isConfigured: true,
        authorizationUrl: providerData.authorizationUrl,
        state,
        provider: providerData.provider,
        expiresAt: new Date(expiresAt).toISOString(),
        data: KycRecordModel.getRecord(userId),
      });
    } catch (err) {
      console.error('[KYC Controller startKyc] Error:', err.message);
      return res.status(500).json({
        success: false,
        error: 'Failed to initiate authorized KYC session',
        message: err.message,
      });
    }
  }

  /**
   * GET & POST /api/kyc/digilocker/callback
   * Processes official OAuth 2.0 callback from DigiLocker
   */
  static async digilockerCallback(req, res) {
    const isGet = req.method === 'GET';
    const query = req.query || {};
    const body = req.body || {};

    const code = query.code || body.code;
    const state = query.state || body.state;
    const error = query.error || body.error;
    const errorDescription = query.error_description || body.error_description;

    // Helper to send response for web redirect vs API call
    const respond = (statusCode, success, title, message, data = null) => {
      if (isGet) {
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        return res.status(statusCode).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — ENX Money KYC</title>
  <style>
    body { background: #0b0c10; color: #f3f4f6; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; }
    .card { background: #13151b; border: 1px solid #232733; border-radius: 20px; max-width: 440px; width: 100%; padding: 36px 28px; text-align: center; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); }
    .icon { width: 64px; height: 64px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 32px; margin-bottom: 20px; background: ${success ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.15)'}; border: 1px solid ${success ? '#10b981' : '#ef4444'}; color: ${success ? '#34d399' : '#f87171'}; }
    h1 { font-size: 22px; font-weight: 700; margin-bottom: 12px; color: #fff; }
    p { font-size: 14px; color: #9ca3af; line-height: 1.6; margin-bottom: 24px; }
    .btn { display: inline-block; background: ${success ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)' : '#232733'}; color: #fff; text-decoration: none; padding: 14px 24px; border-radius: 12px; font-weight: 700; font-size: 14px; width: 100%; box-sizing: border-box; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${success ? '✓' : '✕'}</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <a href="enxmoney://kyc-complete?status=${success ? 'success' : 'failed'}&state=${encodeURIComponent(state || '')}" class="btn">Return to ENX Money App</a>
  </div>
</body>
</html>`);
      }
      return res.status(statusCode).json({
        success,
        title,
        message,
        data,
      });
    };

    // 1. Handle user cancellation or error from DigiLocker
    if (error) {
      const session = KycRecordModel.getOAuthSession(state);
      if (session) {
        KycRecordModel.updateRecord(session.userId, {
          kycStatus: 'FAILED',
          digilockerStatus: 'FAILED',
          failureReason: `DigiLocker error: ${errorDescription || error}`,
        });
        KycRecordModel.consumeOAuthSession(state);
      }
      return respond(400, false, 'Authorization Cancelled', errorDescription || 'DigiLocker authorization was declined or cancelled. Please retry from the ENX Money app.');
    }

    // 2. Validate OAuth state
    if (!state) {
      return respond(400, false, 'Invalid Request', 'Missing OAuth state parameter.');
    }

    const session = KycRecordModel.consumeOAuthSession(state);
    if (!session) {
      return respond(400, false, 'Session Expired', 'The KYC verification session has expired or is invalid. Please start verification again from the app.');
    }

    // 3. Exchange code for verified documents
    try {
      const verifiedResult = await KycProviderService.handleDigilockerCallback(code, session.redirectUri);

      // 4. Update KYC Database Record
      const updated = KycRecordModel.updateRecord(session.userId, {
        kycStatus: 'VERIFIED',
        digilockerStatus: 'LINKED',
        aadhaarStatus: verifiedResult.maskedAadhaar ? 'VERIFIED' : 'NOT_VERIFIED',
        panStatus: verifiedResult.panLast4 ? 'VERIFIED' : 'NOT_VERIFIED',
        verifiedName: verifiedResult.verifiedName,
        verifiedDob: verifiedResult.verifiedDob,
        verifiedMobile: verifiedResult.verifiedMobile,
        maskedAadhaar: verifiedResult.maskedAadhaar,
        panLast4: verifiedResult.panLast4,
        providerReferenceId: verifiedResult.providerReferenceId || verifiedResult.digilockerId,
        verificationTimestamp: verifiedResult.timestamp,
        failureReason: null,
      });

      return respond(200, true, 'KYC Verified Successfully', 'Your government documents have been authenticated via DigiLocker. Your ENX Digital Identity is now active.', updated);
    } catch (exchangeErr) {
      console.error('[KYC Controller Callback] Token exchange error:', exchangeErr.message);
      KycRecordModel.updateRecord(session.userId, {
        kycStatus: 'FAILED',
        digilockerStatus: 'FAILED',
        failureReason: exchangeErr.message,
      });
      return respond(500, false, 'Verification Failed', `Unable to complete verification: ${exchangeErr.message}. Please try again.`);
    }
  }

  /**
   * GET /api/kyc/status
   * Returns current authenticated KYC status
   */
  static async getKycStatus(req, res) {
    try {
      const userId = req.user ? req.user.id : (req.query.userId || '1');
      const record = KycRecordModel.getRecord(userId, req.user);
      const isConfigured = KycProviderService.isDigilockerConfigured() || KycProviderService.isSetuConfigured();

      return res.status(200).json({
        success: true,
        data: {
          ...record,
          isConfigured,
          provider: KycProviderService.getActiveProvider(),
        },
      });
    } catch (err) {
      console.error('[KYC Controller getKycStatus] Error:', err.message);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve KYC status',
        message: err.message,
      });
    }
  }

  /**
   * POST /api/kyc/aadhaar/start
   * Dispatches official UIDAI OTP via authorized provider
   */
  static async initiateAadhaar(req, res) {
    try {
      const { aadhaarNumber } = req.body;
      if (!aadhaarNumber) {
        return res.status(400).json({
          success: false,
          error: 'Aadhaar number is required (12 digits)',
        });
      }

      const result = await KycProviderService.initiateAadhaarOtp(aadhaarNumber);

      if (!result.isConfigured) {
        return res.status(503).json({
          success: false,
          error: result.error,
          message: result.message,
          requiredCredentials: result.requiredCredentials,
        });
      }

      const userId = req.user ? req.user.id : '1';
      KycRecordModel.updateRecord(userId, {
        aadhaarStatus: 'OTP_SENT',
        maskedAadhaar: result.maskedAadhaar,
      });

      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      console.error('[KYC Controller initiateAadhaar] Error:', err.message);
      return res.status(400).json({
        success: false,
        error: err.message,
        message: err.message,
      });
    }
  }

  /**
   * POST /api/kyc/aadhaar/verify
   * Verifies official UIDAI OTP via authorized provider
   */
  static async verifyAadhaar(req, res) {
    try {
      const { requestId, challengeId, otp } = req.body;
      const targetId = requestId || challengeId;

      if (!targetId || !otp) {
        return res.status(400).json({
          success: false,
          error: 'Request ID and 6-digit OTP are required',
        });
      }

      const verified = await KycProviderService.verifyAadhaarOtp(targetId, otp);

      const userId = req.user ? req.user.id : '1';
      const record = KycRecordModel.getRecord(userId);

      const isFullyVerified = record.panStatus === 'VERIFIED';
      const updated = KycRecordModel.updateRecord(userId, {
        aadhaarStatus: 'VERIFIED',
        maskedAadhaar: verified.maskedAadhaar || record.maskedAadhaar,
        verifiedName: verified.verifiedName || record.verifiedName,
        verifiedDob: verified.verifiedDob || record.verifiedDob,
        kycStatus: isFullyVerified ? 'VERIFIED' : record.kycStatus,
        verificationTimestamp: new Date().toISOString(),
      });

      return res.status(200).json({
        success: true,
        message: 'Aadhaar identity verified successfully',
        data: updated,
      });
    } catch (err) {
      console.error('[KYC Controller verifyAadhaar] Error:', err.message);
      return res.status(400).json({
        success: false,
        error: 'Aadhaar OTP verification failed',
        message: err.message,
      });
    }
  }

  /**
   * POST /api/kyc/pan/verify
   * Verifies PAN against Income Tax Department records
   */
  static async verifyPan(req, res) {
    try {
      const { panNumber, fullName } = req.body;
      if (!panNumber) {
        return res.status(400).json({
          success: false,
          error: 'PAN number is required (10 alphanumeric digits)',
        });
      }

      const userId = req.user ? req.user.id : '1';
      const record = KycRecordModel.getRecord(userId);
      const nameToMatch = fullName || record.verifiedName;

      const result = await KycProviderService.verifyPan(panNumber, nameToMatch);

      if (!result.isConfigured) {
        return res.status(503).json({
          success: false,
          error: result.error,
          message: result.message,
          requiredCredentials: result.requiredCredentials,
        });
      }

      if (!result.verified) {
        return res.status(400).json({
          success: false,
          error: result.message || 'PAN verification failed',
          message: result.message || 'The entered PAN could not be verified with tax records.',
        });
      }

      const isFullyVerified = record.aadhaarStatus === 'VERIFIED';
      const updated = KycRecordModel.updateRecord(userId, {
        panStatus: 'VERIFIED',
        panLast4: result.panLast4,
        verifiedName: result.registeredName || record.verifiedName,
        kycStatus: isFullyVerified ? 'VERIFIED' : record.kycStatus,
        verificationTimestamp: new Date().toISOString(),
      });

      return res.status(200).json({
        success: true,
        message: 'PAN verified successfully with Income Tax Department records',
        data: updated,
      });
    } catch (err) {
      console.error('[KYC Controller verifyPan] Error:', err.message);
      return res.status(400).json({
        success: false,
        error: err.message,
        message: err.message,
      });
    }
  }

  /**
   * GET /api/kyc/documents
   * Returns list of verified digital documents
   */
  static async getDocuments(req, res) {
    try {
      const userId = req.user ? req.user.id : (req.query.userId || req.body?.userId || '1');
      const record = KycRecordModel.getRecord(userId);

      const docs = [];
      if (record.aadhaarStatus === 'VERIFIED') {
        docs.push({
          type: 'AADHAAR',
          title: 'Aadhaar Identity Card',
          issuer: 'Unique Identification Authority of India (UIDAI)',
          maskedNumber: record.maskedAadhaar || '•••• •••• ••••',
          status: 'VERIFIED',
          verifiedAt: record.verificationTimestamp,
        });
      }
      if (record.panStatus === 'VERIFIED') {
        docs.push({
          type: 'PAN',
          title: 'Permanent Account Number (PAN)',
          issuer: 'Income Tax Department of India (NSDL)',
          maskedNumber: record.panLast4 ? `••••••${record.panLast4}` : '••••••••••',
          status: 'VERIFIED',
          verifiedAt: record.verificationTimestamp,
        });
      }
      if (record.digilockerStatus === 'LINKED') {
        docs.push({
          type: 'DIGILOCKER_CERTIFICATE',
          title: 'Digital Identity Certificate',
          issuer: 'DigiLocker, Ministry of Electronics & IT',
          status: 'LINKED',
          verifiedAt: record.verificationTimestamp,
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          documents: docs,
          totalVerified: docs.length,
          enxId: record.enxId,
          kycStatus: record.kycStatus,
        },
      });
    } catch (err) {
      console.error('[KYC Controller getDocuments] Error:', err.message);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve KYC documents',
        message: err.message,
      });
    }
  }

  /**
   * GET /api/kyc/digilocker/sandbox
   * Renders the Setu Sandbox DigiLocker authentication interface
   */
  static renderDigilockerSandbox(req, res) {
    const state = req.query.state || '';
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    return res.status(200).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DigiLocker Sandbox — Government of India & Setu</title>
  <style>
    body { background: #0b0f19; color: #f3f4f6; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 16px; }
    .card { background: #131b2e; border: 1px solid #1e293b; border-radius: 20px; max-width: 440px; width: 100%; padding: 32px 24px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); text-align: center; }
    .badge { display: inline-block; background: #0284c7; color: #fff; font-size: 11px; font-weight: 700; text-transform: uppercase; padding: 4px 10px; border-radius: 9999px; margin-bottom: 16px; }
    h1 { font-size: 20px; font-weight: 700; margin: 0 0 8px 0; color: #fff; }
    .subtitle { font-size: 13px; color: #94a3b8; margin-bottom: 24px; line-height: 1.5; }
    .box { background: #0f172a; border: 1px solid #1e293b; border-radius: 12px; padding: 16px; margin-bottom: 20px; text-align: left; }
    .doc-item { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; font-size: 13px; color: #e2e8f0; }
    .doc-item:last-child { margin-bottom: 0; }
    .doc-icon { color: #10b981; font-weight: bold; }
    .btn { display: block; width: 100%; box-sizing: border-box; background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); color: #fff; text-decoration: none; padding: 14px; border-radius: 12px; font-weight: 700; font-size: 15px; border: none; cursor: pointer; text-align: center; }
    .btn:hover { opacity: 0.95; }
    .cancel { display: block; text-align: center; margin-top: 14px; color: #64748b; font-size: 13px; text-decoration: none; }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Setu Sandbox • DigiLocker</span>
    <h1>Digital Identity Authorization</h1>
    <p class="subtitle"><strong>ENX Money</strong> is requesting official consent to verify your identity documents via MeriPehchaan DigiLocker Gateway.</p>
    <div class="box">
      <div style="font-size: 11px; text-transform: uppercase; color: #64748b; font-weight: 700; margin-bottom: 10px;">Requested Documents:</div>
      <div class="doc-item"><span class="doc-icon">✓</span> Aadhaar Card (UIDAI Verified)</div>
      <div class="doc-item"><span class="doc-icon">✓</span> PAN Verification Record (Income Tax Dept)</div>
    </div>
    <a href="/api/kyc/digilocker/callback?code=sbx_auth_${Date.now()}&state=${encodeURIComponent(state)}" class="btn">Allow & Authorize KYC</a>
    <a href="/api/kyc/digilocker/callback?error=access_denied&error_description=User%20denied%20consent&state=${encodeURIComponent(state)}" class="cancel">Cancel</a>
  </div>
</body>
</html>`);
  }

  /**
   * POST /api/kyc/submit-manual
   * The Free & Fast Route (Manual KYC for Launch)
   * Zero third-party API costs. Validates PAN structure, stores merchant details,
   * grants immediate provisional Tier-1 access, and queues for admin approval.
   */
  static async submitManualKyc(req, res) {
    try {
      const userId = req.user ? req.user.id : (req.body.userId || '1');
      const { panNumber, businessName, applicantName, documentType, documentPhoto, phone } = req.body;

      if (!panNumber) {
        return res.status(400).json({
          success: false,
          error: 'PAN number is required (10 alphanumeric characters, e.g. ABCDE1234F)',
        });
      }

      const panUpper = panNumber.trim().toUpperCase();
      const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
      if (!panRegex.test(panUpper)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid PAN format. Must be 10 characters: 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F).',
        });
      }

      const updated = KycRecordModel.submitManualKyc(userId, {
        panNumber: panUpper,
        businessName: businessName || 'Registered Merchant',
        applicantName: applicantName || req.user?.name || 'Business Owner',
        documentType: documentType || 'PAN_CARD',
        documentPhoto,
        applicantPhone: phone || req.user?.phone,
      });

      return res.status(200).json({
        success: true,
        mode: 'MANUAL_KYC_PROVISIONAL',
        message: 'KYC documents received! Provisional Tier-1 active (up to ₹1,00,000/month limit). Full approval within 2-4 hours by compliance team.',
        data: updated,
      });
    } catch (err) {
      console.error('[KYC Controller submitManualKyc] Error:', err.message);
      return res.status(500).json({
        success: false,
        error: 'Failed to submit manual KYC',
        message: err.message,
      });
    }
  }

  /**
   * GET /api/kyc/admin/requests
   * Admin Endpoint: Fetches all KYC submissions with real-time statistics
   */
  static async getAdminManualRequests(req, res) {
    try {
      const all = KycRecordModel.getAllRecords();
      const requests = all.map(r => ({
        userId: r.userId,
        enxId: r.enxId,
        verifiedName: r.verifiedName || 'Merchant User',
        businessName: r.businessName || 'Business Owner',
        verifiedMobile: r.verifiedMobile || '--',
        panLast4: r.panLast4 || '--',
        maskedPan: r.maskedPan || (r.fullPanStored ? `••••••${r.fullPanStored.slice(-4)}` : '--'),
        fullPan: r.fullPanStored || (r.panLast4 ? `••••••${r.panLast4}` : '--'),
        documentType: r.documentType || 'PAN_CARD',
        documentPhoto: r.documentPhoto || null,
        kycStatus: r.kycStatus,
        manualKycStatus: r.manualKycStatus || (r.kycStatus === 'VERIFIED' ? 'VERIFIED' : 'NOT_SUBMITTED'),
        submittedAt: r.manualSubmissionTimestamp || r.createdAt,
        reviewedAt: r.reviewedAt || null,
        reviewedBy: r.reviewedBy || null,
        rejectionReason: r.rejectionReason || null,
      }));

      const summary = {
        total: requests.length,
        pending: requests.filter(r => r.manualKycStatus === 'PENDING_REVIEW' || r.kycStatus === 'IN_PROGRESS' || r.kycStatus === 'PENDING_REVIEW').length,
        verified: requests.filter(r => r.kycStatus === 'VERIFIED').length,
        rejected: requests.filter(r => r.manualKycStatus === 'REJECTED' || r.kycStatus === 'FAILED').length,
      };

      return res.status(200).json({
        success: true,
        summary,
        data: requests,
      });
    } catch (err) {
      console.error('[KYC Controller getAdminManualRequests] Error:', err.message);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/kyc/admin/approve
   * Admin Endpoint: Approves merchant KYC with one click
   */
  static async adminApproveManualKyc(req, res) {
    try {
      const { userId } = req.body;
      if (!userId) {
        return res.status(400).json({ success: false, error: 'User ID is required' });
      }

      const reviewer = req.user ? (req.user.name || req.user.email) : 'Compliance Admin';
      const updated = KycRecordModel.reviewManualKyc(userId, {
        decision: 'APPROVE',
        reviewer,
      });

      return res.status(200).json({
        success: true,
        message: `KYC for merchant #${userId} approved successfully!`,
        data: updated,
      });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/kyc/admin/reject
   * Admin Endpoint: Rejects merchant KYC with an explanation
   */
  static async adminRejectManualKyc(req, res) {
    try {
      const { userId, reason } = req.body;
      if (!userId) {
        return res.status(400).json({ success: false, error: 'User ID is required' });
      }

      const reviewer = req.user ? (req.user.name || req.user.email) : 'Compliance Admin';
      const updated = KycRecordModel.reviewManualKyc(userId, {
        decision: 'REJECT',
        reason: reason || 'Document or PAN details mismatch',
        reviewer,
      });

      return res.status(200).json({
        success: true,
        message: `KYC for merchant #${userId} rejected.`,
        data: updated,
      });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/kyc/admin/auto-approve-all
   * Admin Endpoint: Instant batch approval for launch phase
   */
  static async adminAutoApproveAll(req, res) {
    try {
      const all = KycRecordModel.getAllRecords();
      let approvedCount = 0;
      for (const r of all) {
        if (r.manualKycStatus === 'PENDING_REVIEW' || r.kycStatus === 'PENDING_REVIEW') {
          KycRecordModel.reviewManualKyc(r.userId, { decision: 'APPROVE', reviewer: 'Launch Batch Auto-Approval' });
          approvedCount++;
        }
      }
      return res.status(200).json({
        success: true,
        message: `Successfully approved ${approvedCount} pending KYC merchant applications.`,
        approvedCount,
      });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = KycController;
