/**
 * ENX Business Suite — B2B Invoicing, Billing & Digital Ledger Platform
 * Official Website for Enterprenex Solution Pvt Ltd
 * 100% Compliant with Razorpay Merchant Onboarding & Indian E-Commerce Rules
 */
const config = require('./config/env.config');

function getSaasLandingHtml() {
  const company = config.COMPANY_LEGAL_NAME || 'Enterprenex Solution Pvt Ltd';
  const supportEmail = config.SUPPORT_EMAIL || 'enxproductofficial@gmail.com';
  const phone = config.SUPPORT_PHONE || '+91 9226860060';
  const gstin = '27AARCP9260R1Z2';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ENX Business Suite — GST Billing, Invoicing & Digital Khata Services | Enterprenex Solution</title>
  <meta name="description" content="ENX Business Suite by Enterprenex Solution / Rohit Samadhan Pawar is an all-in-one business service for GST invoicing, inventory tracking, accounting, and digital khata ledgers.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090b10;
      --surface: #11141d;
      --surface-card: #161b26;
      --surface-border: #232b3b;
      --primary: #10b981;
      --primary-dark: #059669;
      --primary-light: #34d399;
      --accent: #3b82f6;
      --text: #f3f4f6;
      --text-muted: #9ca3af;
      --text-dim: #6b7280;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      line-height: 1.6;
      overflow-x: hidden;
    }
    h1, h2, h3, h4, .brand-text {
      font-family: 'Plus Jakarta Sans', sans-serif;
    }
    a { color: inherit; text-decoration: none; }
    
    /* Navbar */
    .navbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 18px 32px;
      background: rgba(17, 20, 29, 0.85);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--surface-border);
      position: sticky;
      top: 0;
      z-index: 100;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .brand-logo {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
      font-weight: 800;
      color: #fff;
      box-shadow: 0 4px 14px rgba(16,185,129,0.3);
    }
    .brand-name {
      font-size: 18px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -0.3px;
    }
    .brand-sub {
      font-size: 11px;
      color: var(--text-muted);
      display: block;
    }
    .nav-menu {
      display: flex;
      align-items: center;
      gap: 24px;
    }
    .nav-item {
      font-size: 14px;
      color: var(--text-muted);
      font-weight: 500;
      transition: color 0.2s;
    }
    .nav-item:hover { color: #fff; }
    .nav-cta {
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
      color: #fff;
      padding: 10px 20px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 700;
      box-shadow: 0 4px 15px rgba(16,185,129,0.3);
      transition: all 0.2s ease;
    }
    .nav-cta:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(16,185,129,0.4); }

    /* Container */
    .container {
      max-width: 1180px;
      margin: 0 auto;
      padding: 0 24px;
    }

    /* Hero Section */
    .hero {
      padding: 80px 0 60px;
      text-align: center;
      position: relative;
    }
    .hero::before {
      content: '';
      position: absolute;
      top: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 600px;
      height: 350px;
      background: radial-gradient(circle, rgba(16,185,129,0.12) 0%, transparent 70%);
      z-index: -1;
      pointer-events: none;
    }
    .badge-pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(16,185,129,0.1);
      border: 1px solid rgba(16,185,129,0.3);
      padding: 6px 16px;
      border-radius: 100px;
      font-size: 12px;
      font-weight: 600;
      color: var(--primary-light);
      margin-bottom: 24px;
    }
    .badge-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--primary);
      box-shadow: 0 0 10px var(--primary);
    }
    .hero h1 {
      font-size: 48px;
      font-weight: 800;
      line-height: 1.15;
      letter-spacing: -1px;
      margin-bottom: 20px;
      color: #fff;
    }
    .hero h1 span {
      background: linear-gradient(135deg, #fff 30%, var(--primary-light) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .hero-p {
      font-size: 18px;
      color: var(--text-muted);
      max-width: 760px;
      margin: 0 auto 36px;
      line-height: 1.6;
    }
    .hero-actions {
      display: flex;
      justify-content: center;
      gap: 16px;
      flex-wrap: wrap;
      margin-bottom: 40px;
    }
    .btn-primary {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
      color: #fff;
      padding: 15px 30px;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 700;
      box-shadow: 0 10px 25px rgba(16,185,129,0.35);
      transition: all 0.2s ease;
    }
    .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 15px 35px rgba(16,185,129,0.45); }
    .btn-secondary {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: var(--surface-card);
      border: 1px solid var(--surface-border);
      color: #fff;
      padding: 15px 28px;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 600;
      transition: all 0.2s ease;
    }
    .btn-secondary:hover { border-color: var(--primary); background: #1c2230; }

    /* Trust strip */
    .trust-strip {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 32px;
      flex-wrap: wrap;
      padding: 20px;
      background: rgba(22, 27, 38, 0.6);
      border: 1px solid var(--surface-border);
      border-radius: 16px;
      max-width: 920px;
      margin: 0 auto 60px;
    }
    .trust-item {
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 13px;
      color: #d1d5db;
    }
    .trust-icon { color: var(--primary); font-size: 16px; font-weight: 800; }

    /* Feature Grid */
    .section-title {
      text-align: center;
      margin-bottom: 48px;
    }
    .section-title h2 {
      font-size: 32px;
      font-weight: 800;
      color: #fff;
      margin-bottom: 12px;
    }
    .section-title p {
      font-size: 16px;
      color: var(--text-muted);
      max-width: 600px;
      margin: 0 auto;
    }
    .grid-3 {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 24px;
      margin-bottom: 80px;
    }
    .feature-card {
      background: var(--surface-card);
      border: 1px solid var(--surface-border);
      border-radius: 20px;
      padding: 32px;
      transition: all 0.2s ease;
    }
    .feature-card:hover {
      border-color: rgba(16,185,129,0.4);
      transform: translateY(-4px);
    }
    .feature-icon-box {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      background: rgba(16,185,129,0.12);
      border: 1px solid rgba(16,185,129,0.25);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      margin-bottom: 20px;
    }
    .feature-card h3 {
      font-size: 19px;
      font-weight: 700;
      color: #fff;
      margin-bottom: 10px;
    }
    .feature-card p {
      font-size: 14px;
      color: var(--text-muted);
      line-height: 1.6;
    }

    /* Web Platform Showcase */
    .showcase {
      background: linear-gradient(180deg, var(--surface-card) 0%, #0d1017 100%);
      border: 1px solid var(--surface-border);
      border-radius: 24px;
      padding: 48px;
      margin-bottom: 80px;
    }
    .showcase-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
      flex-wrap: wrap;
      gap: 20px;
    }
    .showcase-badges {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }
    .pill {
      background: #090b10;
      border: 1px solid var(--surface-border);
      padding: 6px 14px;
      border-radius: 100px;
      font-size: 12px;
      color: #d1d5db;
    }

    /* Pricing Section */
    .pricing-section {
      padding: 40px 0 80px;
    }
    .pricing-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 28px;
      max-width: 900px;
      margin: 0 auto;
    }
    .pricing-box {
      background: var(--surface-card);
      border: 1px solid var(--surface-border);
      border-radius: 24px;
      padding: 36px 32px;
      position: relative;
      display: flex;
      flex-direction: column;
    }
    .pricing-box.featured {
      border-color: var(--primary);
      box-shadow: 0 0 40px rgba(16,185,129,0.15);
    }
    .popular-tag {
      position: absolute;
      top: -12px;
      right: 28px;
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
      color: #fff;
      font-size: 11px;
      font-weight: 800;
      padding: 4px 14px;
      border-radius: 100px;
      letter-spacing: 0.5px;
    }
    .plan-name {
      font-size: 20px;
      font-weight: 800;
      color: #fff;
      margin-bottom: 8px;
    }
    .plan-desc {
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 24px;
      min-height: 40px;
    }
    .price-value {
      font-size: 40px;
      font-weight: 800;
      color: #fff;
      margin-bottom: 4px;
      font-family: 'Plus Jakarta Sans', sans-serif;
    }
    .price-period {
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 24px;
    }
    .plan-list {
      list-style: none;
      margin-bottom: 32px;
      flex-grow: 1;
    }
    .plan-list li {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 14px;
      color: #d1d5db;
      padding: 8px 0;
      border-bottom: 1px solid rgba(255,255,255,0.04);
    }
    .plan-list li:last-child { border-bottom: none; }
    .plan-list li span { color: var(--primary); font-weight: 800; }
    .btn-plan {
      display: block;
      text-align: center;
      padding: 14px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 700;
      transition: all 0.2s ease;
    }
    .btn-plan-primary {
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
      color: #fff;
      box-shadow: 0 8px 20px rgba(16,185,129,0.3);
    }
    .btn-plan-primary:hover { transform: translateY(-2px); box-shadow: 0 12px 25px rgba(16,185,129,0.4); }
    .btn-plan-outline {
      background: #11141d;
      border: 1px solid var(--surface-border);
      color: #fff;
    }
    .btn-plan-outline:hover { border-color: var(--primary); background: #181d29; }

    /* Corporate & Merchant Box */
    .company-box {
      background: var(--surface);
      border: 1px solid var(--surface-border);
      border-radius: 20px;
      padding: 32px;
      margin-bottom: 80px;
    }
    .company-box h3 {
      font-size: 18px;
      font-weight: 700;
      color: #fff;
      margin-bottom: 16px;
    }
    .company-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 20px;
      font-size: 13px;
    }
    .company-item strong {
      display: block;
      color: var(--text-muted);
      font-weight: 600;
      margin-bottom: 4px;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 0.5px;
    }
    .company-item span {
      color: #f3f4f6;
      font-weight: 500;
    }

    /* Footer */
    .footer {
      background: #07090d;
      border-top: 1px solid var(--surface-border);
      padding: 48px 0 32px;
    }
    .footer-grid {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr 1fr;
      gap: 32px;
      margin-bottom: 40px;
    }
    .footer-brand p {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 12px;
      max-width: 320px;
      line-height: 1.6;
    }
    .footer-col h4 {
      font-size: 13px;
      font-weight: 700;
      color: #fff;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 16px;
    }
    .footer-col ul { list-style: none; }
    .footer-col li { margin-bottom: 10px; }
    .footer-col a {
      font-size: 13px;
      color: var(--text-muted);
      transition: color 0.2s;
    }
    .footer-col a:hover { color: var(--primary-light); }
    .footer-bottom {
      border-top: 1px solid rgba(255,255,255,0.06);
      padding-top: 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      font-size: 12px;
      color: var(--text-dim);
    }

    @media (max-width: 768px) {
      .navbar { padding: 14px 20px; }
      .nav-menu { display: none; }
      .hero h1 { font-size: 32px; }
      .hero-p { font-size: 15px; }
      .footer-grid { grid-template-columns: 1fr; gap: 24px; }
    }
  </style>
</head>
<body>

  <!-- Navigation Bar -->
  <nav class="navbar">
    <div class="brand">
      <div class="brand-logo">E</div>
      <div>
        <span class="brand-name">ENX Business Suite</span>
        <span class="brand-sub">${company}</span>
      </div>
    </div>
    <div class="nav-menu">
      <a href="#features" class="nav-item">Features</a>
      <a href="#pricing" class="nav-item">Pricing</a>
      <a href="/checkout" class="nav-item">Web Checkout</a>
      <a href="/contact-us" class="nav-item">Contact</a>
      <a href="/privacy-policy" class="nav-item">Legal</a>
    </div>
    <a href="/checkout" class="nav-cta">Launch Checkout &rarr;</a>
  </nav>

  <!-- Hero Section -->
  <header class="hero">
    <div class="container">
      <div class="badge-pill">
        <span class="badge-dot"></span>
        Enterprise Business Accounting & GST Invoicing Suite
      </div>
      <h1>Smart Invoicing & Billing Services<br><span>Built for Growing Businesses</span></h1>
      <p class="hero-p">
        ENX Business Suite by <strong>${company}</strong> is a secure platform that simplifies GST billing, digital khata ledgers, stock tracking, and payment reconciliations for modern enterprises.
      </p>
      <div class="hero-actions">
        <a href="https://razorpay.me/@rohitsamadhanpawar4145" target="_blank" class="btn-primary">
          <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg>
          Pay via Official UPI / GPay
        </a>
        <a href="#pricing" class="btn-secondary">
          View Pricing & Plans
        </a>
      </div>

      <div class="trust-strip">
        <div class="trust-item"><span class="trust-icon">✓</span> 100% GST Tax Compliant</div>
        <div class="trust-item"><span class="trust-icon">✓</span> Instant Digital Service Activation</div>
        <div class="trust-item"><span class="trust-icon">✓</span> Razorpay 256-Bit SSL Encrypted</div>
        <div class="trust-item"><span class="trust-icon">✓</span> CIN & GST Registered Entity</div>
      </div>
    </div>
  </header>

  <main class="container">
    <!-- Features Grid -->
    <section id="features">
      <div class="section-title">
        <h2>Enterprise Features for Retail & Wholesale</h2>
        <p>Everything your business needs to manage customer billing, taxes, inventory, and accounts in one unified web portal.</p>
      </div>

      <div class="grid-3">
        <div class="feature-card">
          <div class="feature-icon-box">🧾</div>
          <h3>Automated GST Invoicing</h3>
          <p>Generate professional tax invoices, estimates, credit notes, and delivery challans in seconds. Compliant with current CGST, SGST, and IGST tax slabs with thermal and A4 print support.</p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">📖</div>
          <h3>Digital Customer Khata</h3>
          <p>Maintain accurate digital credit and debit ledgers for every customer and supplier. Send automated payment reminders with direct UPI payment links to expedite settlements.</p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">📦</div>
          <h3>Real-Time Inventory</h3>
          <p>Track stock levels across multiple warehouses or store counters in real time. Get automated low-stock alerts, manage batches, and prevent inventory discrepancies.</p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">📊</div>
          <h3>Tax-Ready Reports</h3>
          <p>One-click financial summaries for your chartered accountant. Generate GSTR-1, GSTR-3B ready reports, profit & loss statements, and balance sheets exportable to Excel and PDF.</p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">💳</div>
          <h3>Payment Gateway Integration</h3>
          <p>Seamlessly collect client payments via UPI, QR, Netbanking, and Debit/Credit cards powered by our official Razorpay checkout integration with instant digital receipts.</p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">👥</div>
          <h3>Multi-User Permissions</h3>
          <p>Empower your cashiers, store managers, and billing staff with strict role-based access control while safeguarding master ledger data and administrative settings.</p>
        </div>
      </div>
    </section>

    <!-- Platform Availability Notice -->
    <div class="showcase">
      <div class="showcase-header">
        <div>
          <h3 style="font-size: 22px; font-weight: 800; color: #fff; margin-bottom: 6px;">Unified Web Platform with Instant Access</h3>
          <p style="font-size: 14px; color: var(--text-muted);">Access your billing console from any desktop, tablet, or web browser with instant real-time synchronization.</p>
        </div>
        <div class="showcase-badges">
          <span class="pill">✓ Web Portal Live</span>
          <span class="pill">✓ Real-Time Synchronization</span>
          <span class="pill">📱 Mobile Companion App: Coming Soon to Google Play Store</span>
        </div>
      </div>
    </div>

    <!-- Pricing Section -->
    <section id="pricing" class="pricing-section">
      <div class="section-title">
        <h2>Simple, Transparent Pricing</h2>
        <p>No hidden setup fees. Instant digital activation upon payment authorization.</p>
      </div>

      <div class="pricing-cards">
        <!-- Monthly -->
        <div class="pricing-box">
          <div class="plan-name">Monthly Business Suite</div>
          <div class="plan-desc">Flexible month-to-month subscription for growing retail stores and SMEs.</div>
          <div class="price-value">₹1,999</div>
          <div class="price-period">+ 18% GST (Total: ₹2,358.82 / month)</div>
          <ul class="plan-list">
            <li><span>✓</span> Unlimited GST Invoices & Estimates</li>
            <li><span>✓</span> Customer & Supplier Digital Khata</li>
            <li><span>✓</span> Real-Time Stock & Warehouse Tracking</li>
            <li><span>✓</span> Payment Collection via Razorpay Gateway</li>
            <li><span>✓</span> WhatsApp Payment Reminder Integration</li>
            <li><span>✓</span> Instant Digital Account Activation</li>
          </ul>
          <a href="https://razorpay.me/@rohitsamadhanpawar4145" target="_blank" class="btn-plan btn-plan-outline">Pay ₹2,359 via Real UPI / GPay &rarr;</a>
        </div>

        <!-- Annual -->
        <div class="pricing-box featured">
          <div class="popular-tag">BEST VALUE (SAVE 17%)</div>
          <div class="plan-name">Annual Enterprise Suite</div>
          <div class="plan-desc">Comprehensive year-round billing, invoicing and bookkeeping services for established businesses.</div>
          <div class="price-value">₹19,999</div>
          <div class="price-period">+ 18% GST (Total: ₹23,598.82 / year)</div>
          <ul class="plan-list">
            <li><span>✓</span> Everything in Monthly Suite</li>
            <li><span>✓</span> Priority 24/7 Dedicated Support</li>
            <li><span>✓</span> Multi-Store & Multi-Counter Management</li>
            <li><span>✓</span> Automated Ledger Archiving & Export</li>
            <li><span>✓</span> Custom Branding & PDF Watermark Removal</li>
            <li><span>✓</span> Advanced Export to Excel, Tally & CSV</li>
          </ul>
          <a href="https://razorpay.me/@rohitsamadhanpawar4145" target="_blank" class="btn-plan btn-plan-primary">Pay ₹23,599 via Real UPI / GPay &rarr;</a>
        </div>
      </div>
    </section>

    <!-- Merchant Information Section (Mandatory for Razorpay Compliance) -->
    <section class="company-box">
      <h3>Official Merchant & Corporate Entity Details</h3>
      <div class="company-grid">
        <div class="company-item">
          <strong>Operating Entity / Authorized Proprietor</strong>
          <span>Rohit Samadhan Pawar (Trading as Enterprenex Solution)</span>
        </div>
        <div class="company-item">
          <strong>Registered Address</strong>
          <span>Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, MH 431136</span>
        </div>
        <div class="company-item">
          <strong>Business Category</strong>
          <span>Business Invoicing, GST Billing & Accounting Services</span>
        </div>
        <div class="company-item">
          <strong>Billing Email</strong>
          <span><a href="mailto:billing@enterprenex.solutions" style="color:var(--primary);">billing@enterprenex.solutions</a></span>
        </div>
        <div class="company-item">
          <strong>General / Legal Email</strong>
          <span><a href="mailto:info@enterprenex.solutions" style="color:var(--primary);">info@enterprenex.solutions</a></span>
        </div>
        <div class="company-item">
          <strong>Official Phone</strong>
          <span><a href="tel:+919226860060" style="color:var(--text);">${phone}</a> (Mon–Sat 9AM–6PM IST)</span>
        </div>
        <div class="company-item">
          <strong>WhatsApp Official Desk</strong>
          <span><a href="https://wa.me/919226860060" target="_blank" rel="noopener noreferrer" style="color:var(--primary);">+91 92268 60060</a></span>
        </div>
        <div class="company-item">
          <strong>Fulfillment Model</strong>
          <span>100% Instant Digital Service Activation</span>
        </div>
      </div>
    </section>
  </main>

  <!-- Compliance Footer -->
  <footer class="footer">
    <div class="container">
      <div class="footer-grid">
        <div class="footer-brand">
          <div class="brand">
            <div class="brand-logo">E</div>
            <div>
              <span class="brand-name">ENX Business Suite</span>
              <span class="brand-sub">${company}</span>
            </div>
          </div>
          <p>
            Enterprise business accounting, inventory, and GST invoicing services engineered for Indian businesses. Secure, scalable, and tax compliant.
          </p>
        </div>

        <div class="footer-col">
          <h4>Product & Service</h4>
          <ul>
            <li><a href="#features">Features</a></li>
            <li><a href="#pricing">Pricing Plans</a></li>
            <li><a href="/checkout">Web Checkout</a></li>
            <li><a href="/shipping-delivery-policy">Digital Fulfillment Policy</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Legal Policies</h4>
          <ul>
            <li><a href="/terms-and-conditions">Terms & Conditions</a></li>
            <li><a href="/privacy-policy">Privacy Policy</a></li>
            <li><a href="/refund-cancellation-policy">Refund & Cancellation</a></li>
            <li><a href="/shipping-delivery-policy">Shipping & Delivery</a></li>
            <li><a href="/pricing">Pricing Policy</a></li>
            <li><a href="/delete-account">Account Deletion</a></li>
          </ul>
        </div>

        <div class="footer-col" id="contact-us">
          <h4>Contact Us</h4>
          <ul>
            <li>WhatsApp: <a href="https://wa.me/919226860060" target="_blank" rel="noopener noreferrer" style="color:var(--primary);">+91 92268 60060</a></li>
            <li>Phone: <a href="tel:+919226860060" style="color:var(--text);">+91 9226860060</a></li>
            <li>Billing: <a href="mailto:billing@enterprenex.solutions" style="color:var(--primary);">billing@enterprenex.solutions</a></li>
            <li>General / Legal: <a href="mailto:info@enterprenex.solutions" style="color:var(--primary);">info@enterprenex.solutions</a></li>
          </ul>
          <h4 style="margin-top:16px;">Follow Us</h4>
          <ul>
            <li><a href="https://www.linkedin.com/company/enterprenex-solution-pvt-ltd" target="_blank" rel="noopener noreferrer">LinkedIn</a></li>
            <li><a href="https://www.instagram.com/enterprenexsolution?utm_source=ig_web_button_share_sheet&amp;stkn=ZDNlZDc0MzIxNw==" target="_blank" rel="noopener noreferrer">Instagram</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <div>&copy; 2026 ${company}. All rights reserved. Registered under Indian Companies Act.</div>
        <div>Payments securely processed via Razorpay 256-Bit SSL Encryption.</div>
      </div>
    </div>
  </footer>

</body>
</html>`;
}

module.exports = {
  getSaasLandingHtml,
};
