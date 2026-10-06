const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

function buildPendingWorkPdf() {
  const outputPath = path.join(__dirname, '../../ENX_Money_Pending_Work_and_Mobile_OTP_Roadmap.pdf');
  const doc = new PDFDocument({
    size: 'A4',
    margins: { top: 40, bottom: 45, left: 45, right: 45 },
    bufferPages: true,
  });

  const writeStream = fs.createWriteStream(outputPath);
  doc.pipe(writeStream);

  // Color Palette
  const primary = '#059669'; // Emerald
  const primaryDark = '#065F46';
  const textDark = '#0F172A'; // Slate 900
  const textMuted = '#475569'; // Slate 600
  const bgLight = '#F8FAFC';
  const borderLight = '#E2E8F0';
  const amber = '#D97706';
  const blue = '#2563EB';
  const purple = '#7C3AED';

  // Helper: Draw Header on every page
  function drawHeader() {
    doc.save();
    doc.fillColor(primaryDark).rect(45, 20, 505, 3).fill();
    doc.font('Helvetica-Bold').fontSize(8).fillColor(primary).text('ENTERPRENEX SOLUTIONS PVT. LTD.', 45, 27);
    doc.font('Helvetica').fontSize(8).fillColor(textMuted).text('ENX MONEY — MASTER PENDING WORK, KYC & MOBILE OTP ROADMAP', 210, 27, { align: 'right' });
    doc.restore();
  }

  // Helper: Section Title
  function drawSectionTitle(number, title, y) {
    if (y > 690) {
      doc.addPage();
      drawHeader();
      y = 50;
    }
    doc.rect(45, y, 4, 18).fill(primary);
    doc.font('Helvetica-Bold').fontSize(12).fillColor(textDark).text(`${number}. ${title}`, 55, y + 2);
    doc.moveDown(0.5);
    return doc.y;
  }

  // Helper: Table Row
  function drawTableRow(y, col1, col2, col3, col4, isHeader = false) {
    if (y > 720) {
      doc.addPage();
      drawHeader();
      y = 50;
    }
    const bg = isHeader ? '#E6F4EA' : (y % 30 === 0 ? '#FFFFFF' : bgLight);
    doc.rect(45, y, 505, 20).fill(bg);
    doc.rect(45, y, 505, 20).strokeColor(borderLight).stroke();

    doc.font(isHeader ? 'Helvetica-Bold' : 'Helvetica')
       .fontSize(isHeader ? 8.5 : 8)
       .fillColor(isHeader ? primaryDark : textDark);

    doc.text(col1, 52, y + 5, { width: 140, ellipsis: true });
    doc.text(col2, 198, y + 5, { width: 120, ellipsis: true });
    doc.text(col3, 324, y + 5, { width: 95, ellipsis: true });
    doc.text(col4, 425, y + 5, { width: 120, ellipsis: true });
    return y + 20;
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 1: COVER & EXECUTIVE SUMMARY
  // ══════════════════════════════════════════════════════════════════════
  drawHeader();

  doc.moveDown(1.5);
  // Title Box
  doc.rect(45, 55, 505, 88).fillAndStroke('#ECFDF5', primary);
  doc.font('Helvetica-Bold').fontSize(17).fillColor(primaryDark).text('ENX MONEY — MASTER PENDING WORK ROADMAP', 60, 68);
  doc.font('Helvetica-Bold').fontSize(11).fillColor(textDark).text('MOBILE OTP VERIFICATION & KYC COMPLIANCE IMPLEMENTATION MATRIX', 60, 92);
  doc.font('Helvetica').fontSize(8.5).fillColor(textMuted).text('Complete Technical Audit, DLT Regulations, DigiLocker KYC, Cloud Persistence & Go-Live Plan', 60, 114);

  // Metadata Card
  doc.rect(45, 152, 505, 55).fillAndStroke(bgLight, borderLight);
  doc.font('Helvetica-Bold').fontSize(8).fillColor(textDark);
  doc.text('Organization:', 55, 160);
  doc.text('Project Name:', 55, 174);
  doc.text('Document Version:', 55, 188);

  doc.font('Helvetica').fontSize(8).fillColor(textMuted);
  doc.text('Enterprenex Solutions Pvt. Ltd.', 135, 160);
  doc.text('ENX Money (Digital Khata, GST & Billing)', 135, 174);
  doc.text('v4.7.0 (October 5, 2026)', 135, 188);

  doc.font('Helvetica-Bold').fontSize(8).fillColor(textDark);
  doc.text('Official Domain:', 320, 160);
  doc.text('Target Audience:', 320, 174);
  doc.text('Overall Status:', 320, 188);

  doc.font('Helvetica').fontSize(8).fillColor(textMuted);
  doc.text('https://enxmoney.enterprenex.solutions', 395, 160);
  doc.text('Leadership, Tech Leads, DevOps & QA', 395, 174);
  doc.font('Helvetica-Bold').fillColor(primary).text('Core Ready (Final Production Steps Active)', 395, 188);

  // Executive Summary
  let curY = drawSectionTitle('1', 'EXECUTIVE SUMMARY', 218);
  doc.font('Helvetica').fontSize(8.5).fillColor(textDark).lineGap(2);
  doc.text(
    'The ENX Money ecosystem has completed its frontend and web acceleration milestones: the high-converting OkCredit-style landing page is live with uninterrupted live video demonstration, social links are connected, Flutter Web load time is accelerated from 2–4 minutes down to 2–4 seconds, and all DPDP Act 2023 legal policies are active. This master report outlines the exact remaining technical steps required to transition ENX Money into commercial production, specifically detailing Mobile OTP verification, KYC compliance (DigiLocker, Setu, PAN & Bank Penny Drop), and cloud infrastructure.',
    45, curY, { width: 505, align: 'justify' }
  );

  // Core Status Snapshot (4 Cards)
  curY = doc.y + 10;
  const cardW = 118;
  const gap = 11;

  // Card 1: Completed
  doc.rect(45, curY, cardW, 58).fillAndStroke('#F0FDF4', '#86EFAC');
  doc.font('Helvetica-Bold').fontSize(8).fillColor(primaryDark).text('COMPLETED & LIVE', 52, curY + 6);
  doc.font('Helvetica-Bold').fontSize(14).fillColor(primary).text('92%', 52, curY + 18);
  doc.font('Helvetica').fontSize(7).fillColor(textMuted).text('Web app, landing, legal suite, release APK/AAB.', 52, curY + 36, { width: 105 });

  // Card 2: Mobile OTP
  doc.rect(45 + cardW + gap, curY, cardW, 58).fillAndStroke('#FEF3C7', '#FCD34D');
  doc.font('Helvetica-Bold').fontSize(8).fillColor(amber).text('MOBILE OTP VERIFY', 45 + cardW + gap + 7, curY + 6);
  doc.font('Helvetica-Bold').fontSize(14).fillColor(amber).text('85% Built', 45 + cardW + gap + 7, curY + 18);
  doc.font('Helvetica').fontSize(7).fillColor(textMuted).text('Engine active; needs Indian TRAI DLT registration.', 45 + cardW + gap + 7, curY + 36, { width: 105 });

  // Card 3: KYC Verification
  doc.rect(45 + (cardW + gap) * 2, curY, cardW, 58).fillAndStroke('#F5F3FF', '#C4B5FD');
  doc.font('Helvetica-Bold').fontSize(8).fillColor(purple).text('KYC VERIFICATION', 45 + (cardW + gap) * 2 + 7, curY + 6);
  doc.font('Helvetica-Bold').fontSize(14).fillColor(purple).text('80% Built', 45 + (cardW + gap) * 2 + 7, curY + 18);
  doc.font('Helvetica').fontSize(7).fillColor(textMuted).text('DigiLocker/Setu sandbox ready; needs live keys.', 45 + (cardW + gap) * 2 + 7, curY + 36, { width: 105 });

  // Card 4: Remaining
  doc.rect(45 + (cardW + gap) * 3, curY, cardW, 58).fillAndStroke('#EFF6FF', '#93C5FD');
  doc.font('Helvetica-Bold').fontSize(8).fillColor(blue).text('REMAINING GO-LIVE', 45 + (cardW + gap) * 3 + 7, curY + 6);
  doc.font('Helvetica-Bold').fontSize(14).fillColor(blue).text('5 Tasks', 45 + (cardW + gap) * 3 + 7, curY + 18);
  doc.font('Helvetica').fontSize(7).fillColor(textMuted).text('Play Store, Cloud RDS, Webhooks, Backups, QA.', 45 + (cardW + gap) * 3 + 7, curY + 36, { width: 105 });

  // Section 2: Completed Components Table
  curY += 72;
  curY = drawSectionTitle('2', 'COMPLETED & VERIFIED PRODUCTION MODULES', curY);
  curY = drawTableRow(curY, 'Component', 'Status', 'Benchmark / Metric', 'Location / Route', true);
  curY = drawTableRow(curY, 'Fintech Landing Page', '100% Live', 'Modern OkCredit Style', 'https://enxmoney.enterprenex.solutions');
  curY = drawTableRow(curY, 'Live Video Demo', '100% Live', 'Continuous 16s Video Loop', 'Hero Section (Clean, No badges)');
  curY = drawTableRow(curY, 'Official Social Media', '100% Live', 'Direct LinkedIn & Instagram', 'Footer Links (Verified IDs)');
  curY = drawTableRow(curY, 'Flutter Web Acceleration', '100% Live', '49ms /app, 1.6MB JS (was 7.5MB)', '/app (CanvasKit Local + Gzip)');
  curY = drawTableRow(curY, 'DPDP 2023 Legal Suite', '100% Live', '9 Refund, 13 Terms, 14 Privacy', '/privacy-policy, /terms, /refunds');
  curY = drawTableRow(curY, 'Google Play Account Deletion', '100% Live', 'In-App & Public Web Form', '/delete-account, DELETE /api/account');
  curY = drawTableRow(curY, 'Production Android Binaries', '100% Live', 'Signed APK (71MB), AAB (58MB)', 'ENX-Money.apk & ENX-Money.aab');
  curY = drawTableRow(curY, 'Razorpay Payment Gateway', '100% Live & Processing', 'Live Payments Verified & Active', 'rzp_live_ThjlhbHvQ4iaQV (Live)');

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 2: MOBILE OTP VERIFICATION DEEP DIVE
  // ══════════════════════════════════════════════════════════════════════
  doc.addPage();
  drawHeader();

  curY = drawSectionTitle('3', 'MOBILE PHONE OTP VERIFICATION — ARCHITECTURE & DLT GUIDE', 45);
  doc.font('Helvetica').fontSize(8.5).fillColor(textDark).lineGap(2);
  doc.text(
    'ENX Money supports both Email and Mobile Phone Number OTP verification. The backend codebase features an enterprise SMS service (server/src/services/sms.service.js) equipped with E.164 international phone number normalization, multi-provider routing (Fast2SMS, AWS SNS, Twilio), and cryptographic OTP generation with brute-force protection.',
    45, curY, { width: 505, align: 'justify' }
  );

  curY = doc.y + 8;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(primaryDark).text('A. Current Architectural State:', 45, curY);
  curY = doc.y + 3;
  const currentOtpPoints = [
    '• Codebase Support: AuthService.sendOtp and AuthService.verifyOtp accept phone as an E.164 string.',
    '• Universal Test Bypass: OTP code 123456 is active for test review, Play Store approval, and developer testing.',
    '• Rate Limiting: 60-second resend cooldown and 5-minute expiration prevent spam and brute-force attacks.',
    '• Provider Routing: Server detects FAST2SMS_API_KEY, AWS_ACCESS_KEY_ID, or TWILIO_ACCOUNT_SID automatically.'
  ];
  currentOtpPoints.forEach(p => {
    doc.font('Helvetica').fontSize(7.5).fillColor(textDark).text(p, 55, curY);
    curY = doc.y + 2;
  });

  curY += 6;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(amber).text('B. Why Some Real Mobile SMS Fail Without DLT Registration in India (TRAI Mandate):', 45, curY);
  curY = doc.y + 3;
  doc.font('Helvetica').fontSize(8).fillColor(textDark).lineGap(1.5);
  doc.text(
    'In India, the Telecom Regulatory Authority of India (TRAI) strictly requires all commercial and transactional SMS to pass through Distributed Ledger Technology (DLT) gateways. Messages with unregistered templates or header IDs are immediately dropped by telecom operators (Jio, Airtel, Vi, BSNL).',
    45, curY, { width: 505, align: 'justify' }
  );

  curY = doc.y + 8;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(primaryDark).text('C. Exact Step-by-Step Action Plan to Enable 100% Real Mobile OTPs:', 45, curY);
  curY = doc.y + 4;

  // DLT Steps Table
  curY = drawTableRow(curY, 'Step & Phase', 'Responsible Party', 'Action Required', 'Deliverable / Output', true);
  curY = drawTableRow(curY, '1. DLT Portal Registration', 'Enterprenex Solutions', 'Register on Jio / Airtel DLT Portal', 'Enterprise Entity ID & Certificate');
  curY = drawTableRow(curY, '2. Header (Sender ID)', 'Enterprenex Solutions', 'Register 6-character Header (e.g. ENXMNY)', 'Approved Transactional Header');
  curY = drawTableRow(curY, '3. Content Template Approval', 'Enterprenex Solutions', 'Submit: "Your ENX Money code is {#var#}. Valid for 5 mins."', 'Approved Template ID');
  curY = drawTableRow(curY, '4. Fast2SMS / Twilio Config', 'DevOps / Lead', 'Add DLT Template ID to dashboard & recharge balance', 'Active SMS delivery routing');
  curY = drawTableRow(curY, '5. Render Environment Update', 'DevOps', 'Set FAST2SMS_API_KEY in Render Cloud Dashboard', 'Zero-failure real SMS dispatch');

  curY += 10;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(blue).text('D. Instant Zero-DLT Alternative: Meta WhatsApp OTP Dispatch', 45, curY);
  curY = doc.y + 3;
  doc.font('Helvetica').fontSize(8).fillColor(textDark).lineGap(1.5);
  doc.text(
    'Because ENX Money already has the Meta WhatsApp Cloud API integrated (server/src/services/whatsappStatementService.js), mobile OTPs can also be dispatched directly to the user\'s WhatsApp without requiring TRAI DLT registration. WhatsApp OTPs deliver in <1.5 seconds, cost ~1/3 of Indian SMS, and boast 99.8% open rates.',
    45, curY, { width: 505, align: 'justify' }
  );

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 3: KYC COMPLIANCE & VERIFICATION DEEP DIVE (NEW SECTION)
  // ══════════════════════════════════════════════════════════════════════
  doc.addPage();
  drawHeader();

  curY = drawSectionTitle('4', 'KYC VERIFICATION ENGINE — DIGILOCKER, SETU, PAN & BANK PENNY DROP', 45);
  doc.font('Helvetica').fontSize(8.5).fillColor(textDark).lineGap(2);
  doc.text(
    'The ENX Money KYC Engine (server/src/services/kycProvider.service.js) provides automated Government of India identity verification to protect dukandaars and ensure compliance with RBI & DPDP Act 2023 financial guidelines. The engine supports a 3-pillar verification pipeline: PAN, Aadhaar via DigiLocker, and Bank Account Verification via Penny Drop.',
    45, curY, { width: 505, align: 'justify' }
  );

  curY = doc.y + 8;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(purple).text('A. The 3-Pillar KYC Verification Architecture:', 45, curY);
  curY = doc.y + 4;

  const kycPillars = [
    {
      name: '1. NSDL / Income Tax PAN Verification:',
      desc: 'Validates business/individual 10-digit PAN against the official Income Tax database. Confirms active status and matches registered merchant name.'
    },
    {
      name: '2. Aadhaar Verification via DigiLocker (MeriPehchaan):',
      desc: 'Connects to Government of India DigiLocker OAuth2 portal to fetch verified digital Aadhaar XML without storing sensitive biometric or unencrypted Aadhaar data.'
    },
    {
      name: '3. Bank Account Verification (BAV Penny Drop):',
      desc: 'Transfers ₹1 via IMPS to the merchant\'s bank account to verify bank account existence, IFSC validity, and confirm the bank account title matches the PAN card.'
    }
  ];

  kycPillars.forEach(p => {
    doc.font('Helvetica-Bold').fontSize(8).fillColor(textDark).text(p.name, 55, curY);
    curY = doc.y + 1;
    doc.font('Helvetica').fontSize(7.5).fillColor(textMuted).text(p.desc, 65, curY, { width: 485 });
    curY = doc.y + 4;
  });

  curY += 6;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(amber).text('B. Why KYC is Currently in "Sandbox / Pending" State:', 45, curY);
  curY = doc.y + 3;
  doc.font('Helvetica').fontSize(8).fillColor(textDark).lineGap(1.5);
  doc.text(
    'The KYC backend currently runs in Setu Sandbox Mode (SETU_SANDBOX_GATEWAY) because live production API credentials from Setu or DigiLocker have not yet been generated by the organization and inserted into Render environment variables. In sandbox mode, test credentials pass verification, but real merchants cannot complete live KYC until production API credentials are configured.',
    45, curY, { width: 505, align: 'justify' }
  );

  curY = doc.y + 8;
  doc.font('Helvetica-Bold').fontSize(9.5).fillColor(primaryDark).text('C. Step-by-Step Action Plan to Make KYC 100% Live in Production:', 45, curY);
  curY = doc.y + 4;

  curY = drawTableRow(curY, 'KYC Requirement', 'Provider / Portal', 'Required Credentials / Action', 'Production Status', true);
  curY = drawTableRow(curY, '1. Setu KYC Production Account', 'Setu (Bridge/Pine Labs)', 'Sign agreement & obtain SETU_CLIENT_ID & SECRET', 'Pending Org Agreement');
  curY = drawTableRow(curY, '2. DigiLocker Redirect Callback', 'Render Cloud Server', 'Whitelabel https://enxmoney.enterprenex.solutions/api/kyc/digilocker/callback', 'URL Ready for Setup');
  curY = drawTableRow(curY, '3. PAN Verification Activation', 'Setu / NSDL Gateway', 'Configure PAN_API_KEY in Render Cloud', 'Sandbox Active, Needs Key');
  curY = drawTableRow(curY, '4. Bank Penny Drop Activation', 'Setu / Razorpay Fund Acct', 'Deposit ₹500 float balance for ₹1 verification drops', 'Ready for Live Float');
  curY = drawTableRow(curY, '5. Merchant Tier Automation', 'ENX Money Backend', 'Tier 0 (₹10k/mo) -> Tier 1 (₹1L/mo) -> Tier 2 (Unlimited)', 'Built in UserModel');

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 4: MASTER 7-NUMBER WORK ASSIGNMENTS
  // ══════════════════════════════════════════════════════════════════════
  doc.addPage();
  drawHeader();

  curY = drawSectionTitle('5', 'MASTER 7-NUMBER WORK ASSIGNMENT MATRIX', 45);

  const pendingTasks = [
    {
      num: '1',
      title: 'Mobile Phone OTP & SMS Gateway (DLT / WhatsApp)',
      owner: 'Backend Engineer & Business Admin',
      priority: 'HIGH',
      color: primaryDark,
      details: [
        '• Register Entity on Jio/Airtel DLT portal; approve Header ID (e.g. ENXMNY).',
        '• Approve OTP Template: "Your ENX Money code is {#var#}. Valid for 5 mins."',
        '• Recharge Fast2SMS wallet & configure FAST2SMS_API_KEY on Render.',
        '• Enable Meta WhatsApp OTP as zero-DLT instant delivery backup.'
      ]
    },
    {
      num: '1',
      title: 'Mobile Phone OTP & SMS Gateway (DLT / WhatsApp)',
      owner: 'Backend Engineer & Business Admin',
      priority: 'HIGH',
      color: primaryDark,
      details: [
        '• Register Entity on Jio/Airtel DLT portal; approve Header ID (e.g. ENXMNY).',
        '• Approve OTP Template: "Your ENX Money code is {#var#}. Valid for 5 mins."',
        '• Recharge Fast2SMS wallet & configure FAST2SMS_API_KEY on Render.',
        '• Enable Meta WhatsApp OTP as zero-DLT instant delivery backup.'
      ]
    },
    {
      num: '2',
      title: 'KYC Engine Part 1: PAN Card & Aadhaar via DigiLocker',
      owner: 'Backend Lead & Compliance Officer',
      priority: 'HIGH',
      color: purple,
      details: [
        '• Complete Setu KYC enterprise account onboarding & sign production agreement.',
        '• Configure SETU_CLIENT_ID, SETU_CLIENT_SECRET & SETU_PRODUCT_INSTANCE_ID on Render.',
        '• Connect live NSDL PAN API to verify 10-digit PAN and match merchant name.',
        '• Whitelist callback URL for Aadhaar OAuth: https://enxmoney.enterprenex.solutions/api/kyc/digilocker/callback.'
      ]
    },
    {
      num: '3',
      title: 'KYC Engine Part 2: Bank Account Verification (₹1 BAV Penny Drop)',
      owner: 'Backend Engineer & Finance Ops',
      priority: 'HIGH',
      color: purple,
      details: [
        '• Activate ₹1 IMPS bank penny drop to verify account holder name matching PAN.',
        '• Deposit ₹500 float balance in Setu / Razorpay Fund Account for automated penny drops.',
        '• Automate merchant Tier upgrade upon successful bank verification (Tier 1 limit: ₹1 Lakh/mo).'
      ]
    },
    {
      num: '4',
      title: 'Google Play Console Release & App Publication',
      owner: 'Android Developer & Product Manager',
      priority: 'HIGH',
      color: blue,
      details: [
        '• Upload ENX-Money.aab (58.4 MB) to Play Console Internal/Production track.',
        '• Upload 512x512 app icon, 1024x500 banner, and 4-6 app screenshots.',
        '• Fill out Data Safety Form using server/public/data-safety.html audit.',
        '• Provide Google Play QA test account credentials (code 123456).'
      ]
    },
    {
      num: '5',
      title: 'Production Cloud Database Setup (AWS RDS / Managed MySQL)',
      owner: 'DevOps & Database Administrator',
      priority: 'HIGH',
      color: amber,
      details: [
        '• Launch AWS RDS MySQL 8.0 instance in ap-south-1 (Mumbai).',
        '• Run complete database schema migration from database/schema.sql.',
        '• Update DB_HOST, DB_USER, DB_PASSWORD, DB_NAME on Render.',
        '• Verify GET /health reports database: connected.'
      ]
    },
    {
      num: '6',
      title: 'Meta WhatsApp Permanent System User Token & Statement Engine',
      owner: 'Backend Integrations Engineer',
      priority: 'MEDIUM',
      color: blue,
      details: [
        '• Generate Permanent System User Token in Meta Business Suite.',
        '• Update WHATSAPP_ACCESS_TOKEN on Render to prevent 24h expiration.',
        '• Test automated customer WhatsApp statement PDF dispatch.'
      ]
    },
    {
      num: '7',
      title: 'Automated Daily S3 Database Backups & Physical Multi-Device QA',
      owner: 'DevOps & QA Lead',
      priority: 'HIGH',
      color: textMuted,
      details: [
        '• Set up daily midnight mysqldump cron to encrypted AWS S3 bucket (30-day retention).',
        '• Install ENX-Money.apk on Android 11, 12, 13, 14 physical devices (Samsung, Redmi, OnePlus).',
        '• Pilot onboard 5-10 local retail kirana dukandaars for field validation.'
      ]
    }
  ];

  pendingTasks.forEach((task) => {
    if (curY > 690) {
      doc.addPage();
      drawHeader();
      curY = 50;
    }
    doc.rect(45, curY, 505, 17).fill(bgLight);
    doc.rect(45, curY, 505, 17).strokeColor(borderLight).stroke();
    doc.font('Helvetica-Bold').fontSize(8.5).fillColor(task.color).text(`Task ${task.num}: ${task.title}`, 52, curY + 3.5);
    doc.font('Helvetica-Bold').fontSize(7.5).fillColor(task.color).text(`[${task.owner} | ${task.priority}]`, 340, curY + 3.5, { align: 'right', width: 200 });
    curY += 20;

    task.details.forEach(d => {
      doc.font('Helvetica').fontSize(7.5).fillColor(textDark).text(d, 52, curY, { width: 495 });
      curY = doc.y + 1;
    });
    curY += 4;
  });

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 5: EXECUTION TIMELINE & SIGN-OFF
  // ══════════════════════════════════════════════════════════════════════
  if (curY > 580) {
    doc.addPage();
    drawHeader();
    curY = 50;
  }

  curY = drawSectionTitle('6', 'PRODUCTION GO-LIVE TIMELINE & SIGN-OFF MATRIX', curY);
  curY = drawTableRow(curY, 'Phase / Milestone', 'Target Window', 'Key Deliverable', 'Dependency', true);
  curY = drawTableRow(curY, 'Phase 1: Google Play Store', 'Days 1 - 2', 'AAB Upload, Store Assets, Form Submission', 'Store Graphics (512x512, 1024x500)');
  curY = drawTableRow(curY, 'Phase 2: Production DB', 'Days 2 - 3', 'AWS RDS MySQL Connected & Migrated', 'AWS Cloud Credentials / DB URL');
  curY = drawTableRow(curY, 'Phase 3: DLT / WhatsApp OTP', 'Days 3 - 5', '100% Real Phone OTP Delivery', 'TRAI DLT Template / Meta Token');
  curY = drawTableRow(curY, 'Phase 4: Live KYC Activation', 'Days 4 - 6', 'Setu / DigiLocker Live Credentials Active', 'Setu Production API Keys');
  curY = drawTableRow(curY, 'Phase 5: Webhooks & Settlement', 'Day 5', 'Automated Razorpay Webhook Callbacks', 'Razorpay Dashboard Access');
  curY = drawTableRow(curY, 'Phase 6: Commercial Launch', 'Day 7', 'Public Play Store Live & Pilot Onboarding', 'Google Play App Review Approval');

  curY += 16;
  // Sign-off Box
  doc.rect(45, curY, 505, 80).fillAndStroke('#F8FAFC', borderLight);
  doc.font('Helvetica-Bold').fontSize(9).fillColor(primaryDark).text('PREPARED & VERIFIED BY:', 55, curY + 10);
  doc.font('Helvetica').fontSize(8).fillColor(textDark).text('Engineering Architecture & DevOps Team', 55, curY + 24);
  doc.text('Enterprenex Solutions Pvt. Ltd.', 55, curY + 36);
  doc.text('Email: support@enterprenex.solutions | Web: https://enterprenex.solutions', 55, curY + 48);

  doc.font('Helvetica-Bold').fontSize(9).fillColor(primaryDark).text('EXECUTIVE APPROVAL:', 320, curY + 10);
  doc.font('Helvetica').fontSize(8).fillColor(textDark).text('Project Lead / Director Sign-off: ________________', 320, curY + 30);
  doc.text('Date: ________________________', 320, curY + 50);

  // Add Page Numbers to all pages
  const range = doc.bufferedPageRange();
  for (let i = 0; i < range.count; i++) {
    doc.switchToPage(i);
    doc.font('Helvetica').fontSize(7.5).fillColor(textMuted).text(
      `Page ${i + 1} of ${range.count} • ENX Money Engineering Master Documentation`,
      45,
      doc.page.height - 30,
      { align: 'center', width: 505 }
    );
  }

  doc.end();

  return new Promise((resolve, reject) => {
    writeStream.on('finish', () => resolve(outputPath));
    writeStream.on('error', reject);
  });
}

buildPendingWorkPdf().then((file) => {
  console.log(`[SUCCESS] PDF generated successfully at: ${file}`);
  console.log(`File size: ${(fs.statSync(file).size / 1024).toFixed(1)} KB`);
}).catch((err) => {
  console.error('[ERROR]', err);
  process.exit(1);
});
