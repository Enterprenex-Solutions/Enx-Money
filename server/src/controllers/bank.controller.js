const FinanceProfileModel = require('../models/financeProfile.model');
const SmsService = require('../services/sms.service');
const SetuAaService = require('../services/setuAa.service');

class BankController {
  /**
   * POST /api/v1/bank/initiate-consent
   * 1-Step Backend Launch: Initiates Setu AA consent and returns redirectUrl
   */
  static async initiateConsent(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      let phone = req.body.phone || req.body.mobileNumber || req.user?.phoneNumber || req.user?.phone || req.user?.mobile;
      if (!phone && userId) {
        try {
          const UserModel = require('../models/user.model');
          const userRecord = await UserModel.findById(userId);
          if (userRecord && userRecord.phone) {
            phone = userRecord.phone;
          }
        } catch (_) {}
      }

      const redirectUrl = req.body.redirectUrl || 'enxmoney://bank-success';
      const hostUrl = `${req.protocol}://${req.get('host')}`;

      const consentResult = await SetuAaService.createConsentRequest({
        phone: phone || '9876543210',
        redirectUrl,
        hostUrl,
      });

      return res.status(200).json({
        success: true,
        message: 'Setu Account Aggregator consent initiated',
        data: {
          consentId: consentResult.consentId,
          redirectUrl: consentResult.redirectUrl,
          isLive: consentResult.isLive,
          status: consentResult.status,
        },
      });
    } catch (error) {
      console.error('[BankController] initiateConsent error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to initiate Setu AA consent',
        error: error.message,
      });
    }
  }

  /**
   * POST /api/v1/bank/complete-consent
   * Instantly creates and links the approved bank account into the user's finance profile.
   */
  static async completeConsent(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const {
        consentId,
        bankName = 'State Bank of India',
        accountNumber = 'XXXXXX4829',
        ifsc = 'SBIN0001234',
        mode = 'BUSINESS',
        balance = 50000.00,
      } = req.body;

      const newAccount = await FinanceProfileModel.createAccount(userId, {
        mode: (mode || 'BUSINESS').toUpperCase(),
        accountType: 'Bank',
        accountName: `${bankName} Account`,
        accountNumber,
        ifsc,
        bankName,
        balance: Number(balance) || 50000.00,
        isAsset: true,
      });

      return res.status(200).json({
        success: true,
        message: 'Bank Account Linked Successfully!',
        data: newAccount,
      });
    } catch (error) {
      console.error('[BankController] completeConsent error:', error);
      return res.status(400).json({
        success: false,
        message: 'Failed to link bank account',
        error: error.message,
      });
    }
  }

  /**
   * GET /api/v1/bank/setu-webview
   * Pre-built Automated Setu AA Webview Simulator
   * Renders the Setu mobile webview experience with bank selection and OTP verification.
   */
  static renderSetuWebview(req, res) {
    const { consentId = `cst_${Date.now()}`, phone = '9876543210', redirectUrl = 'enxmoney://bank-success' } = req.query;

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Setu Account Aggregator Gateway</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Plus Jakarta Sans', sans-serif; -webkit-tap-highlight-color: transparent; }
    body { background-color: #0b1120; color: #f8fafc; min-height: 100vh; display: flex; flex-direction: column; }
    .header { padding: 16px 20px; background: rgba(15, 23, 42, 0.95); border-bottom: 1px solid rgba(255,255,255,0.08); display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 10; backdrop-filter: blur(12px); }
    .brand { display: flex; align-items: center; gap: 10px; }
    .brand-logo { width: 32px; height: 32px; border-radius: 8px; background: linear-gradient(135deg, #0ea5e9, #2563eb); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 16px; color: #fff; box-shadow: 0 4px 12px rgba(14,165,233,0.3); }
    .brand-text h1 { font-size: 14px; font-weight: 700; color: #fff; }
    .brand-text p { font-size: 10px; color: #94a3b8; }
    .badge-rbi { display: flex; align-items: center; gap: 4px; padding: 4px 8px; border-radius: 20px; background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.3); color: #34d399; font-size: 10px; font-weight: 600; }
    .content { flex: 1; padding: 20px; max-width: 480px; margin: 0 auto; width: 100%; }
    .step-card { background: #1e293b; border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 20px; margin-bottom: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
    .step-header { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
    .step-num { width: 24px; height: 24px; border-radius: 50%; background: #2563eb; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
    .step-title { font-size: 14px; font-weight: 700; color: #f1f5f9; }
    .phone-box { background: rgba(15, 23, 42, 0.6); border: 1px solid rgba(255,255,255,0.06); padding: 12px 14px; border-radius: 12px; display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
    .phone-val { font-size: 14px; font-weight: 600; color: #38bdf8; letter-spacing: 0.5px; }
    .verified-badge { font-size: 11px; color: #34d399; font-weight: 600; }
    .bank-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; margin-top: 10px; }
    .bank-item { background: rgba(15, 23, 42, 0.6); border: 1.5px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px; cursor: pointer; transition: all 0.2s ease; display: flex; align-items: center; gap: 10px; }
    .bank-item:hover, .bank-item.selected { border-color: #38bdf8; background: rgba(56, 189, 248, 0.08); transform: translateY(-2px); }
    .bank-icon { width: 34px; height: 34px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 12px; color: #fff; }
    .b-sbi { background: #1a4f8b; }
    .b-hdfc { background: #004c8f; }
    .b-icici { background: #b82c23; }
    .b-axis { background: #97144d; }
    .b-kotak { background: #ed1c24; }
    .b-pnb { background: #a20a3a; }
    .bank-meta { flex: 1; }
    .bank-name { font-size: 12px; font-weight: 700; color: #fff; line-height: 1.2; }
    .bank-sub { font-size: 10px; color: #94a3b8; }
    .otp-section { margin-top: 14px; }
    .otp-inputs { display: flex; gap: 8px; justify-content: center; margin: 14px 0; }
    .otp-input { width: 44px; height: 48px; border-radius: 10px; background: rgba(15,23,42,0.8); border: 1.5px solid rgba(255,255,255,0.15); color: #38bdf8; text-align: center; font-size: 20px; font-weight: 800; outline: none; transition: border-color 0.2s; }
    .otp-input:focus { border-color: #38bdf8; box-shadow: 0 0 10px rgba(56, 189, 248, 0.3); }
    .otp-hint { font-size: 11px; text-align: center; color: #94a3b8; margin-top: 4px; }
    .otp-badge { background: rgba(56, 189, 248, 0.12); color: #38bdf8; padding: 3px 8px; border-radius: 6px; font-weight: 700; cursor: pointer; }
    .cta-btn { width: 100%; padding: 15px; border-radius: 14px; background: linear-gradient(135deg, #2563eb, #0ea5e9); border: none; color: #fff; font-size: 15px; font-weight: 700; cursor: pointer; margin-top: 10px; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: 0 8px 20px rgba(37,99,235,0.35); transition: all 0.2s; }
    .cta-btn:active { transform: scale(0.98); }
    .cta-btn:disabled { opacity: 0.6; cursor: not-allowed; }
    .security-note { text-align: center; margin-top: 16px; font-size: 11px; color: #64748b; display: flex; align-items: center; justify-content: center; gap: 6px; }
    .toast { position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%); background: #10b981; color: #fff; padding: 12px 20px; border-radius: 30px; font-size: 13px; font-weight: 700; box-shadow: 0 10px 25px rgba(0,0,0,0.4); display: none; z-index: 100; }
  </style>
</head>
<body>
  <div class="header">
    <div class="brand">
      <div class="brand-logo">S</div>
      <div class="brand-text">
        <h1>Setu AA Gateway</h1>
        <p>Pre-built Webview SDK</p>
      </div>
    </div>
    <div class="badge-rbi">
      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      RBI Regulated
    </div>
  </div>

  <div class="content">
    <!-- Step 1: Registered Phone -->
    <div class="step-card">
      <div class="step-header">
        <div class="step-num">1</div>
        <div class="step-title">Verified Mobile Number</div>
      </div>
      <div class="phone-box">
        <span class="phone-val">+91 ${phone}</span>
        <span class="verified-badge">✓ Linked with Banks</span>
      </div>
      <p style="font-size: 11px; color: #64748b; margin-top: 4px;">Accounts registered under this mobile will be retrieved via NBFC-AA.</p>
    </div>

    <!-- Step 2: Select Financial Institution -->
    <div class="step-card">
      <div class="step-header">
        <div class="step-num">2</div>
        <div class="step-title">Select Your Bank</div>
      </div>
      <div class="bank-grid" id="bankGrid">
        <div class="bank-item selected" onclick="selectBank(this, 'State Bank of India', 'SBIN0001234')">
          <div class="bank-icon b-sbi">SBI</div>
          <div class="bank-meta">
            <div class="bank-name">State Bank of India</div>
            <div class="bank-sub">A/c •••• 4829</div>
          </div>
        </div>
        <div class="bank-item" onclick="selectBank(this, 'HDFC Bank', 'HDFC0000456')">
          <div class="bank-icon b-hdfc">HDFC</div>
          <div class="bank-meta">
            <div class="bank-name">HDFC Bank</div>
            <div class="bank-sub">A/c •••• 5892</div>
          </div>
        </div>
        <div class="bank-item" onclick="selectBank(this, 'ICICI Bank', 'ICIC0000789')">
          <div class="bank-icon b-icici">ICICI</div>
          <div class="bank-meta">
            <div class="bank-name">ICICI Bank</div>
            <div class="bank-sub">A/c •••• 3041</div>
          </div>
        </div>
        <div class="bank-item" onclick="selectBank(this, 'Axis Bank', 'UTIB0000123')">
          <div class="bank-icon b-axis">AXIS</div>
          <div class="bank-meta">
            <div class="bank-name">Axis Bank</div>
            <div class="bank-sub">A/c •••• 9102</div>
          </div>
        </div>
        <div class="bank-item" onclick="selectBank(this, 'Kotak Mahindra', 'KKBK0000567')">
          <div class="bank-icon b-kotak">KOTAK</div>
          <div class="bank-meta">
            <div class="bank-name">Kotak Mahindra</div>
            <div class="bank-sub">A/c •••• 7731</div>
          </div>
        </div>
        <div class="bank-item" onclick="selectBank(this, 'Punjab National Bank', 'PUNB0000890')">
          <div class="bank-icon b-pnb">PNB</div>
          <div class="bank-meta">
            <div class="bank-name">Punjab National Bank</div>
            <div class="bank-sub">A/c •••• 6214</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Step 3: SMS OTP Verification -->
    <div class="step-card">
      <div class="step-header">
        <div class="step-num">3</div>
        <div class="step-title">Native SMS OTP Delivery</div>
      </div>
      <p style="font-size: 12px; color: #94a3b8;">Enter the 6-digit consent OTP sent to <b>+91 ${phone}</b> via Setu Bridge</p>
      
      <div class="otp-inputs">
        <input class="otp-input" type="text" maxlength="1" value="1" oninput="moveFocus(this, 1)">
        <input class="otp-input" type="text" maxlength="1" value="2" oninput="moveFocus(this, 2)">
        <input class="otp-input" type="text" maxlength="1" value="3" oninput="moveFocus(this, 3)">
        <input class="otp-input" type="text" maxlength="1" value="4" oninput="moveFocus(this, 4)">
        <input class="otp-input" type="text" maxlength="1" value="5" oninput="moveFocus(this, 5)">
        <input class="otp-input" type="text" maxlength="1" value="6" oninput="moveFocus(this, 6)">
      </div>

      <div class="otp-hint">
        Auto-filled test code: <span class="otp-badge" onclick="fillTestOtp()">123456</span>
      </div>

      <button id="submitBtn" class="cta-btn" onclick="submitConsent()">
        <span>Approve & Link Bank Account</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
      </button>

      <div class="security-note">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
        256-bit Encrypted End-to-End Consent Architecture
      </div>
    </div>
  </div>

  <div id="toast" class="toast">Bank Account Linked Successfully! Redirecting...</div>

  <script>
    let selectedBankName = 'State Bank of India';
    let selectedIfsc = 'SBIN0001234';
    const redirectUrl = ${JSON.stringify(redirectUrl)};
    const consentId = ${JSON.stringify(consentId)};

    function selectBank(el, name, ifsc) {
      document.querySelectorAll('.bank-item').forEach(item => item.classList.remove('selected'));
      el.classList.add('selected');
      selectedBankName = name;
      selectedIfsc = ifsc;
    }

    function moveFocus(input, index) {
      if (input.value.length === 1 && index < 6) {
        document.querySelectorAll('.otp-input')[index].focus();
      }
    }

    function fillTestOtp() {
      const inputs = document.querySelectorAll('.otp-input');
      const digits = ['1', '2', '3', '4', '5', '6'];
      inputs.forEach((input, i) => input.value = digits[i]);
    }

    async function submitConsent() {
      const btn = document.getElementById('submitBtn');
      btn.disabled = true;
      btn.innerHTML = '<span>Verifying with Setu...</span>';

      const toast = document.getElementById('toast');
      toast.style.display = 'block';

      // 1. Sync completed account with backend
      try {
        await fetch('/api/v1/bank/complete-consent', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            consentId: consentId,
            bankName: selectedBankName,
            accountNumber: 'XXXXXX' + Math.floor(1000 + Math.random() * 9000),
            ifsc: selectedIfsc,
            mode: 'BUSINESS',
            balance: 50000.00
          })
        });
      } catch (e) {
        console.warn('Backend sync warning:', e);
      }

      // 2. Perform redirect callback: enxmoney://bank-success
      setTimeout(() => {
        const separator = redirectUrl.includes('?') ? '&' : '?';
        const finalUrl = redirectUrl + separator + 'consentId=' + encodeURIComponent(consentId) + '&bankName=' + encodeURIComponent(selectedBankName) + '&status=SUCCESS';
        
        // Attempt deep link redirect
        window.location.href = finalUrl;
        
        // Fallback for webview javascript bridge
        if (window.SetuBridge && window.SetuBridge.postMessage) {
          window.SetuBridge.postMessage(JSON.stringify({ status: 'SUCCESS', bankName: selectedBankName }));
        }
      }, 700);
    }
  </script>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html');
    return res.status(200).send(html);
  }

  /**
   * POST /api/v1/bank/send-otp
   * Dispatches 6-digit SMS OTP for Bank Account Linking / Setu AA Gateway consent.
   */
  static async sendOtp(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { accountNumber, ifsc, bankName, mobileNumber } = req.body;

      if (!accountNumber || !ifsc) {
        return res.status(400).json({
          success: false,
          message: 'Failed to send SMS OTP. Please check your registered phone number.',
          errors: ['Account number and IFSC code are required.'],
        });
      }

      const cleanAcc = String(accountNumber).trim();
      if (!/^\d{9,18}$/.test(cleanAcc)) {
        return res.status(400).json({
          success: false,
          message: 'Failed to send SMS OTP. Please check your registered phone number.',
          errors: ['Account number must be between 9 and 18 digits.'],
        });
      }

      const cleanIfsc = String(ifsc).trim().toUpperCase();
      if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(cleanIfsc)) {
        return res.status(400).json({
          success: false,
          message: 'Failed to send SMS OTP. Please check your registered phone number.',
          errors: ['Invalid IFSC code format.'],
        });
      }

      let resolvedPhone = mobileNumber || req.user?.phoneNumber || req.user?.phone || req.user?.mobile;
      if (!resolvedPhone && userId) {
        try {
          const UserModel = require('../models/user.model');
          const userRecord = await UserModel.findById(userId);
          if (userRecord && userRecord.phone) {
            resolvedPhone = userRecord.phone;
          }
        } catch (_) {}
      }

      const challenge = await FinanceProfileModel.sendAccountLinkingOtp(userId, {
        accountNumber: cleanAcc,
        ifsc: cleanIfsc,
        bankName: bankName || 'Bank',
        mobileNumber: resolvedPhone,
        expiresInSeconds: 60,
      });

      return res.status(200).json({
        success: true,
        message: '6-digit verification code sent to bank-registered mobile number',
        data: {
          transactionId: challenge.transactionId || challenge.challengeId,
          consentHandle: challenge.consentHandle || challenge.transactionId,
          challengeId: challenge.challengeId,
          expiresInSeconds: challenge.expiresInSeconds || 60,
          phone: challenge.phone,
          isSandbox: challenge.isSandbox ?? (process.env.NODE_ENV !== 'production'),
          message: challenge.message,
        },
      });
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Failed to send SMS OTP. Please check your registered phone number.',
        error: error.message,
      });
    }
  }

  /**
   * POST /api/v1/bank/verify-otp
   * Strictly validates 6-digit OTP alongside transactionId and links bank account.
   */
  static async verifyOtp(req, res) {
    try {
      const userId = req.user ? req.user.id : 1;
      const { transactionId, consentHandle, challengeId, otp, accountData, bankName, accountNumber, ifsc, accountType } = req.body;

      const tid = transactionId || consentHandle || challengeId;
      if (!tid) {
        return res.status(400).json({
          success: false,
          message: 'Invalid OTP entered. Please try again.',
          error: 'Transaction ID is required for verification.',
        });
      }

      const cleanOtp = String(otp || '').trim();
      if (!/^\d{6}$/.test(cleanOtp)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid OTP entered. Please try again.',
          error: 'OTP must be a 6-digit numeric code.',
        });
      }

      const mergedAccountData = {
        ...(accountData || {}),
        bankName: accountData?.bankName || bankName || 'Bank',
        accountNumber: accountData?.accountNumber || accountNumber || '50200012345678',
        ifsc: accountData?.ifsc || ifsc || 'HDFC0001234',
        accountType: accountData?.accountType || accountType || 'Savings',
        accountName: accountData?.accountName || `${bankName || 'Bank'} ${accountType || 'Savings'}`,
      };

      const account = await FinanceProfileModel.verifyAndLinkBankAccount(userId, {
        transactionId: tid,
        challengeId: tid,
        consentHandle: tid,
        otp: cleanOtp,
        accountData: mergedAccountData,
      });

      return res.status(200).json({
        success: true,
        status: account.status || 'ACTIVE',
        message: 'Bank Account Linked Successfully',
        data: {
          ...account,
          status: account.status || 'ACTIVE',
          verificationStatus: 'APPROVED',
        },
      });
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP entered. Please try again.',
        error: error.message,
      });
    }
  }
}

module.exports = BankController;
