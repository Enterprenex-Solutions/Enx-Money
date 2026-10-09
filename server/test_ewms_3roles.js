const http = require('http');
const app = require('./src/app');

async function runTests() {
  console.log('--- TESTING EWMS PORTAL & 3 ROLES ---');
  const server = http.createServer(app);

  await new Promise(resolve => server.listen(0, resolve));
  const port = server.address().port;
  console.log(`Test server running on port ${port}`);

  function makeRequest(method, path, body = null) {
    return new Promise((resolve, reject) => {
      const postData = body ? JSON.stringify(body) : null;
      const options = {
        hostname: '127.0.0.1',
        port,
        path,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(postData ? { 'Content-Length': Buffer.byteLength(postData) } : {})
        }
      };

      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, data: JSON.parse(data), headers: res.headers });
          } catch (e) {
            resolve({ status: res.statusCode, text: data, headers: res.headers });
          }
        });
      });

      req.on('error', reject);
      if (postData) req.write(postData);
      req.end();
    });
  }

  try {
    // 1. Test GET /ewms/ HTML content
    console.log('\n[1] Checking GET /ewms/ HTML content:');
    let pageRes = await makeRequest('GET', '/ewms/');
    if (pageRes.status === 301 && pageRes.headers.location) {
      pageRes = await makeRequest('GET', pageRes.headers.location);
    }
    console.log(`Status: ${pageRes.status}`);
    const hasEnterprenex = pageRes.text && pageRes.text.includes('Enterprenex Solutions EWMS');
    const has3Roles = pageRes.text && pageRes.text.includes('Quick Role Switcher (3 Canonical Roles)');
    const hasDirector = pageRes.text && pageRes.text.includes('director@enterprenex.solutions');
    const hasManager = pageRes.text && pageRes.text.includes('manager@enterprenex.solutions');
    const hasEmployee = pageRes.text && pageRes.text.includes('employee@enterprenex.solutions');
    
    console.log(`- Contains 'Enterprenex Solutions EWMS': ${hasEnterprenex}`);
    console.log(`- Contains 'Quick Role Switcher (3 Canonical Roles)': ${has3Roles}`);
    console.log(`- Contains director@enterprenex.solutions: ${hasDirector}`);
    console.log(`- Contains manager@enterprenex.solutions: ${hasManager}`);
    console.log(`- Contains employee@enterprenex.solutions: ${hasEmployee}`);

    if (!hasEnterprenex || !has3Roles || !hasDirector || !hasManager || !hasEmployee) {
      throw new Error('GET /ewms verification failed!');
    }

    // 2. Test Login for DIRECTOR
    console.log('\n[2] Testing Auth Login for DIRECTOR:');
    const dirLogin = await makeRequest('POST', '/api/v1/auth/login', {
      email: 'director@enterprenex.solutions',
      password: 'Enterprenex@2026'
    });
    console.log(`Status: ${dirLogin.status}, Success: ${dirLogin.data && dirLogin.data.success}`);
    console.log(`Role: ${dirLogin.data?.data?.user?.role}, Name: ${dirLogin.data?.data?.user?.firstName} ${dirLogin.data?.data?.user?.lastName}`);
    if (dirLogin.status !== 200 || dirLogin.data?.data?.user?.role !== 'DIRECTOR') {
      throw new Error('DIRECTOR login failed');
    }

    // 3. Test Login for MANAGER
    console.log('\n[3] Testing Auth Login for MANAGER:');
    const mgrLogin = await makeRequest('POST', '/api/v1/auth/login', {
      email: 'manager@enterprenex.solutions',
      password: 'Enterprenex@2026'
    });
    console.log(`Status: ${mgrLogin.status}, Success: ${mgrLogin.data && mgrLogin.data.success}`);
    console.log(`Role: ${mgrLogin.data?.data?.user?.role}, Name: ${mgrLogin.data?.data?.user?.firstName} ${mgrLogin.data?.data?.user?.lastName}`);
    if (mgrLogin.status !== 200 || mgrLogin.data?.data?.user?.role !== 'MANAGER') {
      throw new Error('MANAGER login failed');
    }

    // 4. Test Login for EMPLOYEE
    console.log('\n[4] Testing Auth Login for EMPLOYEE:');
    const empLogin = await makeRequest('POST', '/api/v1/auth/login', {
      email: 'employee@enterprenex.solutions',
      password: 'Enterprenex@2026'
    });
    console.log(`Status: ${empLogin.status}, Success: ${empLogin.data && empLogin.data.success}`);
    console.log(`Role: ${empLogin.data?.data?.user?.role}, Name: ${empLogin.data?.data?.user?.firstName} ${empLogin.data?.data?.user?.lastName}`);
    if (empLogin.status !== 200 || empLogin.data?.data?.user?.role !== 'EMPLOYEE') {
      throw new Error('EMPLOYEE login failed');
    }

    console.log('\n>>> ALL EWMS 3-ROLE PORTAL TESTS PASSED PERFECTLY! <<<');
  } finally {
    server.close();
  }
}

runTests().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
