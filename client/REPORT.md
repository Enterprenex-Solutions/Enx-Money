# ENX Money — Technical Architecture & Implementation Report

---

## 1. Executive Summary

**ENX Money** is a mobile finance tracking application developed in **Flutter/Dart**. The project delivers an end-to-end security and finance management system. The solution implements a multi-step user onboarding sequence integrated with hardware **Biometric Authentication (Fingerprint & Face ID)** alongside a visual financial dashboard.

---

## 2. Introduction

### 2.1 Problem Statement
Modern users demand fast, secure access to financial tools without sacrificing security. Traditional password-only authentication is prone to friction, while security measures must remain robust when sensitive transaction records are stored locally.

### 2.2 Objectives
1. Build a registration pipeline: **Create Account ➔ Create Password ➔ Set Up Biometric ➔ Biometric Registered ➔ Dashboard**.
2. Support dual-path login for returning users: **Email/Mobile + Password** OR **Biometric Auth**.
3. Develop an interactive finance dashboard featuring summary cards, trend analysis (`fl_chart` LineChart), category distribution (`fl_chart` PieChart), and transaction history.
4. Ensure clean, modular software architecture adhering to Flutter best practices.

---

## 3. System Architecture

```
                               ┌───────────────────────────┐
                               │     ENX Money App UI      │
                               └─────────────┬─────────────┘
                                             │
      ┌──────────────────────────────────────┼──────────────────────────────────────┐
      ▼                                      ▼                                      ▼
┌──────────────┐                       ┌──────────────┐                       ┌──────────────┐
│ Auth Service │                       │  Biometric   │                       │   Storage    │
│  (Session)   │                       │   Service    │                       │   Service    │
└──────┬───────┘                       └──────┬───────┘                       └──────┬───────┘
       │                                      │                                      │
       ▼                                      ▼                                      ▼
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│                             SharedPreferences & Hardware Secure Enclave                   │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Layer Breakdown
- **Presentation Layer (`lib/screens/`, `lib/widgets/`)**: Reactive UI built with Material Design widgets, custom animations, and responsive layouts.
- **Business & Service Layer (`lib/services/`)**:
  - `AuthService`: Handles user registration, credentials validation, hashing, and session management.
  - `BiometricService`: Encapsulates `local_auth` plugin for hardware fingerprint and facial recognition checks.
  - `StorageService`: Manages CRUD operations and calculations for transactions stored in JSON format.
- **Data Model Layer (`lib/models/`)**: Strongly typed Dart classes (`UserModel`, `TransactionModel`, `TransactionType`).

---

## 4. Authentication Pipeline Implementation

```
[Screen 1: Create Account] ──(Name, Email, Mobile)──► [Screen 2: Create Password]
                                                             │
                                                    (Password & Strength Check)
                                                             │
                                                             ▼
[Screen 4: Biometric Registered] ◄──(Auth Success)─── [Screen 3: Biometric Setup]
               │                                             │
      (Continue Button)                                  (Skip Option)
               │                                             │
               └──────────────────────┬──────────────────────┘
                                      ▼
                            [Screen 5: Dashboard]
```

### 4.1 Step 1: Create Account (`create_account_screen.dart`)
- Captures Full Name, Email Address, and Mobile Number.
- Implements real-time regex validation for email structure and phone length.
- Features a step progress indicator set to 33%.

### 4.2 Step 2: Create Password (`create_password_screen.dart`)
- Evaluates password strength dynamically across four parameters:
  1. Minimum 8 characters
  2. Uppercase letter presence (`A-Z`)
  3. Numeric digit presence (`0-9`)
  4. Special character presence (`!@#$%^&*`)
- Displays a multi-colored strength bar indicator (Weak ➔ Fair ➔ Good ➔ Strong) and live checklist.

### 4.3 Step 3: Biometric Setup (`biometric_setup_screen.dart`)
- Interrogates device hardware via `local_auth` for biometric sensor availability.
- Prompts user to scan Fingerprint or Face ID.
- Provides fallback "Skip for Now" option to ensure non-blocking user flow.

### 4.4 Step 4: Biometric Registered (`biometric_registered_screen.dart`)
- Displays an animated success indicator using `ElasticOut` curve animations.
- Persists user preferences to local storage and redirects to the Dashboard.

### 4.5 Returning Login Flow (`login_screen.dart`)
- Enables traditional credentials entry (Email/Mobile + Password).
- Dynamically exposes "Login with Biometrics" button when biometric credentials are active on the device.

---

## 5. Dashboard & Analytics

### 5.1 Financial Summary Card
Computes real-time totals:
$$\text{Total Balance} = \sum \text{Income} - \sum \text{Expenses}$$

Formatted dynamically using Indian Rupee currency standard (`₹`).

### 5.2 7-Day Spending Trend (`fl_chart` LineChart)
- Aggregates daily expense sums over the rolling 7-day period.
- Renders a curved line with gradient area fill under the curve for intuitive visualization.

### 5.3 Category Expense Breakdown (`fl_chart` PieChart)
- Groups expense transactions by category (`Food`, `Transport`, `Shopping`, `Bills`, `Entertainment`, `Health`, `Education`).
- Displays percentage contributions and color-coded legend tiles.

---

## 6. Security Analysis

| Feature | Implementation | Recommendation for Production |
|---|---|---|
| Password Storage | Hash matching via `String.hashCode` | Replace with Argon2 / bcrypt on server side |
| Session Token | `SharedPreferences` boolean flag | Use `flutter_secure_storage` encrypted keystore |
| Biometrics | `local_auth` with `stickyAuth: true` | Hardware-backed Keychain / KeyStore validation |

---

## 7. Deliverables Checklist

- [x] Complete Flutter source code in one folder (`enx_money`)
- [x] Biometric authentication integration (`local_auth`)
- [x] Full registration sequence (4 screens)
- [x] Dual-path Login Screen
- [x] Financial Dashboard with Line & Pie Charts (`fl_chart`)
- [x] Add Transaction form with category selection
- [x] Comprehensive `README.md`
- [x] Full Technical Report (`REPORT.md`)
