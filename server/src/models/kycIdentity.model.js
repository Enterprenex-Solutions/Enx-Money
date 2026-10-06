const { generateUuid } = require('../utils/crypto.util');

class KycIdentityModel {
  // In-memory stores
  static _kycStore = new Map();
  static _aadhaarChallenges = new Map();

  static _getStore(userId, userName = null, deviceId = null) {
    if (!this._kycStore.has(userId)) {
      const userHash = Math.abs(String(userId).split('').reduce((a, b) => { a = ((a << 5) - a) + b.charCodeAt(0); return a & a; }, 0));
      const idPart1 = String((userHash % 9000) + 1000).padStart(4, '0');
      const idPart2 = String((Math.floor(userHash / 7) % 9000) + 1000).padStart(4, '0');
      this._kycStore.set(userId, {
        userId,
        tier: 'TIER_1_BASIC', // TIER_1_BASIC | TIER_2_GOVT_ID | TIER_3_FULL_BIOMETRIC
        isAadhaarVerified: false,
        maskedAadhaar: null,
        aadhaarData: null,
        isPanVerified: false,
        panNumber: null,
        panData: null,
        isPassportVerified: false,
        passportNumber: null,
        isBiometricBound: false,
        biometricBoundAt: null,
        isDigilockerConnected: false,
        digitalIdentityNumber: `ENX-ID-${idPart1}-${idPart2}`,
        deviceBinding: {
          deviceId: deviceId || 'DEVICE-PRIMARY',
          simSlot: 'SIM 1 (Active)',
          simActive: true,
          hardwareKeystoreBound: false,
          verifiedAt: new Date().toISOString(),
        },
        verifiedName: userName || 'Verified User',
        updatedAt: new Date().toISOString(),
      });
    }
    const store = this._kycStore.get(userId);
    if (userName && (store.verifiedName === 'Verified User' || store.verifiedName === 'P. Revanth Reddy')) {
      store.verifiedName = userName;
    }
    if (deviceId && (store.deviceBinding.deviceId === 'DEV-PIXEL-8-PRO-IND' || store.deviceBinding.deviceId === 'DEVICE-PRIMARY')) {
      store.deviceBinding.deviceId = deviceId;
    }
    return store;
  }

  static getKycStatus(userId, userName = null, deviceId = null) {
    return this._getStore(userId, userName, deviceId);
  }

  static initiateAadhaarOtp(userId, aadhaarNumber, customChallengeId = null) {
    const cleanAadhaar = (aadhaarNumber || '').replace(/\s+/g, '').replace(/\D/g, '');
    if (cleanAadhaar.length !== 12) {
      throw new Error('Invalid Aadhaar number. Must be exactly 12 numeric digits.');
    }

    const challengeId = customChallengeId || `uidai_ch_${Date.now()}`;
    const otp = '123456'; // Simulated UIDAI secure OTP
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 min expiry

    this._aadhaarChallenges.set(challengeId, {
      userId,
      cleanAadhaar,
      otp,
      expiresAt,
    });

    return {
      challengeId,
      maskedAadhaar: `•••• •••• ${cleanAadhaar.slice(-4)}`,
      expiresInSeconds: 300,
      resendCountdown: 30,
      message: '6-digit Aadhaar OTP dispatched to UIDAI-linked mobile number.',
    };
  }

  static verifyAadhaarOtp(challengeId, otp, customAadhaarData = null) {
    const challenge = this._aadhaarChallenges.get(challengeId);
    if (!challenge && !customAadhaarData) {
      throw new Error('Aadhaar verification session expired or invalid.');
    }
    if (challenge && Date.now() > challenge.expiresAt) {
      this._aadhaarChallenges.delete(challengeId);
      throw new Error('Aadhaar verification OTP expired.');
    }
    if (challenge && otp !== challenge.otp && otp !== '123456' && !customAadhaarData) {
      throw new Error('Invalid Aadhaar OTP. Please check the code sent by UIDAI.');
    }

    const targetUserId = challenge ? challenge.userId : 1;
    const userKyc = this._getStore(targetUserId);
    userKyc.isAadhaarVerified = true;
    userKyc.maskedAadhaar = challenge ? `•••• •••• ${challenge.cleanAadhaar.slice(-4)}` : '•••• •••• 4821';
    userKyc.aadhaarData = customAadhaarData || {
      fullName: userKyc.verifiedName,
      gender: 'MALE',
      dateOfBirth: '1992-08-15',
      addressState: 'Telangana',
      country: 'India',
      pincode: '500081',
      uidaiVerified: true,
      verifiedTimestamp: new Date().toISOString(),
    };

    if (userKyc.tier === 'TIER_1_BASIC') {
      userKyc.tier = 'TIER_2_GOVT_ID';
    }
    userKyc.updatedAt = new Date().toISOString();
    this._aadhaarChallenges.delete(challengeId);

    return userKyc;
  }

  static verifyPan(userId, panNumber, fullName) {
    const cleanPan = (panNumber || '').trim().toUpperCase();
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
    if (!panRegex.test(cleanPan)) {
      throw new Error('Invalid PAN format. Must be 10 alphanumeric characters (e.g. ABCDE1234F).');
    }

    const userKyc = this._getStore(userId);
    userKyc.isPanVerified = true;
    userKyc.panNumber = cleanPan;
    userKyc.panData = {
      panNumber: cleanPan,
      holderName: fullName || userKyc.verifiedName,
      status: 'ACTIVE_AND_SEEDED_WITH_AADHAAR',
      category: cleanPan[3] === 'P' ? 'INDIVIDUAL' : 'COMPANY/FIRM',
      nsdlVerified: true,
      verifiedTimestamp: new Date().toISOString(),
    };

    if (userKyc.tier === 'TIER_1_BASIC') {
      userKyc.tier = 'TIER_2_GOVT_ID';
    }
    userKyc.updatedAt = new Date().toISOString();

    return userKyc;
  }

  static connectDigiLocker(userId) {
    const userKyc = this._getStore(userId);
    userKyc.isDigilockerConnected = true;
    userKyc.isAadhaarVerified = true;
    userKyc.maskedAadhaar = '•••• •••• 9102';
    userKyc.aadhaarData = {
      fullName: userKyc.verifiedName,
      gender: 'MALE',
      dateOfBirth: '1992-08-15',
      addressState: 'Telangana',
      country: 'India',
      pincode: '500081',
      uidaiVerified: true,
      source: 'DIGILOCKER_ISSUED_DOCUMENTS',
      verifiedTimestamp: new Date().toISOString(),
    };

    userKyc.isPanVerified = true;
    userKyc.panNumber = 'ABCDE1234F';
    userKyc.panData = {
      panNumber: 'ABCDE1234F',
      holderName: userKyc.verifiedName,
      status: 'ACTIVE_AND_SEEDED_WITH_AADHAAR',
      category: 'INDIVIDUAL',
      nsdlVerified: true,
      source: 'DIGILOCKER_INCOME_TAX_DEPT',
      verifiedTimestamp: new Date().toISOString(),
    };

    userKyc.tier = 'TIER_2_GOVT_ID';
    userKyc.updatedAt = new Date().toISOString();

    return userKyc;
  }

  static bindBiometrics(userId, deviceSignature, mpin) {
    const userKyc = this._getStore(userId);
    userKyc.isBiometricBound = true;
    userKyc.biometricBoundAt = new Date().toISOString();
    userKyc.deviceBinding.hardwareKeystoreBound = true;
    userKyc.deviceBinding.biometricSignature = deviceSignature || generateUuid();
    userKyc.mpinHash = mpin ? 'BCRYPT_SECURE_MPIN_HASH' : userKyc.mpinHash;

    // Upgrades to maximum tier: Tier 3 Full Biometric KYC
    userKyc.tier = 'TIER_3_FULL_BIOMETRIC';
    userKyc.updatedAt = new Date().toISOString();

    return userKyc;
  }
}

module.exports = KycIdentityModel;
