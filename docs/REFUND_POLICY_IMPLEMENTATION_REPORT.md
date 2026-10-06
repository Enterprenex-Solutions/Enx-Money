# Section 03 — Refund & Cancellation Policy: Implementation & Audit Report

**Document Version:** 1.0.0  
**Audit & Implementation Date:** September 5, 2026  
**Application:** ENX Money (`com.enterprenex.enx_money`)  
**Operating Entity:** Enterprenex Solutions Pvt Ltd  

---

## 1. Executive Summary

This report documents the implementation of the dedicated, production-ready **Refund & Cancellation Policy** for ENX Money, strictly harmonized with the existing Terms & Conditions, Privacy Policy, codebase reality, and Google Play Billing requirements.

---

## 2. Project Audit Findings

### 2.1 Actual Payment Model & Billing Status
* **Zero Active Payment Gateways:** A comprehensive search across `client/` and `server/` confirms that no third-party payment gateway SDKs (Stripe, Razorpay, Cashfree, PayU, Paytm, or Braintree) are integrated into the application.
* **Google Play Billing Status:** No `in_app_purchase` or Android `BillingClient` packages are currently bundled into the Flutter application. 
* **Current Monetization:** All core features of ENX Money—including digital Khata ledgers, GST invoice generation, loan amortization schedules, and business analytics—are currently accessible **free of charge** without paywalls.
* **Offline Ledger Clarification:** Financial records logged by merchants (such as cash repayments, UPI receipts, or bank wire entries) are manual user inputs documenting external transactions. ENX Money does not handle, escrow, or transmit money.

### 2.2 Purchase Types Discovered
* **Physical Goods:** **None.** ENX Money does not sell, warehouse, or ship physical goods.
* **Real-World Services:** **None.** No offline manual services are sold through the platform.
* **Marketplace Intermediation:** **None.** *Marketplace functionality was not identified in the current implementation.* There are no buyer/seller listings, escrow holds, or transaction commission cuts.
* **Future Digital Purchases:** Optional premium digital tiers or Google Play subscriptions may be introduced in future releases; the Refund Policy establishes transparent terms and Google Play alignment in advance.

---

## 3. Implemented Policy Architecture

### 3.1 Public Legal Web Page (`/refund-policy`, `/refunds`, `/refund`)
* **Endpoint:** Served by the Express server (`server/src/public_legal_pages.js`) as a mobile-responsive HTML5 web page requiring no login or authentication.
* **Dedicated 11-Section Structure:**
  1. **Policy Overview & Scope:** Delineates software scope and adherence to Google Play Payments Policy.
  2. **Eligible Purchase Categories:** Discloses current free status and refund rules for any future optional digital purchases/subscriptions.
  3. **Non-Eligible Items & Clarifications:** Explicitly disclaims physical goods returns, real-world services, marketplace trades, and offline Khata debts.
  4. **Refund Request Window:** Dual-window structure:
     - *Google Play Automated Window:* Within 48 hours directly via Google Play.
     - *Developer Review Window:* Within 7 calendar days (configurable via `REFUND_WINDOW_DAYS`).
  5. **Refund Request Process:** Step-by-step instructions for:
     - *Method A:* Google Play Order History (`play.google.com/store/account/orderhistory`).
     - *Method B:* Direct developer support via `support@enxmoney.com` with Google Play Order ID (`GPA.XXXX-XXXX-XXXX-XXXXX`).
  6. **Refund Denial Conditions:** Late submissions, abuse/fraud, Terms of Service violations, and simultaneous active bank chargebacks.
  7. **Subscription Cancellation:** Self-service via Google Play Subscriptions (`play.google.com/store/account/subscriptions`). Explains that cancellation halts future renewals and retains access until the end of the paid billing period.
  8. **Google Play Billing Framework:** Establishes Google LLC as Merchant of Record for Android purchases; acknowledges Google Play's automated refund authority.
  9. **Statutory & Regional Rights:** Explicitly protects statutory consumer rights under EU/UK 14-day cooling-off directives and India's Consumer Protection Act, 2019.
  10. **Account Deletion & Refunds:** Clarifies that deleting an account does not automatically issue a refund or cancel Google Play subscriptions.
  11. **Contact & Support Information:** Published channels (`support@enxmoney.com`, `legal@enxmoney.com`, physical address).

### 3.2 In-App Access & UI Consistency
* **Profile Settings (`ProfileScreen`):** Direct tile linking to `ProfileModals.showRefundPolicyModal` and web launcher.
* **Data & Privacy Dashboard (`DataAndPrivacyScreen`):** Action tile providing both in-app modal reading and direct external web page launching.
* **In-App Modal (`ProfileModals`):** Updated summary reflecting the 11-section policy with a direct "Open Web Page" button.
* **Centralized Configuration (`ApiConfig.dart`):** `ApiConfig.refundPolicyUrl` routes to the public HTTPS domain.

---

## 4. Consistency Matrix Across Legal Suite

| Feature / Topic | Terms & Conditions | Privacy Policy | Refund Policy | Actual App Behavior | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **Marketplace** | Explicitly disclaimed (Sec. 1) | Disclaimed (No buyer/seller data) | Explicitly disclaimed (Sec. 3) | No marketplace code | **CONSISTENT** |
| **Physical Goods** | Disclaimed (Software SaaS) | Disclaimed (No shipping data) | Explicitly disclaimed (Sec. 3) | No physical catalog/shipping | **CONSISTENT** |
| **Payments** | Offline ledger tracking (Sec. 15) | No card/bank secrets stored | Clarified as offline logging (Sec. 3) | User manual entries only | **CONSISTENT** |
| **Google Play Role** | Google Play compliance (Sec. 15) | Play Store data safety alignment | Google as Merchant of Record (Sec. 8) | Android release build | **CONSISTENT** |
| **Account Deletion** | Right to delete account (Sec. 25) | Permanent purging (Sec. 18) | Account deletion vs. refund (Sec. 10) | `DELETE /api/users/account` | **CONSISTENT** |
| **Contact Channels** | `support@enxmoney.com` (Sec. 33) | `privacy@enxmoney.com` (Sec. 24) | `support@enxmoney.com` (Sec. 11) | Active mailer configuration | **CONSISTENT** |

---

## 5. Configuration & Legal Review Placeholders

The following parameters are centrally managed in `server/src/config/env.config.js`:

| Placeholder Variable | Configured Value | Verification Requirement |
| :--- | :--- | :--- |
| `REFUND_POLICY_VERSION` | `3.2.0` | Matches production release version. |
| `REFUND_POLICY_EFFECTIVE_DATE` | `September 1, 2026` | Operating start date. |
| `REFUND_POLICY_LAST_UPDATED` | `September 5, 2026` | Date of last material revision. |
| `REFUND_WINDOW_DAYS` | `7` | Confirm with business whether 7 days or 14 days is preferred for direct developer requests. |
| `SUPPORT_EMAIL` | `support@enxmoney.com` | Ensure dedicated customer support routing. |
| `LEGAL_CONTACT_EMAIL` | `legal@enxmoney.com` | Ensure monitored by legal/compliance officer. |
| `COMPANY_NAME` | `Enterprenex Solutions Pvt Ltd` | Matches RoC registration. |
| `COMPANY_ADDRESS` | `Hyderabad, Telangana, India` | Physical registered corporate address. |

---

## 6. Verification & Test Results

* **Flutter Static Analysis:** `flutter analyze` &rarr; **0 issues found**.
* **Client Unit & Widget Tests:** `flutter test` &rarr; **16 / 16 passed**.
* **Backend API & Integration Tests:** `npm test` &rarr; **13 / 13 suites passed (130 / 130 tests)**.
* **Public Web Routes:**
  - `GET /refund-policy` &rarr; **HTTP 200 OK (18.4 KB, HTML5, all 11 sections present)**.
  - `GET /refunds` &rarr; **HTTP 200 OK (alias)**.
  - `GET /terms-and-conditions` &rarr; **HTTP 200 OK (cross-linked to `/refund-policy`)**.
* **Release APK:** Production build `flutter build apk --release` compiled successfully (`ENX-Money.apk`, 59.4 MB).
