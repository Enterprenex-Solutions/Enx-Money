# Google Play Data Safety & Codebase Audit: ENX Money

**Document Version:** 1.0.0  
**Effective Date:** September 5, 2026  
**Audited Target:** ENX Money Mobile Application (Flutter `client/`) & API Backend (`server/`)  
**Package Name:** `com.enterprenex.enx_money`  
**Publisher:** Enterprenex Solutions Pvt Ltd  

---

## 1. Executive Summary & Codebase Audit Methodology

This document establishes the developer-facing ground truth for Google Play Data Safety declarations, built by performing a static and dynamic inspection of the actual ENX Money codebase (`client/`, `server/`, `AndroidManifest.xml`, database schemas, and networking layer).

### Audited Permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
* **Location:** Zero permissions declared (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` are **NOT** present).
* **Contacts:** Zero permissions declared (`READ_CONTACTS`, `WRITE_CONTACTS` are **NOT** present).
* **Camera / Microphone:** Zero permissions declared (`CAMERA`, `RECORD_AUDIO` are **NOT** present).
* **SMS / Call Logs:** Zero permissions declared (`READ_SMS`, `RECEIVE_SMS`, `READ_CALL_LOG` are **NOT** present).
* **Storage:** No legacy external storage permissions declared. PDF/Excel ledger exports leverage scoped storage and system share intents.

### Audited Third-Party SDKs (`pubspec.yaml`):
* `http: ^1.2.0` (REST API networking)
* `shared_preferences: ^2.2.2` (Local session and preference key-value storage)
* `intl: ^0.19.0` (Currency and date formatting)
* `share_plus: ^10.0.0` (System file sharing)
* `url_launcher: ^6.3.0` (Opening external legal URLs and mailto intents)
* `pdf: ^3.10.8` & `printing: ^5.13.0` (Client-side document rendering)
* `excel: ^4.0.3` (Client-side spreadsheet generation)
* `local_auth: ^2.2.0` (On-device Android BiometricPrompt / iOS LocalAuthentication)
* **Zero Advertising SDKs** (No AdMob, UnityAds, AppLovin, or ironSource)
* **Zero Behavioral Trackers** (No Firebase Analytics, AppsFlyer, Mixpanel, or Facebook SDK)

---

### 2. Google Play Data Safety Declaration Table

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
| **App activity/analytics** | **No** | **No** | N/A (No third-party analytics or behavioral tracking SDKs integrated) | N/A |
| **SMS/call data** | **No** | **No** | N/A (No SMS or telephony permissions requested) | N/A |

*\*Email is shared strictly with Google LLC (Gmail SMTP relay) solely for the technical execution of OTP authentication emails.*

### SDK Data Cross-Reference Tree

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

### Consistency Rule
**Data Safety = Privacy Policy = Actual App Behavior**

The three contain verified, consistent information based directly on the audited codebase.

---

## 3. Detailed Data Category Audit

### 3.1 Personal Information
1. **Name:** User's profile display name (`users.name`). Stored in MySQL database. Used to identify the account holder and display on exported PDF invoices. User can update anytime in Profile. Deleted upon account deletion.
2. **Email Address:** Primary account identifier (`users.email`). Stored in MySQL database. Used for login, password resets, and 2FA verification. Purged upon account deletion.
3. **Phone Number:** Secondary contact identifier (`users.phone`). Stored in MySQL database. Optional field. Purged upon account deletion.
4. **Business Information:** Business name, GSTIN, PAN, and physical address entered by the user in `businesses` or `profile` tables. Stored in MySQL database. Used to generate compliant GST invoices. Purged or anonymized upon account deletion.

### 3.2 Financial & Accounting Records
1. **Customer & Supplier Records:** Names, phone numbers, and addresses of counterparties entered manually by the merchant into their digital Khata. Stored in `customers` and `suppliers` tables. Never sold or shared with any third party.
2. **Ledger Transactions & Khata Entries:** Credit/debit amounts, descriptions, transaction dates, and bill references stored in `transactions`, `customer_ledger`, and `purchase_ledger`. Under Indian taxation laws (GST Act / Companies Act), accounting records must be preserved for statutory audit periods (up to 8 years). When an account is deleted, personal identities are severed, and ledger entries are retained in an anonymized, unlinked state.
3. **Bank & Card Data:** ENX Money does **NOT** collect, process, or store credit card numbers, CVVs, or net banking credentials.

### 3.3 Biometric Data
1. **Local Authentication:** Biometric login (Fingerprint / Face ID) is implemented strictly on-device using the `local_auth` package invoking the Android `BiometricPrompt` API.
2. **Privacy Guarantee:** Biometric templates and raw sensor data **NEVER** leave the hardware secure enclave of the mobile device and are **NEVER** transmitted to or stored on ENX Money servers.

### 3.4 Device & Network Diagnostics
1. **IP Address & User-Agent:** Automatically processed in volatile memory by the Node.js/Express web server to establish TCP/HTTPS connections and enforce rate limiting.
2. **No Hardware Identifiers:** The application does **NOT** collect IMEI, Android ID, MAC address, or Advertising ID (GAID).

---

## 4. Third-Party Integrations & Processors

| Service / Processor | Purpose | Data Transmitted | Storage Location | Privacy Impact |
| :--- | :--- | :--- | :--- | :--- |
| **Gmail SMTP (Google LLC)** | Dispatching 6-digit OTP verification codes | Recipient email address & 6-digit numerical code | Google Mail Servers | Ephemeral transmission; no analytics or user profiling |
| **Cloud Database (MySQL)** | Multi-tenant persistent relational data storage | Encrypted account credentials, ledger balances, invoices | Enterprise Cloud VPC | Isolated tenant queries; protected by connection pooling & strict auth |
| **Cloud Ingress / HTTPS Edge** | Secure cloud routing & TLS termination | Encrypted HTTPS payloads in transit | Cloud Edge | Zero storage; TLS 1.3 encryption end-to-end |

---

## 5. Security & Cryptographic Standards

* **Encryption in Transit:** All traffic between the Flutter mobile client and backend APIs is enforced over HTTPS utilizing TLS 1.2 and TLS 1.3 cipher suites. Cleartext HTTP is prohibited.
* **Password Hashing:** Passwords are never stored in plaintext. They are salted and cryptographically hashed with `bcryptjs` (salt rounds: 10).
* **Session Management:** Stateless JSON Web Tokens (JWT) signed with a secret key. Invalidation is enforced via server-side token blacklisting on logout and account deletion.
* **Sensitive Log Sanitization:** `ApiLogger` on the Flutter client and Morgan/Winston on the backend automatically redact passwords, OTP codes, bearer tokens, and customer secrets from console logs.
* **Authorization & Multi-Tenancy:** Insecure Direct Object Reference (IDOR) protections verify user ownership (`WHERE user_id = ?`) across all customer, loan, invoice, and transaction endpoints.

---

## 6. Account & Data Deletion Compliance (Google Play Policy)

In accordance with Google Play's Account Deletion requirements:
1. **In-App Deletion:** Available via `Settings` &rarr; `Data & Privacy Dashboard` &rarr; `Delete Account Permanently`. Invokes `DELETE /api/users/account` with active Bearer token.
2. **External Web Deletion Portal:** For users who have uninstalled the application, a public HTTPS web portal is hosted at `/delete-account`. Users submit their registered email address, initiating an automated verification and deletion workflow.
3. **Execution Scope:** 
   - Personal profile and credentials (`name`, `email`, `phone`, `password`) are purged or replaced with cryptographic pseudonyms.
   - Authentication tokens are revoked immediately in the Redis/Memory token blacklist.
   - Device storage (`SharedPreferences`) is wiped.
   - Historical tax-mandated ledger records are permanently disassociated from personal identity.

---

## 7. Sign-off Checklist

- [x] **All first-party data collection documented**
- [x] **All third-party SDKs audited for data collection**
- [x] **Data Safety form in Google Play Console completed to match findings**
- [x] **Cross-checked against Privacy Policy for exact consistency**
- [x] **Re-verified after any SDK update or new feature that changes data collection**
