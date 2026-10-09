const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 8080;
const BACKEND_PORT = 5000;
const WEB_DIR = fs.existsSync(path.join(__dirname, 'landing', 'dist'))
  ? path.join(__dirname, 'landing', 'dist')
  : (fs.existsSync(path.join(__dirname, 'client', 'build', 'web'))
      ? path.join(__dirname, 'client', 'build', 'web')
      : path.join(__dirname, 'client', 'web'));

// Legal pages in-memory provider fallback
let legalPages = null;
try {
  legalPages = require('./server/src/public_legal_pages');
} catch (_) {}

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function getLocalIpAddress() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

const server = http.createServer((req, res) => {
  const cleanUrl = req.url.split('?')[0].toLowerCase();

  // Proxy API requests to backend
  if (req.url.startsWith('/api')) {
    const options = {
      hostname: '127.0.0.1',
      port: BACKEND_PORT,
      path: req.url,
      method: req.method,
      headers: req.headers,
    };

    const proxyReq = http.request(options, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res, { end: true });
    });

    proxyReq.on('error', (err) => {
      res.writeHead(502, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, message: 'Backend unavailable', error: err.message }));
    });

    req.pipe(proxyReq, { end: true });
    return;
  }

  // Handle direct Android APK download
  if (cleanUrl === '/download-apk' || cleanUrl === '/enx-money.apk' || cleanUrl === '/app-release.apk' || cleanUrl === '/app-debug.apk') {
    const candidateApkPaths = [
      path.join(__dirname, 'ENX-Money.apk'),
      path.join(__dirname, 'client', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
      path.join(WEB_DIR, 'ENX-Money.apk'),
      path.join(WEB_DIR, 'enx-money.apk'),
      path.join(__dirname, 'client', 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk'),
    ];

    let foundApk = null;
    for (const p of candidateApkPaths) {
      if (fs.existsSync(p)) {
        foundApk = p;
        break;
      }
    }

    if (foundApk) {
      const stat = fs.statSync(foundApk);
      res.writeHead(200, {
        'Content-Type': 'application/vnd.android.package-archive',
        'Content-Length': stat.size,
        'Content-Disposition': 'attachment; filename="ENX_Money.apk"',
        'Access-Control-Allow-Origin': '*',
      });
      fs.createReadStream(foundApk).pipe(res);
      return;
    }
  }

  // Handle direct Android AAB / ABB bundle download
  if (cleanUrl === '/download-aab' || cleanUrl === '/download-abb' ||
      cleanUrl === '/enx-money.aab' || cleanUrl === '/enx-money.abb' ||
      cleanUrl === '/enx_money.aab' || cleanUrl === '/enx_money.abb' ||
      cleanUrl === '/app-release.aab' || cleanUrl === '/app-release.abb') {
    const isAbb = cleanUrl.endsWith('.abb') || cleanUrl.includes('abb');
    const outName = isAbb ? 'ENX-Money.abb' : 'ENX-Money.aab';
    const candidateAabPaths = [
      path.join(__dirname, 'ENX-Money.aab'),
      path.join(__dirname, 'ENX-Money.abb'),
      path.join(__dirname, 'server', 'ENX-Money.aab'),
      path.join(__dirname, 'server', 'ENX-Money.abb'),
      path.join(__dirname, 'server', 'public', 'ENX-Money.aab'),
      path.join(__dirname, 'server', 'public', 'ENX-Money.abb'),
      path.join(__dirname, 'client', 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'),
      path.join(__dirname, 'client', 'build', 'app', 'outputs', 'bundle', 'release', 'ENX-Money.aab'),
    ];

    let foundAab = null;
    for (const p of candidateAabPaths) {
      if (fs.existsSync(p)) {
        foundAab = p;
        break;
      }
    }

    if (foundAab) {
      const stat = fs.statSync(foundAab);
      res.writeHead(200, {
        'Content-Type': 'application/octet-stream',
        'Content-Length': stat.size,
        'Content-Disposition': `attachment; filename="${outName}"`,
        'Access-Control-Allow-Origin': '*',
      });
      fs.createReadStream(foundAab).pipe(res);
      return;
    }
  }

  // Explicit Legal and Policy Routes (Non-PDF, Google Play Compliant)
  const legalRoutesMap = {
    '/privacy-policy': () => legalPages?.getPrivacyPolicyHtml(),
    '/privacy': () => legalPages?.getPrivacyPolicyHtml(),
    '/terms-and-conditions': () => legalPages?.getTermsHtml(),
    '/terms': () => legalPages?.getTermsHtml(),
    '/refund-cancellation-policy': () => legalPages?.getRefundPolicyHtml(),
    '/refund-policy': () => legalPages?.getRefundPolicyHtml(),
    '/refunds': () => legalPages?.getRefundPolicyHtml(),
    '/delete-account': () => legalPages?.getDeleteAccountHtml(),
    '/account-deletion': () => legalPages?.getDeleteAccountHtml(),
    '/data-safety': () => legalPages?.getDataSafetyHtml(),
    '/datasafety': () => legalPages?.getDataSafetyHtml(),
    '/permissions-audit': () => legalPages?.getPermissionsAuditHtml(),
    '/permissions': () => legalPages?.getPermissionsAuditHtml(),
    '/sdk-audit': () => legalPages?.getSdkAuditHtml(),
    '/sdks': () => legalPages?.getSdkAuditHtml(),
    '/security-audit': () => legalPages?.getSecurityAuditHtml(),
    '/security': () => legalPages?.getSecurityAuditHtml(),
  };

  if (legalRoutesMap[cleanUrl]) {
    // Check static file on disk first
    const diskCandidates = [
      path.join(WEB_DIR, `${cleanUrl}.html`),
      path.join(WEB_DIR, cleanUrl, 'index.html'),
      path.join(__dirname, 'client', 'web', `${cleanUrl}.html`),
      path.join(__dirname, 'client', 'web', cleanUrl, 'index.html'),
    ];

    for (const candidate of diskCandidates) {
      if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
        const content = fs.readFileSync(candidate, 'utf8');
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=3600',
        });
        res.end(content);
        return;
      }
    }

    // In-memory generation fallback
    const htmlGenerator = legalRoutesMap[cleanUrl];
    if (htmlGenerator) {
      const htmlContent = htmlGenerator();
      if (htmlContent) {
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=3600',
        });
        res.end(htmlContent);
        return;
      }
    }
  }

  // Serve static Flutter web files
  let reqPath = req.url.split('?')[0];
  if (reqPath === '/' || reqPath === '') {
    reqPath = '/index.html';
  }

  let filePath = path.join(WEB_DIR, reqPath);

  // If request points to a directory, check directory index.html
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    const dirIndex = path.join(filePath, 'index.html');
    if (fs.existsSync(dirIndex)) {
      filePath = dirIndex;
    }
  }

  // If path + .html exists (e.g. /privacy-policy.html), serve that
  if (!fs.existsSync(filePath) && fs.existsSync(`${filePath}.html`)) {
    filePath = `${filePath}.html`;
  }

  // Fallback to SPA index.html
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(WEB_DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('File Not Found');
    } else {
      res.writeHead(200, {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Cross-Origin-Opener-Policy': 'same-origin-allow-popups',
        'Cross-Origin-Embedder-Policy': 'unsafe-none',
      });
      res.end(content);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIpAddress();
  console.log('\n======================================================');
  console.log('🌐 ENX Money Web App Server Running!');
  console.log(`💻 Localhost (PC):   http://localhost:${PORT}`);
  console.log(`📱 Mobile (Wi-Fi):  http://${localIp}:${PORT}`);
  console.log(`📡 API Proxy:       http://localhost:${PORT}/api ➔ :${BACKEND_PORT}`);
  console.log('======================================================\n');
});
