# ENX Money — Full-Stack Fintech & Smart Wealth Platform

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x%20Web%20%7C%20Android-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-v20+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-4.x-000000?style=for-the-badge&logo=express&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.x%20%7C%20Postgres-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Brevo](https://img.shields.io/badge/Brevo-Enterprise%20Mail-0092FF?style=for-the-badge&logo=brevo&logoColor=white)
![Meta WhatsApp](https://img.shields.io/badge/Meta%20WhatsApp-Cloud%20API%20v21.0-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)
![Fast2SMS](https://img.shields.io/badge/Fast2SMS-Instant%20OTP-FF3E3E?style=for-the-badge)
![Cloudflare/Render](https://img.shields.io/badge/Production-SSL%20Secured-46a344?style=for-the-badge)

**Institutional-Grade Fintech Application for High-Net-Worth Wealth, Liabilities, Loan EMI Management, Expense Analytics, Smart Business Khata & Automated WhatsApp Financial Bot**  
*Inspired by the high-contrast luxury dark aesthetic of CRED and the autonomous financial intelligence of Walnut.*

🌐 **[Live Production Web App](https://enxmoney.enterprenex.solutions)** • 💬 **[WhatsApp Financial Hub](https://enxmoney.enterprenex.solutions/portal)** • 📱 **[Download Android APK](https://enxmoney.enterprenex.solutions/download-apk)**

</div>

---

## 📑 Table of Contents

- [Live Production Deployments & URLs](#-live-production-deployments--urls)
- [System Architecture](#-system-architecture)
- [Automated WhatsApp Financial Bot & Statements Engine](#-automated-whatsapp-financial-bot--statements-engine)
- [Enterprise Communications & Email Infrastructure](#-enterprise-communications--email-infrastructure)
- [Authentication, Biometrics & Dual OTP Verification](#-authentication-biometrics--dual-otp-verification)
- [Flutter Web & Mobile Responsive Architecture](#-flutter-web--mobile-responsive-architecture)
- [Production Release Artifacts & Play Store Compliance](#-production-release-artifacts--play-store-compliance)
- [CI/CD & Automated Verification](#-cicd--automated-verification)
- [Repository Structure](#-repository-structure)

---

## 🌐 Live Production Deployments & URLs

The entire ENX Money ecosystem is deployed on enterprise cloud infrastructure with continuous deployment from GitHub:

| Service / Component | Live Production URL | Description |
| :--- | :--- | :--- |
| **Official Web Application** | **[`https://enxmoney.enterprenex.solutions`](https://enxmoney.enterprenex.solutions)** | Full Flutter Web SPA matching mobile UI, optimized with zero-latency typography & responsive fintech desktop framing. |
| **WhatsApp Financial Hub** | **[`https://enxmoney.enterprenex.solutions/portal`](https://enxmoney.enterprenex.solutions/portal)** | Live interactive portal with dynamic balance preview, PDF Khata generator, and 1-tap WhatsApp chat triggers. |
| **WhatsApp Simulator** | **[`https://enxmoney.enterprenex.solutions/whatsapp-simulator`](https://enxmoney.enterprenex.solutions/whatsapp-simulator)** | Interactive sandbox to simulate incoming bot chats, test keywords, and preview PDF statement delivery. |
| **WhatsApp Live Webhook** | **[`https://enxmoney.enterprenex.solutions/api/v1/whatsapp/webhook`](https://enxmoney.enterprenex.solutions/api/v1/whatsapp/webhook)** | Verified Meta Cloud API webhook endpoint processing real-time incoming messages & dispatching responses. |
| **Corporate Apex Domain** | **[`https://enterprenex.solutions`](https://enterprenex.solutions)** | Official enterprise gateway and public domain. |
| **Production REST API** | **[`https://enxmoney.enterprenex.solutions/api/v1`](https://enxmoney.enterprenex.solutions/api/v1)** | Secure Node.js/Express API with Rate Limiting, Helmet, and JWT authorization. |
| **API Healthcheck** | **[`https://enxmoney.enterprenex.solutions/health`](https://enxmoney.enterprenex.solutions/health)** | Real-time service uptime, database connectivity, and environment status. |
| **Direct APK Download** | **[`https://enxmoney.enterprenex.solutions/download-apk`](https://enxmoney.enterprenex.solutions/download-apk)** | Direct Android production APK binary distribution portal. |
| **Legal Privacy Policy** | **[`https://enxmoney.enterprenex.solutions/privacy-policy`](https://enxmoney.enterprenex.solutions/privacy-policy)** | Public statutory policy compliant with Indian DPDP Act 2023 & Google Play rules. |
| **Account Deletion Portal** | **[`https://enxmoney.enterprenex.solutions/delete-account`](https://enxmoney.enterprenex.solutions/delete-account)** | User-facing self-service account and data deletion request portal. |

---

## 🏗️ System Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                Flutter Client (Web & Android)                          │
│   • Dark Luxury Theme (CRED Aesthetics) • Material 3 • Responsive Breakpoints          │
│   • Zero-Latency System Typography on Web • Native GoogleFonts on Mobile               │
│   • Inline Dual Verification (Email + Mobile Number) with Real-Time Badging            │
│   • Biometric Vault (Face/Fingerprint) & Salted SHA-256 4-Digit MPIN                   │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │ HTTPS / JSON (REST API)
                                            │ Bearer JWT Authentication
┌───────────────────────────────────────────▼────────────────────────────────────────────┐
│                             Node.js / Express API Gateway                              │
│   • Helmet Security (Strict CSP whitelisting Google Font CDNs & CanvasKit)             │
│   • Custom Rate Limiting (Brute-force protection on /send-otp and /login)              │
│   • Multi-Tenant Request Scoping by Authenticated User & Business ID                   │
│   • Double-Entry Khata Ledger & Amortization Loan EMI Calculation Engine               │
│   • Meta WhatsApp Cloud API v21.0 Webhook Handler & PDFKit Ledger Generator            │
└───────┬───────────────────┬───────────────────────────┬────────────────────────┬───────┘
        │                   │                           │                        │
        ▼                   ▼                           ▼                        ▼
┌───────────────┐   ┌───────────────┐           ┌───────────────┐        ┌───────────────┐
│ Database Pool │   │ Mail Engine   │           │ SMS Gateway   │        │ Meta WhatsApp │
│ • PostgreSQL  │   │ • Brevo HTTPS │           │ • Fast2SMS    │        │ • Cloud API   │
│ • Schema Sync │   │ • Port 443    │           │ • Dev API     │        │ • Webhooks    │
│ • Isolation   │   │ • DKIM/DMARC  │           │ • 2-5s OTP    │        │ • PDF Reports │
└───────────────┘   └───────────────┘           └───────────────┘        └───────────────┘
```

---

## 💬 Automated WhatsApp Financial Bot & Statements Engine

The ENX Money WhatsApp engine transforms standard messaging into an autonomous financial co-pilot connected directly to the **Meta WhatsApp Cloud API (Graph API v21.0)**. Users and business owners across India can check live balances, generate official audit-ready PDF ledgers, and collect customer receivables instantly.

### 1. Inbound Bot Commands

The engine features deterministic keyword recognition designed for fast, zero-friction execution:

| Keyword / Command | Trigger Aliases | System Response & Output |
| :--- | :--- | :--- |
| **`Balance`** | `bal`, `summary`, `account` | Returns instant real-time financial balance, monthly income, expense breakdown, net cash flow, and total customer Khata dues. |
| **`Statement`** | `ledger`, `report`, `pdf`, `khata` | Dynamically renders an official A4 PDF Khata ledger report with dual-entry transactions and SHA-256 digital stamp, delivered directly as a WhatsApp document attachment + secure browser link. |
| **`Remind`** | `dues`, `overdue`, `reminder` | Scans all debtor customers with positive balances and dispatches personalized WhatsApp reminders with **1-tap UPI deep links** (`upi://pay?pa=...`). |
| **`Help`** | `menu`, `commands`, `start` | Displays interactive navigation menu with all available bot operations and live financial portal links. |

### 2. Cryptographic PDF Statement Engine (`pdfkit`)
- **Dual-Entry Ledger Table:** Automatically aggregates journal entries, debtor receivables, and creditor payables with running balance calculations.
- **SHA-256 Tamper-Evident Stamp:** Every generated PDF computes a unique cryptographic hash embedded in the document header and database audit logs to guarantee authenticity.
- **Dual Delivery Pipeline:** Dispatched natively as a binary document attachment via Meta Cloud API and cached securely under `server/public/statements/` served via HTTPS at `https://enxmoney.enterprenex.solutions/statements/:filename`.

### 3. Customer Due Collection with 1-Tap UPI Links
When the owner triggers `"Remind"`, the autonomous reminder service (`server/services/whatsappReminderService.js`):
1. Queries the database for all customers belonging to the user's business with `balance > 0`.
2. Assembles an individualized reminder message containing exact outstanding amounts, due dates, and a formatted UPI URI:
   ```text
   upi://pay?pa=enxmoney@upi&pn=ENX%20Money&am=2500.00&cu=INR&tn=Invoice%20Settlement
   ```
3. Dispatches the reminder directly to each debtor's WhatsApp and logs the transaction in the `whatsapp_reminders` audit table.
4. Returns an executive summary back to the business owner confirming total debts reminded and delivery count.

### 4. Interactive Financial Hub & Web Simulator
- **Live Financial Hub Portal:** **[`https://enxmoney.enterprenex.solutions/portal`](https://enxmoney.enterprenex.solutions/portal)**  
  Real-time browser dashboard displaying live KPI widgets, instant statement generator, customer due scanner, and direct 1-tap WhatsApp chat triggers.
- **Interactive WhatsApp Simulator:** **[`https://enxmoney.enterprenex.solutions/whatsapp-simulator`](https://enxmoney.enterprenex.solutions/whatsapp-simulator)**  
  Embedded browser sandbox replicating mobile WhatsApp UI with quick command pills (`💰 Balance`, `📄 Statement`, `🔔 Remind`) and interactive PDF download cards.

### 5. Meta Developer Environment Configuration

To configure the live WhatsApp Cloud API integration in Render:

```env
# Meta WhatsApp Cloud API Production Variables
WHATSAPP_PROVIDER=meta
WHATSAPP_PHONE_NUMBER_ID=1338842652645626
WHATSAPP_ACCESS_TOKEN=EAAPubrNNFLsBSu...  # Permanent Meta System User Token
WHATSAPP_VERIFY_TOKEN=enx_money_webhook_token_2026
META_GRAPH_VERSION=v21.0
BASE_URL=https://enxmoney.enterprenex.solutions
```

### 6. Automated Bot Verification Test Suite
Run the 8-suite automated test covering webhooks, PDF generation, reminder dispatching, and REST controllers:
```bash
cd server
node tests/test_whatsapp_financial_bot.js
```
*Validates 8/8 comprehensive checks with 100% pass rate.*

---

## 📬 Enterprise Communications & Email Infrastructure

The platform uses a dedicated, authenticated corporate email and forwarding architecture:

### 1. Outgoing Transactional Email (Brevo HTTPS API)
- **Official Sender:** `ENX Money <support@enterprenex.solutions>`
- **Delivery Protocol:** Native HTTPS API (`POST https://api.brevo.com/v3/smtp/email`) over port 443 — immune to cloud provider SMTP port blocking (ports 25, 465, 587).
- **Domain Authentication (100% Verified in DNS):**
  - **Brevo Code:** `brevo-code:93fc028e2562587764eaf2c03c0b45fd` (GoDaddy TXT Record)
  - **DKIM 1 & DKIM 2:** 2048-bit domain keys ensuring tamper-proof cryptographic delivery.
  - **DMARC Record:** Strict quarantine enforcement (`v=DMARC1; p=quarantine;`).
  - **Combined SPF Record:** `v=spf1 include:spf.improvmx.com include:_spf.brevo.com ~all`.

### 2. Inbound Customer Support Routing (ImprovMX)
- **Catch-All Wildcard Rule:** `*@enterprenex.solutions` $\rightarrow$ Forwarded instantly to corporate inbox **`enxproductofficial@gmail.com`**.
- **Active Operational Aliases:**
  - `support@enterprenex.solutions` — Customer support & ticket resolution
  - `info@enterprenex.solutions` — General enquiries & public information
  - `contact@enterprenex.solutions` — Business partnerships & corporate communication
  - `sales@enterprenex.solutions` — Subscriptions & enterprise onboarding
  - `billing@enterprenex.solutions` — Payment confirmations & billing inquiries
  - `admin@enterprenex.solutions` — Systems & infrastructure governance
  - `feedback@enterprenex.solutions` — Customer suggestions & feedback
  - `help@enterprenex.solutions` — General platform assistance

---

## 🔐 Authentication, Biometrics & Dual OTP Verification

### 1. Registration Flow with Inline Verification
The signup form (`CreateAccountScreen`) features independent verification directly within the form fields:
- **Email Verification:** Interactive **`[ Verify ]`** button inside the email input field triggers an OTP dispatch via Brevo. Entering the 6-digit code in the modal transforms the button into a green **`[ ✓ Verified ]`** badge.
- **Mobile Number Verification:** Interactive **`[ Verify ]`** button inside the mobile input field triggers an instant SMS OTP via Fast2SMS. Entering the 6-digit code marks the phone number as **`[ ✓ Verified ]`**.
- **Account Creation:** Submitting the form creates the account and binds both verified channels directly to the user's primary database profile.

### 2. Returning User Login Options
The login screen (`LoginScreen`) provides 3 streamlined authentication options:
1. **Option A: Email + Password** — Traditional credential login with Bcrypt password hashing.
2. **Option B: Mobile / Email + OTP** — Passwordless sign-in for users entering either their registered phone number or email address.
3. **Option C: Quick Unlock (Biometric & 4-Digit MPIN)** — Returning users on recognized devices unlock the app in <1 second using device biometrics (Fingerprint / Face ID) or a salted SHA-256 MPIN, eliminating repetitive OTP costs.

---

## 💻 Flutter Web & Mobile Responsive Architecture

### 1. Zero-Latency Typography Engine on Web
- Replaced runtime font downloads with an instant native typography fallback stack on web (`Segoe UI`, `Roboto`, `San Francisco`, `Arial`).
- Mobile Android builds continue leveraging luxury `GoogleFonts.outfit` and `GoogleFonts.spaceGrotesk`.
- Configured Helmet Content Security Policy (`connectSrc`, `fontSrc`, `styleSrc`) whitelisting Google Font CDNs and CanvasKit.

### 2. Centered Responsive Desktop Card Framing
- On ultra-wide monitors (1080p, 1440p, 4K), forms and onboarding flows are wrapped in centered `ConstrainedBox(maxWidth: 500)` containers.
- Forms render as sleek, elegant fintech cards rather than stretching 1920px wide across desktop viewports.

---

## 📱 Production Release Artifacts & Play Store Compliance

### 1. Android Binaries
- **Google Play App Bundle (AAB):** [`ENX-Money.aab`](./ENX-Money.aab) *(~58.4 MB)*  
  Built with Gradle 8, Android NDK 28, and minified R8 code shrinking for Play Store console submission.
- **Standalone Android APK:** [`ENX-Money.apk`](./ENX-Money.apk) *(~59.4 MB)*  
  Direct APK binary with multi-architecture support (armeabi-v7a, arm64-v8a, x86_64).

### 2. Google Play Store Compliance (15 Policy Areas)
Fully documented in [`docs/PROJECT_COMPLIANCE.md`](./docs/PROJECT_COMPLIANCE.md):
- **Official Developer Support Email:** `support@enterprenex.solutions`
- **Official Support Phone:** `+91 9226860060`
- **Official Corporate Website:** `https://enxmoney.enterprenex.solutions`
- **Public Privacy Policy:** `https://enxmoney.enterprenex.solutions/privacy-policy`
- **Account Deletion URL:** `https://enxmoney.enterprenex.solutions/delete-account`
- **Terms & Conditions:** `https://enxmoney.enterprenex.solutions/terms`

---

## 🛠️ CI/CD & Automated Verification

### 1. Running Backend Test Suites
```bash
cd server
npm test
```
*Executes all 14 Jest test suites validating Auth, Cards, Invoices, Khata Ledger, KYC, and Razorpay standard checkout.*

### 2. Testing End-to-End OTP Dispatches
```bash
# Verify Email OTP via Brevo HTTPS API:
node -e "require('./src/services/email.service').sendOtpEmail({ email: 'support@enterprenex.solutions', otp: '123456' })"

# Verify Fast2SMS Mobile OTP:
node -e "require('./src/services/sms.service').sendOtpSms({ phone: '+919440829762', otp: '123456' })"
```

### 3. Compiling Production Web App
```bash
cd client
flutter build web --release
# Sync built output to backend public web directory:
Copy-Item -Path "client\build\web\*" -Destination "server\public\" -Recurse -Force
```

---

## 📁 Repository Structure

```
ENX_Money/
├── client/                     # Production Flutter Multi-Platform App (Web + Android)
│   ├── lib/
│   │   ├── core/               # Design tokens, typography fallback, network clients
│   │   └── features/           # Auth, Cards, Khata, Expenses, Loans, Profile, KYC
│   └── web/                    # Web configuration, manifest.json, index.html
├── server/                     # Production Node.js / Express API Backend
│   ├── public/                 # Production Flutter Web distribution bundle (served at /)
│   ├── src/
│   │   ├── config/             # Environment, DB connection pool, Brevo mailer, SMS
│   │   ├── controllers/        # Request handlers (Auth, KYC, Expenses, Cards, UPI)
│   │   ├── models/             # Database access models & tenant isolation
│   │   ├── routes/             # REST API route declarations
│   │   └── services/           # Brevo EmailService, Fast2SMS SmsService, TokenService
│   └── tests/                  # 14 Jest automated test suites
├── docs/                       # Google Play policies, compliance docs & data safety
├── render.yaml                 # Infrastructure-as-code deployment configuration
├── ENX-Money.aab               # Google Play Console production release bundle
├── ENX-Money.apk               # Direct install Android release APK
└── DOCUMENTATION.md            # Comprehensive 64-chapter engineering manual
```

---

<div align="center">
  <b>ENX Money</b> • Engineered with Precision by Enterprenex Solutions Pvt. Ltd.  
  <i>Official Support: <a href="mailto:support@enterprenex.solutions">support@enterprenex.solutions</a></i>
</div>
