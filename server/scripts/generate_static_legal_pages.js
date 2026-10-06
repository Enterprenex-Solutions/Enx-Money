/**
 * Static Legal Web Pages Pre-renderer
 * Generates standalone, Google Play Compliant HTML files directly into client/web
 * so they are immediately available for any static web host, CDN, or web server.
 */
const fs = require('fs');
const path = require('path');
const {
  getPrivacyPolicyHtml,
  getTermsHtml,
  getRefundPolicyHtml,
  getDeleteAccountHtml,
  getDataSafetyHtml,
  getPermissionsAuditHtml,
  getSdkAuditHtml,
  getSecurityAuditHtml,
} = require('../src/public_legal_pages');

const CLIENT_WEB_DIR = path.join(__dirname, '../../client/web');
const CLIENT_BUILD_WEB_DIR = path.join(__dirname, '../../client/build/web');
const SERVER_PUBLIC_DIR = path.join(__dirname, '../public');

const pages = [
  {
    name: 'privacy-policy',
    aliases: ['privacy', 'settings/privacy-policy'],
    html: getPrivacyPolicyHtml(),
  },
  {
    name: 'terms-and-conditions',
    aliases: ['terms', 'settings/terms-conditions', 'settings/terms'],
    html: getTermsHtml(),
  },
  {
    name: 'refund-cancellation-policy',
    aliases: ['refund-policy', 'refunds', 'settings/refund-policy', 'settings/refund-cancellation-policy'],
    html: getRefundPolicyHtml(),
  },
  {
    name: 'delete-account',
    aliases: ['account-deletion'],
    html: getDeleteAccountHtml(),
  },
  {
    name: 'data-safety',
    aliases: ['datasafety'],
    html: getDataSafetyHtml(),
  },
  {
    name: 'permissions-audit',
    aliases: ['permissions'],
    html: getPermissionsAuditHtml(),
  },
  {
    name: 'sdk-audit',
    aliases: ['sdks'],
    html: getSdkAuditHtml(),
  },
  {
    name: 'security-audit',
    aliases: ['security'],
    html: getSecurityAuditHtml(),
  },
];

function writePageToDir(targetDir, p) {
  if (!fs.existsSync(targetDir)) return;

  // 1. Direct file: /<name>.html
  const directFile = path.join(targetDir, `${p.name}.html`);
  fs.mkdirSync(path.dirname(directFile), { recursive: true });
  fs.writeFileSync(directFile, p.html, 'utf8');

  // 2. Directory index for clean SPA routing: /<name>/index.html
  const subDir = path.join(targetDir, p.name);
  if (!fs.existsSync(subDir)) {
    fs.mkdirSync(subDir, { recursive: true });
  }
  fs.writeFileSync(path.join(subDir, 'index.html'), p.html, 'utf8');

  // 3. Aliases
  for (const alias of p.aliases) {
    const aliasFile = path.join(targetDir, `${alias}.html`);
    fs.mkdirSync(path.dirname(aliasFile), { recursive: true });
    fs.writeFileSync(aliasFile, p.html, 'utf8');

    const aliasDir = path.join(targetDir, alias);
    if (!fs.existsSync(aliasDir)) {
      fs.mkdirSync(aliasDir, { recursive: true });
    }
    fs.writeFileSync(path.join(aliasDir, 'index.html'), p.html, 'utf8');
  }
}

console.log('Generating pre-rendered static legal pages...');
for (const p of pages) {
  writePageToDir(SERVER_PUBLIC_DIR, p);
  writePageToDir(CLIENT_WEB_DIR, p);
  if (fs.existsSync(CLIENT_BUILD_WEB_DIR)) {
    writePageToDir(CLIENT_BUILD_WEB_DIR, p);
  }
  console.log(`✔ Generated static page: /${p.name} (+ aliases: ${p.aliases.join(', ')})`);
}

console.log('All static legal pages generated successfully!');
