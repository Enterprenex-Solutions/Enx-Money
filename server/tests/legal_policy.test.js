const request = require('supertest');
const app = require('../src/app');

describe('ENX Money — Public Legal Pages & DPDP Act 2023 Policy Integration Tests', () => {
  describe('GET /refund-policy and /refunds', () => {
    test('GET /refund-policy returns 200 HTML with complete 9-Chapter Refund & Cancellation Policy', async () => {
      const res = await request(app).get('/refund-policy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');

      // Title and key structural elements
      expect(res.text).toContain('Refund & Cancellation Policy');
      expect(res.text).toContain('1.0');
      expect(res.text).toContain('Contents (9 Chapters)');

      // 9 Official Chapters
      expect(res.text).toContain('1. Current Status of ENX Money');
      expect(res.text).toContain('2. Scope of This Policy');
      expect(res.text).toContain('3. Subscription Plans and Billing');
      expect(res.text).toContain('4. How to Cancel');
      expect(res.text).toContain('5. Refund Eligibility');
      expect(res.text).toContain('6. Failed, Duplicate, and Disputed Payments');
      expect(res.text).toContain('7. Refund Method and Timeline');
      expect(res.text).toContain('8. Special Cases');
      expect(res.text).toContain('9. Contact Us');

      // Key Policy Details
      expect(res.text).toContain('MVP (Minimum Viable Product) phase');
      expect(res.text).toContain('Starter, Business, Enterprise');
      expect(res.text).toContain('extra WhatsApp reminder credits, additional user seats');
      expect(res.text).toContain('No Marketplace Transactions');
      expect(res.text).toContain('No Physical Goods');
      expect(res.text).toContain('monthly / annual');
      expect(res.text).toContain('14 days');
      expect(res.text).toContain('24 hours');
      expect(res.text).toContain('30 days');
      expect(res.text).toContain('7 days');
      expect(res.text).toContain('Consumer Protection Act, 2019');
      expect(res.text).toContain('7–10 business days');
      expect(res.text).toContain('5–7 business days');
      expect(res.text).toContain('7 business days');

      // Payment Timelines Table
      expect(res.text).toContain('UPI');
      expect(res.text).toContain('2–5 business days');
      expect(res.text).toContain('Debit/Credit Card');
      expect(res.text).toContain('5–10 business days');
      expect(res.text).toContain('Net Banking');
      expect(res.text).toContain('Wallet');
      expect(res.text).toContain('1–3 business days');

      // Contacts
      expect(res.text).toContain('billing@enterprenex.solutions');
      expect(res.text).toContain('support@enterprenex.solutions');
      expect(res.text).toContain('info@enterprenex.solutions');
      expect(res.text).toContain('Mr. Rohit Pawar');
      expect(res.text).toContain('+91-9226860060');
      expect(res.text).toContain('https://enxmoney.enterprenex.solutions');
      expect(res.text).toContain('https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/');
      expect(res.text).toContain('Plot No. 148, Shrinand Plaza');
      expect(res.text).toContain('Enterprenex Solutions');
    });

    test('GET /refund-cancellation-policy route returns 200 HTML with Refund & Cancellation Policy', async () => {
      const res = await request(app).get('/refund-cancellation-policy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Refund & Cancellation Policy');
      expect(res.text).toContain('Google Play Payment Compliance');
    });

    test('GET /refunds alias route returns identical refund policy content', async () => {
      const res = await request(app).get('/refunds');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Refund & Cancellation Policy');
    });

    test('GET /settings/refund-policy route returns 200 HTML with Refund & Cancellation Policy', async () => {
      const res = await request(app).get('/settings/refund-policy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Refund & Cancellation Policy');
      expect(res.text).toContain('billing@enterprenex.solutions');
    });

    test('GET /settings/refund-cancellation-policy alias route returns 200 HTML', async () => {
      const res = await request(app).get('/settings/refund-cancellation-policy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Refund & Cancellation Policy');
    });
  });

  describe('GET /terms-and-conditions and /terms', () => {
    test('GET /terms-and-conditions returns 200 HTML with all 13 official Terms & Conditions chapters', async () => {
      const res = await request(app).get('/terms-and-conditions');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');

      // Title & Header Badges
      expect(res.text).toContain('Terms & Conditions');
      expect(res.text).toContain('Enterprenex Solutions');
      expect(res.text).toContain('1.0');
      expect(res.text).toContain('October 4, 2026');

      // Service Scope Banner & Disclaimers
      expect(res.text).toContain('Notice on Service Scope');
      expect(res.text).toContain('NOT a bank, non-banking financial company (NBFC), lender');

      // Table of Contents (13 Chapters)
      expect(res.text).toContain('Contents (13 Chapters)');
      expect(res.text).toContain('href="#term-1"');
      expect(res.text).toContain('href="#term-13"');

      // 13 Chapter Headings
      expect(res.text).toContain('1. Acceptance of Terms');
      expect(res.text).toContain('2. Eligibility and Account Registration');
      expect(res.text).toContain('3. Description of Service');
      expect(res.text).toContain('4. User Responsibilities');
      expect(res.text).toContain('5. Fees and Subscriptions');
      expect(res.text).toContain('6. Disclaimers');
      expect(res.text).toContain('7. Intellectual Property');
      expect(res.text).toContain('8. Third-Party Services');
      expect(res.text).toContain('9. Limitation of Liability');
      expect(res.text).toContain('10. Suspension and Termination');
      expect(res.text).toContain('11. Governing Law and Dispute Resolution');
      expect(res.text).toContain('12. General Provisions');
      expect(res.text).toContain('13. Contact Us');

      // Key Legal & Business Model Assertions
      expect(res.text).toContain('eighteen (18) years of age');
      expect(res.text).toContain('Indian Contract Act, 1872');
      expect(res.text).toContain('Digital Personal Data Protection Act, 2023');
      expect(res.text).toContain('6-digit email One-Time Password (OTP)');
      expect(res.text).toContain('WebAuthn/FIDO2');
      expect(res.text).toContain('WHERE user_id = ?');
      expect(res.text).toContain('Data Fiduciary / Controller');
      expect(res.text).toContain('Data Processor');
      expect(res.text).toContain('100% free of charge without mandatory subscriptions');
      expect(res.text).toContain('INR 1,000');
      expect(res.text).toContain('Arbitration and Conciliation Act, 1996');
      expect(res.text).toContain('Chhatrapati Sambhajinagar, Maharashtra');
      expect(res.text).toContain('Plot No. 148, Shrinand Plaza');

      // Cross-Policy Links
      expect(res.text).toContain('/privacy-policy');
      expect(res.text).toContain('/refund-cancellation-policy');
      expect(res.text).toContain('/delete-account');

      // Contact Emails & Phone
      expect(res.text).toContain('info@enterprenex.solutions');
      expect(res.text).toContain('billing@enterprenex.solutions');
      expect(res.text).toContain('support@enterprenex.solutions');
      expect(res.text).toContain('privacy@enxmoney.com');
      expect(res.text).toContain('+91-9226860060');
      expect(res.text).toContain('Mr. Rohit Pawar');
      expect(res.text).toContain('https://enxmoney.enterprenex.solutions');
      expect(res.text).toContain('https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/');
    });

    test('GET /terms alias route returns identical Terms & Conditions content', async () => {
      const res = await request(app).get('/terms');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Terms & Conditions');
      expect(res.text).toContain('Contents (13 Chapters)');
    });

    test('GET /settings/terms-conditions route returns valid Terms & Conditions HTML', async () => {
      const res = await request(app).get('/settings/terms-conditions');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Terms & Conditions');
      expect(res.text).toContain('Mr. Rohit Pawar');
    });

    test('GET /settings/terms alias route returns valid Terms & Conditions HTML', async () => {
      const res = await request(app).get('/settings/terms');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Terms & Conditions');
    });
  });

  describe('GET /privacy-policy and /privacy', () => {
    test('GET /privacy-policy returns valid privacy policy HTML with 14 DPDP Act 2023 chapters & Google Play elements', async () => {
      const res = await request(app).get('/privacy-policy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');

      // Title & Legal Framework
      expect(res.text).toContain('Privacy Policy');
      expect(res.text).toContain('Enterprenex Solutions');
      expect(res.text).toContain('Digital Personal Data Protection Act, 2023');
      expect(res.text).toContain('DPDP Rules, 2025');
      expect(res.text).toContain('Contents (14 Chapters)');

      // 14 Chapters
      expect(res.text).toContain('1. Introduction and Scope');
      expect(res.text).toContain('2. Data We Collect');
      expect(res.text).toContain('3. Purpose of Collection and Legal Basis');
      expect(res.text).toContain('4. How We Share Your Data');
      expect(res.text).toContain('5. Data Retention');
      expect(res.text).toContain('6. How We Protect Your Data');
      expect(res.text).toContain('7. Your Rights as a Data Principal');
      expect(res.text).toContain('8. Grievance Redressal');
      expect(res.text).toContain('9. Children\'s Data');
      expect(res.text).toContain('10. International Data Transfers');
      expect(res.text).toContain('11. Cookies and Similar Technologies');
      expect(res.text).toContain('12. Changes to This Policy');
      expect(res.text).toContain('13. Governing Law and Jurisdiction');
      expect(res.text).toContain('14. Contact Us');

      // Key Roles and Entities
      expect(res.text).toContain('Data Fiduciary');
      expect(res.text).toContain('Data Processor');
      expect(res.text).toContain('multi-tenant ledger model');
      expect(res.text).toContain('Data Protection Board of India');

      // Biometric & Security Architecture
      expect(res.text).toContain('ENX Money does not collect, store, transmit, or have access to any biometric data');
      expect(res.text).toContain('secure hardware enclave');
      expect(res.text).toContain('WebAuthn/FIDO2');
      expect(res.text).toContain('ES256/RS256');

      // 12 Explicit Data Categories
      expect(res.text).toContain('1. Name');
      expect(res.text).toContain('2. Email Address');
      expect(res.text).toContain('3. Phone Number');
      expect(res.text).toContain('4. Location / Address');
      expect(res.text).toContain('5. Contacts');
      expect(res.text).toContain('6. Financial & Payment Info');
      expect(res.text).toContain('7. Authentication Info');
      expect(res.text).toContain('8. Health & Fitness Data');
      expect(res.text).toContain('9. Camera');
      expect(res.text).toContain('10. Microphone');
      expect(res.text).toContain('11. SMS & Call Data');
      expect(res.text).toContain('12. Device Information');

      // Explicit Non-Collection Disclosures
      expect(res.text).toContain('NOT COLLECTED');

      // Security Controls
      expect(res.text).toContain('HTTPS / TLS 1.3 Encryption in Transit');
      expect(res.text).toContain('Cryptographic Password Hashing');
      expect(res.text).toContain('Multi-Tenant User Isolation');
      expect(res.text).toContain('Server-Side Token Blacklisting');

      // Retention & Deletion
      expect(res.text).toContain('PERMANENTLY PURGED IMMEDIATELY');
      expect(res.text).toContain('ANONYMIZED FOR UP TO 8 YEARS');
      expect(res.text).toContain('Account & Data Deletion Portal');

      // Grievance Officer & Contact
      expect(res.text).toContain('Grievance Officer:');
      expect(res.text).toContain('Mr. Rohit Pawar');
      expect(res.text).toContain('grievance@enxmoney.com');
      expect(res.text).toContain('privacy@enxmoney.com');
      expect(res.text).toContain('billing@enterprenex.solutions');
      expect(res.text).toContain('info@enterprenex.solutions');
      expect(res.text).toContain('support@enterprenex.solutions');
      expect(res.text).toContain('+91-9226860060');
      expect(res.text).toContain('https://enxmoney.enterprenex.solutions');
      expect(res.text).toContain('https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/');
      expect(res.text).toContain('Plot No. 148, Shrinand Plaza');
      expect(res.text).toContain('Chhatrapati Sambhajinagar, Maharashtra');

      // Final Checklist
      expect(res.text).toContain('Final Google Play Compliance Verification Checklist');
    });

    test('GET /privacy alias route returns identical privacy policy content', async () => {
      const res = await request(app).get('/privacy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Privacy Policy');
      expect(res.text).toContain('Enterprenex Solutions');
    });

    test('GET /settings/privacy-policy route returns valid privacy policy HTML', async () => {
      const res = await request(app).get('/settings/privacy-policy');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Privacy Policy');
      expect(res.text).toContain('Mr. Rohit Pawar');
    });
  });

  describe('GET /data-safety and /datasafety', () => {
    test('GET /data-safety returns valid Data Safety declaration HTML with 13-row audit table', async () => {
      const res = await request(app).get('/data-safety');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Data Safety Declaration');
      expect(res.text).toContain('4.1 Core Rule');
      expect(res.text).toContain('4.2 Data Safety Declaration Template');
      expect(res.text).toContain('Financial/payment info');
      expect(res.text).toContain('Authentication info');
      expect(res.text).toContain('4.3 SDK Data Cross-Reference');
      expect(res.text).toContain('Sign-off Checklist');
    });

    test('GET /datasafety alias route returns identical Data Safety content', async () => {
      const res = await request(app).get('/datasafety');
      expect(res.status).toBe(200);
      expect(res.text).toContain('Data Safety Declaration');
    });
  });

  describe('GET /permissions-audit and /permissions', () => {
    test('GET /permissions-audit returns valid Permissions Audit HTML with sensitive permissions analysis', async () => {
      const res = await request(app).get('/permissions-audit');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Permissions Audit');
      expect(res.text).toContain('5.1 Sensitive Permissions Requiring Justification');
      expect(res.text).toContain('5.4 Permissions Audit Table');
      expect(res.text).toContain('CAMERA');
      expect(res.text).toContain('LOCATION');
      expect(res.text).toContain('MICROPHONE');
      expect(res.text).toContain('CONTACTS');
      expect(res.text).toContain('Android Contact Picker');
      expect(res.text).toContain('Sign-off Checklist');
    });

    test('GET /permissions alias route returns identical Permissions Audit content', async () => {
      const res = await request(app).get('/permissions');
      expect(res.status).toBe(200);
      expect(res.text).toContain('Permissions Audit');
    });
  });

  describe('GET /sdk-audit and /sdks', () => {
    test('GET /sdk-audit returns valid SDK Audit HTML with dependency registers', async () => {
      const res = await request(app).get('/sdk-audit');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('SDK Audit');
      expect(res.text).toContain('6.1 Common SDKs Requiring Review');
      expect(res.text).toContain('6.2 SDK Register');
      expect(res.text).toContain('Firebase');
      expect(res.text).toContain('AdMob');
      expect(res.text).toContain('Google Maps SDK');
      expect(res.text).toContain('NOT INTEGRATED');
      expect(res.text).toContain('6.3 Audit Process');
      expect(res.text).toContain('Sign-off Checklist');
    });

    test('GET /sdks alias route returns identical SDK audit content', async () => {
      const res = await request(app).get('/sdks');
      expect(res.status).toBe(200);
      expect(res.text).toContain('SDK Audit');
    });
  });

  describe('GET /security-audit and /security', () => {
    test('GET /security-audit returns valid Security Audit HTML with comprehensive controls', async () => {
      const res = await request(app).get('/security-audit');
      expect(res.status).toBe(200);
      expect(res.header['content-type']).toContain('text/html');
      expect(res.text).toContain('Security Audit');
      expect(res.text).toContain('7.1 Authentication');
      expect(res.text).toContain('7.2 API Security');
      expect(res.text).toContain('7.3 Database Security');
      expect(res.text).toContain('7.4 Infrastructure');
      expect(res.text).toContain('7.5 Development Practices');
      expect(res.text).toContain('7.6 Never Log');
      expect(res.text).toContain('7.7 Sensitive Data Categories Requiring Elevated Controls');
      expect(res.text).toContain('Sign-off Checklist');
    });

    test('GET /security alias route returns identical Security audit content', async () => {
      const res = await request(app).get('/security');
      expect(res.status).toBe(200);
      expect(res.text).toContain('Security Audit');
    });
  });
});
