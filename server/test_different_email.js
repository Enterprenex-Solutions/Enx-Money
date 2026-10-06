const https = require('https');

async function testEmail(email) {
  const payload = JSON.stringify({ email, phone: '9876540002', purpose: 'REGISTRATION' });
  return new Promise((resolve) => {
    const req = https.request({
      hostname: 'enx-money-api.onrender.com',
      path: '/api/auth/send-otp',
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) },
      timeout: 30000,
    }, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on('error', (e) => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'TIMEOUT' }); });
    req.write(payload);
    req.end();
  });
}

async function run() {
  console.log('Testing send-otp with non-owner email...');
  const res = await testEmail('test_recipient_' + Date.now() + '@enxmoney.com');
  console.log('Response:', JSON.stringify(res, null, 2));
}

run();
