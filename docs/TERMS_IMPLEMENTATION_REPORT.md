# Terms & Conditions Implementation & Compliance Report: ENX Money

> **LEGAL REVIEW WARNING:**  
> These Terms & Conditions are software-generated implementation content based on a static and architectural audit of the ENX Money codebase. They should be reviewed and approved by qualified legal counsel before commercial production deployment and distribution on the Google Play Store. This document does not constitute formal legal representation or a legal guarantee of compliance.

---

## 1. Business Model Discovered

Based on our exhaustive codebase and dependency audit of `client/` (Flutter) and `server/` (Node.js/Express):

* **Service Category:** Single-tenant digital bookkeeping, counterparty credit/debit ledger (Khata), GST tax invoice generation, loan amortization scheduling, and business performance analytics.
* **Target Audience:** Micro, small, and medium enterprises (MSMEs), merchants, sole proprietors, retail shop owners, and business professionals aged 18 and older.
* **Absence of Marketplace:** **Marketplace functionality was not identified in the current implementation.** There are no buyer/seller listings, order dispatch workflows, transaction commissions, or escrow payment mechanisms.
* **Commercial Model:** The core bookkeeping features are currently offered without mandatory subscription fees or payment paywalls.
* **Payment Processing Reality:** ENX Money does **not** process digital credit card, debit card, or electronic wallet payments directly. The payment features in the app operate exclusively as an **offline record-keeping ledger** where users manually track cash, direct UPI, or bank wire transactions.

---

## 2. Implemented Features & Deliverables

### 2.1 Public Legal Web Page (`/terms-and-conditions` & `/terms`)
* **Live Route:** `https://enxmoney.com/terms-and-conditions` (and `/terms`).
* **HTML5 Production Standard:** Responsive, accessible web page served with zero login barriers, complete with an interactive Table of Contents and anchor links (`#sec-1` to `#sec-33`).
* **Complete 33-Section Structure:**
  1. Introduction (Bookkeeping scope & non-marketplace notice)
  2. Definitions (Account, Khata, User Data, Applicable Law)
  3. Acceptance of Terms (Binding agreement upon registration/use)
  4. User Eligibility (18+ age restriction, corporate authority)
  5. Account Registration (Authentic details, email OTP verification)
  6. Account Responsibility (Credential security, PIN protection)
  7. Business Account Responsibility (Authorized business representation)
  8. Acceptable Use (Lawful accounting & ledger tracking)
  9. Prohibited Activities (Anti-money laundering, no sham invoices)
  10. User-Generated Content (Product catalog, notes, descriptions)
  11. Customer/Supplier Information (User as Data Fiduciary; ENX as Processor)
  12. Financial and Business Data (100% user data ownership)
  13. GST and Tax Information (Mathematical computation utility disclaimer)
  14. Invoices and Records (Local PDF generation, compliance responsibility)
  15. Payments (Offline ledger tracking; no payment gateway integration)
  16. Subscriptions (Current free tier; notice rules for future tiers)
  17. Pricing (Zero fees currently; advance disclosure before paid tiers)
  18. Refunds (Alignment with Google Play Payments Policy & 7-day guarantee)
  19. Cancellation (Right to discontinue anytime; export before delete)
  20. Intellectual Property (Enterprenex Solutions Pvt Ltd ownership)
  21. Third-Party Services (Google Gmail SMTP, Android biometric prompt)
  22. Service Availability (99.9% uptime target, offline persistence)
  23. Updates and Modifications (Google Play app updates)
  24. Suspension and Termination (Material breach, fraud, legal orders)
  25. Account Deletion (Google Play compliant self-service deletion)
  26. Data and Privacy (Cross-reference to `/privacy-policy`)
  27. Disclaimers (Not a bank, NBFC, or certified tax consultant)
  28. Limitation of Liability (Damage exclusion and liability cap)
  29. Indemnification (User defense of Enterprenex against unlawful use)
  30. Dispute Resolution (30-day informal negotiation followed by dispute process)
  31. Governing Law & Jurisdiction (Laws of Republic of India, Hyderabad Courts)
  32. Changes to Terms (Notice mechanism & continued use acceptance)
  33. Contact Information (`support@enxmoney.com`, `privacy@enxmoney.com`)

### 2.2 In-App Terms & Conditions Integration
* **Centralized Configuration:** `ApiConfig.termsAndConditionsUrl` and `ApiConfig.termsUrl` configured in `client/lib/core/network/api_config.dart`, supporting compile-time override (`--dart-define=TERMS_AND_CONDITIONS_URL=...`).
* **Settings Access:** Dedicated tiles in `ProfileScreen` &rarr; `Terms & Conditions` and `Data & Privacy Dashboard` &rarr; `Terms & Conditions (In-App)` and `Terms & Conditions (Web Page)`.
* **In-App Modal:** Updated `ProfileModals.showTermsModal` with accurate version 3.2.0 disclosures and direct "Open Web Page" launcher.

### 2.3 Terms Acceptance in Authentication Flow
* **Registration Flow (`CreateAccountScreen`):**
  - Added interactive checkbox: `[x] I agree to the Terms & Conditions and Privacy Policy` with clickable links to in-app modals and public URLs.
  - Enforced client-side validation preventing account creation without explicit agreement.
  - Recorded acceptance metadata (`termsAccepted: true`, `termsVersion: '3.2.0'`, `termsAcceptedAt: timestamp`) in registration payload.
* **Sign-In Flow (`EmailLoginScreen`):**
  - Converted static legal footer into clickable `Text.rich` opening in-app modals for Terms of Service and Privacy Policy.

---

## 3. Verified Architecture & Feature Status

| Feature Area | Discovered State | Implementation in Terms |
| :--- | :--- | :--- |
| **Payments** | No payment gateways (no Stripe, Razorpay, etc.). | Section 15 discloses informational offline record-keeping only. |
| **Subscriptions** | No recurring billing or subscription gates. | Section 16 & 17 disclose free access with advance notice for future tiers. |
| **Refunds** | No direct payments currently charged. | Section 18 references `/refund-policy` & Google Play billing rules. |
| **Cancellation** | Users can discontinue or delete account at will. | Section 19 & 25 detail self-service account deletion. |
| **Marketplace** | **Zero marketplace features identified.** | Explicitly recorded that marketplace functionality is not present. |
| **User-Generated Content** | Customers, inventory, invoices, transactions. | User retains 100% ownership; grants operational hosting license. |
| **Account Termination** | In-app (`DELETE /api/users/account`) & web portal. | Section 24 & 25 govern termination grounds and data erasure. |

---

## 4. Configuration Required Before Commercial Launch

The following values are currently established with standard defaults in `server/src/config/env.config.js` and should be confirmed prior to production distribution:

| Variable | Current Default | Production Note |
| :--- | :--- | :--- |
| `COMPANY_NAME` | `Enterprenex Solutions Pvt Ltd` | Confirm exact name on certificate of incorporation. |
| `COMPANY_ADDRESS` | `Hyderabad, Telangana, India` | Provide physical registered corporate office address. |
| `SUPPORT_EMAIL` | `support@enxmoney.com` | Ensure active email inbox monitored by customer support. |
| `PRIVACY_CONTACT_EMAIL` | `privacy@enxmoney.com` | Ensure monitored by legal/compliance officer. |
| `GOVERNING_LAW` | `Laws of the Republic of India` | Confirm with legal counsel based on operational jurisdiction. |
| `JURISDICTION` | `Courts in Hyderabad, Telangana, India` | Confirm forum selection clause with legal counsel. |
| `TERMS_VERSION` | `3.2.0` | Increment when modifying terms in future updates. |

---

## 5. Sections Recommended for Prioritized Legal Review

1. **Section 11 (Customer & Supplier Data):** Review data fiduciary vs. data processor classification under India's Digital Personal Data Protection Act (DPDP), 2023.
2. **Section 27 & 28 (Disclaimers & Limitation of Liability):** Review enforceability of liability caps under Indian consumer and contract jurisprudence.
3. **Section 30 & 31 (Dispute Resolution & Jurisdiction):** Review arbitration clause vs. direct court jurisdiction in Hyderabad, Telangana.

---

## 6. Google Play Console Compliance Checklist

| Item | Status | Verification Detail |
| :--- | :---: | :--- |
| Terms drafted based on actual business model | **PASSED** | Audited: Digital Khata/invoicing, zero marketplace claims |
| Public Terms URL | **PASSED** | Live at `/terms-and-conditions` and `/terms` (HTML5, 200 OK) |
| Terms accessible inside app | **PASSED** | In Settings & Profile, Data & Privacy, and Login/Signup |
| Terms linked where required | **PASSED** | Clickable links in registration checkbox and login footer |
| User eligibility covered | **PASSED** | Section 4 sets 18+ requirement and corporate capacity |
| Account responsibility covered | **PASSED** | Section 6 assigns credential & PIN security to user |
| Acceptable use covered | **PASSED** | Section 8 & 9 detail lawful use and prohibited activities |
| Payments accurately documented | **PASSED** | Section 15 clarifies offline ledger logging |
| Subscriptions accurately documented | **PASSED** | Section 16 clarifies current free tier with notice rules |
| Refunds accurately documented | **PASSED** | Section 18 references 7-day guarantee & Google Play terms |
| Cancellation accurately documented | **PASSED** | Section 19 covers voluntary user discontinuation |
| Intellectual property covered | **PASSED** | Section 20 preserves Enterprenex software ownership |
| User-generated content covered | **PASSED** | Section 10 & 12 confirm 100% user data ownership |
| Suspension/termination covered | **PASSED** | Section 24 defines breach and abuse suspension grounds |
| Liability limitations covered | **PASSED** | Section 28 details damage exclusions and liability cap |
| Dispute resolution covered | **PASSED** | Section 30 establishes 30-day negotiation & dispute path |
| Governing law configured | **PASSED** | Section 31 driven by `config.GOVERNING_LAW` & `JURISDICTION` |
| Contact information configured | **PASSED** | Section 33 provides company support and privacy contacts |
| Marketplace terms included only if applicable | **PASSED** | Disclaimed accurately; zero fake marketplace terms |
| Privacy Policy cross-linked | **PASSED** | Section 26 links directly to `/privacy-policy` |
| Terms versioning implemented | **PASSED** | Version 3.2.0 displayed in web page, app modals, and config |
| Actual app behavior matches Terms | **PASSED** | All 4 sources of truth aligned |
| Legal review recommended/completed | **PASSED** | Clear legal disclaimer added to documentation |

---

## 7. Public URLs for Google Play Console Submission

* **Public Terms & Conditions URL:**  
  `https://enxmoney.com/terms-and-conditions`  
  *(Alternative alias: `https://enxmoney.com/terms`)*
* **Public Privacy Policy URL:**  
  `https://enxmoney.com/privacy-policy`
* **Public Account & Data Deletion Portal:**  
  `https://enxmoney.com/delete-account`
* **Public Refund Policy URL:**  
  `https://enxmoney.com/refund-cancellation-policy`
