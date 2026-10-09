/**
 * ENX Money — DPDP Act 2023 & Security Compliance Automated Test Suite
 * Validates:
 * 1. RBI CoFT & DPDP Sec 8(5): Zero raw CVV storage & card masking with token references
 * 2. Aadhaar Act & DPDP Sec 8(5): Zero raw 12-digit Aadhaar storage in challenges or records
 * 3. DPDP Sec 6 & Sec 9: Affirmative consent tracking & age verification flags
 * 4. DPDP Sec 12: Cascading Right to Erasure across models (Cards, KYC, Wallets, OTPs)
 */

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_dpdp_jwt_secret_key_2026_super_secure';

const assert = require('assert');
const CardModel = require('./src/models/card.model');
const KycIdentityModel = require('./src/models/kycIdentity.model');
const KycRecordModel = require('./src/models/kycRecord.model');
const MultiAssetWalletModel = require('./src/models/multiAssetWallet.model');
const UserModel = require('./src/models/user.model');
const OtpModel = require('./src/models/otp.model');
const AuthService = require('./src/services/auth.service');

async function runTests() {
  console.log('====================================================');
  console.log('🛡️  DPDP ACT 2023 COMPLIANCE & PRIVACY AUDIT TEST SUITE');
  console.log('====================================================\n');

  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  async function testAsync(name, fn) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  // --- TEST GROUP 1: Card Tokenization & Zero CVV Storage ---
  console.log('--- TEST GROUP 1: Card Tokenization & Zero CVV Storage (Sec 8(5)) ---');

  await testAsync('CardModel.createCard never stores or outputs CVV in memory or response', async () => {
    CardModel._clearStore();
    const testUserId = 'user_dpdp_test_1';
    const card = await CardModel.createCard({
      userId: testUserId,
      cardHolderName: 'Kishore Kumar',
      cardTier: 'Black Metal',
      network: 'Visa',
    });

    assert.strictEqual(card.cvv, undefined, 'Card object must NEVER expose a cvv property');
    assert.strictEqual(typeof card.tokenRef, 'string', 'Card must have a token reference');
    assert.ok(card.tokenRef.startsWith('tok_card_'), 'Token reference must follow secure token scheme');
    assert.ok(card.cardNumber.includes('•••'), 'Card number must be masked');
    assert.strictEqual(card.lastFourDigits.length, 4, 'Last 4 digits should be preserved for recognition');

    // Inspect internal store directly
    const storedCards = await CardModel.findByUserId(testUserId);
    assert.strictEqual(storedCards.length, 1);
    assert.strictEqual(storedCards[0].cvv, undefined, 'Internal store must not contain CVV');
  });

  // --- TEST GROUP 2: Aadhaar Number Protection & Masking ---
  console.log('\n--- TEST GROUP 2: Aadhaar Privacy & Masking (Sec 8(5) & Aadhaar Act) ---');

  test('KycIdentityModel.initiateAadhaarOtp never stores clean 12-digit Aadhaar in challenges', () => {
    KycIdentityModel._clearStore();
    const testUserId = 'user_dpdp_test_2';
    const rawAadhaar = '542189014821';

    const challenge = KycIdentityModel.initiateAadhaarOtp(testUserId, rawAadhaar);
    assert.ok(challenge.challengeId, 'Challenge ID must be generated');
    assert.strictEqual(challenge.maskedAadhaar, '•••• •••• 4821', 'Must return masked Aadhaar only');

    // Inspect internal challenge map
    const internalChallenge = KycIdentityModel._aadhaarChallenges.get(challenge.challengeId);
    assert.ok(internalChallenge, 'Challenge record must exist in map');
    assert.strictEqual(internalChallenge.cleanAadhaar, undefined, 'Raw 12-digit cleanAadhaar must NEVER be stored in memory');
    assert.strictEqual(internalChallenge.maskedAadhaar, '•••• •••• 4821', 'Only masked Aadhaar should be retained');
    assert.ok(internalChallenge.aadhaarHash, 'Aadhaar must be stored as one-way cryptographic hash');
  });

  test('KycIdentityModel.verifyAadhaarOtp verifies successfully without storing raw Aadhaar', () => {
    const testUserId = 'user_dpdp_test_2';
    const challenge = KycIdentityModel.initiateAadhaarOtp(testUserId, '542189014821');
    const verified = KycIdentityModel.verifyAadhaarOtp(challenge.challengeId, '123456');

    assert.strictEqual(verified.isAadhaarVerified, true);
    assert.strictEqual(verified.maskedAadhaar, '•••• •••• 4821');
    assert.strictEqual(verified.aadhaarNumber, undefined, 'Raw Aadhaar must not exist in user KYC store');
  });

  // --- TEST GROUP 3: Affirmative Consent & Adult Age Verification ---
  console.log('\n--- TEST GROUP 3: Affirmative Consent & Age Verification (Sec 6 & Sec 9) ---');

  await testAsync('UserModel stores consentGiven, consentTimestamp, and isAdult flags', async () => {
    const email = `dpdp_consent_${Date.now()}@example.com`;
    const user = await UserModel.create({
      email,
      name: 'Aditi Sharma',
      consentGiven: true,
      isAdult: true,
    });

    assert.strictEqual(user.consentGiven, true, 'User must record consentGiven as true');
    assert.strictEqual(user.isAdult, true, 'User must record isAdult flag');
    assert.ok(user.consentTimestamp, 'Consent timestamp must be recorded');
  });

  await testAsync('AuthService.getMe exposes affirmative consent metadata', async () => {
    const email = `dpdp_profile_${Date.now()}@example.com`;
    const user = await UserModel.create({
      email,
      name: 'Rohan Mehta',
      consentGiven: true,
      isAdult: true,
    });

    const profile = await AuthService.getMe(user.id);
    assert.strictEqual(profile.consentGiven, true);
    assert.strictEqual(profile.isAdult, true);
    assert.ok(profile.consentTimestamp);
  });

  // --- TEST GROUP 4: Cascading Right to Erasure ---
  console.log('\n--- TEST GROUP 4: Cascading Right to Erasure (Sec 12) ---');

  await testAsync('AuthService.deleteAccount purges cards, KYC identity, wallets, and OTP records', async () => {
    const email = `dpdp_erase_${Date.now()}@example.com`;
    const user = await UserModel.create({
      email,
      name: 'Devika Pillai',
      phone: '+919999988888',
      passwordHash: 'dummy_hash',
      isEmailVerified: true,
    });

    const userId = user.id;

    // 1. Seed auxiliary stores for user
    await CardModel.createCard({ userId, cardHolderName: 'Devika Pillai' });
    const aadhaarChallenge = KycIdentityModel.initiateAadhaarOtp(userId, '111122223333');
    KycIdentityModel.verifyAadhaarOtp(aadhaarChallenge.challengeId, '123456');
    MultiAssetWalletModel.getWallet(userId);
    await OtpModel.createOtp({ email, otpHash: 'sample_otp_hash', expiresAt: new Date(Date.now() + 60000) });

    // Verify data exists prior to deletion
    const cardsBefore = await CardModel.findByUserId(userId);
    assert.strictEqual(cardsBefore.length, 1);
    assert.ok(KycIdentityModel._kycStore.has(userId));

    // 2. Perform Account Erasure
    const deleteResult = await AuthService.deleteAccount(userId);
    assert.ok(deleteResult.message.includes('deleted successfully'));

    // 3. Verify auxiliary stores are scrubbed
    const cardsAfter = await CardModel.findByUserId(userId);
    assert.strictEqual(cardsAfter.length, 0, 'User cards must be completely purged');
    assert.strictEqual(KycIdentityModel._kycStore.has(userId), false, 'User KYC identity store must be deleted');
    assert.strictEqual(MultiAssetWalletModel._wallets.has(userId), false, 'User wallet must be deleted');

    // Verify OTP records for this email are purged
    const activeOtp = await OtpModel.getLatestActiveOtp(email);
    assert.strictEqual(activeOtp, null, 'Active OTPs for deleted user must be purged');
  });

  console.log('\n====================================================');
  console.log(`TEST SUMMARY: ${passed} Passed, ${failed} Failed`);
  console.log('====================================================');

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTests().catch((err) => {
  console.error('Fatal error running DPDP compliance tests:', err);
  process.exit(1);
});
