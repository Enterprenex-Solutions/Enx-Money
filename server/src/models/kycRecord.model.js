/**
 * ENX Money — KYC Record Model & Persistent Store
 * Associated with authenticated ENX user.
 * Strictly avoids storing full Aadhaar number, OTPs, or provider secrets.
 */
const fs = require('fs');
const path = require('path');
const { generateUuid } = require('../utils/crypto.util');

const STORE_FILE = process.env.NODE_ENV === 'test'
  ? path.join(__dirname, '../../../database/enx_kyc_records.test.json')
  : path.join(__dirname, '../../../database/enx_kyc_records.json');

class KycRecordModel {
  static _records = new Map(); // Key: userId
  static _oauthSessions = new Map(); // Key: state -> { userId, createdAt, expiresAt }

  static _loadFromDisk() {
    try {
      if (fs.existsSync(STORE_FILE)) {
        const raw = fs.readFileSync(STORE_FILE, 'utf8');
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) {
          for (const item of parsed) {
            if (item && item.userId) {
              this._records.set(String(item.userId), item);
            }
          }
        }
      }
    } catch (_) {}
  }

  static _saveToDisk() {
    try {
      const dir = path.dirname(STORE_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      const data = Array.from(this._records.values());
      fs.writeFileSync(STORE_FILE, JSON.stringify(data, null, 2), 'utf8');
    } catch (_) {}
  }

  static getRecord(userId, defaultUser = null) {
    if (this._records.size === 0) {
      this._loadFromDisk();
    }

    const key = String(userId);
    if (!this._records.has(key)) {
      const userHash = Math.abs(key.split('').reduce((a, b) => { a = ((a << 5) - a) + b.charCodeAt(0); return a & a; }, 0));
      const idPart1 = String((userHash % 9000) + 1000).padStart(4, '0');
      const idPart2 = String((Math.floor(userHash / 7) % 9000) + 1000).padStart(4, '0');

      const initial = {
        userId: key,
        kycStatus: 'NOT_VERIFIED', // NOT_VERIFIED | IN_PROGRESS | VERIFIED | FAILED
        digilockerStatus: 'NOT_STARTED', // NOT_STARTED | IN_PROGRESS | LINKED | FAILED
        aadhaarStatus: 'NOT_VERIFIED', // NOT_VERIFIED | OTP_SENT | VERIFIED | FAILED
        panStatus: 'NOT_VERIFIED', // NOT_VERIFIED | VERIFIED | FAILED
        verifiedName: defaultUser?.name || defaultUser?.fullName || null,
        verifiedDob: null,
        verifiedMobile: defaultUser?.phone || null,
        maskedAadhaar: null,
        panLast4: null,
        enxId: `ENX-ID-${idPart1}-${idPart2}`,
        documentReference: null,
        providerReferenceId: null,
        verificationTimestamp: null,
        failureReason: null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      this._records.set(key, initial);
      this._saveToDisk();
    }

    return this._records.get(key);
  }

  static updateRecord(userId, updates) {
    const record = this.getRecord(userId);
    Object.assign(record, updates, { updatedAt: new Date().toISOString() });
    this._records.set(String(userId), record);
    this._saveToDisk();
    return record;
  }

  // --- OAuth Session Management for DigiLocker ---
  static createOAuthSession(userId, redirectUri) {
    const state = generateUuid().replace(/-/g, '') + Date.now().toString(36);
    const expiresAt = Date.now() + 15 * 60 * 1000; // 15 minutes TTL

    this._oauthSessions.set(state, {
      userId: String(userId),
      redirectUri,
      createdAt: Date.now(),
      expiresAt,
    });

    return { state, expiresAt };
  }

  static getOAuthSession(state) {
    if (!state) return null;
    const session = this._oauthSessions.get(state);
    if (!session) return null;

    if (Date.now() > session.expiresAt) {
      this._oauthSessions.delete(state);
      return null;
    }

    return session;
  }

  static consumeOAuthSession(state) {
    const session = this.getOAuthSession(state);
    if (session) {
      this._oauthSessions.delete(state);
    }
    return session;
  }

  // --- Free & Fast Route: Manual KYC for Launch ---
  static getAllRecords() {
    if (this._records.size === 0) {
      this._loadFromDisk();
    }
    return Array.from(this._records.values());
  }

  static submitManualKyc(userId, { panNumber, businessName, applicantName, documentType, documentPhoto, applicantPhone } = {}) {
    const key = String(userId);
    const existing = this.getRecord(key);

    const panUpper = (panNumber || '').trim().toUpperCase();
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
    const isValidFormat = panRegex.test(panUpper);

    const updates = {
      manualKycStatus: 'PENDING_REVIEW', // PENDING_REVIEW | VERIFIED | REJECTED
      kycStatus: existing.kycStatus === 'VERIFIED' ? 'VERIFIED' : 'PENDING_REVIEW',
      panStatus: isValidFormat ? 'SUBMITTED' : 'NOT_VERIFIED',
      panLast4: panUpper.length >= 4 ? panUpper.slice(-4) : existing.panLast4,
      maskedPan: panUpper.length === 10 ? `••••••${panUpper.slice(-4)}` : null,
      fullPanStored: panUpper, // Stored safely for admin visual verification
      businessName: businessName || existing.businessName || null,
      verifiedName: applicantName || existing.verifiedName || null,
      verifiedMobile: applicantPhone || existing.verifiedMobile || null,
      documentType: documentType || 'PAN_CARD',
      documentPhoto: documentPhoto || existing.documentPhoto || null,
      manualSubmissionTimestamp: new Date().toISOString(),
      failureReason: null,
      rejectionReason: null,
    };

    return this.updateRecord(key, updates);
  }

  static reviewManualKyc(userId, { decision, reason, reviewer = 'Admin' } = {}) {
    const key = String(userId);
    this.getRecord(key);

    if (decision === 'APPROVE') {
      const updates = {
        kycStatus: 'VERIFIED',
        manualKycStatus: 'VERIFIED',
        panStatus: 'VERIFIED',
        tier: 'TIER_2_UNLIMITED',
        verificationTimestamp: new Date().toISOString(),
        reviewedBy: reviewer,
        reviewedAt: new Date().toISOString(),
        failureReason: null,
        rejectionReason: null,
      };
      return this.updateRecord(key, updates);
    } else {
      const updates = {
        kycStatus: 'FAILED',
        manualKycStatus: 'REJECTED',
        rejectionReason: reason || 'Document rejected during manual KYC verification',
        failureReason: reason || 'Document rejected during manual KYC verification',
        reviewedBy: reviewer,
        reviewedAt: new Date().toISOString(),
      };
      return this.updateRecord(key, updates);
    }
  }

  /**
   * DPDP Act 2023 Section 12 (Right to Erasure):
   * Purge all persistent and in-memory KYC records for user
   */
  static purgeUserData(userId) {
    const key = String(userId);
    this._records.delete(key);
    for (const [state, sess] of this._oauthSessions.entries()) {
      if (String(sess.userId) === key) {
        this._oauthSessions.delete(state);
      }
    }
    this._saveToDisk();
  }

  static resetForTesting() {
    this._records.clear();
    this._oauthSessions.clear();
    try {
      if (fs.existsSync(STORE_FILE)) {
        fs.unlinkSync(STORE_FILE);
      }
    } catch (_) {}
  }
}

// Initial disk load
KycRecordModel._loadFromDisk();

module.exports = KycRecordModel;
