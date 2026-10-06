# Section 7: Security Audit — ENX Money

## Purpose
Defines the internal security policy and audit checklist covering authentication, API security, database security, infrastructure, and development practices for ENX Money.

---

## 7.1 Authentication
- [x] **Strong Password Requirements Enforced:** Passwords must meet minimum length, complexity (alphanumeric + special characters), and cannot match common credential dictionaries. Passwords are salted and hashed using `bcryptjs` with high cost factors.
- [x] **Multi-Factor Authentication (MFA) Available / Enforced:** Real 6-digit cryptographic Email OTP verification enforced via secure Gmail SMTP relay (`nodemailer`) for registration, password reset, and sensitive financial authorizations.
- [x] **Secure Session Management:** Sessions utilize cryptographically signed JSON Web Tokens (JWT) with standard expiration (24 hours). Token rotation and server-side blacklisting (`activeTokens` in-memory / redis store) invalidate sessions upon explicit user logout or account deletion.
- [x] **Secure Password Reset Flow:** Implemented via time-limited (10-minute validity), single-use OTP codes (`/api/auth/verify-reset-otp`) and ephemeral reset tokens (`/api/auth/reset-password`). Tokens cannot be replayed or reused.

---

## 7.2 API Security
- [x] **Authentication & Authorization Enforced on Every Endpoint:** All financial, customer, loan, and profile endpoints require a valid `Bearer <token>` header verified by `auth.middleware.js`. No endpoint relies on client-side authentication checks alone.
- [x] **Rate Limiting on Sensitive/High-Risk Endpoints:** Enforced using `express-rate-limit` on `/api/auth/send-otp`, `/api/auth/login`, and `/api/auth/register` to block brute-force, credential-stuffing, and DDoS attempts.
- [x] **Input Validation and Sanitization Server-Side:** Enforced using `express-validator` across all incoming request bodies, query strings, and URL parameters to reject malformed inputs before database execution.
- [x] **Protection Against Injection, XSS, and CSRF:**
  - Database queries utilize parameterized statements (`mysql2/promise` with placeholder bindings) preventing SQL/NoSQL injection.
  - HTTP response security headers enforced by `helmet()` (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, Content Security Policy).
- [x] **No Excessive Data Exposure in API Responses:** Passwords, password hashes, internal DB credentials, and unmasked system secrets are completely stripped from API response payloads.
- [x] **Protection Against IDOR (Insecure Direct Object Reference):** Multi-tenant tenant isolation is strictly verified. Queries always enforce `WHERE id = ? AND user_id = ?`, preventing unauthorized access to another user's financial ledger or customers.
- [x] **JWT / Token Manipulation Resistance Verified:** Tokens are signed using `HS256` with a strong server-side secret (`JWT_SECRET`). Algorithm none-attacks and altered payloads are strictly rejected with HTTP 401 Unauthorized.

---

## 7.3 Database Security
- [x] **Encryption at Rest:** Storage volumes and database partitions are encrypted at rest using AES-256 in managed production environments.
- [x] **Regular, Automated Backups:** Automated daily snapshots and point-in-time recovery configurations with defined retention windows.
- [x] **Restricted, Least-Privilege Access:** Database credentials use restricted application-specific user grants without global `SUPER` or administrative privileges.
- [x] **Database Never Directly Exposed to the Public Internet:** Database binds strictly to `localhost` or isolated VPC private subnets; public ingress is completely disabled.

---

## 7.4 Infrastructure
- [x] **Firewall Rules Restricting Access to Internal Services:** Strict ingress firewall rules allow only public HTTPS (port 443) to reverse proxies/application gateways; database and cache ports are blocked from external access.
- [x] **HTTPS/TLS Enforced Everywhere:** All network transport uses TLS 1.2/1.3. Android `NetworkSecurityConfig` explicitly enforces `cleartextTrafficPermitted="false"`.
- [x] **Secrets Management Solution:** Database passwords, JWT signing keys, and SMTP credentials reside strictly in server `.env` files and environment variables, never committed to git or bundled in the Android client APK/AAB.
- [x] **Ongoing Monitoring and Alerting:** Application health checks (`/api/health`), request logging via `morgan`, and error handling middleware alert on unexpected runtime anomalies.

---

## 7.5 Development Practices
- [x] **Code Review Required:** Pull requests and multi-party reviews required prior to merging into production branches (`main`, `release/*`).
- [x] **Dependency Scanning for Known Vulnerabilities:** Regular automated `npm audit` and `flutter pub outdated` vulnerability checks.
- [x] **Secret Scanning on Commits & Git History:** Git hooks and CI pipelines verify zero API keys, private keys, or passwords in committed files.
- [x] **Periodic Vulnerability / Penetration Testing:** Pre-launch security audits and automated integration testing across all auth, card, customer, and ledger endpoints.

---

## 7.6 Never Log
The following sensitive data types must **NEVER** appear in application logs, console output, crash dumps, or error reports:
- Passwords
- OTP verification codes
- Credit/Debit card numbers (PANs) and CVVs
- JWT tokens and authorization headers
- API secrets, private keys, and database passwords

### Logging Examples
```
❌ BAD:  User login: email=abc@gmail.com password=123456 otp=814906
✓  GOOD: LOGIN_SUCCESS user_id=8291 timestamp=2026-09-08T21:30:00Z ip=127.0.0.1
```

---

## 7.7 Sensitive Data Categories Requiring Elevated Controls
The following sensitive data categories require elevated security and architectural safeguards:
- **Financial Information:** Double-entry ledger balances, customer dues, and transaction histories are isolated per tenant and transmitted solely over TLS 1.3.
- **Identity Documents & Government IDs:** Not stored in plaintext; masked when displayed.
- **Authentication Credentials:** Passwords salted and hashed with `bcryptjs`.
- **Biometrics:** Kept entirely on-device within Android Keystore / Trusted Execution Environment (TEE); raw biometrics are never sent over the network or stored in database tables.
- **Children’s Data:** Strictly zero data collected (app intended for adult business & personal finance).

---

## Sign-off Checklist
- [x] Authentication controls reviewed (MFA, password policy, session handling, password reset).
- [x] API endpoints tested for authz/authn bypass, IDOR, injection, and rate limiting.
- [x] Database access restricted, isolated from public internet, and encrypted where appropriate.
- [x] Secrets management in place; no hardcoded secrets in code or APK.
- [x] Logging reviewed to ensure no sensitive data (passwords, OTPs, tokens) is captured.
- [x] Dependency and secret scanning integrated into development lifecycle.
- [x] Elevated review completed for all sensitive financial and authentication data categories.
