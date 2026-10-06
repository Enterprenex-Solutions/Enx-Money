import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/localization/locale_controller.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/email_login_screen.dart';
import 'features/auth/presentation/screens/create_account_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/security_credential_setup_screen.dart';
import 'features/auth/models/user_model.dart';
import 'features/loans/presentation/screens/add_loan_screen.dart';
import 'features/loans/presentation/screens/loan_dashboard_screen.dart';
import 'features/customers/presentation/screens/customers_screen.dart';
import 'features/customers/presentation/screens/add_customer_screen.dart';
import 'features/suppliers/presentation/screens/suppliers_screen.dart';
import 'features/suppliers/presentation/screens/add_supplier_screen.dart';
import 'features/expenses/models/expense_model.dart';
import 'features/expenses/presentation/screens/expenses_screen.dart';
import 'features/expenses/presentation/screens/add_expense_screen.dart';
import 'features/invoices/presentation/screens/invoices_screen.dart';
import 'features/invoices/presentation/screens/create_invoice_screen.dart';
import 'features/inventory/presentation/screens/inventory_screen.dart';
import 'features/inventory/presentation/screens/add_product_screen.dart';
import 'features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import 'features/shell/presentation/screens/main_shell_screen.dart';
import 'core/services/notification_service.dart';
import 'features/finance_mode/presentation/screens/fund_transfer_screen.dart';
import 'features/finance_mode/presentation/screens/personal_dashboard_screen.dart';
import 'features/finance_mode/presentation/screens/consolidated_dashboard_screen.dart';
import 'features/finance_mode/presentation/screens/business_banking_screen.dart';
import 'features/finance_mode/presentation/screens/financial_calendar_screen.dart';
import 'features/finance_mode/presentation/screens/financial_goals_screen.dart';
import 'features/finance_mode/presentation/screens/personal_budget_screen.dart';
import 'features/finance_mode/presentation/screens/personal_expenses_screen.dart';
import 'features/finance_mode/presentation/screens/mode_selector_screen.dart';
import 'features/finance_mode/presentation/screens/account_setup_screen.dart';
import 'features/finance_mode/presentation/screens/personal_analytics_screen.dart';
import 'features/finance_mode/presentation/screens/autopay_mandates_screen.dart';
import 'package:provider/provider.dart';
import 'domain/repositories/transaction_repository.dart';
import 'ui/features/compliance/compliance_center_view.dart';
import 'features/profile/presentation/screens/devices_management_screen.dart';
import 'features/legal/presentation/screens/legal_pages_screens.dart';
import 'screens/settings/support_screen.dart';
import 'core/services/reminder_service.dart';
import 'core/services/app_lock_service.dart';
import 'features/ai/presentation/screens/meta_ai_chat_screen.dart';
import 'features/auth/presentation/screens/app_lock_pin_screen.dart';
import 'features/auth/presentation/screens/security_questions_setup_screen.dart';
import 'features/profile/presentation/screens/security_settings_screen.dart';
import 'features/profile/presentation/screens/digital_identity_kyc_screen.dart';
import 'features/wallet/presentation/screens/central_wallet_dashboard.dart';
import 'features/wallet/presentation/screens/add_money_screen.dart';
import 'features/analytics/presentation/screens/audit_reporting_screen.dart';
import 'ui/features/whatsapp/whatsapp_chatbot_view.dart';
import 'features/subscription/presentation/screens/pricing_screen.dart';
import 'features/subscription/presentation/screens/billing_dashboard_screen.dart';
import 'core/widgets/entitlement_guard.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  await ThemeController().init();
  await LocaleController().init();
  await ReminderService.instance.initialize();
  await AppLockService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionRepository()),
      ],
      child: const ENXMoneyApp(),
    ),
  );
}

class ENXMoneyApp extends StatefulWidget {
  const ENXMoneyApp({super.key});

  @override
  State<ENXMoneyApp> createState() => _ENXMoneyAppState();
}

class _ENXMoneyAppState extends State<ENXMoneyApp> with WidgetsBindingObserver {
  final AppLockService _appLockService = AppLockService.instance;
  bool _isLockScreenShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLockService.addListener(_onLockStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appLockService.removeListener(_onLockStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _appLockService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _appLockService.onAppResumed();
    }
  }

  void _onLockStateChanged() {
    if (_appLockService.isLocked &&
        !_appLockService.isAppUnlocked &&
        !_isLockScreenShowing &&
        !_appLockService.isAuthenticated) {
      _showLockScreen();
    }
  }

  void _showLockScreen() {
    final nav = _appLockService.navigatorKey.currentState;
    if (nav == null) return;

    _isLockScreenShowing = true;
    nav.push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, __) => AppLockPinScreen(
          onUnlocked: () {
            _isLockScreenShowing = false;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    ).then((_) {
      _isLockScreenShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeController(), LocaleController(), _appLockService]),
      builder: (context, _) {
        final isDark = ThemeController().isDarkMode;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark ? const Color(0xFF12161F) : const Color(0xFFF1F5F9),
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          navigatorKey: _appLockService.navigatorKey,
          title: 'ENX Money',
          scaffoldMessengerKey: NotificationService.messengerKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController().themeMode,
          locale: LocaleController().locale,
          supportedLocales: LocaleController.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/app-lock': (_) => const AppLockPinScreen(),
            '/': (_) => const SplashScreen(),
            '/app': (_) => const SplashScreen(),
            '/app/': (_) => const SplashScreen(),
            '/web': (_) => const SplashScreen(),
            '/web/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/email-login': (_) => const EmailLoginScreen(),
            '/create-account': (_) => const CreateAccountScreen(),
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const MainShellScreen(),
            '/customers': (_) => const CustomersScreen(),
            '/add-customer': (_) => const AddCustomerScreen(),
            '/suppliers': (_) => const SuppliersScreen(),
            '/add-supplier': (_) => const AddSupplierScreen(),
            '/expenses': (_) => const ExpensesScreen(),
            '/add-expense': (_) => const AddExpenseScreen(),
            '/invoices': (_) => const InvoicesScreen(),
            '/create-invoice': (_) => const CreateInvoiceScreen(),
            '/inventory': (_) => const InventoryScreen(),
            '/add-product': (_) => const AddProductScreen(),
            '/loans': (_) => const LoanDashboardScreen(),
            '/add-loan': (_) => const AddLoanScreen(),
            '/analytics': (_) => const AnalyticsDashboardScreen(),
            '/fund-transfer': (_) => const FundTransferScreen(),
            '/personal-dashboard': (_) => const PersonalDashboardScreen(),
            '/consolidated-dashboard': (_) => const ConsolidatedDashboardScreen(),
            '/business-banking': (_) => const BusinessBankingScreen(),
            '/financial-calendar': (_) => const FinancialCalendarScreen(),
            '/financial-calculator': (_) => const FinancialCalendarScreen(),
            '/financial-goals': (_) => const FinancialGoalsScreen(),
            '/personal-budget': (_) => const PersonalBudgetScreen(),
            '/personal-expenses': (_) => const PersonalExpensesScreen(),
            '/mode-selector': (_) => const ModeSelectorScreen(),
            '/account-setup': (_) => const AccountSetupScreen(),
            '/personal-analytics': (_) => const PersonalAnalyticsScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/compliance-center': (_) => const ComplianceCenterView(),
            '/devices': (_) => const DevicesManagementScreen(),
            '/privacy-policy': (_) => const PrivacyPolicyScreen(),
            '/settings/privacy-policy': (_) => const PrivacyPolicyScreen(),
            '/privacy': (_) => const PrivacyPolicyScreen(),
            '/terms-and-conditions': (_) => const TermsAndConditionsScreen(),
            '/terms-conditions': (_) => const TermsAndConditionsScreen(),
            '/settings/terms-conditions': (_) => const TermsAndConditionsScreen(),
            '/settings/terms': (_) => const TermsAndConditionsScreen(),
            '/terms': (_) => const TermsAndConditionsScreen(),
            '/refund-cancellation-policy': (_) => const RefundCancellationPolicyScreen(),
            '/settings/refund-policy': (_) => const RefundCancellationPolicyScreen(),
            '/settings/refund-cancellation-policy': (_) => const RefundCancellationPolicyScreen(),
            '/refund-policy': (_) => const RefundCancellationPolicyScreen(),
            '/refunds': (_) => const RefundCancellationPolicyScreen(),
            '/support': (_) => const SupportSettingsScreen(),
            '/contact': (_) => const SupportSettingsScreen(),
            '/settings/support': (_) => const SupportSettingsScreen(),
            '/settings/contact': (_) => const SupportSettingsScreen(),
            '/meta-ai': (_) => const MetaAiChatScreen(),
            '/ai-chat': (_) => const MetaAiChatScreen(),
            '/security-recovery-questions': (_) => const SecurityRecoveryQuestionsScreen(),
            '/security-questions': (_) => const SecurityRecoveryQuestionsScreen(),
            '/security-settings': (_) => const SecuritySettingsScreen(),
            '/autopay-mandates': (_) => const AutopayMandatesScreen(),
            '/digital-identity-kyc': (_) => const DigitalIdentityKycScreen(),
            '/digital-wallet': (_) => const CentralWalletDashboard(),
            '/add-money': (_) => const AddMoneyScreen(),
            '/audit-reporting': (_) => const AuditReportingScreen(),
            '/pricing': (_) => const PricingScreen(),
            '/billing': (_) => const BillingDashboardScreen(),
            '/subscription': (_) => const BillingDashboardScreen(),
            '/whatsapp-chatbot': (_) => const EntitlementGuard(
              featureCode: 'WHATSAPP_CHATBOT',
              child: WhatsAppChatbotView(),
            ),
          },

          onGenerateRoute: (settings) {
            if (settings.name == '/security-recovery-questions' || settings.name == '/security-questions') {
              final args = (settings.arguments as Map<String, dynamic>?) ?? {};
              return MaterialPageRoute(
                builder: (_) => SecurityRecoveryQuestionsScreen(
                  userEmail: args['userEmail'] as String? ?? args['email'] as String?,
                  userPhone: args['userPhone'] as String? ?? args['phone'] as String?,
                ),
              );
            }
            if (settings.name == '/otp-verification') {
              final args = (settings.arguments as Map<String, dynamic>?) ?? {};
              return MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  email: args['email'] as String? ?? '',
                  phone: args['phone'] as String? ?? args['mobile'] as String?,
                  isRegistration: args['isRegistration'] as bool? ?? false,
                  isForgotPassword: args['isForgotPassword'] as bool? ?? false,
                  name: args['name'] as String?,
                  registrationData: args['registrationData'] as Map<String, String>?,
                ),
              );
            }
            if (settings.name == '/security-setup') {
              final user = settings.arguments as UserModel;
              return MaterialPageRoute(
                builder: (_) => SecurityCredentialSetupScreen(user: user),
              );
            }
            if (settings.name == '/reset-password') {
              final args = (settings.arguments as Map<String, dynamic>?) ?? {};
              return MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  email: args['email'] as String? ?? '',
                  otp: args['otp'] as String?,
                  resetToken: args['resetToken'] as String?,
                ),
              );
            }
            if (settings.name == '/add-expense') {
              final initialExpense = settings.arguments is ExpenseItem ? settings.arguments as ExpenseItem : null;
              return MaterialPageRoute(
                builder: (_) => AddExpenseScreen(initialExpense: initialExpense),
              );
            }
            return null;
          },
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      },
    );
  }
}
