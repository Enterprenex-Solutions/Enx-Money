const AuthService = require('../src/services/auth.service');
const OtpService = require('../src/services/otp.service');
const OtpModel = require('../src/models/otp.model');

describe('E2E OTP Verification & Security Suite', () => {
  const testEmail = `e2etest_${Date.now()}@enxmoney.com`;
  let activeOtpCode;

  test('1. Registration triggers real OTP generation & storage', async () => {
    const regResult = await AuthService.register({
      name: 'Anjali Dhere',
      businessName: 'Dhere Enterprises',
      email: testEmail,
      phone: '9876543210',
      password: 'SecurePassword123!',
    });

    expect(regResult).toBeDefined();
    expect(regResult.requiresOtpVerification).toBe(true);

    const activeRecord = await OtpModel.getLatestActiveOtp(testEmail, 'AUTH');
    expect(activeRecord).toBeDefined();
    expect(activeRecord.attempts).toBe(0);
    expect(activeRecord.is_used).toBeFalsy();
  });

  test('2. Incorrect OTP code is rejected properly', async () => {
    await expect(
      AuthService.verifyOtp({ email: testEmail, otp: '000000' })
    ).rejects.toThrow('Invalid verification code');
  });

  test('3. Real OTP code verifies and generates access token', async () => {
    const { rawOtp } = await OtpService.createAndStoreOtp(testEmail, 'AUTH');
    activeOtpCode = rawOtp;

    const verifySuccess = await AuthService.verifyOtp({ email: testEmail, otp: activeOtpCode });
    expect(verifySuccess.message).toContain('verified');
    expect(verifySuccess.accessToken).toBeDefined();
  });

  test('4. Replay attack with same OTP is rejected (Single Use)', async () => {
    await expect(
      AuthService.verifyOtp({ email: testEmail, otp: activeOtpCode })
    ).rejects.toThrow('This verification code has already been used');
  });

  test('5. Atomic registration credentials in verifyOtp sets password, business, and verification status', async () => {
    const signupEmail = `atomic_${Date.now()}@enxmoney.com`;
    const signupPassword = 'StrongPassword99!';
    const { rawOtp } = await OtpService.createAndStoreOtp(signupEmail, 'AUTH');

    const result = await AuthService.verifyOtp({
      email: signupEmail,
      otp: rawOtp,
      name: 'Priya Sharma',
      businessName: 'Sharma Textiles',
      phone: '+919123456780',
      password: signupPassword,
    });

    expect(result.user).toBeDefined();
    expect(result.user.isEmailVerified).toBe(true);
    expect(result.user.kycTier).toBe('VERIFIED');
    expect(result.user.businessName).toBe('Sharma Textiles');
    expect(result.accessToken).toBeDefined();

    // Verify user can immediately log in with password
    const loginResult = await AuthService.loginWithPassword({
      identifier: signupEmail,
      password: signupPassword,
    });
    expect(loginResult.accessToken).toBeDefined();
    expect(loginResult.user.isEmailVerified).toBe(true);

    // Verify getMe confirms verified status
    const meResult = await AuthService.getMe(result.user.id);
    expect(meResult.isEmailVerified).toBe(true);
    expect(meResult.kycTier).toBe('VERIFIED');
  });

  test('6. Expired OTP returns clear expiration error', async () => {
    const expiredEmail = `expired_${Date.now()}@enxmoney.com`;
    await OtpModel.createOtp({
      email: expiredEmail,
      otpHash: await require('../src/utils/crypto.util').hashValue('123456'),
      purpose: 'AUTH',
      expiresAt: new Date(Date.now() - 1000), // Expired 1 second ago
    });

    await expect(
      AuthService.verifyOtp({ email: expiredEmail, otp: '123456' })
    ).rejects.toThrow('This verification code has expired');
  });
});
