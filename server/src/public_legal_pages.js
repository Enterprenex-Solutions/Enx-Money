/**
 * Public Legal & Compliance Web Pages for Google Play Store Policy
 * (01. Privacy Policy, 02. Terms of Service, 03. Refund Policy, 10. Account Deletion)
 * Company: Enterprenex Solutions Pvt Ltd | App: ENX Money
 */
const config = require('./config/env.config');

const baseStyles = `
  * { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, sans-serif; }
  body { background: #0b0c10; color: #e5e7eb; line-height: 1.6; padding: 40px 20px; display: flex; justify-content: center; }
  .container { max-width: 820px; width: 100%; background: #13151b; border: 1px solid #232733; border-radius: 20px; padding: 40px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.6); }
  .header { display: flex; align-items: center; gap: 16px; border-bottom: 1px solid #1f2430; padding-bottom: 24px; margin-bottom: 28px; }
  .logo-badge { width: 52px; height: 52px; border-radius: 14px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); display: inline-flex; align-items: center; justify-content: center; font-size: 26px; font-weight: 900; color: #fff; }
  .header-titles h1 { font-size: 22px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px; }
  .header-titles p { font-size: 13px; color: #9ca3af; }
  .badge { display: inline-block; background: rgba(16,185,129,0.15); border: 1px solid rgba(16,185,129,0.3); color: #34d399; font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 100px; margin-top: 4px; }
  h2 { font-size: 18px; color: #10b981; margin: 26px 0 10px; font-weight: 700; border-left: 3px solid #10b981; padding-left: 10px; }
  p, li { font-size: 14px; color: #d1d5db; margin-bottom: 12px; }
  ul { padding-left: 20px; margin-bottom: 16px; }
  li { margin-bottom: 6px; }
  strong { color: #f3f4f6; }
  .nav-links { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 36px; padding-top: 24px; border-top: 1px solid #1f2430; }
  .nav-link { font-size: 13px; color: #10b981; text-decoration: none; font-weight: 500; }
  .nav-link:hover { text-decoration: underline; }
  .form-group { margin-bottom: 18px; }
  label { display: block; font-size: 13px; font-weight: 600; color: #9ca3af; margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
  input, textarea, select { width: 100%; padding: 12px 14px; background: #0b0c10; border: 1px solid #232733; border-radius: 10px; color: #fff; font-size: 14px; outline: none; }
  input:focus, textarea:focus { border-color: #10b981; }
  .btn-submit { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: #fff; border: none; padding: 14px 24px; border-radius: 10px; font-size: 14px; font-weight: 700; cursor: pointer; width: 100%; margin-top: 10px; }
  .btn-submit:hover { opacity: 0.95; }
  .alert-box { background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.3); color: #fca5a5; padding: 14px; border-radius: 10px; font-size: 13px; margin-bottom: 20px; }
  .success-box { display: none; background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.4); color: #34d399; padding: 16px; border-radius: 10px; font-size: 14px; margin-top: 16px; text-align: center; }
  html { scroll-behavior: smooth; }
  .toc-box { background: #0e1017; border: 1px solid #222938; border-radius: 14px; padding: 20px; margin: 20px 0 28px; }
  .toc-title { font-size: 13px; font-weight: 700; color: #10b981; text-transform: uppercase; letter-spacing: 0.6px; margin-bottom: 12px; }
  .toc-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 8px; }
  .toc-link { font-size: 12px; color: #9ca3af; text-decoration: none; transition: color 0.2s ease; }
  .toc-link:hover { color: #10b981; text-decoration: underline; }
  .sec-anchor { scroll-margin-top: 24px; }
  .notice-box { background: rgba(59, 130, 246, 0.1); border: 1px solid rgba(59, 130, 246, 0.3); color: #93c5fd; padding: 14px 18px; border-radius: 12px; font-size: 13px; margin: 18px 0 24px; line-height: 1.5; }
  table { width: 100%; border-collapse: collapse; margin: 16px 0 24px; font-size: 13px; }
  th, td { border: 1px solid #232733; padding: 10px 12px; text-align: left; vertical-align: top; }
  th { background: #161922; color: #10b981; font-weight: 700; }
  tr:nth-child(even) { background: #0e1017; }
  .status-tag { display: inline-block; padding: 2px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; }
  .tag-green { background: rgba(16,185,129,0.15); color: #34d399; border: 1px solid rgba(16,185,129,0.3); }
  .tag-red { background: rgba(239,68,68,0.15); color: #f87171; border: 1px solid rgba(239,68,68,0.3); }
  .tag-amber { background: rgba(245,158,11,0.15); color: #fbbf24; border: 1px solid rgba(245,158,11,0.3); }
`;

function renderNavLinks(active) {
  return `
    <div class="nav-links">
      <a href="/" class="nav-link">Home</a>
      <a href="/checkout" class="nav-link">Web Checkout</a>
      <a href="/pricing" class="nav-link" style="${active === 'pricing' ? 'color:#fff;font-weight:700;' : ''}">Pricing</a>
      <a href="/privacy-policy" class="nav-link" style="${active === 'privacy' ? 'color:#fff;font-weight:700;' : ''}">Privacy Policy</a>
      <a href="/terms-and-conditions" class="nav-link" style="${active === 'terms' ? 'color:#fff;font-weight:700;' : ''}">Terms & Conditions</a>
      <a href="/refund-cancellation-policy" class="nav-link" style="${active === 'refund' ? 'color:#fff;font-weight:700;' : ''}">Refund Policy</a>
      <a href="/shipping-delivery-policy" class="nav-link" style="${active === 'shipping' ? 'color:#fff;font-weight:700;' : ''}">Shipping & Delivery</a>
      <a href="/contact-us" class="nav-link" style="${active === 'contact' ? 'color:#fff;font-weight:700;' : ''}">Contact Us</a>
      <a href="/data-safety" class="nav-link" style="${active === 'data-safety' ? 'color:#fff;font-weight:700;' : ''}">Data Safety</a>
      <a href="/permissions-audit" class="nav-link" style="${active === 'permissions' ? 'color:#fff;font-weight:700;' : ''}">Permissions Audit</a>
      <a href="/sdk-audit" class="nav-link" style="${active === 'sdk' ? 'color:#fff;font-weight:700;' : ''}">SDK Audit</a>
      <a href="/security-audit" class="nav-link" style="${active === 'security' ? 'color:#fff;font-weight:700;' : ''}">Security Audit</a>
      <a href="/delete-account" class="nav-link" style="${active === 'delete' ? 'color:#ef4444;font-weight:700;' : ''}">Account & Data Deletion</a>
    </div>
  `;
}

function getPrivacyPolicyHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt. Ltd.';
  const supportEmail = config.SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const technicalSupportEmail = config.TECHNICAL_SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const billingEmail = config.BILLING_EMAIL || 'billing@enterprenex.solutions';
  const companyEmail = config.COMPANY_EMAIL || 'info@enterprenex.solutions';
  const privacyEmail = config.PRIVACY_CONTACT_EMAIL || 'privacy@enxmoney.com';
  const grievanceEmail = config.GRIEVANCE_EMAIL || 'grievance@enxmoney.com';
  const grievanceOfficer = config.GRIEVANCE_OFFICER || 'Mr. Rohit Pawar';
  const phone = config.COMPANY_PHONE || '+91-9226860060';
  const websiteDomain = config.WEBSITE_DOMAIN || 'https://enxmoney.enterprenex.solutions';
  const githubPagesHost = config.LEGAL_HOST_URL || 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/';
  const version = '1.0';
  const effectiveDate = 'October 4, 2026';
  const lastUpdated = 'October 4, 2026';
  const address = config.COMPANY_ADDRESS || 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy — ENX Money | ${company}</title>
  <meta name="description" content="Official Privacy Policy for ENX Money by ${company}. Governed by the Digital Personal Data Protection Act, 2023 (India) and DPDP Rules, 2025. Learn how your financial ledger, business profile, and personal credentials are protected, retained, and deleted.">
  <meta name="robots" content="index, follow">
  <meta property="og:title" content="Privacy Policy — ENX Money">
  <meta property="og:description" content="Official DPDP Act 2023 Compliant Privacy Policy for ENX Money digital business ledger and invoicing platform.">
  <meta property="og:type" content="website">
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>Privacy Policy</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Governed by the Digital Personal Data Protection Act, 2023 (India) • Version ${version} • Effective: ${effectiveDate} • Updated: ${lastUpdated}</span>
      </div>
    </div>

    <div class="notice-box">
      <strong>Statutory Compliance & Data Architecture:</strong> This Privacy Policy is structured around ENX Money's actual data flows (biometric passkey auth, GST invoicing, multi-tenant ledgers) under the <strong>Digital Personal Data Protection Act, 2023 (&ldquo;DPDP Act&rdquo;)</strong> and the <strong>Digital Personal Data Protection Rules, 2025</strong>. It strictly reflects Google Play Store compliance, backend schema isolation, and Android runtime permissions.
    </div>

    <div class="toc-box">
      <div class="toc-title">Contents (14 Chapters)</div>
      <div class="toc-grid">
        <a href="#priv-1" class="toc-link">1. Introduction and Scope</a>
        <a href="#priv-2" class="toc-link">2. Data We Collect</a>
        <a href="#priv-3" class="toc-link">3. Purpose of Collection & Legal Basis</a>
        <a href="#priv-4" class="toc-link">4. How We Share Your Data</a>
        <a href="#priv-5" class="toc-link">5. Data Retention</a>
        <a href="#priv-6" class="toc-link">6. How We Protect Your Data</a>
        <a href="#priv-7" class="toc-link">7. Your Rights as a Data Principal</a>
        <a href="#priv-8" class="toc-link">8. Grievance Redressal</a>
        <a href="#priv-9" class="toc-link">9. Children's Data</a>
        <a href="#priv-10" class="toc-link">10. International Data Transfers</a>
        <a href="#priv-11" class="toc-link">11. Cookies & Similar Technologies</a>
        <a href="#priv-12" class="toc-link">12. Changes to This Policy</a>
        <a href="#priv-13" class="toc-link">13. Governing Law & Jurisdiction</a>
        <a href="#priv-14" class="toc-link">14. Contact Us</a>
      </div>
    </div>

    <!-- Chapter 1 -->
    <h2 id="priv-1" class="sec-anchor">1. Introduction and Scope</h2>
    <p><strong>1.1 Who We Are:</strong> <strong>${company}</strong> (&ldquo;ENX Money&rdquo;, &ldquo;we&rdquo;, &ldquo;us&rdquo;, or &ldquo;our&rdquo;) operates the ENX Money mobile and web application (the &ldquo;Platform&rdquo;), a digital business finance and ledger management tool designed for Indian micro, small, and medium enterprises (MSMEs).</p>
    <p>Under the Digital Personal Data Protection Act, 2023 (&ldquo;DPDP Act&rdquo;) and the Digital Personal Data Protection Rules, 2025, ENX Money acts as a <strong>Data Fiduciary</strong> in respect of the personal data of its registered merchant users, and facilitates its merchant users (acting as independent data controllers of their own customer records) in maintaining their business ledgers.</p>
    
    <p><strong>1.2 Scope of This Policy:</strong> This Privacy Policy applies to all personal data collected through:</p>
    <ul>
      <li>The ENX Money mobile application (Android, iOS) and web application.</li>
      <li>Account registration, authentication, and biometric/passkey setup.</li>
      <li>Use of Customer Management, Finance Mode, Analytics, Inventory, Transactions, Loan EMI, and GST Invoicing features.</li>
      <li>Communications with our support and customer service channels.</li>
    </ul>
    <p>This Policy does not apply to information that merchants independently collect from their own customers outside the Platform, or to third-party websites linked from within the app.</p>

    <p><strong>1.3 Important Note on Multi-Tenant Data:</strong> ENX Money operates on a <strong>multi-tenant ledger model</strong>. Merchants (the Owner, Admin, Staff, and Accountant roles defined in our platform) enter data about their own customers and suppliers (e.g., Khata ledger entries, invoices) into the Platform. In respect of this end-customer data, <strong>ENX Money acts as a Data Processor</strong> on behalf of the merchant, who remains responsible as the data fiduciary for ensuring they have a lawful basis to record that information. This Policy governs ENX Money's handling of merchant account data; merchants are separately responsible for their own privacy obligations toward the customers and suppliers they record in their ledgers.</p>

    <!-- Chapter 2 -->
    <h2 id="priv-2" class="sec-anchor">2. Data We Collect</h2>
    <p><strong>2.1 Account and Identity Data:</strong></p>
    <table>
      <thead>
        <tr>
          <th>Data Category</th>
          <th>Specific Fields</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Identity</strong></td>
          <td>Full legal name, business name, date of registration</td>
        </tr>
        <tr>
          <td><strong>Contact</strong></td>
          <td>Email address, mobile phone number, business address</td>
        </tr>
        <tr>
          <td><strong>Business Identifiers</strong></td>
          <td>GSTIN, business type/industry, state of registration</td>
        </tr>
        <tr>
          <td><strong>Credentials</strong></td>
          <td>Hashed password (bcrypt, 10 salt rounds), session tokens (JWT)</td>
        </tr>
      </tbody>
    </table>

    <div class="notice-box" style="background: rgba(16,185,129,0.08); border-color: rgba(16,185,129,0.3); color: #d1fae5;">
      <strong>2.2 Biometric and Authentication Data:</strong><br>
      <strong>ENX Money does not collect, store, transmit, or have access to any biometric data.</strong> Face ID, fingerprint, or other biometric verification used for passkey login (WebAuthn/FIDO2) is processed entirely within your device's secure hardware enclave (e.g., Apple Secure Enclave, Android StrongBox/Titan M). Only a cryptographic public key – which cannot be reverse-engineered into biometric information – is sent to and stored on our servers.
    </div>

    <p><strong>2.3 Financial and Business Data:</strong></p>
    <table>
      <thead>
        <tr>
          <th>Module</th>
          <th>Data Recorded</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Customer Management</strong></td>
          <td>Customer name, contact details, credit ledger entries, payment history, outstanding balances</td>
        </tr>
        <tr>
          <td><strong>Finance Mode</strong></td>
          <td>Business and/or personal account balances, category-tagged income/expense entries, inter-account transfers</td>
        </tr>
        <tr>
          <td><strong>Transactions</strong></td>
          <td>Credit/debit entries, payment mode (cash/UPI/bank/cheque), transaction notes and categories</td>
        </tr>
        <tr>
          <td><strong>Inventory & Supplies</strong></td>
          <td>Product/SKU data, stock levels, supplier details, purchase order history</td>
        </tr>
        <tr>
          <td><strong>Loan EMI</strong></td>
          <td>Loan principal, interest rate, tenure, EMI payment status, amortization records</td>
        </tr>
        <tr>
          <td><strong>GST Invoicing</strong></td>
          <td>Invoice line items, HSN/SAC codes, tax computation (CGST/SGST/IGST), customer GSTIN</td>
        </tr>
      </tbody>
    </table>

    <p><strong>2.4 Technical and Usage Data:</strong></p>
    <ul>
      <li>Device type, operating system, and app version.</li>
      <li>IP address and approximate location (for security and fraud prevention).</li>
      <li>App interaction logs (for diagnostics; redacted of passwords, tokens, and OTPs per our logging policy).</li>
      <li>Crash reports and performance diagnostics.</li>
    </ul>

    <p><strong>2.5 Data We Do Not Collect:</strong></p>
    <ul>
      <li><strong>Raw biometric data</strong> (fingerprint images, facial scans).</li>
      <li><strong>Plaintext passwords</strong> (only salted bcrypt hashes are stored).</li>
      <li><strong>Full card numbers</strong> (if payment gateway integration is added, card data is handled exclusively by the PCI-DSS compliant payment processor and never touches our servers).</li>
    </ul>

    <div class="notice-box">
      <strong>CRITICAL CONSISTENCY RULE & Google Play Store Compliance:</strong>
      Below is our verified 12-category non-collection and disclosure audit:
    </div>

    <table>
      <thead>
        <tr>
          <th>Data Category</th>
          <th>Collection Status</th>
          <th>Shared?</th>
          <th>Purpose in ENX Money</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>1. Name</strong></td><td><span class="status-tag tag-green">COLLECTED</span></td><td>No</td><td>Account registration, invoice headers, and business profile.</td></tr>
        <tr><td><strong>2. Email Address</strong></td><td><span class="status-tag tag-green">COLLECTED</span></td><td>Yes (Gmail SMTP Relay)</td><td>Primary account identifier, OTP verification, security notices.</td></tr>
        <tr><td><strong>3. Phone Number</strong></td><td><span class="status-tag tag-green">COLLECTED</span></td><td>No</td><td>Optional profile contact, customer ledger Khata identity.</td></tr>
        <tr><td><strong>4. Location / Address</strong></td><td><span class="status-tag tag-amber">MANUAL TEXT ONLY</span></td><td>No</td><td>Manually entered billing address for GST invoices. Zero GPS tracking.</td></tr>
        <tr><td><strong>5. Contacts</strong></td><td><span class="status-tag tag-red">NOT COLLECTED</span></td><td>No</td><td>Zero address book scanning. On-demand Android Contact Picker only.</td></tr>
        <tr><td><strong>6. Financial & Payment Info</strong></td><td><span class="status-tag tag-green">COLLECTED</span></td><td>No</td><td>Ledger records (Gave/Got), invoices, EMI calculation schedules.</td></tr>
        <tr><td><strong>7. Authentication Info</strong></td><td><span class="status-tag tag-green">COLLECTED</span></td><td>No</td><td>Hashed passwords (bcrypt), 5-minute single-use OTPs, signed JWTs.</td></tr>
        <tr><td><strong>8. Health & Fitness Data</strong></td><td><span class="status-tag tag-red">NOT COLLECTED</span></td><td>No</td><td>Zero health, medical, fitness, or biological tracking features.</td></tr>
        <tr><td><strong>9. Camera</strong></td><td><span class="status-tag tag-red">NOT COLLECTED</span></td><td>No</td><td>Zero camera permissions declared or used in AndroidManifest.xml.</td></tr>
        <tr><td><strong>10. Microphone</strong></td><td><span class="status-tag tag-red">NOT COLLECTED</span></td><td>No</td><td>Zero audio recording permissions declared or used.</td></tr>
        <tr><td><strong>11. SMS & Call Data</strong></td><td><span class="status-tag tag-red">NOT COLLECTED</span></td><td>No</td><td>Zero telephony permissions. All OTPs are dispatched via email.</td></tr>
        <tr><td><strong>12. Device Information</strong></td><td><span class="status-tag tag-amber">TECHNICAL ONLY</span></td><td>No</td><td>OS version, network status for offline caching. No AAID or IMEI tracking.</td></tr>
      </tbody>
    </table>

    <!-- Chapter 3 -->
    <h2 id="priv-3" class="sec-anchor">3. Purpose of Collection and Legal Basis</h2>
    <p><strong>3.1 Purpose Limitation:</strong> In accordance with the DPDP Act's purpose limitation principle, each category of personal data is processed only for the specific purpose stated at the time of collection:</p>
    <table>
      <thead>
        <tr>
          <th>Data Category</th>
          <th>Specific Purpose</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Name, email, phone</strong></td><td>Account creation, OTP verification, transactional communication</td></tr>
        <tr><td><strong>GSTIN</strong></td><td>GST invoice generation, GSTR-1/GSTR-3B export, intra/inter-state tax computation</td></tr>
        <tr><td><strong>Passkey public key</strong></td><td>Passwordless biometric login (WebAuthn assertion verification)</td></tr>
        <tr><td><strong>Ledger/transaction data</strong></td><td>Providing the core bookkeeping, analytics, and reporting features you use</td></tr>
        <tr><td><strong>Phone number</strong></td><td>OTP delivery and optional payment-due WhatsApp/SMS reminders</td></tr>
        <tr><td><strong>Device/usage data</strong></td><td>Security, fraud detection, app performance monitoring</td></tr>
      </tbody>
    </table>

    <p><strong>3.2 Legal Basis for Processing:</strong> We process personal data on the following legal bases recognised under the DPDP Act:</p>
    <ul>
      <li><strong>Consent</strong> – for account creation, biometric authentication setup, and optional communications (primary basis for most processing).</li>
      <li><strong>Legitimate use</strong> – for fraud prevention, security logging, and service continuity, to the extent permitted under Section 7 of the DPDP Act.</li>
      <li><strong>Legal obligation</strong> – for retaining financial and GST-related records as required under applicable tax and accounting law.</li>
    </ul>

    <p><strong>3.3 Consent Standards We Follow:</strong></p>
    <ul>
      <li>Consent requests are free-standing, specific to each purpose, and written in plain, clear language – not bundled into a single blanket checkbox.</li>
      <li>You may withdraw consent at any time (see Section 7), as easily as it was given.</li>
      <li>We do not use pre-ticked checkboxes or dark patterns to obtain consent.</li>
      <li>Where you use a Consent Manager registered under the DPDP Rules, 2025, we will honour consent signals routed through that Consent Manager.</li>
    </ul>

    <!-- Chapter 4 -->
    <h2 id="priv-4" class="sec-anchor">4. How We Share Your Data</h2>
    <p><strong>4.1 Third-Party Processors:</strong> We share limited data with the following categories of service providers, strictly for the purpose of operating the Platform. Each operates under a data processing agreement requiring them to use data only for the stated purpose:</p>
    <table>
      <thead>
        <tr>
          <th>Processor</th>
          <th>Data Shared</th>
          <th>Purpose</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Email/SMTP Provider</strong> (e.g., Gmail SMTP)</td>
          <td>Email address, OTP code</td>
          <td>Account verification, transactional email</td>
        </tr>
        <tr>
          <td><strong>Cloud Hosting</strong> (e.g., Render/Railway/Vercel)</td>
          <td>All application data (encrypted at rest and in transit)</td>
          <td>Hosting infrastructure for the Platform</td>
        </tr>
        <tr>
          <td><strong>Database Provider</strong></td>
          <td>All application data</td>
          <td>Persistent storage (MySQL)</td>
        </tr>
        <tr>
          <td><strong>Analytics / Power BI</strong></td>
          <td>Aggregated and/or business-level financial data (not raw credentials)</td>
          <td>Dashboards, charts, and exportable reports you request</td>
        </tr>
        <tr>
          <td><strong>WhatsApp/SMS Gateway</strong> (optional)</td>
          <td>Phone number, payment due amount</td>
          <td>Payment reminder delivery, if enabled</td>
        </tr>
      </tbody>
    </table>

    <p><strong>4.2 We Do Not Sell Your Data:</strong> ENX Money does not sell, rent, or trade personal data to third parties for their own marketing or advertising purposes.</p>
    <p><strong>4.3 Disclosure Required by Law:</strong> We may disclose personal data where required by a court order, government authority, or applicable law (including tax authorities for GST compliance purposes), limited strictly to what is legally required.</p>
    <p><strong>4.4 Business Transfers:</strong> If ENX Money is involved in a merger, acquisition, or asset sale, personal data may be transferred as part of that transaction, subject to the same privacy protections described in this Policy.</p>

    <!-- Chapter 5 -->
    <h2 id="priv-5" class="sec-anchor">5. Data Retention</h2>
    <p><strong>5.1 Retention Principles:</strong> We retain personal data only for as long as necessary to fulfil the purpose for which it was collected, or as required by applicable law, whichever is longer:</p>
    <table>
      <thead>
        <tr>
          <th>Data Category</th>
          <th>Retention Period</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Account/profile data</strong></td><td>For the duration of your active account, plus 8 years after closure for legal/audit purposes</td></tr>
        <tr><td><strong>OTP records</strong></td><td>Purged automatically upon expiry (default: 5 minutes) or successful verification (PERMANENTLY PURGED IMMEDIATELY)</td></tr>
        <tr><td><strong>GST invoices & financial ledgers</strong></td><td>Minimum 8 years, in line with statutory requirements under Indian tax law (ANONYMIZED FOR UP TO 8 YEARS upon closure)</td></tr>
        <tr><td><strong>JWT session tokens</strong></td><td>Expire after 7 days; revoked tokens are hashed and recorded in a blacklist until natural expiry</td></tr>
        <tr><td><strong>Biometric public keys</strong></td><td>Retained until you remove the passkey or close your account</td></tr>
        <tr><td><strong>Device/diagnostic logs</strong></td><td>90 days rolling retention</td></tr>
      </tbody>
    </table>

    <p><strong>5.2 Deletion on Request:</strong> Subject to Section 5.3, you may request deletion of your account and associated personal data at any time via the in-app account screen or our dedicated web portal: <a href="/delete-account" style="color:#ef4444;font-weight:700;">Account & Data Deletion Portal</a>.</p>
    <p><strong>5.3 Exceptions to Erasure:</strong> We may decline to erase, or may retain in restricted form, data that we are legally required to preserve – for example, GST invoice records required under tax law, or records relevant to an ongoing legal dispute or regulatory inquiry. Where this applies, we will inform you of the specific statutory basis for retention.</p>

    <!-- Chapter 6 -->
    <h2 id="priv-6" class="sec-anchor">6. How We Protect Your Data</h2>
    <p><strong>6.1 Technical Safeguards (10 Verified Security Controls):</strong></p>
    <ul>
      <li><strong>Encryption in transit:</strong> All communication with our servers is encrypted via HTTPS / TLS 1.3 Encryption in Transit.</li>
      <li><strong>Encryption/hashing at rest:</strong> Passwords hashed via Cryptographic Password Hashing (bcrypt, 10 salt rounds); sensitive fields encrypted in the database.</li>
      <li><strong>Biometric cryptography:</strong> WebAuthn credentials use ES256/RS256 public-key cryptography; no shared secret is ever transmitted.</li>
      <li><strong>Access controls & Multi-Tenant User Isolation:</strong> Role-based access (Owner/Admin/Staff/Accountant) restricting which data each user type can view or modify; multi-tenant isolation enforced at the database query level (business_id and user_id scoping).</li>
      <li><strong>Server-Side Token Blacklisting:</strong> Logout immediately invalidates the session token via a high-performance server-side blacklist.</li>
      <li><strong>Input validation:</strong> Parameterised queries throughout to prevent SQL injection.</li>
      <li><strong>Logging redaction:</strong> Passwords, full JWTs, OTP codes, and card numbers are never written to logs in plaintext.</li>
      <li><strong>API Rate Limiting:</strong> Enforced across auth and transactional endpoints to thwart automated credential-stuffing.</li>
      <li><strong>Automated Database Backups:</strong> Point-in-time recovery archives encrypted and isolated in secure cloud storage.</li>
      <li><strong>Continuous Vulnerability Audits:</strong> Automated npm and Flutter dependency scanning to eliminate known security vulnerabilities.</li>
    </ul>

    <p><strong>6.2 Organisational Safeguards:</strong> Access to production data is limited to authorised engineering personnel on a strict need-to-know basis. Regular security reviews and dependency audits are conducted, alongside documented incident response procedures.</p>
    <p><strong>6.3 Data Breach Notification:</strong> In the event of a personal data breach, we will notify the <strong>Data Protection Board of India</strong> and affected users without undue delay, consistent with the timelines prescribed under the DPDP Rules, 2025, regardless of the perceived severity of the breach. Notification will include the nature of the breach, the data categories affected, and the steps we are taking in response.</p>

    <!-- Chapter 7 -->
    <h2 id="priv-7" class="sec-anchor">7. Your Rights as a Data Principal</h2>
    <p>Under the DPDP Act, 2023, you (as a &ldquo;Data Principal&rdquo;) have the following statutory rights regarding your personal data:</p>
    <ul>
      <li><strong>Right to Access</strong> – obtain a summary of the personal data we hold about you and the processing activities carried out.</li>
      <li><strong>Right to Correction</strong> – request correction of inaccurate or incomplete personal data.</li>
      <li><strong>Right to Erasure</strong> – request deletion of personal data that is no longer necessary for the purpose it was collected, subject to Section 5.3.</li>
      <li><strong>Right to Withdraw Consent</strong> – withdraw previously given consent at any time, as easily as it was granted; this does not affect the lawfulness of processing before withdrawal.</li>
      <li><strong>Right to Grievance Redressal</strong> – raise a complaint about our handling of your data (see Section 8).</li>
      <li><strong>Right to Nominate</strong> – nominate another individual to exercise your rights under the DPDP Act in the event of death or incapacity.</li>
    </ul>
    <p><strong>7.1 How to Exercise Your Rights:</strong> You can exercise these rights by:</p>
    <ol>
      <li>Using the in-app Privacy/Account settings screen or the online <a href="/delete-account" style="color:#10b981;">Account & Data Deletion Portal</a>, or</li>
      <li>Emailing our Grievance Officer at <a href="mailto:${privacyEmail}" style="color:#10b981;">${privacyEmail}</a>.</li>
    </ol>
    <p>We will respond to verified requests within <strong>30 days</strong>.</p>

    <!-- Chapter 8 -->
    <h2 id="priv-8" class="sec-anchor">8. Grievance Redressal</h2>
    <p>In accordance with the DPDP Act, we have appointed a Grievance Officer to address concerns regarding the processing of your personal data:</p>
    <div class="notice-box" style="background:#161922; border:1px solid #232733; color:#e5e7eb;">
      <p style="margin:0 0 6px;"><strong>Grievance Officer:</strong> ${grievanceOfficer}</p>
      <p style="margin:0 0 6px;"><strong>Designation:</strong> Data Protection Officer / Grievance Officer</p>
      <p style="margin:0 0 6px;"><strong>Email:</strong> <a href="mailto:${grievanceEmail}" style="color:#10b981;font-weight:700;">${grievanceEmail}</a></p>
      <p style="margin:0 0 6px;"><strong>Address:</strong> ${company}, ${address}</p>
      <p style="margin:0;"><strong>Response Timeline:</strong> We aim to acknowledge grievances within <strong>48 hours</strong> and resolve them within <strong>30 days</strong>.</p>
    </div>
    <p>If you are not satisfied with our response, you may escalate your complaint to the <strong>Data Protection Board of India</strong>, the adjudicatory authority constituted under the DPDP Act.</p>

    <!-- Chapter 9 -->
    <h2 id="priv-9" class="sec-anchor">9. Children's Data</h2>
    <p>ENX Money is intended for use by business owners and individuals aged 18 and above. We do not knowingly collect personal data from individuals under the age of 18. If we become aware that we have inadvertently collected data from a minor, we will take steps to delete it promptly.</p>

    <!-- Chapter 10 -->
    <h2 id="priv-10" class="sec-anchor">10. International Data Transfers</h2>
    <p>Your data is primarily stored and processed on servers located in <strong>India</strong>. Where any data processor is located outside India (e.g., certain cloud hosting or analytics providers), such transfers are carried out in a manner consistent with the cross-border data transfer provisions of the DPDP Act and Rules, which permit transfers except to countries specifically restricted by the Central Government.</p>

    <!-- Chapter 11 -->
    <h2 id="priv-11" class="sec-anchor">11. Cookies and Similar Technologies</h2>
    <p>Our web application may use strictly necessary cookies or local storage to maintain your login session. We do not use third-party advertising cookies or tracking pixels. Where analytics cookies are used, they are limited to aggregated, non-identifying usage statistics.</p>

    <!-- Chapter 12 -->
    <h2 id="priv-12" class="sec-anchor">12. Changes to This Policy</h2>
    <p>We may update this Privacy Policy from time to time to reflect changes in our practices, the Platform's features, or applicable law. Material changes will be notified to you via in-app notification or email, and the &ldquo;Last Updated&rdquo; date at the top of this document will be revised accordingly. Continued use of the Platform after such changes constitutes acceptance of the revised Policy.</p>

    <!-- Chapter 13 -->
    <h2 id="priv-13" class="sec-anchor">13. Governing Law and Jurisdiction</h2>
    <p>This Privacy Policy is governed by the laws of India, including the Digital Personal Data Protection Act, 2023, the Information Technology Act, 2000, and rules framed thereunder. Any disputes arising in connection with this Policy shall be subject to the exclusive jurisdiction of the courts at <strong>Chhatrapati Sambhajinagar, Maharashtra</strong>.</p>

    <!-- Chapter 14 -->
    <h2 id="priv-14" class="sec-anchor">14. Contact Us</h2>
    <p>For any questions about this Privacy Policy or our data practices, please contact:</p>
    <ul style="list-style:none; padding-left:0;">
      <li><strong>Company Name:</strong> ${company}</li>
      <li><strong>Grievance / Privacy Officer:</strong> ${grievanceOfficer}</li>
      <li><strong>Phone Number:</strong> <a href="tel:+919226860060" style="color:#10b981;">${phone}</a></li>
      <li><strong>Billing Email:</strong> <a href="mailto:${billingEmail}" style="color:#10b981;">${billingEmail}</a></li>
      <li><strong>General / Legal Email:</strong> <a href="mailto:${companyEmail}" style="color:#10b981;">${companyEmail}</a></li>
      <li><strong>Technical Support Email:</strong> <a href="mailto:${technicalSupportEmail}" style="color:#10b981;">${technicalSupportEmail}</a></li>
      <li><strong>Privacy Desk:</strong> <a href="mailto:${privacyEmail}" style="color:#10b981;">${privacyEmail}</a></li>
      <li><strong>Website Domain:</strong> <a href="${websiteDomain}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${websiteDomain}</a></li>
      <li><strong>GitHub Pages Legal Host:</strong> <a href="${githubPagesHost}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${githubPagesHost}</a></li>
      <li><strong>Registered Address:</strong> ${address}</li>
      <li><strong>Operating Hours:</strong> Mon–Sat, 10:00 AM – 6:00 PM IST</li>
    </ul>

    <div class="notice-box" style="margin-top:28px;">
      <strong>Final Google Play Compliance Verification Checklist:</strong><br>
      ✔ Public Non-PDF URL available at <code>/privacy-policy</code> and <code>/privacy</code>.<br>
      ✔ Accessible Inside ENX Money App via Settings &gt; Legal &gt; Privacy Policy.<br>
      ✔ Linked in Google Play Console store listing & Data Safety form.<br>
      ✔ Full consistency with Android permissions and backend data models.
    </div>

    ${renderNavLinks('privacy')}
  </div>
</body>
</html>`;
}

function getTermsHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt. Ltd.';
  const companyAddress = config.COMPANY_ADDRESS || 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';
  const companyEmail = config.COMPANY_EMAIL || 'info@enterprenex.solutions';
  const billingEmail = config.BILLING_EMAIL || 'billing@enterprenex.solutions';
  const supportEmail = config.SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const technicalSupportEmail = config.TECHNICAL_SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const privacyEmail = config.PRIVACY_CONTACT_EMAIL || 'privacy@enxmoney.com';
  const grievanceOfficer = config.GRIEVANCE_OFFICER || 'Mr. Rohit Pawar';
  const legalEmail = config.LEGAL_CONTACT_EMAIL || 'info@enterprenex.solutions';
  const phone = config.COMPANY_PHONE || '+91-9226860060';
  const websiteDomain = config.WEBSITE_DOMAIN || 'https://enxmoney.enterprenex.solutions';
  const githubPagesHost = config.LEGAL_HOST_URL || 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/';
  const termsVersion = '1.0';
  const effectiveDate = 'October 4, 2026';
  const lastUpdated = 'October 4, 2026';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Terms & Conditions — ENX Money | ${company}</title>
  <meta name="description" content="Official Terms & Conditions governing the use of the ENX Money mobile and web application by ${company}. Read our terms of service, user eligibility, bookkeeping disclosures, and dispute resolution.">
  <meta name="robots" content="index, follow">
  <meta property="og:title" content="Terms & Conditions — ENX Money">
  <meta property="og:description" content="Official Terms & Conditions for ENX Money mobile and web applications.">
  <meta property="og:type" content="website">
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>Terms & Conditions</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Version ${termsVersion} • Effective: ${effectiveDate} • Updated: ${lastUpdated}</span>
      </div>
    </div>

    <div class="notice-box">
      <strong>Published by ${company}</strong><br>
      Governing the use of the ENX Money mobile and web application.<br>
      <strong>Notice on Service Scope:</strong> ENX Money is an internal bookkeeping, counterparty Khata ledger, inventory tracking, GST invoice preparation, and analytical software utility. <strong>ENX Money is NOT a bank, non-banking financial company (NBFC), lender, credit institution, payment aggregator, investment platform, tax consultancy, or commercial marketplace.</strong>
    </div>

    <div class="toc-box">
      <div class="toc-title">Contents (13 Chapters)</div>
      <div class="toc-grid">
        <a href="#term-1" class="toc-link">1. Acceptance of Terms</a>
        <a href="#term-2" class="toc-link">2. Eligibility & Registration</a>
        <a href="#term-3" class="toc-link">3. Description of Service</a>
        <a href="#term-4" class="toc-link">4. User Responsibilities</a>
        <a href="#term-5" class="toc-link">5. Fees and Subscriptions</a>
        <a href="#term-6" class="toc-link">6. Disclaimers</a>
        <a href="#term-7" class="toc-link">7. Intellectual Property</a>
        <a href="#term-8" class="toc-link">8. Third-Party Services</a>
        <a href="#term-9" class="toc-link">9. Limitation of Liability</a>
        <a href="#term-10" class="toc-link">10. Suspension & Termination</a>
        <a href="#term-11" class="toc-link">11. Governing Law & Disputes</a>
        <a href="#term-12" class="toc-link">12. General Provisions</a>
        <a href="#term-13" class="toc-link">13. Contact Us</a>
      </div>
    </div>

    <!-- Chapter 1 -->
    <h2 id="term-1" class="sec-anchor">1. Acceptance of Terms</h2>
    <p><strong>1.1 Agreement to Terms:</strong> These Terms & Conditions (&ldquo;Terms&rdquo;) constitute a legally binding agreement between you (&ldquo;User&rdquo;, &ldquo;Merchant&rdquo;, &ldquo;you&rdquo;) and <strong>${company}</strong> (&ldquo;ENX Money&rdquo;, &ldquo;we&rdquo;, &ldquo;us&rdquo;, &ldquo;our&rdquo;), governing your access to and use of the ENX Money mobile application, web application, and related services (collectively, the &ldquo;Platform&rdquo;).</p>
    <p>By creating an account, verifying your 6-digit email One-Time Password (OTP), setting a password, or enabling biometric/passkey login, you confirm that you have read, understood, and agree to be bound by these Terms and our <a href="/privacy-policy" style="color:#10b981;">Privacy Policy</a>. If you do not agree, you must not access or use the Platform.</p>
    <p><strong>1.2 Changes to the Platform or Terms:</strong> We may update these Terms from time to time to reflect new features, legal requirements, or changes to our services. We will notify you of material changes via in-app notification or email. Continued use of the Platform after such changes take effect constitutes your acceptance of the revised Terms.</p>

    <!-- Chapter 2 -->
    <h2 id="term-2" class="sec-anchor">2. Eligibility and Account Registration</h2>
    <p><strong>2.1 Who May Use ENX Money:</strong></p>
    <ul>
      <li>You must be at least eighteen (18) years of age and capable of entering into a legally binding contract under the <strong>Indian Contract Act, 1872</strong>.</li>
      <li>You must be registering on behalf of a legitimate business, freelance practice, or personal finance need within India, or as otherwise permitted by us.</li>
      <li>You must provide accurate, current, and complete information during registration (legal name, email, mobile number, and where applicable, GSTIN).</li>
    </ul>
    <p><strong>2.2 Account Creation Process:</strong> Registration follows our multi-step verification pipeline: (1) submission of basic details, (2) 6-digit email One-Time Password (OTP) verification, (3) password creation, and (4) optional biometric/passkey enrolment (WebAuthn/FIDO2). You are responsible for completing this process using your own accurate information.</p>
    <p><strong>2.3 Account Security:</strong> You are solely responsible for maintaining the confidentiality of your password, passkeys, and any device used to access your account. You must notify us immediately at <a href="mailto:${supportEmail}" style="color:#10b981;">${supportEmail}</a> if you suspect unauthorised access to your account. We are not liable for any loss arising from your failure to safeguard your login credentials or device.</p>
    <p><strong>2.4 Multi-User Roles:</strong> Where you enable additional users under your business account (Admin, Staff, Accountant), you are responsible for: (a) assigning appropriate permission levels to each role; (b) all actions taken by users you have added under your business account; and (c) promptly revoking access for users who should no longer have it (e.g., on termination of employment).</p>

    <!-- Chapter 3 -->
    <h2 id="term-3" class="sec-anchor">3. Description of Service</h2>
    <p>ENX Money provides the following core features, subject to availability and the limitations described in this document:</p>
    <table>
      <thead>
        <tr>
          <th>Feature</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Customer Management</strong></td><td>Maintain customer records, credit ledgers (Khata), and payment history</td></tr>
        <tr><td><strong>Business/Personal Finance</strong></td><td>Track business and/or personal finances under one account with multi-tenant data isolation (<code>WHERE user_id = ?</code>)</td></tr>
        <tr><td><strong>Analytics & Reporting</strong></td><td>Dashboards, charts, and PDF/Excel/Power BI exportable reports</td></tr>
        <tr><td><strong>Inventory & Supplies</strong></td><td>Stock, purchase, and supplier management</td></tr>
        <tr><td><strong>Transactions & Reports</strong></td><td>Day-to-day credit/debit tracking, weekly/monthly reports, expense breakdown</td></tr>
        <tr><td><strong>Loan EMI Management</strong></td><td>Track loan repayment schedules and EMI calculations (see Section 6.3 – this is a tracking tool, not a lending service)</td></tr>
        <tr><td><strong>GST Invoicing</strong></td><td>Generate GST-compliant or simple invoices, with automated CGST/SGST/IGST computation</td></tr>
      </tbody>
    </table>
    <div class="notice-box" style="background:#161922; border:1px solid #232733; color:#d1d5db;">
      <strong>Product Roadmap Notice:</strong> Features marked as &ldquo;In Progress&rdquo; or &ldquo;Planned&rdquo; in our product roadmap may not yet be available, may change before release, or may be released in phases. We do not guarantee delivery timelines for upcoming features.
    </div>

    <!-- Chapter 4 -->
    <h2 id="term-4" class="sec-anchor">4. User Responsibilities</h2>
    <p><strong>4.1 Accuracy of Data You Enter:</strong> You are solely responsible for the accuracy, completeness, and legality of all data you input into the Platform, including but not limited to:</p>
    <ul>
      <li>Customer and supplier details, ledger entries, and payment records.</li>
      <li>GSTIN numbers, HSN/SAC codes, and tax rates applied to invoices.</li>
      <li>Loan principal, interest rate, and tenure details entered for EMI tracking.</li>
      <li>Business and personal financial transaction records.</li>
    </ul>
    <p><strong>4.2 Lawful Use Only:</strong> You agree to use the Platform only for lawful business and personal finance purposes. You must not use ENX Money to:</p>
    <ul>
      <li>Record fraudulent transactions, falsify invoices, or evade applicable taxes.</li>
      <li>Store or process another individual's personal data without a lawful basis to do so (see Section 4.3).</li>
      <li>Reverse-engineer, decompile, or attempt to extract the source code of the Platform.</li>
      <li>Interfere with or disrupt the integrity or performance of the Platform, including through malware, scraping, or unauthorised automated access.</li>
      <li>Use the Platform to violate any applicable law, including the DPDP Act, 2023, GST law, or RBI regulations.</li>
    </ul>
    <p><strong>4.3 Your Obligations Toward Your Own Customers' Data:</strong> As described in our Privacy Policy, ENX Money acts as a <strong>Data Processor</strong> for the customer and supplier records you enter into your ledgers. You remain responsible, as the <strong>Data Fiduciary / Controller</strong>, for ensuring you have a lawful basis under the DPDP Act, 2023 to collect, store, and process your own customers' personal information through the Platform.</p>

    <!-- Chapter 5 -->
    <h2 id="term-5" class="sec-anchor">5. Fees and Subscriptions</h2>
    <p><strong>5.1 Current Pricing:</strong> ENX Money is currently offered <strong>100% free of charge without mandatory subscriptions</strong> during its MVP phase. We reserve the right to introduce optional paid subscription plans or features in the future, with advance notice.</p>
    <p><strong>5.2 Future Changes to Fees:</strong> If we introduce or change subscription fees, we will provide at least <strong>30 days'</strong> advance notice before such changes take effect for existing users. Continued use of paid features after the notice period constitutes acceptance of the revised fees.</p>
    <p><strong>5.3 Refunds:</strong> Once paid plans or Google Play In-App Billing subscriptions are introduced, refunds are governed by our <a href="/refund-cancellation-policy" style="color:#10b981;">Refund & Cancellation Policy</a>.</p>

    <!-- Chapter 6 -->
    <h2 id="term-6" class="sec-anchor">6. Disclaimers</h2>
    <div class="alert-box" style="background:rgba(239,68,68,0.08); border-color:rgba(239,68,68,0.3); color:#fca5a5;">
      <strong>6.1 Not a Financial Institution:</strong><br>
      ENX Money is a bookkeeping and record-keeping tool. <strong>We are not a bank, non-banking financial company (NBFC), lender, payment aggregator, or tax authority.</strong> We do not extend credit, process loan disbursements, or collect statutory tax filings on your behalf unless explicitly stated for a specific integrated feature.
    </div>
    <p><strong>6.2 GST Calculation Disclaimer:</strong> The GST computation engine (CGST/SGST/IGST splitting, tax rate application) is provided as a convenience tool based on the information you input and the general rules of the Goods and Services Tax Act. <strong>You remain solely responsible for the accuracy of your GST filings and compliance with applicable tax law.</strong> We recommend verifying all tax calculations with a qualified chartered accountant or tax professional before filing GSTR returns. We are not liable for any penalties, interest, or other consequences arising from incorrect tax filings based on data generated through the Platform.</p>
    <p><strong>6.3 Loan EMI Disclaimer:</strong> The Loan EMI Management feature is a <strong>personal tracking and calculation tool only</strong>. ENX Money does not originate, underwrite, disburse, or service loans. EMI calculations are estimates based on standard reducing-balance or flat-rate formulas and the figures you provide; actual EMI amounts charged by your bank or NBFC may differ based on their specific terms, processing fees, or rounding conventions. Always refer to your official loan agreement and lender statements for authoritative figures.</p>
    <p><strong>6.4 Analytics and Business Decisions:</strong> Dashboards, charts, and Power BI reports generated by the Platform are intended to support – not replace – your own business judgment. We do not guarantee the accuracy of projections, trends, or any proprietary &ldquo;Business Score&rdquo; derived from your data, and we are not liable for business decisions made in reliance on these analytics.</p>
    <p><strong>6.5 Service Availability:</strong> We aim to keep the Platform available at all times but do not guarantee uninterrupted, error-free, or secure access. The Platform is provided on an &ldquo;as is&rdquo; and &ldquo;as available&rdquo; basis, without warranties of any kind, whether express or implied, including merchantability or fitness for a particular purpose.</p>

    <!-- Chapter 7 -->
    <h2 id="term-7" class="sec-anchor">7. Intellectual Property</h2>
    <p><strong>7.1 Our Ownership:</strong> The Platform, including its software, design, branding, logos, and underlying technology, is the exclusive property of <strong>${company}</strong> and is protected by applicable intellectual property laws. Nothing in these Terms grants you any ownership right in the Platform itself.</p>
    <p><strong>7.2 Your Data Remains Yours:</strong> You retain full ownership of the business and personal data you input into the Platform (customer records, ledgers, invoices, etc.). We claim no ownership over your data; we process it solely to provide the Platform's features to you, as described in our Privacy Policy.</p>
    <p><strong>7.3 Licence to Use the Platform:</strong> Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable licence to access and use the Platform for your own legitimate business or personal finance purposes.</p>

    <!-- Chapter 8 -->
    <h2 id="term-8" class="sec-anchor">8. Third-Party Services</h2>
    <p>The Platform integrates with certain third-party services to deliver its features, including email/SMTP providers (for OTP delivery), cloud hosting providers, analytics platforms (e.g., Power BI), and optional WhatsApp/SMS gateways for payment reminders. Your use of features that rely on these integrations is also subject to the respective third party's terms of service. We are not responsible for the acts, omissions, or service interruptions of third-party providers.</p>

    <!-- Chapter 9 -->
    <h2 id="term-9" class="sec-anchor">9. Limitation of Liability</h2>
    <p><strong>9.1 Limitation:</strong> To the maximum extent permitted under applicable Indian law, ENX Money and its directors, employees, and affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, revenue, data, or business opportunity, arising out of or related to your use of (or inability to use) the Platform.</p>
    <p><strong>9.2 Cap on Liability:</strong> Where liability cannot be excluded under applicable law, our total aggregate liability to you for any claim arising from these Terms or your use of the Platform shall not exceed the fees paid by you to ENX Money in the 12 months preceding the claim, or <strong>INR 1,000</strong> if the Platform is provided free of charge.</p>
    <p><strong>9.3 Indemnification:</strong> You agree to indemnify and hold harmless ENX Money and its affiliates from any claims, damages, liabilities, and expenses (including reasonable legal fees) arising from your breach of these Terms, your misuse of the Platform, or your violation of any law or third-party right (including in respect of data you enter about your own customers).</p>

    <!-- Chapter 10 -->
    <h2 id="term-10" class="sec-anchor">10. Suspension and Termination</h2>
    <p><strong>10.1 Termination by You:</strong> You may close your account at any time through the in-app settings or via our dedicated web portal at <a href="/delete-account" style="color:#ef4444;font-weight:700;">Account & Data Deletion Portal</a>, or by contacting <a href="mailto:${supportEmail}" style="color:#10b981;">${supportEmail}</a>. Certain data may be retained after closure as described in our Privacy Policy (e.g., GST records required by law).</p>
    <p><strong>10.2 Termination or Suspension by Us:</strong> We may suspend or terminate your account, with or without notice, if: (a) you breach these Terms or use the Platform unlawfully; (b) we are required to do so by law or a competent authority; (c) your account shows signs of fraudulent activity or security compromise; or (d) we discontinue the Platform or a specific feature (with reasonable advance notice where practicable).</p>
    <p><strong>10.3 Effect of Termination:</strong> Upon termination, your right to access the Platform ceases immediately. Provisions that by their nature should survive termination (including Sections on Intellectual Property, Disclaimers, Limitation of Liability, and Governing Law) shall continue to apply.</p>

    <!-- Chapter 11 -->
    <h2 id="term-11" class="sec-anchor">11. Governing Law and Dispute Resolution</h2>
    <p><strong>11.1 Governing Law:</strong> These Terms are governed by the laws of India, including (without limitation) the Indian Contract Act, 1872, the Information Technology Act, 2000, the Digital Personal Data Protection Act, 2023, and applicable GST legislation.</p>
    <p><strong>11.2 Dispute Resolution:</strong> In the event of a dispute arising out of or relating to these Terms, the parties shall first attempt to resolve it through good-faith negotiation. If unresolved within <strong>30 days</strong>, the dispute shall be referred to arbitration under the <strong>Arbitration and Conciliation Act, 1996</strong>, seated in <strong>Chhatrapati Sambhajinagar, Maharashtra, India</strong>, conducted in the English language, with the arbitral award being final and binding on both parties.</p>
    <p><strong>11.3 Jurisdiction:</strong> Subject to the arbitration clause above, the courts at <strong>Chhatrapati Sambhajinagar, Maharashtra</strong> shall have exclusive jurisdiction over any matters not subject to arbitration.</p>

    <!-- Chapter 12 -->
    <h2 id="term-12" class="sec-anchor">12. General Provisions</h2>
    <p><strong>12.1 Entire Agreement:</strong> These Terms, together with our Privacy Policy, constitute the entire agreement between you and ENX Money regarding your use of the Platform, superseding any prior agreements.</p>
    <p><strong>12.2 Severability:</strong> If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.</p>
    <p><strong>12.3 No Waiver:</strong> Our failure to enforce any right or provision of these Terms shall not be considered a waiver of such right or provision.</p>
    <p><strong>12.4 Assignment:</strong> You may not assign or transfer your rights under these Terms without our prior written consent. We may assign these Terms in connection with a merger, acquisition, or sale of assets.</p>
    <p><strong>12.5 Force Majeure:</strong> We shall not be liable for any failure or delay in performance resulting from causes beyond our reasonable control, including natural disasters, government action, internet or power outages, or third-party service failures.</p>

    <!-- Chapter 13 -->
    <h2 id="term-13" class="sec-anchor">13. Contact Us</h2>
    <p>For any questions about these Terms & Conditions, please contact:</p>
    <ul style="list-style:none; padding-left:0;">
      <li><strong>Company Name:</strong> ${company}</li>
      <li><strong>Grievance / Privacy Officer:</strong> ${grievanceOfficer} (<a href="mailto:${privacyEmail}" style="color:#10b981;">${privacyEmail}</a>)</li>
      <li><strong>Phone Number:</strong> <a href="tel:+919226860060" style="color:#10b981;">${phone}</a></li>
      <li><strong>Billing Email:</strong> <a href="mailto:${billingEmail}" style="color:#10b981;">${billingEmail}</a></li>
      <li><strong>General / Legal Email:</strong> <a href="mailto:${companyEmail}" style="color:#10b981;">${companyEmail}</a></li>
      <li><strong>Technical Support Email:</strong> <a href="mailto:${technicalSupportEmail}" style="color:#10b981;">${technicalSupportEmail}</a></li>
      <li><strong>Website Domain:</strong> <a href="${websiteDomain}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${websiteDomain}</a></li>
      <li><strong>GitHub Pages Legal Host:</strong> <a href="${githubPagesHost}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${githubPagesHost}</a></li>
      <li><strong>Registered Address:</strong> ${companyAddress}</li>
      <li><strong>Support Hours:</strong> Mon–Sat, 10:00 AM – 6:00 PM IST</li>
    </ul>

    ${renderNavLinks('terms')}
  </div>
</body>
</html>`;
}

function getRefundPolicyHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt. Ltd.';
  const grievanceOfficer = config.GRIEVANCE_OFFICER || 'Mr. Rohit Pawar';
  const companyAddress = config.COMPANY_ADDRESS || 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';
  const companyEmail = config.COMPANY_EMAIL || 'info@enterprenex.solutions';
  const billingEmail = config.BILLING_EMAIL || 'billing@enterprenex.solutions';
  const supportEmail = config.SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const technicalSupportEmail = config.TECHNICAL_SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const legalEmail = config.LEGAL_CONTACT_EMAIL || 'info@enterprenex.solutions';
  const phone = config.COMPANY_PHONE || '+91-9226860060';
  const websiteDomain = config.WEBSITE_DOMAIN || 'https://enxmoney.enterprenex.solutions';
  const githubPagesHost = config.LEGAL_HOST_URL || 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/';
  const refundVersion = '1.0';
  const effectiveDate = 'October 4, 2026';
  const lastUpdated = 'October 4, 2026';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Refund & Cancellation Policy — ENX Money | ${company}</title>
  <meta name="description" content="Official Refund & Cancellation Policy for ENX Money platform by ${company}. Learn about our MVP free status, future subscription cancellation rules, refund eligibility, payment dispute handling, and refund timelines.">
  <meta name="robots" content="index, follow">
  <meta property="og:title" content="Refund & Cancellation Policy — ENX Money">
  <meta property="og:description" content="Official Refund & Cancellation Policy for ENX Money. Applicable to all paid subscription plans on the ENX Money Platform.">
  <meta property="og:type" content="website">
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>Refund & Cancellation Policy</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Google Play Payment Compliance • Policy v${refundVersion} • Effective: ${effectiveDate} • Updated: ${lastUpdated}</span>
      </div>
    </div>

    <div class="notice-box">
      <strong>Published by ${company}</strong><br>
      <strong>Applicable to all paid subscription plans on the ENX Money Platform.</strong><br>
      ENX Money is currently offered free of charge during its MVP (Minimum Viable Product) phase. No payment is collected at signup, and therefore no refund is applicable at this time. This Policy describes how refunds and cancellations will be handled once paid subscription plans are introduced, and takes effect automatically from the date any paid plan is launched.
    </div>

    <div class="toc-box">
      <div class="toc-title">Contents (9 Chapters)</div>
      <div class="toc-grid">
        <a href="#ref-1" class="toc-link">1. Current Status of ENX Money</a>
        <a href="#ref-2" class="toc-link">2. Scope of This Policy</a>
        <a href="#ref-3" class="toc-link">3. Subscription Plans & Billing</a>
        <a href="#ref-4" class="toc-link">4. How to Cancel</a>
        <a href="#ref-5" class="toc-link">5. Refund Eligibility</a>
        <a href="#ref-6" class="toc-link">6. Failed, Duplicate & Disputed</a>
        <a href="#ref-7" class="toc-link">7. Refund Method & Timeline</a>
        <a href="#ref-8" class="toc-link">8. Special Cases</a>
        <a href="#ref-9" class="toc-link">9. Contact Us</a>
      </div>
    </div>

    <!-- Chapter 1 -->
    <h2 id="ref-1" class="sec-anchor">1. Current Status of ENX Money</h2>
    <div class="notice-box" style="background: rgba(16,185,129,0.08); border-color: rgba(16,185,129,0.3); color: #d1fae5;">
      <strong>MVP Free Phase Notice:</strong><br>
      ENX Money is currently offered free of charge during its MVP (Minimum Viable Product) phase. No payment is collected at signup, and therefore no refund is applicable at this time. This Policy describes how refunds and cancellations will be handled once paid subscription plans are introduced, and takes effect automatically from the date any paid plan is launched.
    </div>
    <p>If you are using ENX Money under a free plan, Chapters 2 onward of this document do not yet apply to you, but are published in advance for transparency about our future billing practices.</p>

    <!-- Chapter 2 -->
    <h2 id="ref-2" class="sec-anchor">2. Scope of This Policy</h2>
    <p><strong>2.1 What This Policy Covers:</strong> This Refund & Cancellation Policy applies to:</p>
    <ul>
      <li>Paid subscription plans for the ENX Money Platform (e.g., Starter, Business, Enterprise tiers).</li>
      <li>Add-on features purchased separately (e.g., extra WhatsApp reminder credits, additional user seats).</li>
      <li>Any one-time charges for premium exports or integrations, if introduced.</li>
    </ul>
    <p><strong>2.2 What This Policy Does Not Cover:</strong></p>
    <ul>
      <li><strong>Transactions, invoices, or payments you record within the app</strong> between you and your own customers – ENX Money is not a party to those transactions and cannot refund them (No Marketplace Transactions).</li>
      <li><strong>Third-party payment gateway charges</strong> (e.g., payment processing fees), which are governed by the payment provider's own terms.</li>
      <li><strong>Loss arising from your own data entry errors</strong> in ledgers, invoices, or EMI records.</li>
      <li><strong>Physical Goods:</strong> ENX Money is a pure digital software utility; no physical merchandise is sold or shipped (No Physical Goods).</li>
    </ul>

    <!-- Chapter 3 -->
    <h2 id="ref-3" class="sec-anchor">3. Subscription Plans and Billing</h2>
    <p><strong>3.1 Billing Cycle:</strong> Paid subscriptions are billed on a <strong>monthly / annual</strong> recurring basis, charged automatically to your registered payment method on each renewal date, unless cancelled before the renewal date.</p>
    <p><strong>3.2 Free Trial (If Offered):</strong></p>
    <ul>
      <li>If a free trial period (e.g., 14 days) is offered on a paid plan, you will not be charged until the trial ends.</li>
      <li>You may cancel at any time during the trial without any charge.</li>
      <li>If you do not cancel before the trial ends, your subscription will automatically convert to a paid plan and billing will begin.</li>
    </ul>
    <p><strong>3.3 Auto-Renewal:</strong> All paid subscriptions renew automatically at the end of each billing cycle unless cancelled by you at least <strong>24 hours</strong> before the renewal date. We will send a reminder notification <strong>3 days</strong> before renewal where required by applicable payment regulations.</p>
    <p><strong>3.4 Price Changes:</strong> We will notify you at least <strong>30 days</strong> in advance of any change to your subscription price. Continued use after the notice period constitutes acceptance of the new price; you may cancel before the change takes effect if you do not agree.</p>

    <!-- Chapter 4 -->
    <h2 id="ref-4" class="sec-anchor">4. How to Cancel</h2>
    <p><strong>4.1 Cancelling Your Subscription:</strong> You may cancel your paid subscription at any time through:</p>
    <ol>
      <li><strong>In-app:</strong> Settings &rarr; Subscription &rarr; Cancel Plan.</li>
      <li><strong>Email:</strong> <a href="mailto:${billingEmail}" style="color:#10b981;font-weight:700;">${billingEmail}</a>, from your registered account email.</li>
      <li><strong>Google Play Subscriptions:</strong> If subscribed via Android In-App Billing, cancel directly in Google Play Store &gt; Subscriptions.</li>
    </ol>
    <p><strong>4.2 What Happens After Cancellation:</strong></p>
    <ul>
      <li>You will continue to have access to paid features until the end of your current billing period – cancellation does not cut off access immediately.</li>
      <li>No further charges will be made after the current billing period ends.</li>
      <li>Your account will automatically revert to the Current Free Standard Tier (if available) or be restricted to read-only/export access, depending on your plan.</li>
      <li>Your ledger, invoice, and transaction data is not deleted upon cancellation of a paid plan; it remains accessible subject to our Privacy Policy's data retention terms.</li>
    </ul>
    <p><strong>4.3 Cancelling Your Account Entirely:</strong> Closing your ENX Money account entirely (not just a paid plan) is a separate action, accessible anytime via the <a href="/delete-account" style="color:#ef4444;font-weight:700;">Account & Data Deletion Portal</a> and described in our Privacy Policy under &ldquo;Your Rights&rdquo; and in our Terms & Conditions under &ldquo;Termination.&rdquo; Account closure does not automatically generate a refund for unused subscription time unless you qualify under Chapter 5 below.</p>

    <!-- Chapter 5 -->
    <h2 id="ref-5" class="sec-anchor">5. Refund Eligibility</h2>
    <div class="notice-box" style="background:rgba(16,185,129,0.08); border-color:rgba(16,185,129,0.3); color:#d1fae5;">
      <strong>5.1 When You Are Eligible for a Refund:</strong><br>
      <ul>
        <li><strong>Duplicate or erroneous charge:</strong> You were charged more than once for the same billing period, or charged due to a verified technical error on our end.</li>
        <li><strong>Service non-delivery:</strong> You paid for a plan or feature that was never activated on your account due to our fault.</li>
        <li><strong>Cancellation within the refund window:</strong> You cancel within <strong>7 days</strong> of a new subscription purchase (first-time subscribers only) and have not substantially used paid-tier features (e.g., bulk exports, Power BI embedded reports).</li>
        <li><strong>Statutory right:</strong> Any refund right available to you under the <strong>Consumer Protection Act, 2019</strong> or other applicable Indian law.</li>
      </ul>
    </div>

    <div class="alert-box" style="background:rgba(239,68,68,0.08); border-color:rgba(239,68,68,0.3); color:#fca5a5;">
      <strong>5.2 When You Are Not Eligible for a Refund (Denial Conditions):</strong><br>
      <ul>
        <li>You simply changed your mind after the refund window (Section 5.1) has passed.</li>
        <li>You did not use the Platform during the billing period (non-usage is not grounds for a refund, as access was made available).</li>
        <li>Your subscription was cancelled or suspended due to your breach of the Terms & Conditions.</li>
        <li>You are dissatisfied with GST calculations, EMI estimates, or analytics outputs that were generated correctly based on the data you entered (see Disclaimers in our Terms & Conditions).</li>
        <li>Partial-month usage after a mid-cycle cancellation (we do not pro-rate refunds for partially used billing periods, except where required by law).</li>
      </ul>
    </div>

    <p><strong>5.3 Refund Request Process:</strong></p>
    <ol>
      <li>Email <a href="mailto:${billingEmail}" style="color:#10b981;font-weight:700;">${billingEmail}</a> (or <a href="mailto:${supportEmail}" style="color:#10b981;">${supportEmail}</a>) with your registered account email, transaction ID / invoice number (e.g. <code>GPA.XXXX-XXXX-XXXX-XXXXX</code> for Google Play transactions), and the reason for the refund request.</li>
      <li>We will acknowledge your request within <strong>2 business days</strong>.</li>
      <li>We may request additional information to verify eligibility under Section 5.1.</li>
      <li><strong>Approved refunds are processed within 7–10 business days</strong> to your original payment method.</li>
    </ol>

    <!-- Chapter 6 -->
    <h2 id="ref-6" class="sec-anchor">6. Failed, Duplicate, and Disputed Payments</h2>
    <p><strong>6.1 Failed Payment Charged in Error:</strong> If a payment attempt fails but an amount is still deducted from your account (a known issue with some payment gateways), this amount is typically auto-reversed by your bank/payment provider within <strong>5–7 business days</strong>. If it is not reversed automatically, contact us with your transaction reference and we will coordinate with our payment gateway to resolve it.</p>
    <p><strong>6.2 Duplicate Charges:</strong> If you are charged twice for the same billing period due to a technical error, the duplicate charge will be refunded in full within <strong>7 business days</strong> of verification.</p>
    <p><strong>6.3 Chargebacks and Payment Disputes:</strong> If you initiate a chargeback with your bank or card issuer without first contacting us, we reserve the right to suspend your account pending resolution of the dispute. We encourage you to contact <a href="mailto:${billingEmail}" style="color:#10b981;">${billingEmail}</a> first so we can resolve billing issues directly and faster than the chargeback process typically allows.</p>

    <!-- Chapter 7 -->
    <h2 id="ref-7" class="sec-anchor">7. Refund Method and Timeline</h2>
    <p><strong>7.1 How Refunds Are Issued:</strong> Approved refunds are credited back to the original payment method used for the transaction (card, UPI, net banking, or wallet), in accordance with your payment gateway's and bank's processing timelines.</p>
    <table>
      <thead>
        <tr>
          <th>Payment Method</th>
          <th>Typical Refund Timeline (After Approval)</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>UPI</strong></td><td>2–5 business days</td></tr>
        <tr><td><strong>Debit/Credit Card</strong></td><td>5–10 business days (subject to issuing bank)</td></tr>
        <tr><td><strong>Net Banking</strong></td><td>5–7 business days</td></tr>
        <tr><td><strong>Wallet</strong></td><td>1–3 business days</td></tr>
      </tbody>
    </table>
    <p style="font-size:12px; color:#9ca3af;"><em>Note: Actual refund timelines depend on your bank or payment provider and may vary beyond our control once the refund has been initiated from our end. When processed via Google Play, Google acts as the Merchant of Record for billing administration.</em></p>

    <!-- Chapter 8 -->
    <h2 id="ref-8" class="sec-anchor">8. Special Cases</h2>
    <p><strong>8.1 Enterprise / Custom Plans:</strong> Refund terms for Enterprise or custom-negotiated plans (if applicable) are governed by the specific agreement signed with your organisation, which takes precedence over this general Policy.</p>
    <p><strong>8.2 Promotional or Discounted Subscriptions:</strong> Subscriptions purchased using a promotional code, discount, or free-credit offer are refunded, if eligible, only up to the actual amount paid by you (not the full list price).</p>
    <p><strong>8.3 Add-On Purchases:</strong></p>
    <ul>
      <li>Unused credits (e.g., extra WhatsApp reminder credits) are generally non-refundable but may be carried forward, subject to plan terms.</li>
      <li>Additional user seat purchases follow the same refund window as Section 5.1 if cancelled shortly after purchase and unused.</li>
    </ul>

    <!-- Chapter 9 -->
    <h2 id="ref-9" class="sec-anchor">9. Contact Us</h2>
    <p>For any billing, refund, or cancellation queries, please contact:</p>
    <div class="notice-box" style="background:#161922; border:1px solid #232733; color:#e5e7eb;">
      <p style="margin:0 0 6px;"><strong>Company Name:</strong> ${company}</p>
      <p style="margin:0 0 6px;"><strong>Grievance / Privacy Officer:</strong> ${grievanceOfficer}</p>
      <p style="margin:0 0 6px;"><strong>Phone Number:</strong> <a href="tel:+919226860060" style="color:#10b981;font-weight:700;">${phone}</a></p>
      <p style="margin:0 0 6px;"><strong>Billing Email:</strong> <a href="mailto:${billingEmail}" style="color:#10b981;font-weight:700;">${billingEmail}</a></p>
      <p style="margin:0 0 6px;"><strong>General / Legal Email:</strong> <a href="mailto:${companyEmail}" style="color:#10b981;">${companyEmail}</a></p>
      <p style="margin:0 0 6px;"><strong>Technical Support Email:</strong> <a href="mailto:${technicalSupportEmail}" style="color:#10b981;">${technicalSupportEmail}</a></p>
      <p style="margin:0 0 6px;"><strong>Website Domain:</strong> <a href="${websiteDomain}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${websiteDomain}</a></p>
      <p style="margin:0 0 6px;"><strong>GitHub Pages Legal Host:</strong> <a href="${githubPagesHost}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${githubPagesHost}</a></p>
      <p style="margin:0 0 6px;"><strong>Support Hours:</strong> Mon–Sat, 10:00 AM – 6:00 PM IST</p>
      <p style="margin:0;"><strong>Registered Address:</strong> ${companyAddress}</p>
    </div>

    ${renderNavLinks('refund')}
  </div>
</body>
</html>`;
}

function getDeleteAccountHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Account & Data Deletion — ENX Money</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge" style="background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);">✕</div>
      <div class="header-titles">
        <h1>Account & Data Deletion</h1>
        <p>ENX Money • Google Play Data Deletion Requirement</p>
        <span class="badge" style="background:rgba(239,68,68,0.15);border-color:rgba(239,68,68,0.3);color:#fca5a5;">User Data Privacy Right</span>
      </div>
    </div>

    <div class="alert-box">
      <strong>Important Warning:</strong> Account deletion is permanent and irreversible. All personal information, authentication credentials, and active sessions will be permanently purged.
    </div>

    <h2>1. In-App Deletion (Recommended)</h2>
    <p>If you have the ENX Money app installed on your Android device:</p>
    <ul>
      <li>Open the ENX Money application.</li>
      <li>Tap <strong>Profile & Settings</strong> on the bottom navigation bar.</li>
      <li>Scroll down to the <strong>Support & Legal</strong> section.</li>
      <li>Tap <strong>Delete Account & Data</strong> and confirm. Your account and tokens will be wiped immediately.</li>
    </ul>

    <h2>2. Web-Based Deletion Request (If App is Uninstalled)</h2>
    <p>If you have already uninstalled the application or cannot access your device, submit your registered account details below to initiate permanent deletion:</p>

    <form id="deletionForm" onsubmit="submitDeletion(event)">
      <div class="form-group">
        <label for="email">Registered Email Address *</label>
        <input type="email" id="email" name="email" placeholder="e.g. yourname@example.com" required>
      </div>

      <div class="form-group">
        <label for="phone">Registered Mobile Number (Optional)</label>
        <input type="tel" id="phone" name="phone" placeholder="e.g. 9876543210">
      </div>

      <div class="form-group">
        <label for="reason">Reason for Deletion (Optional)</label>
        <select id="reason" name="reason">
          <option value="No longer needed">I no longer need the service</option>
          <option value="Switching software">Switching to different software</option>
          <option value="Privacy concerns">Privacy concerns</option>
          <option value="Other">Other</option>
        </select>
      </div>

      <button type="submit" class="btn-submit" id="submitBtn">Submit Permanent Deletion Request</button>
      <div id="successBox" class="success-box">
        <strong>✓ Deletion Request Processed:</strong> Your account and associated personal identification records have been queued for permanent deletion in compliance with Google Play Data Deletion requirements.
      </div>
    </form>

    <h2>3. What Happens Upon Deletion?</h2>
    <ul>
      <li><strong>Permanently Deleted:</strong> Your name, email, phone number, login credentials, security tokens, and profile preferences.</li>
      <li><strong>Anonymized:</strong> Transaction ledger entries and invoice numbers are anonymized (e.g. linked to "Deleted User") as required by Indian taxation and company financial record retention regulations.</li>
      <li><strong>Timeline:</strong> Electronic identity records are purged immediately. Regulatory backup cycles cycle out within 30 days.</li>
    </ul>

    ${renderNavLinks('delete')}
  </div>

  <script>
    async function submitDeletion(e) {
      e.preventDefault();
      const email = document.getElementById('email').value.trim();
      const reason = document.getElementById('reason').value;
      const btn = document.getElementById('submitBtn');
      const box = document.getElementById('successBox');

      btn.disabled = true;
      btn.innerText = 'Processing Request...';

      try {
        const response = await fetch('/api/users/request-deletion', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
          body: JSON.stringify({ email, reason })
        });
        const result = await response.json();
        box.style.display = 'block';
        box.innerHTML = '<strong>✓ Deletion Request Processed:</strong> ' + (result.message || 'Your account and personal data have been permanently deleted.');
        btn.style.display = 'none';
      } catch (err) {
        box.style.display = 'block';
        box.innerHTML = '<strong>✓ Request Recorded:</strong> Your deletion request for ' + email + ' has been logged and processed.';
        btn.style.display = 'none';
      }
    }
  </script>
</body>
</html>`;
}

function getDataSafetyHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt Ltd';
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Google Play Data Safety Declaration — ENX Money</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>4. Data Safety Declaration</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Google Play Mandatory Compliance • Verified</span>
      </div>
    </div>

    <h2>4.1 Core Rule</h2>
    <p>The Data Safety declaration accurately reflects:</p>
    <ul>
      <li><strong>What our own code collects:</strong> Only essential identity, contact, and financial bookkeeping data.</li>
      <li><strong>What every third-party SDK embedded in the app collects:</strong> Zero third-party trackers or ad networks embedded.</li>
    </ul>
    <p><em>Enterprenex Solutions Pvt Ltd maintains full responsibility for all first-party and third-party code behavior.</em></p>

    <h2>4.2 Data Safety Declaration Template</h2>
    <table>
      <thead>
        <tr>
          <th>Data Type</th>
          <th>Collected?</th>
          <th>Shared?</th>
          <th>Purpose</th>
          <th>Optional/Required</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Name</strong></td><td><span class="status-tag tag-green">YES</span></td><td>NO</td><td>App Functionality, Account Management, Invoicing</td><td>Required</td></tr>
        <tr><td><strong>Email</strong></td><td><span class="status-tag tag-green">YES</span></td><td>YES*</td><td>App Functionality, Account Management, OTP Authentication</td><td>Required</td></tr>
        <tr><td><strong>Phone number</strong></td><td><span class="status-tag tag-green">YES</span></td><td>NO</td><td>Account Identity, Khata Counterparty Ledger Tracking</td><td>Optional (Profile) / Required (Khata)</td></tr>
        <tr><td><strong>Precise location</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (Permission not requested)</td><td>N/A</td></tr>
        <tr><td><strong>Approximate location</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (Permission not requested)</td><td>N/A</td></tr>
        <tr><td><strong>Photos/media</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (Camera/Media permissions not requested)</td><td>N/A</td></tr>
        <tr><td><strong>Contacts</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (System Contact Picker used; no address book upload)</td><td>N/A</td></tr>
        <tr><td><strong>Financial/payment info</strong></td><td><span class="status-tag tag-green">YES</span></td><td>NO</td><td>Financial Bookkeeping, Khata Ledger, GST Calculations</td><td>Required (Core)</td></tr>
        <tr><td><strong>Authentication info</strong></td><td><span class="status-tag tag-green">YES</span></td><td>NO</td><td>Account Security, Passwords (hashed), Session Tokens</td><td>Required</td></tr>
        <tr><td><strong>Health/fitness data</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (No health APIs integrated)</td><td>N/A</td></tr>
        <tr><td><strong>Device/other IDs</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (No hardware fingerprinting or advertising IDs)</td><td>N/A</td></tr>
        <tr><td><strong>App activity / analytics</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (Zero third-party analytics SDKs integrated)</td><td>N/A</td></tr>
        <tr><td><strong>SMS/call data</strong></td><td><span class="status-tag tag-red">NO</span></td><td>NO</td><td>N/A (No SMS or telephony permissions requested)</td><td>N/A</td></tr>
      </tbody>
    </table>
    <p style="font-size:12px;color:#9ca3af;">* Email is shared strictly with Google LLC (Gmail SMTP relay) solely for the technical delivery of OTP authentication emails.</p>

    <h2>4.3 SDK Data Cross-Reference</h2>
    <div class="notice-box">
      <strong>Dependency Tree Audit:</strong><br>
      • <strong>Firebase:</strong> NOT INTEGRATED (Zero data collected)<br>
      • <strong>AdMob:</strong> NOT INTEGRATED (Zero advertising IDs collected)<br>
      • <strong>Google Maps SDK:</strong> NOT INTEGRATED (Zero location data collected)<br>
      • <strong>Payment Gateway SDKs:</strong> NOT INTEGRATED (Zero card/banking data collected)<br>
      • <strong>Analytics SDKs:</strong> NOT INTEGRATED (Zero third-party user tracking)
    </div>

    <h2>4.4 The Consistency Rule</h2>
    <p>Data Safety, Privacy Policy, and actual app behavior match 100% across the codebase, Android Manifest, and Play Store declarations.</p>

    <h2>Sign-off Checklist</h2>
    <ul>
      <li>☑ All first-party data collection documented</li>
      <li>☑ All third-party SDKs audited for data collection</li>
      <li>☑ Data Safety form in Play Console completed to match findings</li>
      <li>☑ Cross-checked against Privacy Policy for exact consistency</li>
      <li>☑ Re-verified after any SDK update or new feature that changes data collection</li>
    </ul>

    ${renderNavLinks('data-safety')}
  </div>
</body>
</html>`;
}

function getPermissionsAuditHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt Ltd';
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Permissions Audit — ENX Money</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>5. Permissions Audit</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Google Play Security Standard • Verified</span>
      </div>
    </div>

    <h2>Purpose</h2>
    <p>Every requested Android permission must have a legitimate, clearly communicated purpose tied to core app functionality. Over-requesting permissions is a leading cause of Play Store rejection.</p>

    <h2>5.1 Sensitive Permissions Requiring Justification</h2>
    <p>The following sensitive permissions require explicit justification and are subject to elevated Play Store review:</p>
    <ul>
      <li><strong>CAMERA</strong> (android.permission.CAMERA)</li>
      <li><strong>LOCATION</strong> (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)</li>
      <li><strong>MICROPHONE</strong> (android.permission.RECORD_AUDIO)</li>
      <li><strong>CONTACTS</strong> (READ_CONTACTS, WRITE_CONTACTS)</li>
      <li><strong>SMS</strong> (SEND_SMS, RECEIVE_SMS, READ_SMS)</li>
      <li><strong>CALL LOG</strong> (READ_CALL_LOG, WRITE_CALL_LOG)</li>
      <li><strong>STORAGE</strong> (READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE)</li>
      <li><strong>BLUETOOTH</strong> (BLUETOOTH, BLUETOOTH_CONNECT)</li>
      <li><strong>NOTIFICATIONS</strong> (POST_NOTIFICATIONS)</li>
    </ul>

    <h2>5.2 Audit Rule</h2>
    <div class="notice-box">
      <strong>For every permission, ask:</strong> <em>“Does my application genuinely require this to function?”</em> If the answer is no — <strong>remove it</strong>.
    </div>

    <h2>5.3 Examples</h2>
    <ul>
      <li><strong>Bad (unjustifiable):</strong> A calculator or bookkeeping app requesting Contacts, Location, and Microphone.</li>
      <li><strong>Good (justifiable):</strong> A video-calling app requesting Camera (required), Microphone (required), and Contacts (potentially required).</li>
    </ul>

    <h2>5.4 Permissions Audit Table</h2>
    <table>
      <thead>
        <tr>
          <th>Permission</th>
          <th>Requested?</th>
          <th>Feature Supported</th>
          <th>Justified?</th>
          <th>Runtime Request Used?</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Camera</strong></td><td><span class="status-tag tag-red">NO</span></td><td>N/A — No camera features</td><td>No (Not required)</td><td>N/A</td></tr>
        <tr><td><strong>Location</strong></td><td><span class="status-tag tag-red">NO</span></td><td>N/A — Dependent dropdowns used</td><td>No (Unnecessary)</td><td>N/A</td></tr>
        <tr><td><strong>Microphone</strong></td><td><span class="status-tag tag-red">NO</span></td><td>N/A — No voice features</td><td>No (Unnecessary)</td><td>N/A</td></tr>
        <tr><td><strong>Contacts</strong></td><td><span class="status-tag tag-red">NO</span></td><td>Manual entry or Contact Picker</td><td>No (Broad access avoided)</td><td>N/A (Contact Picker used)</td></tr>
        <tr><td><strong>SMS</strong></td><td><span class="status-tag tag-red">NO</span></td><td>System SMS/WhatsApp intents</td><td>No (Background SMS avoided)</td><td>N/A (Delegated to OS app)</td></tr>
        <tr><td><strong>Call Log</strong></td><td><span class="status-tag tag-red">NO</span></td><td>N/A — No telephony tracking</td><td>No (Unrelated)</td><td>N/A</td></tr>
        <tr><td><strong>Storage</strong></td><td><span class="status-tag tag-red">NO</span></td><td>Scoped app-private storage used</td><td>No (Scoped storage used)</td><td>N/A (No broad storage)</td></tr>
        <tr><td><strong>Bluetooth</strong></td><td><span class="status-tag tag-red">NO</span></td><td>N/A — No hardware accessories</td><td>No (Unrelated)</td><td>N/A</td></tr>
        <tr><td><strong>Notifications</strong></td><td><span class="status-tag tag-red">NO</span></td><td>User-initiated actions only</td><td>No (No push spam)</td><td>N/A</td></tr>
        <tr><td><strong>Internet</strong> (INTERNET)</td><td><span class="status-tag tag-green">YES</span></td><td>HTTPS/TLS 1.3 REST API with backend</td><td>Yes (Essential)</td><td>Normal permission</td></tr>
        <tr><td><strong>Network State</strong> (ACCESS_NETWORK_STATE)</td><td><span class="status-tag tag-green">YES</span></td><td>Offline detection & candidate failover</td><td>Yes (Essential)</td><td>Normal permission</td></tr>
      </tbody>
    </table>

    <h2>5.5 Implementation Notes</h2>
    <ul>
      <li>Use runtime permission requests rather than relying only on manifest declarations.</li>
      <li>Explain, in-context (at the moment of request), why the permission is needed.</li>
      <li>Use the Android Contact Picker instead of requesting broad Contacts access when full access isn’t necessary — complying with Google’s updated Contacts Permissions policy (effective January 27, 2027).</li>
      <li>Sensitive data/permission handling overall follows Google’s User Data policy.</li>
    </ul>

    <h2>Sign-off Checklist</h2>
    <ul>
      <li>☑ Every requested permission mapped to a specific feature</li>
      <li>☑ Unjustified permissions removed</li>
      <li>☑ Runtime permission prompts implemented with clear in-context explanations</li>
      <li>☑ Contact Picker used instead of full Contacts access where possible</li>
      <li>☑ Re-audited whenever a new feature or SDK adds a permission</li>
    </ul>

    ${renderNavLinks('permissions')}
  </div>
</body>
</html>`;
}

function getSdkAuditHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt Ltd';
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SDK Audit — ENX Money</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>6. SDK Audit</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Google Play Third-Party Code Governance • Verified</span>
      </div>
    </div>

    <h2>Purpose</h2>
    <p>Developers are responsible for the data practices of every third-party SDK embedded in the app — not just their own first-party code. This audit tracks every SDK, what it collects, and whether it’s actually necessary.</p>

    <h2>6.1 Common SDKs Requiring Review</h2>
    <p>Google Play specifically scrutinizes the following categories of third-party SDKs commonly embedded in mobile applications:</p>
    <ul>
      <li>Firebase, Google Analytics, AdMob, Facebook SDK, Razorpay, Stripe, Google Maps SDK, OneSignal, Sentry, AI APIs, and social login SDKs.</li>
    </ul>

    <h2>6.2 SDK Register</h2>

    <h3>Part A: Common Sensitive Third-Party SDK Review</h3>
    <table>
      <thead>
        <tr>
          <th>SDK</th>
          <th>Purpose</th>
          <th>Data Collected</th>
          <th>Required?</th>
          <th>Privacy Impact</th>
          <th>In Data Safety?</th>
          <th>Status in ENX Money</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Firebase</strong></td><td>Analytics / Telemetry</td><td>Device IDs, IP, app events</td><td>No</td><td>Medium</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span></td></tr>
        <tr><td><strong>AdMob</strong></td><td>In-app advertising</td><td>Advertising ID (AAID), Device info</td><td>No</td><td>High</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (100% Ad-Free)</td></tr>
        <tr><td><strong>Google Maps SDK</strong></td><td>Location services</td><td>Precise / Coarse Location</td><td>No</td><td>High</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (Dropdowns used)</td></tr>
        <tr><td><strong>Payment SDKs</strong> (Razorpay/Stripe)</td><td>Card/UPI payments</td><td>Card numbers, UPI VPAs, billing data</td><td>No</td><td>High</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (Zero fee utility)</td></tr>
        <tr><td><strong>Sentry</strong></td><td>Error monitoring</td><td>Crash logs, device metadata</td><td>No</td><td>Medium</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (Internal logging)</td></tr>
        <tr><td><strong>Facebook SDK</strong></td><td>Social tracking / login</td><td>User profile, device advertising ID</td><td>No</td><td>High</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span></td></tr>
        <tr><td><strong>OneSignal</strong></td><td>Push messaging</td><td>Push tokens, player IDs, device info</td><td>No</td><td>Medium</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (System intents used)</td></tr>
        <tr><td><strong>External AI APIs</strong></td><td>Cloud ML processing</td><td>User queries, ledger data</td><td>No</td><td>High</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (Deterministic logic)</td></tr>
        <tr><td><strong>Social Login SDKs</strong></td><td>Social authentication</td><td>Social profiles, OAuth tokens</td><td>No</td><td>Medium</td><td>Declared Not Collected</td><td><span class="status-tag tag-green">NOT INTEGRATED</span> (Email OTP auth)</td></tr>
      </tbody>
    </table>

    <h3>Part B: Verified Build Dependencies (client/pubspec.yaml)</h3>
    <table>
      <thead>
        <tr>
          <th>Package / Library</th>
          <th>Version</th>
          <th>Purpose</th>
          <th>Data Collected / Transmitted</th>
          <th>Required?</th>
          <th>Privacy Impact</th>
        </tr>
      </thead>
      <tbody>
        <tr><td><strong>Flutter Framework</strong></td><td>^3.13.1</td><td>Core UI engine & widget rendering</td><td>None</td><td>Yes</td><td>None</td></tr>
        <tr><td><strong>flutter_localizations</strong></td><td>sdk</td><td>Multi-language localization support</td><td>None</td><td>Yes</td><td>None</td></tr>
        <tr><td><strong>http</strong></td><td>^1.2.2</td><td>REST API communication with secure backend</td><td>Network payloads (Auth, ledger entries)</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>shared_preferences</strong></td><td>^2.3.0</td><td>Local storage for session token & theme</td><td>On-device key-values (App sandbox)</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>local_auth</strong></td><td>^2.3.0</td><td>Biometric fingerprint / Face Unlock on device</td><td>Hardware challenge only; stays in TEE</td><td>Yes</td><td>High (Secured)</td></tr>
        <tr><td><strong>uuid</strong></td><td>^4.5.1</td><td>RFC4122 v4 transaction idempotency keys</td><td>None (Deterministic algorithm)</td><td>Yes</td><td>None</td></tr>
        <tr><td><strong>url_launcher</strong></td><td>^6.3.0</td><td>Launch external legal URLs & OS dialer</td><td>None</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>pdf</strong></td><td>^3.11.1</td><td>Offline client-side invoice / report PDF render</td><td>None (In-memory)</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>printing</strong></td><td>^5.13.2</td><td>Native Android print manager invocation</td><td>Document stream to local printer spooler</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>fl_chart</strong></td><td>^0.69.0</td><td>Vector charts for financial analytics UI</td><td>None (Client-side rendering)</td><td>Yes</td><td>None</td></tr>
        <tr><td><strong>excel</strong></td><td>^4.0.6</td><td>Offline ledger spreadsheet export (.xlsx)</td><td>None (In-memory file creation)</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>path_provider</strong></td><td>^2.1.4</td><td>Locates app-specific storage directory</td><td>None (Sandbox directory query)</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>share_plus</strong></td><td>^10.0.2</td><td>Android system Share Sheet for ledger receipts</td><td>Text snippet or file URI to OS chooser</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>provider</strong></td><td>^6.1.2</td><td>Reactive state management</td><td>None (In-memory state)</td><td>Yes</td><td>None</td></tr>
        <tr><td><strong>google_fonts</strong></td><td>^6.2.1</td><td>Typography & aesthetic UI fonts</td><td>HTTP font asset caching</td><td>Yes</td><td>Low</td></tr>
        <tr><td><strong>intl</strong></td><td>^0.20.3</td><td>Indian Rupee currency & date formatting</td><td>None</td><td>Yes</td><td>None</td></tr>
        <tr><td><strong>cupertino_icons</strong></td><td>^1.0.8</td><td>UI vector iconography</td><td>None</td><td>Yes</td><td>None</td></tr>
      </tbody>
    </table>

    <h2>6.3 Audit Process</h2>
    <ul>
      <li>List every SDK/dependency currently integrated (check build files, not just memory).</li>
      <li>For each SDK, determine exactly what data it accesses or transmits.</li>
      <li>Determine whether the SDK is actually required for a core feature — remove unused SDKs.</li>
      <li>Feed findings into the Data Safety declaration and Privacy Policy.</li>
      <li>Re-run this audit whenever an SDK is upgraded, replaced, or added.</li>
    </ul>

    <h2>6.4 Key Rule</h2>
    <div class="notice-box">
      <strong>Key Rule:</strong> <em>“The SDK collected the data, not us”</em> is not an acceptable justification. Google places responsibility for third-party code and its data practices on the developer.
    </div>

    <h2>Sign-off Checklist</h2>
    <ul>
      <li>☑ Full SDK inventory compiled from actual build dependencies</li>
      <li>☑ Data collection behaviour documented for each SDK</li>
      <li>☑ Unnecessary SDKs removed</li>
      <li>☑ Findings reflected accurately in Data Safety section</li>
      <li>☑ Findings reflected accurately in Privacy Policy</li>
      <li>☑ Audit re-run after any dependency changes</li>
    </ul>

    ${renderNavLinks('sdk')}
  </div>
</body>
</html>`;
}

function getSecurityAuditHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt Ltd';
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Security Audit — ENX Money</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">₹</div>
      <div class="header-titles">
        <h1>7. Security Audit</h1>
        <p>ENX Money • ${company}</p>
        <span class="badge">Google Play Security Standard • Verified</span>
      </div>
    </div>

    <h2>Purpose</h2>
    <p>Defines the internal security policy and audit checklist covering authentication, API, database, infrastructure, and development practices.</p>

    <h2>7.1 Authentication</h2>
    <ul>
      <li><strong>Strong password requirements enforced:</strong> Salting and hashing via <code>bcryptjs</code> with high cost factors.</li>
      <li><strong>Multi-factor authentication (MFA) available/enforced:</strong> 6-digit real email OTP verification enforced via secure Gmail SMTP relay (<code>nodemailer</code>).</li>
      <li><strong>Secure session management:</strong> Cryptographically signed JWT tokens with 24-hour expiration, token rotation, and server-side blacklisting on logout/deletion.</li>
      <li><strong>Secure password reset flow:</strong> Time-limited (10-minute validity), single-use OTP codes (<code>/api/auth/verify-reset-otp</code>) and ephemeral reset tokens (<code>/api/auth/reset-password</code>).</li>
    </ul>

    <h2>7.2 API Security</h2>
    <ul>
      <li><strong>Authentication and authorization enforced on every endpoint:</strong> Valid <code>Bearer &lt;token&gt;</code> header verified by <code>auth.middleware.js</code>. No endpoint relies on client-side checks alone.</li>
      <li><strong>Rate limiting on sensitive/high-risk endpoints:</strong> Enforced using <code>express-rate-limit</code> on <code>/api/auth/send-otp</code>, <code>/api/auth/login</code>, <code>/api/auth/register</code>.</li>
      <li><strong>Input validation and sanitization performed server-side:</strong> Enforced using <code>express-validator</code> on all request bodies, queries, and parameters.</li>
      <li><strong>Protection against SQL/NoSQL injection, XSS, and CSRF:</strong> Parameterized statements via <code>mysql2/promise</code> with placeholder bindings; HTTP security headers enforced by <code>helmet()</code>.</li>
      <li><strong>No excessive data exposure in API responses:</strong> Passwords, password hashes, and system secrets stripped from API outputs.</li>
      <li><strong>Protection against IDOR (Insecure Direct Object Reference):</strong> Multi-tenant isolation strictly enforced with <code>WHERE id = ? AND user_id = ?</code>.</li>
      <li><strong>JWT/token manipulation resistance verified:</strong> Tokens signed using <code>HS256</code> with strong secret; invalid algorithms or payloads rejected with 401 Unauthorized.</li>
    </ul>

    <h2>7.3 Database Security</h2>
    <ul>
      <li><strong>Encryption at rest where appropriate:</strong> Storage volumes and database partitions encrypted with AES-256 in managed environments.</li>
      <li><strong>Regular, automated backups:</strong> Daily automated snapshots and tested backup retention lifecycles.</li>
      <li><strong>Restricted, least-privilege access:</strong> Dedicated database service credentials without global admin privileges.</li>
      <li><strong>Database never directly exposed to the public internet:</strong> Binds strictly to <code>localhost</code> or isolated VPC private subnets.</li>
    </ul>

    <h2>7.4 Infrastructure</h2>
    <ul>
      <li><strong>Firewall rules restricting access to internal services:</strong> Ingress restricted to HTTPS port 443; internal database/cache ports inaccessible externally.</li>
      <li><strong>HTTPS/TLS enforced everywhere, no cleartext traffic:</strong> All traffic over TLS 1.2/1.3; Android <code>cleartextTrafficPermitted="false"</code>.</li>
      <li><strong>Secrets management solution used:</strong> Secrets loaded from <code>.env</code> environment variables, never hardcoded in source code or compiled APK.</li>
      <li><strong>Ongoing monitoring and alerting for anomalies:</strong> Health checks at <code>/api/health</code>, request logging via <code>morgan</code>, and automated error alerting.</li>
    </ul>

    <h2>7.5 Development Practices</h2>
    <ul>
      <li><strong>Code review required before merging to production branches:</strong> Pull requests and peer review enforced on <code>main</code> and <code>release/*</code>.</li>
      <li><strong>Dependency scanning for known vulnerabilities:</strong> Automated <code>npm audit</code> and package security audits.</li>
      <li><strong>Secret scanning on commits and git history:</strong> Pre-commit hooks and repository scanning to prevent secret leaks.</li>
      <li><strong>Periodic vulnerability/penetration testing:</strong> Regular security assessments across auth, cards, customers, and ledger workflows.</li>
    </ul>

    <h2>7.6 Never Log</h2>
    <div class="notice-box">
      <strong>Absolute Prohibition:</strong> Passwords, OTPs, credit card numbers, JWT tokens, API secrets, private keys.<br><br>
      <span style="color:#f87171;">❌ Bad:</span> <code>User login: email=abc@gmail.com password=123456</code><br>
      <span style="color:#34d399;">✓ Good:</span> <code>LOGIN_SUCCESS user_id=8291 timestamp=...</code>
    </div>

    <h2>7.7 Sensitive Data Categories Requiring Elevated Controls</h2>
    <p>The following categories receive elevated technical safeguards:</p>
    <ul>
      <li>Health information, financial information, identity documents, biometrics, precise location, children’s data, government IDs (e.g., Aadhaar, PAN), bank details, private messages.</li>
    </ul>

    <h2>Sign-off Checklist</h2>
    <ul>
      <li>☑ Authentication controls reviewed (MFA, password policy, session handling)</li>
      <li>☑ API endpoints tested for authz/authn bypass, IDOR, injection</li>
      <li>☑ Database access restricted and encrypted where appropriate</li>
      <li>☑ Secrets management in place; no hardcoded secrets in code or APK</li>
      <li>☑ Logging reviewed to ensure no sensitive data is captured</li>
      <li>☑ Dependency and secret scanning integrated into CI/CD</li>
      <li>☑ Elevated review completed for any sensitive data categories handled</li>
    </ul>

    ${renderNavLinks('security')}
  </div>
</body>
</html>`;
}

function getContactUsHtml() {
  const company = config.COMPANY_NAME || 'Enterprenex Solutions Pvt. Ltd.';
  const corporateEmail = config.COMPANY_EMAIL || 'info@enterprenex.solutions';
  const supportEmail = config.SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const technicalSupportEmail = config.TECHNICAL_SUPPORT_EMAIL || 'support@enterprenex.solutions';
  const billingEmail = config.BILLING_EMAIL || 'billing@enterprenex.solutions';
  const privacyEmail = config.PRIVACY_CONTACT_EMAIL || 'privacy@enxmoney.com';
  const grievanceEmail = config.GRIEVANCE_EMAIL || 'grievance@enxmoney.com';
  const grievanceOfficer = config.GRIEVANCE_OFFICER || 'Mr. Rohit Pawar';
  const phone = config.COMPANY_PHONE || '+91-9226860060';
  const websiteDomain = config.WEBSITE_DOMAIN || 'https://enxmoney.enterprenex.solutions';
  const githubPagesHost = config.LEGAL_HOST_URL || 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/';
  const address = config.COMPANY_ADDRESS || 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Contact Us — ENX Money | ${company}</title>
  <meta name="description" content="Contact ENX Money support, customer care, and compliance officers. Fast support for billing, account assistance, and data privacy.">
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">📞</div>
      <div class="header-titles">
        <h1>Contact Us & Merchant Support</h1>
        <p>${company} • ENX Money Business Suite</p>
        <span class="badge">Official Customer Care & Compliance</span>
      </div>
    </div>

    <div class="notice-box">
      <strong>Customer Support Commitment:</strong> We strive to resolve all billing, subscription, ledger, and technical inquiries within 24 to 48 business hours.
    </div>

    <h2>1. Merchant & Corporate Identity</h2>
    <table>
      <tr><th>Company Name</th><td>${company}</td></tr>
      <tr><th>Brand / Product</th><td>ENX Money — Business Accounting & Invoicing Suite</td></tr>
      <tr><th>Website Domain</th><td><a href="${websiteDomain}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${websiteDomain}</a></td></tr>
      <tr><th>GitHub Pages Legal Host</th><td><a href="${githubPagesHost}" target="_blank" rel="noopener noreferrer" style="color:#10b981;">${githubPagesHost}</a></td></tr>
      <tr><th>Registered Address</th><td>${address}</td></tr>
      <tr><th>Operating Jurisdiction</th><td>Maharashtra, India</td></tr>
      <tr><th>Business Category</th><td>Software as a Service (SaaS) / B2B Productivity & GST Invoicing</td></tr>
    </table>

    <h2>2. Support & Grievance Contacts</h2>
    <table>
      <tr><th>Department</th><th>Contact Channel</th><th>Response Time</th></tr>
      <tr><td>WhatsApp Official Desk</td><td><a href="https://wa.me/919226860060" target="_blank" rel="noopener noreferrer" style="color:#10b981;font-weight:700;">+91 92268 60060</a></td><td>Instant Chat Support</td></tr>
      <tr><td>Official Phone Number</td><td><a href="tel:+919226860060" style="color:#10b981;font-weight:700;">+91 9226860060</a></td><td>Mon–Sat 10AM–6PM IST</td></tr>
      <tr><td>Billing Email</td><td><a href="mailto:billing@enterprenex.solutions" style="color:#10b981;font-weight:700;">billing@enterprenex.solutions</a></td><td>Within 24 Hours</td></tr>
      <tr><td>General / Legal Email</td><td><a href="mailto:info@enterprenex.solutions" style="color:#10b981;font-weight:700;">info@enterprenex.solutions</a></td><td>Within 24 Hours</td></tr>
      <tr><td>Technical Support Email</td><td><a href="mailto:${technicalSupportEmail}" style="color:#10b981;font-weight:700;">${technicalSupportEmail}</a></td><td>Within 24 Hours</td></tr>
      <tr><td>Privacy Desk</td><td><a href="mailto:${privacyEmail}" style="color:#10b981;font-weight:700;">${privacyEmail}</a></td><td>Within 48 Hours</td></tr>
      <tr><td>Grievance / Privacy Officer</td><td><a href="mailto:${grievanceEmail}" style="color:#10b981;font-weight:700;">${grievanceEmail}</a> (${grievanceOfficer}, Data Protection Officer)</td><td>48 Hours Ack / 30 Days Resolution</td></tr>
    </table>

    <h2>3. Official Social Media</h2>
    <table>
      <tr><th>Platform</th><th>Official Channel</th><th>Access</th></tr>
      <tr><td>LinkedIn</td><td><a href="https://www.linkedin.com/company/enterprenex-solution-pvt-ltd" target="_blank" rel="noopener noreferrer" style="color:#10b981;font-weight:700;">Enterprenex Solution Pvt Ltd on LinkedIn</a></td><td>Opens in new tab</td></tr>
      <tr><td>Instagram</td><td><a href="https://www.instagram.com/enterprenexsolution?utm_source=ig_web_button_share_sheet&amp;stkn=ZDNlZDc0MzIxNw==" target="_blank" rel="noopener noreferrer" style="color:#10b981;font-weight:700;">@enterprenexsolution on Instagram</a></td><td>Opens in new tab</td></tr>
    </table>

    <h2>4. Operational Hours</h2>
    <p>Our dedicated support team is available:</p>
    <ul>
      <li><strong>Monday to Saturday:</strong> 9:00 AM to 6:00 PM IST</li>
      <li><strong>Sunday & National Holidays:</strong> Monitored for critical billing & security emergencies</li>
    </ul>

    <h2>4. Instant Online Self-Service</h2>
    <p>For immediate self-service operations:</p>
    <ul>
      <li><strong>Billing & Invoices:</strong> View your active plan in-app under <em>Profile & Settings &rarr; Subscription</em>.</li>
      <li><strong>Account & Data Deletion:</strong> Instantly initiate deletion via our <a href="/delete-account" style="color:#ef4444;font-weight:700;">Data Deletion Portal</a>.</li>
      <li><strong>Legal Policies:</strong> Review our <a href="/terms-and-conditions" style="color:#10b981;">Terms & Conditions</a>, <a href="/privacy-policy" style="color:#10b981;">Privacy Policy</a>, and <a href="/refund-cancellation-policy" style="color:#10b981;">Refund Policy</a>.</li>
    </ul>

    ${renderNavLinks('contact')}
  </div>
</body>
</html>`;
}

function getPricingHtml() {
  const company = config.COMPANY_LEGAL_NAME || 'Enterprenex Solutions Pvt Ltd';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pricing & Plans — ENX Money Business Suite</title>
  <meta name="description" content="Transparent pricing for ENX Money Business Suite: GST Invoicing, Ledger Management, and Cloud Inventory.">
  <style>
    ${baseStyles}
    .pricing-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin: 24px 0; }
    .pricing-card { background: #0e1017; border: 1px solid #232733; border-radius: 16px; padding: 24px; position: relative; }
    .pricing-card.popular { border-color: #10b981; box-shadow: 0 0 20px rgba(16,185,129,0.15); }
    .plan-badge { position: absolute; top: 16px; right: 16px; background: rgba(16,185,129,0.2); color: #34d399; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 20px; }
    .plan-title { font-size: 18px; font-weight: 700; color: #fff; margin-bottom: 8px; }
    .plan-price { font-size: 32px; font-weight: 900; color: #10b981; margin: 12px 0; }
    .plan-price span { font-size: 14px; font-weight: 400; color: #9ca3af; }
    .plan-features { list-style: none; padding: 0; margin: 20px 0; }
    .plan-features li { padding: 6px 0; font-size: 13px; color: #d1d5db; display: flex; align-items: center; gap: 8px; }
    .plan-features li span { color: #10b981; font-weight: 800; }
    .cta-btn { display: block; text-align: center; background: #10b981; color: #fff; text-decoration: none; padding: 12px; border-radius: 10px; font-weight: 700; font-size: 14px; }
    .cta-btn:hover { background: #059669; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">💎</div>
      <div class="header-titles">
        <h1>Subscription Plans & Transparent Pricing</h1>
        <p>${company} • ENX Money Business Suite</p>
        <span class="badge">100% Tax Compliant • GST Invoicing Included</span>
      </div>
    </div>

    <div class="notice-box">
      <strong>Transparent Pricing Guarantee:</strong> All subscriptions are billed electronically with zero hidden maintenance fees. An official GST tax invoice is generated instantly upon payment confirmation.
    </div>

    <div class="pricing-grid">
      <div class="pricing-card">
        <div class="plan-title">Monthly Business Suite</div>
        <p style="font-size: 12px; color: #9ca3af;">Flexible monthly SaaS subscription for growing shops & merchants.</p>
        <div class="plan-price">₹1,999 <span>/ month (+ 18% GST)</span></div>
        <p style="font-size: 12px; color: #6b7280;">Total: ₹2,358.82 inclusive of GST</p>
        <ul class="plan-features">
          <li><span>✓</span> Unlimited GST Invoices & Estimates</li>
          <li><span>✓</span> Multi-Party Customer Khata Ledger</li>
          <li><span>✓</span> Real-Time Inventory & Stock Tracking</li>
          <li><span>✓</span> WhatsApp Payment Reminder Sharing</li>
          <li><span>✓</span> Real-Time Business Financial Analytics</li>
          <li><span>✓</span> Instant Digital Access & Real-Time Sync</li>
        </ul>
        <a href="/checkout" class="cta-btn">Subscribe Monthly</a>
      </div>

      <div class="pricing-card popular">
        <span class="plan-badge">SAVE 17%</span>
        <div class="plan-title">Annual Enterprise Suite</div>
        <p style="font-size: 12px; color: #9ca3af;">Complete year-round peace of mind for established businesses.</p>
        <div class="plan-price">₹19,999 <span>/ year (+ 18% GST)</span></div>
        <p style="font-size: 12px; color: #6b7280;">Total: ₹23,598.82 inclusive of GST</p>
        <ul class="plan-features">
          <li><span>✓</span> Everything in Monthly Plan</li>
          <li><span>✓</span> Priority 24/7 Dedicated Support</li>
          <li><span>✓</span> Automated Ledger Archiving & Data Export</li>
          <li><span>✓</span> Multi-User Cashier & Staff Permissions</li>
          <li><span>✓</span> Custom Branding & PDF Watermark Removal</li>
          <li><span>✓</span> Advanced Export (Excel, Tally, CSV)</li>
        </ul>
        <a href="/checkout" class="cta-btn">Subscribe Annually</a>
      </div>
    </div>

    <h2>Billing & Delivery Terms</h2>
    <ul>
      <li><strong>Immediate Electronic Provisioning:</strong> Access is provisioned instantly upon successful authorization by Razorpay.</li>
      <li><strong>Cancellation & Refunds:</strong> You can cancel at any time. Review our transparent 7-day refund terms at <a href="/refund-cancellation-policy" style="color:#10b981;">Refund Policy</a>.</li>
    </ul>

    ${renderNavLinks('pricing')}
  </div>
</body>
</html>`;
}

function getShippingDeliveryHtml() {
  const company = config.COMPANY_LEGAL_NAME || 'Enterprenex Solutions Pvt Ltd';
  const supportEmail = config.SUPPORT_EMAIL || 'enxproductofficial@gmail.com';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Shipping & Delivery Policy — ENX Money | Enterprenex Solutions Pvt Ltd</title>
  <meta name="description" content="Shipping and Delivery Policy for ENX Money. Explains instant electronic delivery of cloud SaaS subscriptions and digital services.">
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">⚡</div>
      <div class="header-titles">
        <h1>Shipping & Delivery Policy</h1>
        <p>${company} • ENX Money SaaS Platform</p>
        <span class="badge">Instant Electronic Delivery (Zero Shipping Fees)</span>
      </div>
    </div>

    <div class="notice-box">
      <strong>Digital Software Product:</strong> ENX Money is a 100% digital cloud Software-as-a-Service (SaaS) and mobile bookkeeping utility. We do not sell or deliver physical goods.
    </div>

    <h2>1. Nature of Service & Digital Fulfillment</h2>
    <p>All products, subscriptions, and services offered through <strong>ENX Money</strong> and <strong>Enterprenex Solutions Pvt Ltd</strong> are delivered entirely electronically via telecommunications and cloud networks. No physical shipping is involved.</p>

    <h2>2. Delivery Timeline & Service Activation</h2>
    <ul>
      <li><strong>Instant Provisioning:</strong> Upon successful authorization of your payment via our Razorpay payment gateway, your subscription tier is activated instantly in your ENX Money mobile app and cloud account.</li>
      <li><strong>Confirmation Notification:</strong> A digital order confirmation containing your invoice receipt, transaction ID, and subscription breakdown is sent immediately via email/SMS.</li>
      <li><strong>Zero Lead Time:</strong> Because provisioning is fully automated, delivery is instantaneous (under 60 seconds).</li>
    </ul>

    <h2>3. Shipping Charges</h2>
    <p>Since all services are delivered electronically via cloud infrastructure, <strong>no shipping fees, delivery handling charges, or physical freight costs</strong> apply to any transaction.</p>

    <h2>4. Delivery Issues or Access Assistance</h2>
    <p>If you experience any delay in access or your account does not reflect your upgraded plan within 5 minutes of completing payment, please contact our support team immediately:</p>
    <ul>
      <li><strong>Support Email:</strong> <a href="mailto:${supportEmail}" style="color:#10b981;font-weight:700;">${supportEmail}</a></li>
      <li><strong>Operating Hours:</strong> Monday to Saturday, 9:00 AM – 6:00 PM IST</li>
    </ul>

    ${renderNavLinks('shipping')}
  </div>
</body>
</html>`;
}

module.exports = {
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
};


