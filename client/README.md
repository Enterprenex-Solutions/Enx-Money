# ENX Money — Frontend Documentation

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-brightgreen?style=for-the-badge)

**Next-Gen Minimalist Fintech Application for Wealth, Expenses & Smart Khata Tracking**  
*Built with Flutter, Material 3 Dark Luxury Aesthetics, Live Email OTP & Biometric Authentication.*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Architecture & Design System](#-architecture--design-system)
- [Complete Authentication Flow](#-complete-authentication-flow)
- [Application Modules & Screens](#-application-modules--screens)
- [Project Directory Structure](#-project-directory-structure)
- [Getting Started & Running](#-getting-started--running)
- [API Client & Network Layer](#-api-client--network-layer)
- [Testing & Quality Assurance](#-testing--quality-assurance)

---

## 🌟 Overview

**ENX Money Frontend** is a modern Flutter client designed with high-contrast luxury aesthetics (CRED & Walnut inspired). It provides seamless financial tracking, credit card management, transaction analytics, and bank-grade authentication connecting to the Node.js/Express + MySQL (`enx_money`) backend API.

---

## 🎨 Architecture & Design System

The app utilizes a centralized design token system located in `lib/core/`:
- **Theme**: Dark Material 3 theme (`AppTheme.darkTheme`)
- **Colors (`AppColors`)**:
  - Background: Pitch Black (`#090B0E`) and Surface Slate (`#12161F`, `#1A1F2C`)
  - Accent: Neon Emerald (`#00E599` / `#05D686`)
  - Error / Warning / Success tokens with calibrated opacity states
- **Typography (`AppTypography`)**: Styled via `GoogleFonts` (`Outfit`, `Plus Jakarta Sans`, and monospace `Space Grotesk` for currencies/numerals).
- **Custom UI Components**:
  - `PrimaryButton` & `SecondaryButton` (with loading states & haptics)
  - `FintechTextField` (animated focus border & validation errors)
  - `PinDotIndicator` & `NumericKeypad` (tactile 6-digit & 4-digit input)
  - `CreditCardWidget` & `FintechCard` (luxury gradients & metallic badges)

---

## 🔐 Complete Authentication Flow

The frontend features a unified, multi-factor authentication flow connected directly to the backend API:

```
[Splash Screen]
      │
      ▼
[Onboarding Carousel]
      ├──> "CREATE ACCOUNT" ──> [Create Account Screen] (Name, Email, Mobile)
      │                                │ (Dispatches 6-digit OTP via Backend API)
      │                                ▼
      │                         [Email OTP Verification] (6-digit keypad + 60s cooldown timer)
      │                                │ (Verified against backend & JWT issued)
      │                                ▼
      │                         [Create Password Screen] (Live strength meter & rules)
      │                                │
      │                                ▼
      │                         [Biometric Setup Screen] (Fingerprint / Face ID setup)
      │                                │
      │                                ▼
      │                         [Biometric Registered] ──> [Main Shell / Dashboard]
      │
      └──> "SIGN IN" ─────────> [Login Screen]
                                       ├── Password Sign-In (Email/Mobile + Password)
                                       ├── Biometric Sign-In (Local Auth Face ID / Fingerprint)
                                       └── "Sign in with Email OTP" ──> [Email Login Screen] ──> [OTP Verification] ──> [Dashboard]
```

### Key Auth Screens:
1. **`SplashScreen`**: Animated ENX Shield with luxury gradient pulse and auto-navigation.
2. **`OnboardingScreen`**: 3-step value carousel with "Create Account", "Sign In", and "Skip" options.
3. **`CreateAccountScreen`**: Collects Full Name, Email, and Mobile number, initiating backend OTP generation.
4. **`OtpVerificationScreen`**: 6-digit custom pin indicator, numeric keypad, 60-second cooldown timer, resend OTP API, and dual registration/login routing.
5. **`CreatePasswordScreen`**: Password strength checker (length, uppercase, digits, symbols) and confirm password matching.
6. **`BiometricSetupScreen`**: Hardware-aware biometric enrollment using `local_auth` with skip option.
7. **`LoginScreen`**: Multi-method login offering Password, Biometrics, and direct link to Email OTP sign-in.
8. **`EmailLoginScreen`**: Passwordless email login that triggers verification codes.
9. **`AppLockPinScreen` & `BiometricAuthScreen`**: In-app security lock screens.

---

## 📱 Application Modules & Screens

Once authenticated, the user enters the **`MainShellScreen`** featuring a floating bottom navigation bar:

| Tab | Screen | Key Features |
|---|---|---|
| 🏠 **Home** | `DashboardScreen` | Net worth master vault, ENX Credit Score (842 EXCELLENT), quick actions (Scan & Pay, Send Money), bill payment reminders. |
| 💳 **Cards** | `CardsScreen` | Interactive Black Titanium & Platinum card switcher, one-tap Freeze/Lock toggle, CVV reveal, monthly spend limit progress bar. |
| 📜 **Passbook** | `TransactionsScreen` | Searchable transaction ledger, category filter chips (Shopping, Dining, Transfer, etc.), and transaction detail modal. |
| 📊 **Insights** | `AnalyticsScreen` | Monthly cash outflow tracker, weekly spend bar chart, category breakdown meters. |
| 👤 **Profile** | `ProfileScreen` | Verified KYC badge, Biometric & App Lock security toggles, device session manager, and secure logout. |

---

## 📁 Project Directory Structure

```
frontend/
├── pubspec.yaml
├── test/
│   └── widget_test.dart
└── lib/
    ├── main.dart                               # App entry point & dynamic route generator
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart                 # Color tokens, gradients & shadows
    │   │   ├── app_typography.dart             # Google Fonts typographic hierarchy
    │   │   └── app_dimensions.dart             # Padding, radii, button heights
    │   ├── network/
    │   │   ├── api_client.dart                 # HTTP client with JWT interceptor
    │   │   └── api_config.dart                 # Base URLs and auth endpoint definitions
    │   ├── theme/
    │   │   └── app_theme.dart                  # Global dark theme definition
    │   ├── utils/
    │   │   └── currency_formatter.dart         # INR (₹) formatting utilities
    │   └── widgets/
    │       ├── app_bars/                       # FintechAppBar
    │       ├── buttons/                        # PrimaryButton, SecondaryButton
    │       ├── cards/                          # FintechCard, CreditCardWidget
    │       ├── feedback/                       # StatBadge
    │       └── inputs/                         # FintechTextField, PinDotIndicator, NumericKeypad
    └── features/
        ├── auth/                               # Complete Auth Module
        │   ├── data/
        │   │   ├── auth_repository.dart        # API integration & local session cache
        │   │   ├── biometric_service.dart      # Hardware biometric bridge
        │   │   └── mock_auth_repository.dart
        │   ├── models/
        │   │   └── user_model.dart             # User profile data model
        │   └── presentation/screens/
        │       ├── splash_screen.dart
        │       ├── onboarding_screen.dart
        │       ├── create_account_screen.dart
        │       ├── create_password_screen.dart
        │       ├── otp_verification_screen.dart
        │       ├── biometric_setup_screen.dart
        │       ├── biometric_registered_screen.dart
        │       ├── login_screen.dart
        │       ├── email_login_screen.dart
        │       ├── app_lock_pin_screen.dart
        │       └── biometric_auth_screen.dart
        ├── shell/                              # MainShellScreen & CustomBottomNavBar
        ├── dashboard/                          # DashboardScreen & widgets
        ├── cards/                              # CardsScreen & widgets
        ├── transactions/                       # TransactionsScreen & widgets
        ├── analytics/                          # AnalyticsScreen & charts
        └── profile/                            # ProfileScreen & security toggles
```

---

## 🚀 Getting Started & Running

### 1. Prerequisites
- **Flutter SDK** (`>= 3.13.0`)
- **Dart SDK** (`>= 3.13.0`)
- Google Chrome, Microsoft Edge, or Android Emulator / Physical Device.

### 2. Install Packages
```bash
cd frontend
flutter pub get
```

### 3. Run the App
```bash
# Run in Google Chrome (Web)
flutter run -d chrome

# Run in Microsoft Edge (Web)
flutter run -d edge

# Run on Android Device / Emulator
flutter run
```

---

## 🌐 API Client & Network Layer

The frontend communicates with the backend API via `ApiClient` ([api_client.dart](file:///d:/Enterprenex%20Solutions/ENX_Money/frontend/lib/core/network/api_client.dart)):
- Automatically resolves base URL (`http://localhost:5000/api` for web/desktop, `http://10.0.2.2:5000/api` for Android emulator).
- Automatically attaches `Authorization: Bearer <JWT_TOKEN>` on protected requests.
- Synchronizes authentication status with local `SharedPreferences` for offline resilience.

---

## 🧪 Testing & Quality Assurance

Run static analysis and automated unit tests:

```bash
# Run static analysis
flutter analyze

# Run unit & widget test suite
flutter test
```

---

<div align="center">
  <b>ENX Money</b> • Crafted by Enterprenex Solutions
</div>
