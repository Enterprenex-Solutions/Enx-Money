const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config/env.config');
const db = require('./config/db.config');
const apiRoutes = require('./routes');
const { notFoundHandler, errorHandler } = require('./middleware/error.middleware');
const idempotencyMiddleware = require('./middleware/idempotency.middleware');
const {
  getPrivacyPolicyHtml,
  getTermsHtml,
  getRefundPolicyHtml,
  getDeleteAccountHtml,
  getDataSafetyHtml,
  getPermissionsAuditHtml,
  getSdkAuditHtml,
  getSecurityAuditHtml,
  getContactUsHtml,
  getPricingHtml,
  getShippingDeliveryHtml,
} = require('./public_legal_pages');
const { getSaasLandingHtml } = require('./public_saas_landing');
const { getAdminDashboardHtml } = require('./public_admin_dashboard');
const { getWorkforcePortalHtml } = require('./public_workforce_portal');
const { getCompanyPortalHtml } = require('./public_company_portal');
const DownloadModel = require('./models/download.model');
const compression = require('compression');

const app = express();

// Enable trust proxy for reverse proxies (Render, Cloudflare, Nginx, AWS ALB/CloudFront)
app.set('trust proxy', 1);

// Automatic routing for portal.enterprenex.solutions subdomain
app.use((req, res, next) => {
  const host = (req.headers.host || '').toLowerCase();
  if (host.startsWith('portal.enterprenex.solutions') && !req.path.startsWith('/api')) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    return res.send(getCompanyPortalHtml());
  }
  next();
});

// Enable high-performance HTTP Gzip/Deflate compression for fast loading (<2s)
app.use(compression({ threshold: 1024 }));

// 1. Security Middleware with Razorpay CSP configuration
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: [
          "'self'",
          "'unsafe-inline'",
          "'unsafe-eval'",
          "'wasm-unsafe-eval'",
          'blob:',
          'https://checkout.razorpay.com',
          'https://*.razorpay.com',
          'https://cdn.jsdelivr.net',
          'https://www.gstatic.com',
          'https://fonts.gstatic.com',
        ],
        scriptSrcElem: [
          "'self'",
          "'unsafe-inline'",
          "'unsafe-eval'",
          "'wasm-unsafe-eval'",
          'blob:',
          'https://checkout.razorpay.com',
          'https://*.razorpay.com',
          'https://cdn.jsdelivr.net',
          'https://www.gstatic.com',
        ],
        scriptSrcAttr: ["'self'", "'unsafe-inline'"],
        workerSrc: ["'self'", 'blob:'],
        frameSrc: ["'self'", 'https://api.razorpay.com', 'https://*.razorpay.com'],
        connectSrc: [
          "'self'",
          'blob:',
          'data:',
          'https://api.razorpay.com',
          'https://*.razorpay.com',
          'https://lumberjack.razorpay.com',
          'https://lumberjack-cx.razorpay.com',
          'https://www.gstatic.com',
          'https://*.gstatic.com',
          'https://fonts.googleapis.com',
          'https://fonts.gstatic.com',
          'https://*.googleapis.com',
          'https://enxmoney.enterprenex.solutions',
          'https://enterprenex.solutions',
          'https://*.enterprenex.solutions',
          'https://enx-money-api.onrender.com',
        ],
        imgSrc: ["'self'", 'data:', 'blob:', 'https:', 'http:'],
        styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com', 'https://*.googleapis.com'],
        fontSrc: ["'self'", 'https://fonts.gstatic.com', 'https://*.gstatic.com', 'data:'],
      },
    },
    crossOriginEmbedderPolicy: false,
  })
);

// 2. CORS Configuration for Flutter Web, Mobile, Desktop & API clients
const allowedOrigins = (config.CORS_ORIGIN || '*')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile native apps, curl, Postman)
      if (!origin) return callback(null, true);

      // If wildcard is configured
      if (allowedOrigins.includes('*')) return callback(null, true);

      // Direct match
      if (allowedOrigins.includes(origin)) return callback(null, true);

      // Allow cloud, CloudFront, production domain and local dev ranges
      if (
        /^http:\/\/(localhost|127\.0\.0\.1|10\.0\.2\.2|192\.168\.\d+\.\d+)(:\d+)?$/.test(origin) ||
        /^https:\/\/.*\.onrender\.com$/.test(origin) ||
        /^https:\/\/.*\.cloudfront\.net$/.test(origin) ||
        /^https:\/\/(.*\.)?enxmoney\.com$/.test(origin) ||
        /^https:\/\/(.*\.)?enterprenex\.solutions$/.test(origin) ||
        /^https:\/\/enterprenex-solution-pvt-ltd\.github\.io$/.test(origin)
      ) {
        return callback(null, true);
      }

      callback(new Error(`CORS policy does not allow access from origin: ${origin}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'User-Agent',
      'Idempotency-Key',
      'idempotency-key',
      'X-Idempotency-Key',
      'x-idempotency-key',
    ],
  })
);

// 3. Request Parsers & Idempotency
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(idempotencyMiddleware);

// Automatic URL normalization: Rewrites legacy /api/api/ prefix to /api/
app.use((req, res, next) => {
  if (req.url.startsWith('/api/api/')) {
    req.url = req.url.replace('/api/api/', '/api/');
  }
  next();
});

// 4. Request Logging
if (config.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// 5. Deep Health Check Endpoints (Root & API Paths)
const healthHandler = async (req, res) => {
  let dbStatus = 'disconnected';
  try {
    if (db.isConnected()) {
      dbStatus = 'connected';
    } else {
      dbStatus = 'in-memory-resilience';
    }
  } catch (err) {
    dbStatus = 'error: ' + err.message;
  }

  const memoryUsage = process.memoryUsage();
  res.status(200).json({
    status: 'HEALTHY',
    service: 'ENX Money Auth & Business Backend',
    environment: config.NODE_ENV,
    version: '1.0.0',
    database: dbStatus,
    uptimeSeconds: Math.floor(process.uptime()),
    memory: {
      rssMb: Math.round(memoryUsage.rss / 1024 / 1024),
      heapUsedMb: Math.round(memoryUsage.heapUsed / 1024 / 1024),
    },
    timestamp: new Date().toISOString(),
  });
};

app.get(['/health', '/health/'], healthHandler);
app.get(['/api/health', '/api/health/'], healthHandler);
app.get(['/api/v1/health', '/api/v1/health/'], healthHandler);

app.get('/api', (req, res) => {
  res.status(200).json({
    message: 'Welcome to ENX Money API',
    version: '1.0.0',
    health: '/api/health',
    endpoints: {
      auth: {
        register: 'POST /api/auth/register',
        login: 'POST /api/auth/login',
        sendOtp: 'POST /api/auth/send-otp',
        resendOtp: 'POST /api/auth/resend-otp',
        verifyOtp: 'POST /api/auth/verify-otp',
        me: 'GET /api/auth/me',
        logout: 'POST /api/auth/logout',
      },
      business: {
        customers: '/api/customers',
        suppliers: '/api/suppliers',
        inventory: '/api/inventory',
        invoices: '/api/invoices',
        transactions: '/api/transactions',
        finance: '/api/finance',
        analytics: '/api/analytics',
      },
    },
  });
});

// Serve ENX Money Flutter Web Application at Root
app.get('/', (req, res) => {
  const flutterIndexPath = path.join(__dirname, '../public/index.html');
  if (fs.existsSync(flutterIndexPath)) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    return res.sendFile(flutterIndexPath);
  }
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getSaasLandingHtml());
});

// B2B SaaS Cloud Invoicing Landing Page (for Razorpay compliance / informational overview)
app.get(['/landing', '/saas', '/about-us'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getSaasLandingHtml());
});



// Direct APK download route
app.get('/apk', (req, res) => {
  res.redirect('/download-apk');
});

// Google Play Policy Public Legal Web Pages (Not PDFs - Required by Google Play)
app.get(['/privacy-policy', '/privacy', '/legal/privacy', '/settings/privacy-policy', '/api/privacy-policy', '/api/privacy'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getPrivacyPolicyHtml());
});

app.get(['/terms', '/terms-and-conditions', '/tos', '/legal/terms', '/settings/terms-conditions', '/settings/terms', '/api/terms', '/api/terms-and-conditions'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getTermsHtml());
});

app.get(['/refund-cancellation-policy', '/cancellation-policy', '/refund-policy', '/refunds', '/refund', '/legal/refund', '/settings/refund-policy', '/settings/refund-cancellation-policy', '/api/refund-cancellation-policy', '/api/refund-policy', '/api/refunds'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getRefundPolicyHtml());
});

app.get(['/contact', '/contact-us', '/support', '/customer-care', '/help-support'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getContactUsHtml());
});

app.get(['/pricing', '/plans', '/pricing-plans', '/subscriptions'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getPricingHtml());
});

app.get(['/shipping-delivery-policy', '/shipping-policy', '/delivery-policy', '/shipping'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getShippingDeliveryHtml());
});

app.get(['/delete-account', '/account-deletion', '/data-deletion', '/legal/delete-account', '/api/delete-account', '/api/account-deletion'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getDeleteAccountHtml());
});

app.get(['/data-safety', '/legal/data-safety', '/api/data-safety', '/datasafety'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getDataSafetyHtml());
});

app.get(['/permissions-audit', '/permissions', '/legal/permissions', '/api/permissions-audit', '/api/permissions'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getPermissionsAuditHtml());
});

app.get(['/sdk-audit', '/sdks', '/legal/sdk-audit', '/api/sdk-audit'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getSdkAuditHtml());
});

app.get(['/security-audit', '/security', '/legal/security-audit', '/api/security-audit'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getSecurityAuditHtml());
});

// Interactive Admin Analytics Dashboard Web Portal
app.get(['/admin', '/admin/dashboard', '/admin/analytics-portal'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getAdminDashboardHtml());
});

// Interactive Workforce & Task Management Portal (Internal HRMS & Work Delivery)
app.get(['/workforce', '/workforce/dashboard', '/hrms'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getWorkforcePortalHtml());
});

// Enterprenex Company Management Portal (Unified Single Login & RBAC Executive Dashboards)
app.get([
  '/portal',
  '/portal/*',
  '/company-portal',
  '/company-portal/*',
  '/enterprenex-portal',
], (req, res, next) => {
  if (req.path.startsWith('/portal/api') || req.path.startsWith('/api')) {
    return next();
  }
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(getCompanyPortalHtml());
});


// Direct Android APK Download Endpoints (with real-time download tracking)
app.get(['/download-apk', '/enx-money.apk', '/ENX-Money.apk', '/app-release.apk', '/api/download-apk'], (req, res) => {
  // Track download event
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
  const userAgent = req.headers['user-agent'] || '';
  DownloadModel.recordDownload({
    ipAddress: clientIp,
    userAgent,
    platform: 'Android APK',
    version: '1.0.0',
    channel: req.path,
  }).catch(() => {});

  const candidateApkPaths = [
    path.join(__dirname, '../public/ENX-Money.apk'),
    path.join(__dirname, '../public/app-release.apk'),
    path.join(__dirname, '../../client/build/app/outputs/flutter-apk/app-release.apk'),
    path.join(__dirname, '../ENX-Money.apk'),
    path.join(__dirname, '../../ENX-Money.apk'),
  ];
  for (const p of candidateApkPaths) {
    if (fs.existsSync(p)) {
      const stat = fs.statSync(p);
      res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      res.setHeader('Content-Length', stat.size);
      res.setHeader('Content-Disposition', 'attachment; filename="ENX-Money.apk"');
      res.setHeader('Access-Control-Allow-Origin', '*');
      return fs.createReadStream(p).pipe(res);
    }
  }
  res.status(404).json({ error: 'APK file not found on server' });
});

// Flavor-specific APK download routes
['consumer', 'merchant', 'field'].forEach((flavor) => {
  const flavorLabel = flavor === 'consumer' ? 'ENX Money' : flavor === 'merchant' ? 'ENX Money Merchant' : 'ENX Money Field';
  app.get([`/download-apk/${flavor}`, `/ENX-Money-${flavor.charAt(0).toUpperCase() + flavor.slice(1)}.apk`], (req, res) => {
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
    const userAgent = req.headers['user-agent'] || '';
    DownloadModel.recordDownload({
      ipAddress: clientIp,
      userAgent,
      platform: `Android APK (${flavorLabel})`,
      version: '1.0.0',
      channel: req.path,
    }).catch(() => {});

    const filename = `ENX-Money-${flavor.charAt(0).toUpperCase() + flavor.slice(1)}.apk`;
    const candidatePaths = [
      path.join(__dirname, `../public/${filename}`),
      path.join(__dirname, `../../client/build/app/outputs/flutter-apk/${filename}`),
      // fallback to generic consumer build
      path.join(__dirname, '../public/ENX-Money.apk'),
    ];
    for (const p of candidatePaths) {
      if (fs.existsSync(p)) {
        const stat = fs.statSync(p);
        res.setHeader('Content-Type', 'application/vnd.android.package-archive');
        res.setHeader('Content-Length', stat.size);
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.setHeader('Access-Control-Allow-Origin', '*');
        return fs.createReadStream(p).pipe(res);
      }
    }
    res.status(404).json({ error: `${flavorLabel} APK not found on server` });
  });
});

// Direct Android App Bundle (AAB / ABB) Download Endpoints (for Google Play Console submission)
app.get([
  '/download-aab', '/download-abb',
  '/enx-money.aab', '/enx-money.abb',
  '/ENX-Money.aab', '/ENX-Money.abb',
  '/app-release.aab', '/app-release.abb',
  '/api/download-aab', '/api/download-abb'
], (req, res) => {
  const isAbb = req.path.toLowerCase().endsWith('.abb') || req.path.toLowerCase().includes('abb');
  const filename = isAbb ? 'ENX-Money.abb' : 'ENX-Money.aab';
  const candidateAabPaths = [
    path.join(__dirname, '../../ENX-Money.aab'),
    path.join(__dirname, '../../ENX-Money.abb'),
    path.join(__dirname, '../ENX-Money.aab'),
    path.join(__dirname, '../ENX-Money.abb'),
    path.join(__dirname, '../public/ENX-Money.aab'),
    path.join(__dirname, '../public/ENX-Money.abb'),
    path.join(__dirname, '../../client/build/app/outputs/bundle/release/app-release.aab'),
    path.join(__dirname, '../../client/build/app/outputs/bundle/release/ENX-Money.aab'),
  ];
  for (const p of candidateAabPaths) {
    if (fs.existsSync(p)) {
      const stat = fs.statSync(p);
      res.setHeader('Content-Type', 'application/octet-stream');
      res.setHeader('Content-Length', stat.size);
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.setHeader('Access-Control-Allow-Origin', '*');
      return fs.createReadStream(p).pipe(res);
    }
  }
  res.status(404).json({ error: 'AAB/ABB bundle file not found on server' });
});

// ─── Interactive Financial Hub & WhatsApp Statements Portal ──────────────────
app.get(['/financial-hub', '/financial-portal', '/statement-hub', '/statements', '/khata-portal'], (req, res) => {
  const portalPath = path.join(__dirname, '../public', 'portal.html');
  if (fs.existsSync(portalPath)) {
    return res.sendFile(portalPath);
  }
  res.status(404).json({ error: 'Financial Hub Portal UI not found.' });
});

// ─── WhatsApp Official Chatbot Direct Redirect ──────────────────────────────
app.get(['/whatsapp', '/whatsapp-simulator', '/whatsapp-console', '/whatsapp-bot'], (req, res) => {
  return res.redirect(302, 'https://wa.me/919226860060?text=' + encodeURIComponent('Hi ENX Money AI Assistant'));
});

// ─── Razorpay Standard Web Checkout Portal ───────────────────────────────────
app.get(['/checkout', '/pay', '/razorpay-checkout', '/payment/checkout'], (req, res) => {
  const checkoutPath = path.join(__dirname, '../public', 'checkout.html');
  if (require('fs').existsSync(checkoutPath)) {
    return res.sendFile(checkoutPath);
  }
  res.status(404).json({ error: 'Checkout UI not found.' });
});

// ─── WhatsApp PDF Statement Serving ────────────────────────────────────────────
app.get(['/statements/:filename', '/api/v1/whatsapp/statement/:filename', '/api/whatsapp/statement/:filename'], (req, res) => {
  const filePath = path.join(__dirname, '../public/statements', path.basename(req.params.filename));
  if (fs.existsSync(filePath)) {
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="${path.basename(req.params.filename)}"`);
    return res.sendFile(filePath);
  }
  res.status(404).json({ error: 'Statement PDF not found or expired.' });
});

// 5.5 Serve static Flutter Web assets & public files from /public with aggressive caching for fast load
app.use(express.static(path.join(__dirname, '../public'), {
  index: false,
  maxAge: '7d',
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('.wasm')) {
      res.setHeader('Content-Type', 'application/wasm');
      res.setHeader('Cache-Control', 'public, max-age=604800, stale-while-revalidate=86400, immutable');
    } else if (filePath.endsWith('main.dart.js')) {
      res.setHeader('Cache-Control', 'public, max-age=86400, stale-while-revalidate=43200');
    } else if (
      filePath.endsWith('.woff') ||
      filePath.endsWith('.woff2') ||
      filePath.endsWith('.ttf') ||
      filePath.endsWith('.png') ||
      filePath.endsWith('.jpg') ||
      filePath.endsWith('.svg')
    ) {
      res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
    } else if (
      filePath.endsWith('.html') ||
      filePath.endsWith('.json') ||
      filePath.endsWith('flutter_bootstrap.js')
    ) {
      res.setHeader('Cache-Control', 'no-cache, must-revalidate');
    }
  },
}));

// 5.8 ZeroCarbonix EWMS Modular Monolith Phase 1 API
try {
  const { createApp: createEwmsApp } = require('./ewms/app');
  const ewmsApp = createEwmsApp();
  app.use('/api/v1', ewmsApp);
} catch (ewmsErr) {
  console.warn('[Server] EWMS API mount notice:', ewmsErr.message);
}

// 5.9 ZeroCarbonix EWMS Next.js Web Application
app.get([
  '/ewms',
  '/ewms/*',
  '/work-management',
  '/work-management/*',
  '/system',
  '/system/*'
], (req, res, next) => {
  if (req.path.startsWith('/api')) return next();
  const ewmsHtmlPath = path.join(__dirname, '../public/ewms/index.html');
  if (fs.existsSync(ewmsHtmlPath)) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    return res.sendFile(ewmsHtmlPath);
  }
  next();
});

// 6. Mount API routes (supports /api, /api/v1, /v1, /api/api and root endpoints)
app.use(['/api', '/api/v1', '/v1', '/api/api'], apiRoutes);
app.use(apiRoutes);

// ─── Web App & SPA Routing ───────────────────────────────────────────────────
app.get(['/app', '/app/*', '/web', '/web/*', '/login', '/dashboard', '/customers', '/transactions', '/inventory', '/settings'], (req, res, next) => {
  const appPath = path.join(__dirname, '../public/app.html');
  if (fs.existsSync(appPath)) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    return res.sendFile(appPath);
  }
  next();
});

// Root & Landing Page Fallback
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api') || req.path === '/health') {
    return next();
  }
  const landingIndexPath = path.join(__dirname, '../public/index.html');
  if (fs.existsSync(landingIndexPath)) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    return res.sendFile(landingIndexPath);
  }
  next();
});

// 7. 404 Handler & Global Error Handler
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
