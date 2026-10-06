# ENX Money: Terms & Conditions Configuration Reference

**Document Version:** 1.0.0  
**Effective Date:** September 5, 2026  
**Application:** ENX Money  
**Operating Entity:** Enterprenex Solutions Pvt Ltd  

---

## 1. Overview

To ensure the Terms & Conditions and legal suite remain configurable across different deployment environments and legal reviews, all legal parameters are driven by environment variables and centralized constants.

Below is the exhaustive list of configuration placeholders utilized by the backend (`server/src/config/env.config.js`) and mobile client (`client/lib/core/network/api_config.dart`).

---

## 2. Server Configuration Variables (`server/.env`)

| Variable Name | Current Default Value | Required Action / Description |
| :--- | :--- | :--- |
| `COMPANY_NAME` | `Enterprenex Solutions Pvt Ltd` | Legal registered entity name of the company operating ENX Money. |
| `COMPANY_ADDRESS` | `Hyderabad, Telangana, India` | Physical corporate mailing address for legal notices. Verify against company incorporation certificate. |
| `SUPPORT_EMAIL` | `support@enxmoney.com` | Customer service contact email for user inquiries. |
| `PRIVACY_CONTACT_EMAIL` | `privacy@enxmoney.com` | Data Protection Officer (DPO) contact email for data rights and deletion requests. |
| `TERMS_VERSION` | `3.2.0` | Current version number of the Terms & Conditions. Increment when modifying material legal clauses. |
| `TERMS_EFFECTIVE_DATE` | `September 1, 2026` | Date on which the current Terms became legally operational. |
| `TERMS_LAST_UPDATED` | `September 5, 2026` | Timestamp of the most recent revision. |
| `GOVERNING_LAW` | `Laws of the Republic of India` | Primary legal jurisdiction governing interpretation and enforcement of the Terms. |
| `JURISDICTION` | `Courts of competent jurisdiction in Hyderabad, Telangana, India` | Specific judicial venue for dispute resolution and legal proceedings. |
| `PUBLIC_URL` | Auto-detected / Cloud Domain | Public HTTPS base domain serving web legal pages. |

---

## 3. Flutter Client Configuration (`client/lib/core/network/api_config.dart`)

| Compile-Time Define (`--dart-define`) | Default Fallback | Purpose |
| :--- | :--- | :--- |
| `TERMS_AND_CONDITIONS_URL` | `https://<root>/terms-and-conditions` | Direct URL launched when tapping Terms & Conditions in-app. |
| `TERMS_URL` | `https://<root>/terms-and-conditions` | Shorthand alias fallback for Terms URL. |
| `PRIVACY_POLICY_URL` | `https://<root>/privacy-policy` | Public URL for the Privacy Policy. |
| `REFUND_POLICY_URL` | `https://<root>/refund-policy` | Public URL for the In-App Refund Policy. |
| `DELETE_ACCOUNT_WEB_URL` | `https://<root>/delete-account` | Public web-based deletion request portal for uninstalled app users. |

---

## 4. Production Review Checklist for Business & Legal Counsel

Before commercial distribution on the Google Play Store:
- [ ] Verify registered office address with the Registrar of Companies (RoC).
- [ ] Confirm active mailbox forwarding for `support@enxmoney.com` and `privacy@enxmoney.com`.
- [ ] Review dispute resolution forum (`Hyderabad, Telangana`) with qualified corporate legal counsel.
- [ ] If paid subscription tiers or in-app billing are activated in future releases, update `Section 15 (Payments)`, `Section 16 (Subscriptions)`, and `Section 18 (Refunds)` accordingly.
