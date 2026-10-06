# ENX Money: Business Model & Architecture Audit for Terms of Service

**Document Version:** 1.0.0  
**Audit Date:** September 5, 2026  
**Auditor:** Lead System Architect & Release Engineer  
**Application:** ENX Money (`com.enterprenex.enx_money`)  
**Operating Entity:** Enterprenex Solutions Pvt Ltd  

---

## 1. Executive Summary

This business model audit provides the factual baseline for drafting legally sound, production-ready Terms & Conditions for ENX Money. It establishes what the application actually does, how data flows, what commercial transactions take place, and which legal frameworks govern its operations.

---

## 2. Core Business Model & Architectural Findings

### 2.1 Application Purpose & Target Audience
* **Core Purpose:** Digital business ledger (Khata), customer/supplier credit-debit accounting, GST invoice generator, loan amortization and repayment tracking, and business analytics.
* **Target Audience:** Micro, small, and medium enterprises (MSMEs), sole proprietors, merchants, retail shopkeepers, and individual business professionals.
* **Intended Age Group:** Adults aged 18 and older. Not designed for or marketed to children.

### 2.2 Functional Architecture & Services Discovered
1. **Authentication & Identity:**
   - Email + Password registration with 6-digit one-time password (OTP) verification dispatched via Google Gmail SMTP.
   - On-device local biometric authentication (`local_auth`: Fingerprint / Face ID) and 4-digit App Lock PIN stored in secure local storage.
2. **Khata & Counterparty Ledger (`customers`, `suppliers`):**
   - Offline & online management of customer and supplier ledgers.
   - Recording credit ("You Gave" / Debit) and payment ("You Got" / Credit) transactions.
   - Dynamic debt calculation, customer credit limits, and balance calculation.
3. **GST Invoicing & Billing (`invoices`, `inventory`):**
   - Product catalog with SKU, stock quantity, cost price, selling price, and applicable GST slab rates (0%, 5%, 12%, 18%, 28%).
   - Generation of client-side PDF invoices and print integration (`pdf`, `printing` packages).
4. **Loan & EMI Tracker (`loans`, `emi_schedules`, `loan_payments`, `prepayments`):**
   - Amortization schedule generator for personal and business loans.
   - Calculation of monthly EMIs, principal vs. interest breakdown, and late fees.
   - Offline logging of borrower/lender loan repayments and prepayment impact simulations.
5. **Business Analytics & KPI Dashboard (`analytics`):**
   - Trend charts (`fl_chart`), revenue vs. expense aggregates, and category distribution.
6. **Data Export & Portability:**
   - On-device rendering of PDF summaries and Excel (`.xlsx`) spreadsheets shared via system share sheet (`share_plus`).

---

## 3. Commercial & Transactional Verification

| Question | Codebase Reality | Terms of Service Implication |
| :--- | :--- | :--- |
| **Is the app currently free?** | **Yes.** All core accounting, Khata, loan tracking, and invoicing features are freely accessible to registered users. | Standard software license terms apply without mandatory payment conditions. |
| **Do paid features / paywalls exist?** | **No active paywalls in code.** No features are locked behind payment barriers in the current build. | Terms must disclose that free access is provided at company discretion, with provisions for future optional premium tiers. |
| **Do recurring subscriptions exist?** | **No active subscription APIs.** No recurring payment schedulers, webhooks, or subscription tables exist. | No fabricated subscription renewal clauses. Configurable placeholder provided for future tiers. |
| **Are online payments processed?** | **No payment gateway integrated.** No Stripe, Razorpay, PayU, Cashfree, Paytm, or Google Play Billing SDKs exist in `client/` or `server/`. | Software does NOT process digital payments or hold escrow funds. Repayments logged are manual records of offline transactions. |
| **Does ENX Money act as a marketplace?** | **NO.** *Marketplace functionality was not identified in the current implementation.* There are no buyer/seller listings, no cart, no order dispatch, and no escrow. | **No marketplace buyer/seller terms shall be included.** |
| **Do buyers and sellers interact on platform?** | **No.** Users manage their own private records of external customers and suppliers. Counterparties do not log in to execute trades. | Relationship is strictly Software Provider &rarr; Single Tenant Merchant. |
| **Does ENX Money charge commissions?** | **No.** Zero transaction fees, cut percentages, or marketplace commission logic exists. | Commission clauses must NOT be included. |
| **Do users generate/upload content?** | **Yes.** Users input customer names, phone numbers, product catalogs, invoice line items, loan parameters, and business metadata. | User retains ownership of their data; grants limited operational processing license to ENX Money. |
| **Can users transact with each other directly?** | **No.** Users cannot transfer digital money or execute P2P transfers within the app. | Clear financial disclaimer: ENX Money is an informational record-keeping tool, not a payment intermediary. |
| **Is ENX Money a bank or NBFC?** | **No.** ENX Money does not disburse loans, underwrite credit, or accept deposits. | Mandatory Financial & Tax Disclaimer required in Terms. |

---

## 4. Operational Legal Classification

ENX Money operates strictly as a **Software-as-a-Service (SaaS) Digital Bookkeeping and Business Utility**. It provides record-keeping tools on a multi-tenant cloud architecture with local offline persistence.

* **Developer & Legal Entity:** Enterprenex Solutions Pvt Ltd
* **Jurisdiction:** Republic of India (Hyderabad, Telangana)
* **Primary Compliance Regulations:** Information Technology Act, 2000; Digital Personal Data Protection Act, 2023; Google Play Developer Distribution Agreement.
