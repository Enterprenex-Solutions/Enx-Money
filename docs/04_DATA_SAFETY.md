# 04. Data Safety

## Purpose
The Data Safety section in Google Play Console is a mandatory, user-facing declaration of what data the app (including its third-party SDKs) collects, why, and how it is handled.

## Core Rule
The Data Safety declaration must accurately reflect:
* What your own code collects
* What every third-party SDK embedded in your app collects (Firebase, AdMob, Maps, payment SDKs, analytics SDKs, etc.)

You are responsible for both — Google does not accept "the SDK did it, not us" as a defense.

---

## Data Safety Declaration Template

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

*\*Email is shared strictly with Google LLC (Gmail SMTP relay) solely for the technical execution of OTP authentication emails.*

---

## SDK Data Cross-Reference

Before finalizing the declaration, cross-check every SDK in the app's dependency tree:

```text
Your App (ENX Money)
   |
   +-- Firebase       -> NOT INTEGRATED (Zero Firebase SDKs in pubspec.yaml; zero data collected)
   +-- AdMob          -> NOT INTEGRATED (Zero advertising SDKs; zero advertising IDs collected)
   +-- Maps           -> NOT INTEGRATED (Zero Maps SDKs; zero location data collected)
   +-- Payment SDK    -> NOT INTEGRATED (Zero active payment gateways; zero banking data collected)
   +-- Analytics SDK  -> NOT INTEGRATED (Zero third-party analytics; zero user tracking)
   +-- Other SDKs:
        |-- http (^1.2.2)               -> Transmits app requests to official backend over TLS 1.3
        |-- shared_preferences (^2.3.0) -> Local on-device storage for auth tokens & UI state (No telemetry)
        |-- local_auth (^2.3.0)         -> On-device Android BiometricPrompt; biometric data never leaves secure hardware enclave
        |-- share_plus (^10.0.2)        -> System share sheet for user-exported PDF/Excel invoices (No telemetry)
        |-- url_launcher (^6.3.0)       -> Invokes default system web browser for legal pages (No telemetry)
        |-- pdf (^3.11.1)               -> Local client-side PDF invoice rendering (Zero data collection)
        |-- excel (^4.0.6)              -> Local client-side spreadsheet generation (Zero data collection)
        |-- printing (^5.13.2)          -> Invokes Android PrintManager for local printing (Zero telemetry)
        |-- fl_chart (^0.69.0)          -> Local UI canvas rendering for cashflow graphs (Zero data collection)
        |-- provider (^6.1.2)           -> In-memory state management (Zero data collection)
        |-- uuid (^4.5.1)               -> Local RFC4122 cryptographic ID generator (Zero data collection)
        |-- google_fonts (^6.2.1)       -> Font asset retrieval via Google Fonts CDN (Zero personal data collected)
        |-- path_provider (^2.1.4)      -> File path helper for local temporary cache (Zero data collection)
```

---

## The Consistency Rule

**Data Safety, Privacy Policy, and actual app behavior must all match. A mismatch is one of the most common causes of rejection or suspension.**

1. **Privacy Policy Consistency:** The official Privacy Policy (hosted at `/privacy-policy` and within the mobile app at *Profile &rarr; Privacy Policy*) declares the exact same data collection categories, purposes, retention periods, and third-party restrictions as this Data Safety declaration.
2. **Actual App Behavior Consistency:**
   * `AndroidManifest.xml` requests only `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE`.
   * Sensitive permissions (`CAMERA`, `READ_CONTACTS`, `ACCESS_FINE_LOCATION`, `READ_SMS`, `RECORD_AUDIO`) are completely absent.
   * Encryption in transit (TLS 1.2/1.3) is enforced across all API endpoints.
   * Plaintext passwords and payment card numbers are never collected or stored.
   * Account deletion (both in-app via *Data & Privacy Dashboard* and public web via `/delete-account`) permanently purges or anonymizes all associated user records.

---

## Sign-off Checklist

- [x] **All first-party data collection documented**
- [x] **All third-party SDKs audited for data collection**
- [x] **Data Safety form in Play Console completed to match findings**
- [x] **Cross-checked against Privacy Policy for exact consistency**
- [x] **Re-verified after any SDK update or new feature that changes data collection**
