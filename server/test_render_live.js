const https = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { timeout: 15000 }, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    }).on('error', reject).on('timeout', () => reject(new Error('Timeout')));
  });
}

async function main() {
  const BASE = 'https://enx-money-api.onrender.com';

  console.log('=== Render Live Server Diagnostics ===\n');

  // 1. Health check
  console.log('[1] GET /health');
  try {
    const r = await get(BASE + '/health');
    console.log('   Status:', r.status);
    try { const j = JSON.parse(r.body); console.log('   Body:', JSON.stringify(j, null, 2)); }
    catch { console.log('   Body:', r.body.slice(0, 300)); }
  } catch (e) { console.log('   ERROR:', e.message); }

  // 2. Send OTP request (triggers SMTP on Render)
  console.log('\n[2] POST /api/auth/send-otp (triggers SMTP on Render server)');
  const testEmail = 'polamreddyrevanth.82@gmail.com';
  const payload = JSON.stringify({ email: testEmail, phone: '9876540001', purpose: 'REGISTRATION' });
  await new Promise((resolve) => {
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
        console.log('   Status:', res.statusCode);
        try { const j = JSON.parse(data); console.log('   Body:', JSON.stringify(j, null, 2)); }
        catch { console.log('   Body:', data.slice(0, 500)); }
        resolve();
      });
    });
    req.on('error', (e) => { console.log('   ERROR:', e.message); resolve(); });
    req.on('timeout', () => { console.log('   TIMEOUT'); req.destroy(); resolve(); });
    req.write(payload);
    req.end();
  });

  console.log('\n=== Done ===');
}

main();
