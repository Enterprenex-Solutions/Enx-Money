const assert = require('assert');
const request = require('supertest');
const app = require('./src/app');
const OtpModel = require('./src/models/otp.model');
const bcrypt = require('bcryptjs');

async function testRegistrationAndCollisionFlow() {
  console.log('Testing Registration Flow and False 409 Collision Resolution...');

  const testEmail = `candidate_${Date.now()}@enterprenex.solutions`;
  const testPhone = `+919876${Math.floor(100000 + Math.random() * 900000)}`;

  // Step 1: Check availability prior to any verification -> 200 OK
  const check1 = await request(app)
    .post('/api/auth/check-registered')
    .send({ email: testEmail, phone: testPhone });
  assert.strictEqual(check1.statusCode, 200, 'Initial check must be 200');
  console.log('✔ Step 1: Initial check availability returns 200 OK');

  // Step 2: Inline email verification (generates user record without password)
  const otpCode = '123456';
  const hashedOtp = await bcrypt.hash(otpCode, 10);
  await OtpModel.createOtp({
    email: testEmail,
    otpHash: hashedOtp,
    purpose: 'REGISTRATION',
    expiresAt: new Date(Date.now() + 5 * 60 * 1000),
  });

  const verifyRes = await request(app)
    .post('/api/auth/verify-otp')
    .send({
      email: testEmail,
      otp: otpCode,
      purpose: 'REGISTRATION',
    });
  assert.strictEqual(verifyRes.statusCode, 200, 'Verify inline OTP must be 200');
  console.log('✔ Step 2: Inline email OTP verification returns 200 OK');

  // Step 3: Check availability for the same user with mobile number -> MUST BE 200 (NOT false 409!)
  const check2 = await request(app)
    .post('/api/auth/check-registered')
    .send({ email: testEmail, phone: testPhone });
  assert.strictEqual(check2.statusCode, 200, 'Post-email-verification check must be 200, no false 409');
  assert.strictEqual(check2.body.data.isRegistered, false, 'Should be marked available');
  console.log('✔ Step 3: Check availability after email verified returns 200 OK (no false 409!)');

  // Step 4: Register account -> MUST BE 200/201 OK
  const regRes = await request(app)
    .post('/api/auth/register')
    .send({
      name: 'Krishna Candidate',
      businessName: 'Krishna Enterprises',
      email: testEmail,
      phone: testPhone,
      password: 'SecurePassword@2026',
    });
  assert.strictEqual(regRes.statusCode, 201, 'Registration must succeed with 201');
  assert.strictEqual(regRes.body.data.email, testEmail);
  console.log('✔ Step 4: Account creation succeeds with 201 Created');

  // Step 5: Second user tries to use the same phone -> MUST BE 409 Conflict (true collision)
  const otherEmail = `other_${Date.now()}@enterprenex.solutions`;
  const check3 = await request(app)
    .post('/api/auth/check-registered')
    .send({ email: otherEmail, phone: testPhone });
  assert.strictEqual(check3.statusCode, 409, 'Duplicate phone check must be 409');
  assert.strictEqual(check3.body.data.field, 'phone', 'Collision field must be phone');
  console.log('✔ Step 5: True phone collision on another user returns 409 Conflict (field: phone)');

  console.log('\nAll 5 steps passed perfectly! False 409 mobile collision is completely resolved.');
}

testRegistrationAndCollisionFlow()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Test failed:', err);
    process.exit(1);
  });
