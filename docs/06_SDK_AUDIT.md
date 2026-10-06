# Section 6: SDK Audit — ENX Money

## Purpose
Developers are responsible for the data practices of every third-party SDK embedded in the app — not just their own first-party code. This audit tracks every SDK, what it collects, and whether it’s actually necessary.

---

## 6.1 Common SDKs Requiring Review
Google Play specifically scrutinizes the following categories of third-party SDKs commonly embedded in mobile applications:
- **Firebase** (Analytics, Crashlytics, Performance Monitoring, Remote Config, Auth)
- **Google Analytics / GA4**
- **AdMob** (Google Mobile Ads)
- **Facebook SDK** (Meta Audience Network, Login, App Events)
- **Payment Gateways** (Razorpay, Stripe, Cashfree, PayU)
- **Google Maps SDK / Location Services**
- **OneSignal / Push Notification SDKs**
- **Sentry / Bugsnag / Crashlytics**
- **External AI APIs / LLMs** (OpenAI, Gemini SDK)
- **Social Login SDKs** (Google Sign-In, Apple Sign-In, Facebook Login)

---

## 6.2 SDK Register

### Part A: Third-Party & Common Sensitive SDK Audit (Status in ENX Money)

| SDK | Purpose | Data Collected | Required? | Privacy Impact | In Data Safety? | Status in ENX Money |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Firebase** | Analytics, Push, Telemetry | Device IDs, IP, app events | No | Medium | Declared as Not Collected | **NOT INTEGRATED** |
| **AdMob** | In-app advertising | AAID, Device IDs, approximate location | No | High | Declared as Not Collected | **NOT INTEGRATED** (App is 100% ad-free) |
| **Google Maps** | Location services / Maps UI | Fine / Coarse Location, Wi-Fi SSID | No | High | Declared as Not Collected | **NOT INTEGRATED** (Dropdown address selection) |
| **Payment SDKs** (Razorpay/Stripe) | Card/UPI payment processing | PAN, card numbers, UPI VPA, billing info | No | High | Declared as Not Collected | **NOT INTEGRATED** (App is zero-cost utility) |
| **Sentry** | Crash & error monitoring | Stack traces, device metadata, OS version | No | Medium | Declared as Not Collected | **NOT INTEGRATED** (Internal error handling) |
| **Facebook SDK** | Social login & ad attribution | User profile, device advertising IDs | No | High | Declared as Not Collected | **NOT INTEGRATED** |
| **OneSignal** | Background push messaging | Push tokens, player IDs, device info | No | Medium | Declared as Not Collected | **NOT INTEGRATED** (System intents used) |
| **External AI APIs** | Machine learning processing | User prompts, transaction records | No | High | Declared as Not Collected | **NOT INTEGRATED** (Deterministic calculations) |
| **Social Login SDKs** | Third-party single sign-on | Social profile, avatar, OAuth tokens | No | Medium | Declared as Not Collected | **NOT INTEGRATED** (Direct email OTP auth) |

---

### Part B: Complete Verified Dependency Tree (From `client/pubspec.yaml` & Build Manifest)

| Package / Library | Version | Purpose | Data Collected / Transmitted | Required? | Privacy Impact | In Data Safety? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Flutter SDK** | `^3.13.1` | Core cross-platform rendering engine | None | **Yes** | None | N/A |
| **flutter_localizations** | `sdk` | Multi-language localization support | None | **Yes** | None | N/A |
| **http** | `^1.2.2` | REST API communication with secure backend | Network payloads (User auth, ledger entries) | **Yes** | Low | Yes (Declared) |
| **shared_preferences** | `^2.3.0` | Local key-value store (Theme, session tokens) | On-device key-values (Private app sandbox) | **Yes** | Low | Yes (On-device only) |
| **local_auth** | `^2.3.0` | Biometric fingerprint / Face Unlock on device | Hardware challenge only; biometric never leaves TEE | **Yes** | High (Secured) | Yes (On-device only) |
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

---

## 6.3 Audit Process
To maintain strict compliance with Google Play Store standards, ENX Money enforces the following audit lifecycle:
1. **Source of Truth Inspection:** Every dependency must be verified from actual build files (`pubspec.yaml`, `package.json`, `build.gradle`), not assumptions or memory.
2. **Data Flow & Transmission Tracing:** For every library added, determine whether it communicates with external servers, accesses device sensors, or reads persistent storage.
3. **Core Functionality Test:** If a package is not strictly necessary for a core user-facing feature, it must be removed.
4. **Data Safety Alignment:** Findings are fed directly into the Google Play Data Safety declaration and Privacy Policy.
5. **Continuous Re-Verification:** The audit is automatically re-run whenever dependencies are upgraded, replaced, or added.

---

## 6.4 Key Rule
> **“The SDK collected the data, not us” is not an acceptable justification.**  
> Google places sole and non-delegable legal responsibility for all embedded third-party code and its data handling practices directly on the application developer.

---

## Sign-off Checklist
- [x] Full SDK inventory compiled from actual build dependencies (`client/pubspec.yaml`, `server/package.json`).
- [x] Data collection behavior documented for each integrated library.
- [x] Unnecessary tracking, ad, and behavioral analytics SDKs completely omitted/removed.
- [x] Findings reflected accurately in Google Play Console Data Safety section.
- [x] Findings reflected accurately in public Privacy Policy (`/privacy-policy`).
- [x] Audit process integrated into CI/CD release gate and re-run on dependency updates.
