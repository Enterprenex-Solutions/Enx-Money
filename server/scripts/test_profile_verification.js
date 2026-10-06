const http = require('http');
const OtpService = require('../src/services/otp.service');

const BASE_URL = 'http://localhost:5000';

function makeRequest(path, method = 'GET', body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(
      url,
      { method, headers },
      (res) => {
        let raw = '';
        res.on('data', (chunk) => (raw += chunk));
        res.on('end', () => {
          let data = null;
          try {
            data = JSON.parse(raw);
          } catch (_) {
            data = raw;
          }
          resolve({ status: res.statusCode, body: data });
        });
      }
    );

    req.on('error', (err) => reject(err));
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ ASSERTION FAILED: ${message}`);
    process.exit(1);
  } else {
    console.log(`✅ ${message}`);
  }
}

async function runTest() {
  console.log('========================================================');
  console.log('🔍 TESTING REAL PROFILE VERIFICATION FLOW (BACKEND)');
  console.log('========================================================\n');

  const timestamp = Date.now();
  const testEmail = `user_verify_${timestamp}@enxmoney.test`;

  // 1. Register Account
  console.log('--- 1. Register Account ---');
  const regRes = await makeRequest('/api/auth/register', 'POST', {
    name: 'Krishna Rao',
    email: testEmail,
    password: 'Password123!',
    phone: `+9198${timestamp.toString().slice(-8)}`,
    businessName: 'Rao Enterprise',
  });
  if (regRes.status !== 200 && regRes.status !== 201) {
    console.error('Registration failed:', regRes.status, regRes.body);
  }
  assert(regRes.status === 200 || regRes.status === 201, `Account created for ${testEmail}`);
  const regData = regRes.body.data || regRes.body;
  const initialToken = regData.accessToken || regData.token;
  assert(initialToken, 'Access token received');
  assert(regData.user.isEmailVerified === false, 'Registration payload has isEmailVerified = false');
  assert(regData.user.kycTier === 'NOT VERIFIED', 'Registration payload has kycTier = NOT VERIFIED');

  // 2. Fetch /api/auth/me BEFORE OTP verification
  console.log('\n--- 2. Query /api/auth/me (Before OTP) ---');
  const meBefore = await makeRequest('/api/auth/me', 'GET', null, initialToken);
  assert(meBefore.status === 200, 'GET /api/auth/me succeeded');
  const meBeforeData = meBefore.body.data || meBefore.body;
  assert(meBeforeData.isEmailVerified === false, 'meBefore.isEmailVerified === false');
  assert(meBeforeData.kycTier === 'NOT VERIFIED', 'meBefore.kycTier === "NOT VERIFIED"');
  assert(meBeforeData.fullName === 'Krishna Rao', `meBefore.fullName === 'Krishna Rao' (got ${meBeforeData.fullName})`);

  // 3. Verify OTP
  console.log('\n--- 3. Verify OTP ---');
  const { rawOtp } = await OtpService.createAndStoreOtp(testEmail, 'AUTH');
  assert(rawOtp, `Retrieved generated OTP from server for verification: ${rawOtp}`);

  const verifyRes = await makeRequest('/api/auth/verify-otp', 'POST', {
    email: testEmail,
    otp: rawOtp,
    purpose: 'AUTH',
  });
  assert(verifyRes.status === 200, `verify-otp returned HTTP 200 (message: ${verifyRes.body.message || verifyRes.body.data?.message})`);
  const verifyData = verifyRes.body.data || verifyRes.body;
  const verifiedToken = verifyData.accessToken;
  assert(verifiedToken, 'Received verified session access token');
  assert(verifyData.user.isEmailVerified === true, 'verifyOtp user payload has isEmailVerified = true');
  assert(verifyData.user.kycTier === 'VERIFIED', 'verifyOtp user payload has kycTier = VERIFIED');

  // 4. Fetch /api/auth/me AFTER OTP verification
  console.log('\n--- 4. Query /api/auth/me (After OTP) ---');
  const meAfter = await makeRequest('/api/auth/me', 'GET', null, verifiedToken);
  assert(meAfter.status === 200, 'GET /api/auth/me succeeded after verification');
  const meAfterData = meAfter.body.data || meAfter.body;
  assert(meAfterData.isEmailVerified === true, 'meAfterData.isEmailVerified === true');
  assert(meAfterData.kycTier === 'VERIFIED', 'meAfterData.kycTier === "VERIFIED"');
  assert(meAfterData.kycStatus === 'VERIFIED', 'meAfterData.kycStatus === "VERIFIED"');
  assert(meAfterData.email === testEmail, `meAfterData.email === ${testEmail}`);

  // 5. Query /api/users/profile alias
  console.log('\n--- 5. Query /api/users/profile Alias ---');
  const profileAlias = await makeRequest('/api/users/profile', 'GET', null, verifiedToken);
  assert(profileAlias.status === 200, 'GET /api/users/profile succeeded');
  const profileData = profileAlias.body.data || profileAlias.body;
  assert(profileData.kycTier === 'VERIFIED', 'profileAlias.kycTier === "VERIFIED"');

  console.log('\n========================================================');
  console.log('🎉 REAL BACKEND VERIFICATION FLOW PASSED 100%!');
  console.log('========================================================');
}

runTest().catch((err) => {
  console.error('Fatal Verification Test Error:', err);
  process.exit(1);
});
