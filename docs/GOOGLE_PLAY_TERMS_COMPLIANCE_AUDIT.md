# Google Play Terms & Policy Compliance Audit: ENX Money

**Audit Date:** September 5, 2026  
**Application:** ENX Money (`com.enterprenex.enx_money`)  
**Publisher:** Enterprenex Solutions Pvt Ltd  
**Target App Version:** 3.2.0  

---

## 1. Compliance Audit Matrix

| Google Play / Developer Policy Requirement | Actual App Implementation | Terms & Conditions Clause | Compliance Status | Verification Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Clear Business & Service Identification** | Digital bookkeeping, Khata, GST invoices, loan tracking utility. | Section 1 (Introduction) & Section 2 (Definitions) explicitly declare SaaS bookkeeping scope. | **COMPLIANT** | Confirmed: Zero false claims of banking or lending status. |
| **Marketplace Disclosures** | App does NOT act as a marketplace; no buyer/seller listings or platform trades. | Explicitly disclaims marketplace intermediary status; confirms direct merchant tool. | **COMPLIANT** | Audited: No marketplace functionality exists in code. |
| **User Eligibility & Minors Policy** | App targets micro/small businesses and adult accounting. No child features. | Section 4 (User Eligibility) sets minimum age at 18; restricted to legally competent users. | **COMPLIANT** | Matches Privacy Policy Section 19 (Children's Privacy). |
| **Account & Password Security** | Bcrypt password hashing, 6-digit email OTPs, JWT tokens, on-device biometric lock. | Section 5 (Registration) & Section 6 (Account Responsibility) assign credential security to user. | **COMPLIANT** | Security mechanisms verified in `auth.service.js` & `local_auth`. |
| **Acceptable Use & Anti-Fraud** | Multi-tenant tenant isolation (`WHERE user_id = ?`), input validation, rate limiting. | Section 8 (Acceptable Use) & Section 9 (Prohibited Activities) prohibit laundering, fraudulent invoices, malware. | **COMPLIANT** | IDOR guards and Express Validator middleware verified. |
| **Financial & Tax Disclaimer** | App calculates GST slabs (0-28%) and loan EMIs mathematically based on user inputs. | Section 11 & Section 27 declare software calculations are NOT certified legal, tax, or accounting advice. | **COMPLIANT** | Protects merchant while ensuring compliance with Indian tax laws. |
| **Payment Gateway Disclosures** | App has NO integrated payment gateways (no credit card charging, no wallet). | Section 15 (Payments) accurately discloses software is informational record-keeping only. | **COMPLIANT** | Confirmed: Zero payment gateway SDKs in client or server. |
| **Subscription & Billing Transparency** | Free tier access; zero paywalls or recurring credit card billing currently present. | Section 16 (Subscriptions) & Section 17 (Pricing) declare current free tier with notice rights for future tiers. | **COMPLIANT** | Aligned with Google Play Payments Policy (no deceptive billing). |
| **Refunds & Cancellation Policy** | Digital tool; no automated subscription billing currently processed. | Section 18 (Refunds) & Section 19 (Cancellation) outline 7-day policy for future tiers and Google Play billing alignment. | **COMPLIANT** | Cross-linked to `/refund-policy`. |
| **User Content Ownership** | User enters customers, suppliers, inventory, and notes stored in MySQL partition. | Section 10 & Section 12 establish user retains full ownership of data; grants limited operational license. | **COMPLIANT** | Confirmed: Enterprenex claims no ownership of merchant records. |
| **Data Deletion & Account Termination** | Self-service in-app deletion (`DELETE /api/users/account`) & public portal (`/delete-account`). | Section 24 (Termination) & Section 25 (Account Deletion) specify permanent erasure and anonymization rules. | **COMPLIANT** | Meets Google Play User Data & Account Deletion Policy. |
| **Privacy Policy Consistency** | 24-section audited Privacy Policy live at `/privacy-policy`. | Section 26 (Data & Privacy) cross-references Privacy Policy and confirms GDPR/DPDP alignment. | **COMPLIANT** | 100% consistent across Terms, Privacy, and Codebase. |
| **Public Unauthenticated Access** | Legal web pages served over HTTP/HTTPS by Express server without login barriers. | Terms live at `/terms-and-conditions` and `/terms` as responsive HTML5 web pages. | **COMPLIANT** | Tested: Returns HTTP 200 OK without session cookie or token. |
| **In-App Accessibility** | Settings & Profile contains direct links to Terms and legal documentation. | `ProfileScreen` &rarr; `Support & Legal` &rarr; `Terms of Service` opens modal and web link. | **COMPLIANT** | Tested in Flutter client. |
| **Terms Acceptance at Registration** | Registration flow requires user to review and accept Terms & Conditions. | Interactive checkbox in `CreateAccountScreen` with clickable links to Terms and Privacy Policy. | **COMPLIANT** | Tested in registration flow. |

---

## 2. Four Sources of Truth Consistency Check

```
                       ACTUAL APP
        (Digital Khata, Invoicing, Loan Tracker, Free)
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
   TERMS OF SERVICE   PRIVACY POLICY    DATA SAFETY AUDIT
   (33 Audited Secs) (24 Audited Secs) (Google Play Matrix)
        |                   |                   |
        +-------------------+-------------------+
                            |
                            v
                    PLAY STORE LISTING
        (Accounting Utility, Zero Ads, Safe Data)
```

* **Consistency Result:** **100% ALIGNED.**
* No conflicting statements exist regarding payments, marketplace intermediation, location tracking, camera access, or third-party sharing.
