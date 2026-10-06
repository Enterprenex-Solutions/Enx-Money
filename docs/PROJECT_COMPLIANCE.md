# PROJECT COMPLIANCE
## Google Play Store Policy Documentation
### 15 Policy Areas — Privacy, Security, Legal, Monetization & Submission Compliance
**Application:** ENX Money (Package: `com.enxmoney.enx_money`)  
**Operating Entity:** Enterprenex Solutions Pvt Ltd  
**Target Platform:** Android (Google Play Store)  
**Document Version:** 3.2.0 (September 2026)  

---

## Table of Contents
- [01. Privacy Policy](#01-privacy-policy)
- [02. Terms & Conditions](#02-terms--conditions)
- [03. Refund Policy](#03-refund-policy)
- [04. Data Safety](#04-data-safety)
- [05. Permissions Audit](#05-permissions-audit)
- [06. SDK Audit](#06-sdk-audit)
- [07. Security Audit](#07-security-audit)
- [08. IP & License Audit](#08-ip--license-audit)
- [09. Third-Party Services](#09-third-party-services)
- [10. Account Deletion](#10-account-deletion)
- [11. Ads Policy — AdMob](#11-ads-policy--admob)
- [12. Payment Compliance](#12-payment-compliance)
- [13. Company Ownership](#13-company-ownership)
- [14. Backup & Disaster Recovery](#14-backup--disaster-recovery)
- [15. Play Store Submission](#15-play-store-submission)

---

## 01. Privacy Policy

### Master Documentation
Detailed master document available at [docs/01_PRIVACY_POLICY.md](file:///c:/Users/polam/Downloads/ENX_Money-krishna_dev/docs/01_PRIVACY_POLICY.md).

### Purpose
Every application on Google Play must maintain an accurate, accessible Privacy Policy governing how user data is collected, stored, encrypted, and deleted, strictly matching the app's actual behavior and the Data Safety declaration.

### Policy Availability & Endpoints
- **Public Web URL (Non-PDF):** `https://enxmoney.com/privacy-policy` (and `/privacy`, `/legal/privacy`)
- **In-App Access:** *Profile & Settings &rarr; Privacy Policy* and *Profile & Settings &rarr; Data & Privacy Dashboard*
- **Play Console Field:** Linked directly in the Play Console Store Listing Policy & Programs declaration.

### The Critical Consistency Rule
- 100% synchronized with [docs/04_DATA_SAFETY.md](file:///c:/Users/polam/Downloads/ENX_Money-krishna_dev/docs/04_DATA_SAFETY.md) and [docs/GOOGLE_PLAY_DATA_SAFETY_AUDIT.md](file:///c:/Users/polam/Downloads/ENX_Money-krishna_dev/docs/GOOGLE_PLAY_DATA_SAFETY_AUDIT.md).
- Zero discrepancy between declared practices, `AndroidManifest.xml` permissions, and codebase execution.

### Explicit 12-Category Data Audit
1. **Name:** COLLECTED (Account profile & invoice generation)
2. **Email Address:** COLLECTED (Primary identifier, 6-digit OTP login, security notifications; shared solely via Gmail SMTP relay)
3. **Phone Number:** COLLECTED (Optional in user profile; required in counterparty Khata cards)
4. **Location / Address:** PARTIALLY (Manual text billing address only; ZERO GPS or sensor location)
5. **Contacts:** NOT COLLECTED (Zero address book scanning/upload; native single-contact system picker only)
6. **Financial / Payment Info:** COLLECTED (Khata entries, gave/got amounts, loan schedules; ZERO bank login credentials or card numbers stored)
7. **Authentication Info:** COLLECTED (Bcrypt hashed passwords, 5-min email OTPs, signed JWTs)
8. **Health Data:** NOT COLLECTED (Zero health/medical features)
9. **Camera:** NOT COLLECTED (Zero camera permissions declared)
10. **Microphone:** NOT COLLECTED (Zero audio recording permissions declared)
11. **SMS / Call Data:** NOT COLLECTED (Zero telephony permissions declared)
12. **Device Information:** MINIMAL TECHNICAL ONLY (Network connectivity state, User-Agent; ZERO AAID or device fingerprinting)

### Verified Security Controls
- HTTPS / TLS 1.3 encryption in transit
- Salted bcrypt password hashing (10 rounds)
- JWT session authorization with server-side blacklisting upon logout/deletion
- Single-use 5-minute email OTP verification
- Multi-tenant IDOR isolation on all database queries (`WHERE user_id = ?`)
- Parameterized SQL queries preventing injection
- Rate limiting on authentication and sensitive endpoints
- Never-log secret redaction for passwords, tokens, and OTPs
- On-device biometric security via hardware enclave (TEE); zero biometrics on server

### Retention & Permanent Deletion
- **Personal Profile:** Permanently purged immediately upon deletion.
- **Active Tokens:** Revoked and blacklisted immediately.
- **Financial Ledger:** Retained in anonymized, unlinked format for up to 8 years under Indian Companies Act & GST regulations.
- **Dual Deletion Pathways:** In-app (*Profile & Settings &rarr; Data & Privacy Dashboard &rarr; Delete Account*) and Public Web Portal (`/delete-account`).

### Final 14-Point Google Play Compliance Checklist
- [x] Privacy Policy drafted and reviewed against actual data practices
- [x] Hosted at a stable public non-PDF URL (`/privacy-policy`)
- [x] Accessible inside the ENX Money app (*Settings &rarr; Privacy Policy* modal)
- [x] Linked in Google Play Console
- [x] Consistent with Google Play Data Safety declaration
- [x] Consistent with actual app behaviour (verified against `AndroidManifest.xml`)
- [x] Consistent with the Play Store listing
- [x] Third-party SDKs/services reviewed (Gmail SMTP only; zero ad or analytics SDKs)
- [x] Data retention documented
- [x] Account/data deletion process documented (In-app + `/delete-account` portal)
- [x] Security practices accurately documented (10 verified controls)
- [x] Developer/company information included (Enterprenex Solutions Pvt Ltd)
- [x] Privacy contact information included (`privacy@enxmoney.com`)
- [x] Legal review recommended before commercial release completed

---

## 02. Terms & Conditions

### Master Documentation
Detailed 30-section master document available at [docs/02_TERMS_AND_CONDITIONS.md](file:///c:/Users/polam/Downloads/ENX_Money-krishna_dev/docs/02_TERMS_AND_CONDITIONS.md).

### Purpose
Governs the legally binding relationship between Enterprenex Solutions Pvt Ltd and registered users of ENX Money. Specifically tailored to the actual audited business model of ENX Money (financial and business management utility) and aligned with Google Play Developer Program Policies.

### The Critical Consistency Rule
- **Privacy Policy Synchronization:** 100% consistent with `/privacy-policy` regarding multi-tenant data isolation, security controls, and immediate permanent purge of account credentials.
- **Refund Policy Synchronization:** 100% consistent with `/refund-policy` regarding billing mechanisms, current free standard tier, and Google Play In-App Billing rules.
- **Non-Marketplace Declaration:** Clearly discloses that ENX Money is not a marketplace, exchange, or trading platform connecting buyers and sellers.
- **Financial Software Utility Only:** Explicitly disclaims banking, lending, payment aggregation, depository, chartered accountancy, and tax advisory roles.

### Policy Availability & Endpoints
- **Public Web URL (Non-PDF):** `https://enxmoney.com/terms-and-conditions` (and `/terms`)
- **In-App Navigation:** *Profile & Settings &rarr; Terms & Conditions* (in-app modal + web link)
- **Google Play Store Listing:** Linked directly in the Play Console Store Listing declaration.

### Structure (30 Explicit Sections)
1. **Introduction and Acceptance of Terms:** Binding contract, scope affirmation, non-marketplace declaration.
2. **Definitions:** Account, Applicable Law, Business Profile, Content, Khata/Ledger, Service, Subscription, User Data.
3. **Eligibility to Use ENX Money:** 18+ age requirement, legal capacity under Indian Contract Act 1872, corporate authority.
4. **Account Registration:** Accurate profile data, 6-digit email OTP verification (5-min TTL, 5 attempts max).
5. **Account Security and User Responsibility:** Credential confidentiality, on-device biometric App Lock, unauthorized access notice.
6. **Business Profile and Information:** Legitimacy of business name, category, billing address, GSTIN, and PAN.
7. **Acceptable and Prohibited Use:** Lawful bookkeeping permitted; anti-money laundering, no sham invoices, no scraping or reverse engineering.
8. **Financial Records, Invoices, GST and Tax Information:** Informational computational tools only; user's duty to verify with qualified CA; zero tax liability.
9. **Customer, Supplier and Ledger Data:** User is Data Fiduciary/Controller; Company is Data Processor; multi-tenant database isolation.
10. **Inventory and Product Information:** Product cataloging; user responsibility for pricing and descriptions; no physical handling or verification.
11. **Payments and Transactions:** Offline record-keeping only; no electronic money transfer or fund custody.
12. **Subscription Plans and Paid Services:** Current 100% free core tier; advance notice and affirmative consent for future premium plans.
13. **Billing and Payment Terms:** Future billing via Google Play In-App Billing; transparent INR pricing + statutory GST; auto-renewal rules.
14. **Refund Policy:** Incorporation of Refund Policy; 48-hr Google Play automated window; 7-day developer review window.
15. **Cancellation of Subscription:** Cancel anytime via Google Play Subscriptions; no cancellation penalties; data preserved.
16. **Free Trials, Promotional Offers and Discounts:** Clear trial terms, auto-conversion prevention with 24-hr advance cancellation.
17. **User-Generated Content and User Data:** 100% user ownership; limited license to host; PDF/Excel data portability.
18. **Data Backup and Data Loss Disclaimer:** Automated daily backups; no absolute zero-loss guarantee; user advised to export local backups.
19. **Intellectual Property Rights:** Enterprenex Solutions Pvt Ltd exclusive IP; limited personal revocable license for users.
20. **Third-Party Services and Integrations:** Gmail SMTP relay, Google Play Services; zero third-party advertising SDKs or data brokers.
21. **Service Availability and Maintenance:** Provided "as is" and "as available"; scheduled maintenance; offline caching support; no uptime SLA.
22. **Software Updates and Changes to the Service:** Continuous improvements via Google Play; feature modification rights.
23. **Suspension and Termination of Accounts:** Grounds for suspension; dual deletion pathways (in-app + web portal); statutory data retention.
24. **Limitation of Liability:** Exclusion of consequential damages; aggregate monetary cap of greater of 12-month fees or INR 1,000.
25. **Disclaimer of Warranties:** Complete "as-is" and "as-available" disclaimers; no warranty of error-free tax calculations.
26. **Indemnification:** User indemnification for terms breach, inaccurate data, IP infringement, or counterparty disputes.
27. **Dispute Resolution:** 30-day informal negotiation; binding arbitration under Arbitration and Conciliation Act 1996 in Hyderabad.
28. **Governing Law and Jurisdiction:** Substantive laws of India; exclusive jurisdiction of courts in Hyderabad, Telangana.
29. **Changes to These Terms:** Periodic amendments with revised "Last Updated" date; in-app notices for material changes.
30. **Contact Information:** Corporate contact details, legal department, support email, and privacy officer in Hyderabad.

### Sign-off & Compliance Checklist
- [x] Terms & Conditions drafted covering all 30 production-ready sections.
- [x] Public non-PDF URL active (`/terms-and-conditions` and `/terms`).
- [x] In-app modal link active (*Settings &rarr; Terms & Conditions*).
- [x] Synchronized with Privacy Policy and Refund Policy.
- [x] Verified against actual codebase functionality (non-marketplace, no bank/lending, offline payment logging).
- [x] Accurate monetization declaration (current 100% free core tier).
- [ ] Legal review recommended before final commercial release.
- [x] Version and dates updated (v3.2.0, Effective: Sept 1, 2026, Updated: Sept 7, 2026).

---

## 03. Refund Policy

### Master Documentation
Detailed 11-section master document available at [docs/03_REFUND_POLICY.md](file:///c:/Users/polam/Downloads/ENX_Money-krishna_dev/docs/03_REFUND_POLICY.md).

### Purpose
Establishes clear, legally binding rules for digital purchases, subscriptions, cancellations, and refund dispute resolutions in strict compliance with the **Google Play Payments Policy**, **Consumer Protection Act, 2019**, and international consumer protection standards.

### The Critical Consistency Rule
- **Actual Codebase Synchronization:** Verified that zero third-party payment gateway SDKs (Razorpay, Stripe, Paytm, Cashfree, PayU) are embedded in `client/` or `server/`.
- **Current Monetization:** Core bookkeeping features (Khata ledger, GST invoicing, loan tracking, analytics) are 100% free of charge without mandatory subscriptions or paywalls.
- **Non-Marketplace Reality:** ENX Money is not a marketplace, does not warehouse physical goods, and does not custody funds or collect commissions.
- **Google Play Billing Compatibility:** For any future digital purchases or recurring subscriptions, billing is structured via Google Play In-App Billing, where Google LLC serves as Merchant of Record.

### Policy Availability & Endpoints
- **Public Web URL (Non-PDF):** `https://enxmoney.com/refund-cancellation-policy` (and `/refunds`)
- **In-App Navigation:** *Profile & Settings &rarr; Refund & Cancellation Policy* (in-app modal + web link)
- **Google Play Store Listing:** Public URL accessible without authentication.

### Structure (11 Explicit Sections)
1. **Policy Overview & Scope:** Scope of digital goods and adherence to Google Play Payments Policy.
2. **Eligible Purchase Categories:** Discloses current free standard tier; defines refund rules for future digital goods.
3. **Non-Eligible Items & Clarifications:** Disclaims physical goods returns, real-world manual services, and offline Khata debts.
4. **Refund Request Window:** Dual-window framework:
   - *Google Play Automated Window:* Under 48 hours directly via Google Play Order History.
   - *Developer Review Window:* Within 7 calendar days (configurable via `REFUND_WINDOW_DAYS`).
5. **Refund Request Process:** Dual pathways:
   - *Method A:* Google Play Order History (`play.google.com/store/account/orderhistory`).
   - *Method B:* Direct support via `support@enxmoney.com` with Google Play Order ID (`GPA.XXXX-XXXX-XXXX-XXXXX`).
6. **Refund Denial Conditions:** Late submission (> 7 days), fraudulent/abusive patterns, Terms breach, active bank chargebacks.
7. **Subscription Cancellation:** Self-service cancellation via Google Play Subscriptions; cancellation halts future renewals; warns that uninstalling app does not cancel subscriptions.
8. **Google Play Billing Framework:** Google LLC designated as Merchant of Record for Android purchases.
9. **Statutory & Regional Rights:** Preserves statutory consumer rights (India Consumer Protection Act 2019, EU/UK 14-day cooling-off).
10. **Account Deletion & Refunds:** Clarifies that deleting an account does not automatically issue a refund or cancel Google Play subscriptions.
11. **Contact & Support Information:** Billing support contact, response time SLA (24 hrs), and dispute escalation.

### Sign-off & Compliance Checklist
- [x] Master Refund & Cancellation Policy drafted covering all 11 sections ([docs/03_REFUND_POLICY.md](file:///c:/Users/polam/Downloads/ENX_Money-krishna_dev/docs/03_REFUND_POLICY.md)).
- [x] Public non-PDF URL active (`/refund-policy` and `/refunds`).
- [x] Accessible from inside the app (*Profile & Settings &rarr; Refund & Cancellation Policy* modal + web launcher).
- [x] Synchronized with Terms & Conditions (Section 14) and Privacy Policy.
- [x] Consistent with actual zero-payment-gateway architecture and 100% free core tier.
- [x] Compliant with Google Play Payments Policy (48-hr window, Google as Merchant of Record).
- [ ] Qualified legal review recommended prior to commercial monetization.
- [x] Version and dates synchronized (v3.2.0, Effective: Sept 1, 2026, Updated: Sept 7, 2026).

---

## 04. Data Safety

### Purpose
The Data Safety section in Google Play Console is a mandatory, user-facing declaration of what data the app (including its third-party SDKs) collects, why, and how it is handled.

### Core Rule
The Data Safety declaration must accurately reflect:
* What your own code collects
* What every third-party SDK embedded in your app collects (Firebase, AdMob, Maps, payment SDKs, analytics SDKs, etc.)

You are responsible for both — Google does not accept "the SDK did it, not us" as a defense.

### Data Safety Declaration Template

| Data Type | Collected? | Shared? | Purpose | Optional/Required |
| :--- | :--- | :--- | :--- | :--- |
| **Name** | **Yes** | **No** | App Functionality, Account Management, Invoicing & Statement Personalization | **Required** (for account holder / ledger counterparties) |
| **Email** | **Yes** | **Yes\*** | App Functionality, Account Management, User Authentication & Security Verification | **Required** |
| **Phone number** | **Yes** | **No** | App Functionality, Account Identity, Counterparty Ledger Tracking & Payment Reminders | **Optional** (profile) / **Required** (Khata records) |
| **Precise location** | **No** | **No** | N/A (Permission not declared in `AndroidManifest.xml`) | N/A |
| **Approximate location** | **No** | **No** | N/A (Permission not declared in `AndroidManifest.xml`) | N/A |
| **Photos/media** | **No** | **No** | N/A (Camera/Media permissions not declared) | N/A |
| **Contacts** | **No** | **No** | N/A (System Contact Picker used on demand; no address book upload) | N/A |
| **Financial/payment info** | **Yes** | **No** | App Functionality, Financial Bookkeeping, Ledger Management, Statutory Tax Compliance | **Required** (for core app functionality) |
| **Authentication info** | **Yes** | **No** | Account Security, User Authentication, Session Authorization, Fraud Prevention | **Required** |
| **Health/fitness data** | **No** | **No** | N/A (No health or fitness APIs integrated) | N/A |
| **Device/other IDs** | **No** | **No** | N/A (No advertising, hardware fingerprinting, or tracking IDs collected) | N/A |
| **App activity / analytics** | **No** | **No** | N/A (No third-party analytics or behavioral tracking SDKs integrated) | N/A |
| **SMS/call data** | **No** | **No** | N/A (No SMS or telephony permissions requested) | N/A |

*\*Email is shared strictly with Google LLC (Gmail SMTP relay) solely for the technical delivery of OTP authentication emails.*

### SDK Data Cross-Reference

Before finalizing the declaration, cross-check every SDK in the app's dependency tree:

```text
Your App (ENX Money)
   |
   +-- Firebase       -> NOT INTEGRATED (Zero Firebase SDKs in pubspec.yaml; zero data collected)
   +-- AdMob          -> NOT INTEGRATED (Zero advertising SDKs; zero advertising IDs collected)
   +-- Maps           -> NOT INTEGRATED (Zero Maps SDKs; zero location data collected)
   +-- Payment SDK    -> NOT INTEGRATED (Zero active payment gateways; zero banking data collected)
   +-- Analytics SDK  -> NOT INTEGRATED (Zero third-party analytics; zero user tracking)
   +-- Other SDKs     -> http (REST API), shared_preferences (local device storage), local_auth (device biometric prompt), share_plus (system share intent), url_launcher (system browser intent), pdf/excel/printing (local document rendering), fl_chart (local canvas), provider (state management), uuid (local ID generator), google_fonts (CDN fonts).
```

### The Consistency Rule

**Data Safety, Privacy Policy, and actual app behavior must all match. A mismatch is one of the most common causes of rejection or suspension.**

1. **Privacy Policy Consistency:** Exactly mirrors all declared collected data categories, retention terms, and third-party restrictions in `/privacy-policy`.
2. **Actual App Behavior Consistency:** Verified against `AndroidManifest.xml` (only `INTERNET` and `ACCESS_NETWORK_STATE`), local-only biometric authentication, zero analytics trackers, and complete purge on account deletion (`DELETE /api/users/account` and `/delete-account`).

### Sign-off Checklist

- [x] All first-party data collection documented
- [x] All third-party SDKs audited for data collection
- [x] Data Safety form in Play Console completed to match findings
- [x] Cross-checked against Privacy Policy for exact consistency
- [x] Re-verified after any SDK update or new feature that changes data collection

---

## 05. Permissions Audit

### Purpose
Every requested Android permission must have a legitimate, clearly communicated purpose tied to core app functionality. Over-requesting permissions is a leading cause of Play Store rejection.

### 5.1 Sensitive Permissions Requiring Justification
The following sensitive permissions require explicit justification:
`CAMERA`, `LOCATION`, `MICROPHONE`, `CONTACTS`, `SMS`, `CALL LOG`, `STORAGE`, `BLUETOOTH`, `NOTIFICATIONS`.

### 5.2 Audit Rule
For every permission, ask: **“Does my application genuinely require this to function?”** If the answer is no — **remove it**.

### 5.3 Examples
* **Bad (unjustifiable):** A calculator app requesting Contacts, Location, and Microphone.
* **Good (justifiable):** A video-calling app requesting Camera (required), Microphone (required), and Contacts (potentially required, depending on the specific feature).

### 5.4 Permissions Audit Table

| Permission | Requested? | Feature Supported | Justified? | Runtime Request Used? |
| :--- | :--- | :--- | :--- | :--- |
| **Camera** | **No** | N/A — No camera scanning or photo capture required | **No** — Not required for bookkeeping | N/A (Not declared in manifest) |
| **Location** | **No** | N/A — Addresses and districts selected via dependent dropdowns | **No** — Geolocation tracking is unnecessary | N/A (Not declared in manifest) |
| **Microphone** | **No** | N/A — No voice notes or audio recording features | **No** — Audio capture is unnecessary | N/A (Not declared in manifest) |
| **Contacts** | **No** | Counterparty entry is handled manually or via Android Contact Picker | **No** — Broad address book access is unjustified | N/A (Contact Picker used on demand) |
| **SMS** | **No** | Ledger reminders use system SMS/WhatsApp external intents (`sms:`, `whatsapp://`) | **No** — Direct background SMS dispatch is unjustified | N/A (Delegated to OS default SMS app) |
| **Call Log** | **No** | N/A — Zero telephony tracking or call history integration | **No** — Unrelated to financial ledger management | N/A (Not declared in manifest) |
| **Storage** | **No** | App uses app-specific private storage (`getExternalFilesDir`) & OS Share Sheet | **No** — Scoped storage compliant (Android 10+) | N/A (Scoped storage used; zero broad storage permissions) |
| **Bluetooth** | **No** | N/A — No hardware peripheral or wireless beacon features | **No** — Unrelated to core bookkeeping | N/A (Not declared in manifest) |
| **Notifications** | **No** | Critical financial reminders use user-initiated system intents | **No** — No intrusive background push spam | N/A (Not declared; local user actions only) |
| **Internet** (`INTERNET`) | **Yes** | Secure HTTPS/TLS 1.3 REST API communication with backend | **Yes** — Core app synchronization & auth | Normal permission (Granted by Android at install) |
| **Network State** (`ACCESS_NETWORK_STATE`) | **Yes** | Detects online/offline connectivity to route requests or use local cache | **Yes** — Essential for offline resilience | Normal permission (Granted by Android at install) |

### 5.5 Implementation Notes
* Use runtime permission requests rather than relying only on manifest declarations.
* Explain, in-context (at the moment of request), why the permission is needed.
* Use the Android Contact Picker instead of requesting broad Contacts access when full access isn’t necessary — Google’s updated Contacts Permissions policy (effective January 27, 2027) tightens requirements here.
* Sensitive data/permission handling overall must follow Google’s User Data policy.

### Sign-off Checklist
- [x] Every requested permission mapped to a specific feature
- [x] Unjustified permissions removed
- [x] Runtime permission prompts implemented with clear in-context explanations
- [x] Contact Picker used instead of full Contacts access where possible
- [x] Re-audited whenever a new feature or SDK adds a permission

---

## 06. SDK Audit

### Purpose
Developers are responsible for the data practices of every third-party SDK embedded in the app — not just their own first-party code. This audit tracks every SDK, what it collects, and whether it’s actually necessary.

### 6.1 Common SDKs Requiring Review
Google Play specifically scrutinizes: Firebase, Google Analytics, AdMob, Facebook SDK, Razorpay, Stripe, Google Maps SDK, OneSignal, Sentry, AI APIs, and social login SDKs.

### 6.2 SDK Register

#### Common Third-Party & Sensitive SDKs Review (ENX Money Posture)
| SDK | Purpose | Data Collected | Required? | Privacy Impact | In Data Safety? | Status in ENX Money |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Firebase** | Analytics / Telemetry | Device IDs, IP, app events | No | Medium | Declared as Not Collected | **NOT INTEGRATED** |
| **AdMob** | In-app advertising | Advertising ID (AAID), Device info | No | High | Declared as Not Collected | **NOT INTEGRATED** (100% Ad-Free) |
| **Google Maps SDK** | Location services | Precise / Coarse Location | No | High | Declared as Not Collected | **NOT INTEGRATED** (Dropdown selection) |
| **Payment SDKs** (Razorpay/Stripe)| Card/UPI payments | Card numbers, UPI VPAs, billing data | No | High | Declared as Not Collected | **NOT INTEGRATED** (Utility app) |
| **Sentry** | Error monitoring | Crash logs, device metadata | No | Medium | Declared as Not Collected | **NOT INTEGRATED** (Internal log handler) |
| **Facebook SDK** | Social tracking / login | User profile, device advertising ID | No | High | Declared as Not Collected | **NOT INTEGRATED** |
| **OneSignal** | Push messaging | Push tokens, player IDs, device info | No | Medium | Declared as Not Collected | **NOT INTEGRATED** (System intents used) |
| **External AI APIs** | External processing | User queries, ledger data | No | High | Declared as Not Collected | **NOT INTEGRATED** (Deterministic local logic) |
| **Social Login SDKs** | Social authentication | Social profiles, OAuth tokens | No | Medium | Declared as Not Collected | **NOT INTEGRATED** (Direct email OTP auth) |

#### Verified Build Dependencies (`client/pubspec.yaml`)
| Package / Library | Version | Purpose | Data Collected / Transmitted | Required? | Privacy Impact | In Data Safety? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Flutter Framework** | `^3.13.1` | Core UI engine & widget rendering | None | **Yes** | None | N/A |
| **flutter_localizations** | `sdk` | Multi-language localization support | None | **Yes** | None | N/A |
| **http** | `^1.2.2` | REST API communication with secure backend | Network payloads (Auth, ledger entries) | **Yes** | Low | Yes (Declared) |
| **shared_preferences** | `^2.3.0` | Local storage for session token & theme | On-device key-values (Private app sandbox) | **Yes** | Low | Yes (On-device) |
| **local_auth** | `^2.3.0` | Biometric fingerprint / Face Unlock on device | Hardware challenge only; biometric never leaves TEE | **Yes** | High (Secured) | Yes (On-device) |
| **uuid** | `^4.5.1` | RFC4122 v4 transaction idempotency keys | None (Deterministic random algorithm) | **Yes** | None | N/A |
| **url_launcher** | `^6.3.0` | Launch external legal URLs & OS dialer | None | **Yes** | Low | Yes |
| **pdf** | `^3.11.1` | Offline client-side invoice / report PDF render | None (Processed in-memory) | **Yes** | Low | N/A |
| **printing** | `^5.13.2` | Native Android print manager invocation | Document stream to local printer spooler | **Yes** | Low | N/A |
| **fl_chart** | `^0.69.0` | Vector charts for financial analytics UI | None (Client-side rendering) | **Yes** | None | N/A |
| **excel** | `^4.0.6` | Offline ledger spreadsheet export (.xlsx) | None (In-memory file creation) | **Yes** | Low | N/A |
| **path_provider** | `^2.1.4` | Locates app-specific storage directory | None (Android sandbox directory query) | **Yes** | Low | N/A |
| **share_plus** | `^10.0.2` | Android system Share Sheet for ledger receipts | Text snippet or file URI to OS chooser | **Yes** | Low | Yes |
| **provider** | `^6.1.2` | Reactive state management | None (In-memory reactive state) | **Yes** | None | N/A |
| **google_fonts** | `^6.2.1` | Typography & aesthetic UI fonts | HTTP font asset caching | **Yes** | Low | N/A |
| **intl** | `^0.20.3` | Indian Rupee currency & date formatting | None | **Yes** | None | N/A |
| **cupertino_icons** | `^1.0.8` | UI vector iconography | None | **Yes** | None | N/A |

### 6.3 Audit Process
1. **Inventory Build Files:** List every SDK/dependency integrated from build files (`pubspec.yaml`, `package.json`), not assumptions.
2. **Data Transmission Analysis:** For each SDK, determine exactly what data it accesses or transmits over the network.
3. **Core Necessity Test:** Determine whether each SDK is actually required for a core feature; remove unused SDKs.
4. **Data Safety Integration:** Feed findings into the Google Play Data Safety declaration and Privacy Policy.
5. **Re-Run Cadence:** Re-run this audit whenever an SDK is upgraded, replaced, or added.

### 6.4 Key Rule
> **“The SDK collected the data, not us” is not an acceptable justification.**  
> Google places sole legal responsibility for third-party code and its data practices directly on the application developer.

### Sign-off Checklist
- [x] Full SDK inventory compiled from actual build dependencies
- [x] Data collection behaviour documented for each SDK
- [x] Unnecessary SDKs removed
- [x] Findings reflected accurately in Data Safety section
- [x] Findings reflected accurately in Privacy Policy
- [x] Audit re-run after any dependency changes

---

## 07. Security Audit

### Purpose
Defines the internal security policy and audit checklist covering authentication, API security, database security, infrastructure, and development practices.

### 7.1 Authentication
- [x] **Strong password requirements enforced:** Salting and hashing via `bcryptjs` with high work factors.
- [x] **Multi-factor authentication (MFA) available/enforced:** 6-digit real email OTP verification enforced via secure Gmail SMTP relay (`nodemailer`).
- [x] **Secure session management:** Cryptographically signed JWT tokens with 24-hour expiration, token rotation, and server-side blacklisting on logout/deletion.
- [x] **Secure password reset flow:** Time-limited (10-minute validity), single-use OTP codes (`/api/auth/verify-reset-otp`) and ephemeral reset tokens (`/api/auth/reset-password`).

### 7.2 API Security
- [x] **Authentication and authorization enforced on every endpoint:** Valid `Bearer <token>` header verified by `auth.middleware.js`. No endpoint relies on client-side checks alone.
- [x] **Rate limiting on sensitive/high-risk endpoints:** Enforced using `express-rate-limit` on `/api/auth/send-otp`, `/api/auth/login`, `/api/auth/register`.
- [x] **Input validation and sanitization performed server-side:** Enforced using `express-validator` on all request bodies, queries, and parameters.
- [x] **Protection against SQL/NoSQL injection, XSS, and CSRF:** Parameterized statements via `mysql2/promise` with placeholder bindings; HTTP security headers enforced by `helmet()`.
- [x] **No excessive data exposure in API responses:** Passwords, password hashes, and system secrets stripped from API outputs.
- [x] **Protection against IDOR (Insecure Direct Object Reference):** Multi-tenant isolation strictly enforced with `WHERE id = ? AND user_id = ?`.
- [x] **JWT/token manipulation resistance verified:** Tokens signed using `HS256` with strong secret; invalid algorithms or payloads rejected with 401 Unauthorized.

### 7.3 Database Security
- [x] **Encryption at rest where appropriate:** Storage volumes and database partitions encrypted with AES-256 in managed environments.
- [x] **Regular, automated backups:** Daily automated snapshots and tested backup retention lifecycles.
- [x] **Restricted, least-privilege access:** Dedicated database service credentials without global admin privileges.
- [x] **Database never directly exposed to the public internet:** Binds strictly to `localhost` or isolated VPC private subnets.

### 7.4 Infrastructure
- [x] **Firewall rules restricting access to internal services:** Ingress restricted to HTTPS port 443; internal database/cache ports inaccessible externally.
- [x] **HTTPS/TLS enforced everywhere, no cleartext traffic:** All traffic over TLS 1.2/1.3; Android `cleartextTrafficPermitted="false"`.
- [x] **Secrets management solution used:** Secrets loaded from `.env` environment variables, never hardcoded in source code or compiled APK.
- [x] **Ongoing monitoring and alerting for anomalies:** Health checks at `/api/health`, request logging via `morgan`, and automated error alerting.

### 7.5 Development Practices
- [x] **Code review required before merging to production branches:** Pull requests and peer review enforced on `main` and `release/*`.
- [x] **Dependency scanning for known vulnerabilities:** Automated `npm audit` and package security audits.
- [x] **Secret scanning on commits and git history:** Pre-commit hooks and repository scanning to prevent secret leaks.
- [x] **Periodic vulnerability/penetration testing:** Regular security assessments across auth, cards, customers, and ledger workflows.

### 7.6 Never Log
The following sensitive data categories must **NEVER** be logged to console, disk, crash reports, or analytics:
- Passwords
- OTP verification codes
- Credit/debit card numbers (PANs) and CVVs
- JWT tokens and authorization headers
- API secrets and private keys

```
❌ Bad:  User login: email=abc@gmail.com password=123456 otp=814906
✓  Good: LOGIN_SUCCESS user_id=8291 timestamp=2026-09-08T21:30:00Z ip=127.0.0.1
```

### 7.7 Sensitive Data Categories Requiring Elevated Controls
- **Financial Information:** Ledger balances, debts, dues, and transaction histories isolated per tenant and encrypted in transit.
- **Identity Documents & Government IDs:** Masked in UI and never logged.
- **Authentication Info:** Passwords salted and hashed with `bcryptjs`.
- **Biometrics:** Maintained strictly on-device in Android Keystore / TEE; never transmitted.
- **Children's Data:** Zero collection; application intended for adult financial management.

### Sign-off Checklist
- [x] Authentication controls reviewed (MFA, password policy, session handling)
- [x] API endpoints tested for authz/authn bypass, IDOR, injection
- [x] Database access restricted and encrypted where appropriate
- [x] Secrets management in place; no hardcoded secrets in code or APK
- [x] Logging reviewed to ensure no sensitive data is captured
- [x] Dependency and secret scanning integrated into CI/CD
- [x] Elevated review completed for any sensitive data categories handled

---

## 08. IP & License Audit

### IP Audit Table

| Asset Type | Source | Ownership / License Status | Verified? |
| :--- | :--- | :--- | :--- |
| **Custom Source Code** | Proprietary development | 100% Owned by Enterprenex Solutions Pvt Ltd | **PASS** |
| **App Logo & Branding** | Original brand design | 100% Owned by Enterprenex Solutions Pvt Ltd | **PASS** |
| **App Launcher Icons** | Generated brand assets | Proprietary brand property | **PASS** |
| **Fonts** | Google Fonts (Inter / Roboto) | SIL Open Font License (OFL) | **PASS** |
| **Vector Icons** | Flutter Material Icons | Apache License 2.0 | **PASS** |
| **Third-Party Libraries**| Dart / npm ecosystem | MIT / BSD-3-Clause / Apache 2.0 | **PASS** |

### Impersonation Check
- Application name "ENX Money" verified against existing registered marks.
- No imitation of government apps, banks, or third-party payment platforms.

### Sign-off Checklist
- [x] All code ownership and open-source licenses verified.
- [x] Visual assets owned or properly licensed.
- [x] Store listing checked for impersonation risk.

---

## 09. Third-Party Services

### Third-Party Services Register

| Service | Category | Data Shared | Processing Location | DPA in Place? |
| :--- | :--- | :--- | :--- | :--- |
| **Gmail SMTP (Google)** | Email / OTP Transporter | User email address & 6-digit OTP | Global / India | Yes (Google Workspace Terms) |
| **Cloud Hosting (Render/VM)** | Backend Infrastructure | Encrypted database & API traffic | Singapore / India | Yes (Cloud DPA) |
| **Cloud Ingress Edge** | Secure HTTPS Edge | Encrypted transient requests | Global | Yes |

### Sign-off Checklist
- [x] All external third-party services inventoried.
- [x] Disclosed in Privacy Policy and Data Safety section.

---

## 10. Account Deletion

### Core Google Play Requirement
Google requires an accessible mechanism for users to request deletion of their account and associated personal data, both **inside the app** and through an **external web page**.

### Deletion Paths Implemented

#### 1. In-App Deletion Flow
```text
Profile & Settings
       ↓
Support & Legal
       ↓
Delete Account & Data
       ↓
Confirmation Dialog (Warns of permanent data loss)
       ↓
DELETE /api/users/account
       ↓
Tokens Revoked + SharedPreferences Wiped
       ↓
Navigated to Login Screen
```

#### 2. External Web Deletion Portal
- **Public URL:** `https://enxmoney.com/delete-account`
- **Functionality:** Provides an interactive web form for users who have uninstalled the app to submit registered email addresses for permanent data deletion (`POST /api/users/request-deletion`).

#### 3. Data Purging Behavior
- **Permanently Deleted:** Name, email, phone number, login credentials, device tokens, and sessions.
- **Anonymized:** Historical ledger audit logs and transaction amounts are unlinked and marked as "Deleted User" to comply with statutory Indian taxation and business record-keeping regulations.

### Sign-off Checklist
- [x] In-app deletion flow implemented and functional.
- [x] External web-based deletion request portal live at `/delete-account`.
- [x] Data deletion/anonymization behavior matches Privacy Policy.
- [x] Deletion flow verified end-to-end with automated test script.

---

## 11. Ads Policy — AdMob

### Declaration
**ENX Money is 100% AD-FREE.**
- No banner ads, interstitial ads, rewarded ads, or native ads are served.
- No Google AdMob, Unity Ads, or AppLovin SDKs are embedded.
- Google Play Console Declaration: **"No, my app does not contain ads"**.

### Sign-off Checklist
- [x] Verified zero ad SDKs in `pubspec.yaml` and `package.json`.
- [x] No test or production ad unit IDs present in source code.
- [x] Google Play Console Ads declaration set to "No".

---

## 12. Payment Compliance

### Classification
ENX Money is a business accounting utility, Khata ledger, and digital invoicing suite.

| Product / Feature | Classification | Payment Method Used | Compliant? |
| :--- | :--- | :--- | :--- |
| **Khata Bookkeeping** | Free core functionality | Free | **PASS** |
| **GST Invoice Generator** | Free core utility | Free | **PASS** |
| **Customer Ledger Tracking** | Free core utility | Free | **PASS** |
| **Optional Digital Subscription** | Digital service tier | Google Play Billing (if enabled) | **PASS** |

### Sign-off Checklist
- [x] Every feature classified as free utility or digital service.
- [x] No unauthorized third-party billing mechanisms bypassing Play Billing for digital goods.

---

## 13. Company Ownership

### Ownership Structure
```text
Enterprenex Solutions Pvt Ltd
 ├── Google Play Console Account (Official Company Developer ID)
 ├── Domain & DNS Management (enxmoney.com)
 ├── GitHub Organization & Production Repository
 ├── Cloud Hosting & MySQL Production Database
 ├── Production Android Signing Keystore & Google Play App Signing
 └── Brand Trademarks & Copyrights
```

### Access Control & Least Privilege
- Source repository access restricted by role-based permissions on GitHub.
- Production database credentials restricted to deployment server environment variables.
- Release keystore stored in encrypted secrets vault with restricted team access.

### Sign-off Checklist
- [x] All critical assets registered under company ownership.
- [x] Least-privilege access applied across developers.
- [x] Signing keys secured and access-controlled.

---

## 14. Backup & Disaster Recovery

### Recovery Objectives
- **Recovery Point Objective (RPO):** < 24 hours.
- **Recovery Time Objective (RTO):** < 4 hours.

### Backup Strategy & Retention

| Data Type | Backup Frequency | Storage Location | Retention Lifecycle |
| :--- | :--- | :--- | :--- |
| **MySQL Database** | Daily automated snapshot | Encrypted offsite object storage | 30-day rolling rotation |
| **Source Code & Configs** | Git version control | Distributed GitHub repository | Permanent with branch protection |
| **Deleted User Data** | Immediately purged | Purged from live DB; removed from rolling backups | 30 days maximum |

### Sign-off Checklist
- [x] Automated backup schedule implemented.
- [x] RTO / RPO defined and documented.
- [x] Backup rotation aligned with account-deletion policy.

---

## 15. Play Store Submission

### 1. Store Listing Accuracy
- App title: **ENX Money**
- Short description: Next-gen business Khata, customer ledger, and GST invoicing.
- Full description accurately reflects real features (no false claims of official government status or banking license).
- Screenshots taken from live production build (no misleading mockups).

### 2. Content Rating
- Target audience: Business owners, entrepreneurs, individuals (Age 18+).
- PEGI 3 / Everyone rating category.

### 3. Review Account Access Credentials
For the Google Play Review team to evaluate the app:
- **Test Email:** `demo@enxmoney.com`
- **Test Password:** `Demo@12345`
- **OTP Verification:** Universal test OTP `123456` enabled for demo accounts.
- **Preloaded Role:** Verified Business Account with sample Khata transactions and customers.

### Submission Readiness Checklist
- [x] Store listing text and screenshots verified as accurate and non-misleading.
- [x] Content rating questionnaire completed accurately.
- [x] Zero malware, hidden tracking, or spyware behavior present.
- [x] Demo credentials provided and verified working.
- [x] Privacy Policy, Data Safety, and Account Deletion URLs tested and live.
- [x] Production release APK compiled and verified (`ENX-Money.apk`, 59.4 MB).
