import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/models/account_model.dart';
import 'package:enx_money/features/finance_mode/models/mandate_model.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/upi_bank_linking_screen.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/autopay_mandates_screen.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/fund_transfer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: child,
    );
  }

  group('UPI Bank Linking Flow Tests', () {
    testWidgets('Bank selection screen displays search bar, popular banks grid, and all banks list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const UpiBankLinkingScreen()));
      await tester.pumpAndSettle();

      // Screen title and header
      expect(find.text('Link Bank via UPI'), findsOneWidget);
      expect(find.text('Linked Mobile Number'), findsOneWidget);

      // Search bar
      expect(find.byKey(const Key('bank_search_field')), findsOneWidget);
      expect(find.text('Search your bank name (e.g. HDFC, SBI, ICICI)...'), findsOneWidget);

      // Popular Banks section
      expect(find.text('Popular Banks'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsWidgets);
      expect(find.text('State Bank of India'), findsWidgets);
      expect(find.text('ICICI Bank'), findsWidgets);
      expect(find.text('Axis Bank'), findsWidgets);

      // All Banks section
      expect(find.text('All Banks'), findsOneWidget);
    });

    testWidgets('Search query filters banks dynamically', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const UpiBankLinkingScreen()));
      await tester.pumpAndSettle();

      // Search for 'Kotak'
      await tester.enterText(find.byKey(const Key('bank_search_field')), 'Kotak');
      await tester.pumpAndSettle();

      expect(find.text('Kotak Mahindra Bank'), findsWidgets);
      expect(find.text('Canara Bank'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Canara Bank'), findsWidgets);
    });

    testWidgets('Selecting a bank initiates SIM verification sheet and advances to 2FA OTP modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const UpiBankLinkingScreen()));
      await tester.pumpAndSettle();

      // Tap on HDFC Bank popular tile
      await tester.tap(find.byKey(const Key('popular_bank_hdfc')).first);
      await tester.pump();

      // SIM verification sheet opens
      expect(find.text('Verifying SIM & Linkable Accounts'), findsOneWidget);

      // Fast-forward SIM verification
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // 2FA OTP Modal is now presented
      expect(find.text('Bank Security Verification'), findsOneWidget);
      expect(find.textContaining('Resend OTP in'), findsOneWidget);

      // Verify all 6 individual numeric OTP input boxes exist
      for (int i = 0; i < 6; i++) {
        expect(find.byKey(Key('otp_box_$i')), findsOneWidget);
      }
    });

    testWidgets('Invalid OTP displays error message with red border, valid OTP advances to Account Found modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const UpiBankLinkingScreen()));
      await tester.pumpAndSettle();

      // Tap HDFC Bank
      await tester.tap(find.byKey(const Key('popular_bank_hdfc')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Enter invalid OTP '000000'
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_box_$i')), '0');
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Verify explicit error state is displayed
      expect(find.text('Invalid OTP code. Please enter 123456 to verify.'), findsOneWidget);

      // Now enter valid OTP '123456'
      final validDigits = ['1', '2', '3', '4', '5', '6'];
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_box_$i')), validDigits[i]);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Account Found Card is displayed
      expect(find.text('Account Found!'), findsOneWidget);
      expect(find.text('ACTIVE UPI'), findsOneWidget);
      expect(find.text('Confirm & Set Default Account'), findsOneWidget);
      expect(find.text('Set 4/6-Digit UPI PIN (Debit Card Required)'), findsOneWidget);
    });

    testWidgets('UPI PIN modal accepts debit card details and 4/6 digit PIN', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const UpiBankLinkingScreen()));
      await tester.pumpAndSettle();

      // Tap ICICI Bank
      await tester.tap(find.byKey(const Key('popular_bank_icici')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Enter valid OTP
      final validDigits = ['1', '2', '3', '4', '5', '6'];
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_box_$i')), validDigits[i]);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Tap "Set 4/6-Digit UPI PIN"
      await tester.tap(find.text('Set 4/6-Digit UPI PIN (Debit Card Required)'));
      await tester.pumpAndSettle();

      // Verify debit card and PIN form
      expect(find.text('Set UPI PIN for ICICI Bank'), findsOneWidget);
      expect(find.text('Last 6 Digits of Debit Card'), findsOneWidget);
      expect(find.text('Valid Thru (MM)'), findsOneWidget);
      expect(find.text('Valid Thru (YY)'), findsOneWidget);
      expect(find.text('Set New 4 or 6-Digit UPI PIN'), findsOneWidget);
      expect(find.text('Confirm UPI PIN'), findsOneWidget);
    });
  });

  group('UPI AutoPay Mandates Flow Tests', () {
    testWidgets('AutopayMandatesScreen displays active mandates and status tags', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testMandates = [
        MandateModel(
          id: 'man_01',
          name: 'Netflix & Media Subscription',
          frequency: 'Monthly',
          maxLimit: 1499.0,
          startDate: '2026-09-01',
          endDate: '2027-09-01',
          isUntilCancelled: true,
          status: 'ACTIVE',
          sourceAccountId: 'acc_01',
          sourceBankName: 'HDFC Bank',
          vpa: 'user@okhdfcbank',
          createdAt: DateTime.now().toIso8601String(),
        ),
        MandateModel(
          id: 'man_02',
          name: 'SIP Mutual Fund Investment',
          frequency: 'Monthly',
          maxLimit: 5000.0,
          startDate: '2026-09-01',
          endDate: '2028-09-01',
          isUntilCancelled: false,
          status: 'PAUSED',
          sourceAccountId: 'acc_02',
          sourceBankName: 'SBI',
          vpa: 'user@oksbi',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      await tester.pumpWidget(wrapWithTheme(AutopayMandatesScreen(initialMandates: testMandates)));
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Active AutoPay & Mandates'), findsOneWidget);

      // Verify Mandates & Status Badges
      expect(find.text('Netflix & Media Subscription'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      expect(find.text('SIP Mutual Fund Investment'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('Tapping Pause toggles mandate to PAUSED, Resume toggles back to ACTIVE', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testMandates = [
        MandateModel(
          id: 'man_01',
          name: 'AWS Cloud Hosting',
          frequency: 'Monthly',
          maxLimit: 8500.0,
          startDate: '2026-09-01',
          endDate: '2027-09-01',
          isUntilCancelled: true,
          status: 'ACTIVE',
          sourceAccountId: 'acc_01',
          sourceBankName: 'HDFC Bank',
          vpa: 'company@okhdfcbank',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      await tester.pumpWidget(wrapWithTheme(AutopayMandatesScreen(initialMandates: testMandates)));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      // Tap Pause
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets('Setup New AutoPay modal opens with form inputs and Until Cancelled toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const AutopayMandatesScreen(initialMandates: [])));
      await tester.pumpAndSettle();

      // Zero-state displayed
      expect(find.text('No Active AutoPay Mandates'), findsOneWidget);

      // Tap "+ Setup AutoPay"
      await tester.tap(find.byKey(const Key('setup_autopay_fab')));
      await tester.pumpAndSettle();

      // Verify form fields in modal
      expect(find.text('Setup UPI AutoPay Mandate'), findsOneWidget);
      expect(find.text('Mandate Name / Purpose'), findsOneWidget);
      expect(find.text('AutoPay Frequency'), findsOneWidget);
      expect(find.text('Maximum AutoDebit Limit (₹)'), findsOneWidget);
      expect(find.text('Until Cancelled'), findsOneWidget);

      // Verify frequencies
      expect(find.text('Monthly'), findsWidgets);
      expect(find.text('Weekly'), findsWidgets);
      expect(find.text('Quarterly'), findsWidgets);
      expect(find.text('As Presented'), findsWidgets);
    });
  });

  group('FundTransferScreen UPI & Mandates Integration Tests', () {
    testWidgets('Displays ACTIVE UPI badge and UPI ID when source account is UPI-linked', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final upiAccount = const AccountModel(
        id: 'acc_upi_01',
        title: 'HDFC Current',
        bankName: 'HDFC Bank',
        accountNumberLast4: '9876',
        balance: 75000.0,
        financeType: FinanceType.business,
        ifsc: 'HDFC0009876',
        vpa: 'business@okhdfcbank',
        isUpiLinked: true,
      );

      final normalAccount = const AccountModel(
        id: 'acc_02',
        title: 'SBI Savings',
        bankName: 'SBI',
        accountNumberLast4: '4321',
        balance: 25000.0,
        financeType: FinanceType.personal,
        ifsc: 'SBIN0004321',
        isUpiLinked: false,
      );

      await tester.pumpWidget(wrapWithTheme(FundTransferScreen(initialAccounts: [upiAccount, normalAccount])));
      await tester.pumpAndSettle();

      // Verify ACTIVE UPI badge is displayed for the source account
      expect(find.text('ACTIVE UPI'), findsOneWidget);
      expect(find.text('UPI ID: business@okhdfcbank'), findsOneWidget);

      // Verify Fast Toggle: Pay via Instant UPI / AutoPay
      expect(find.text('Pay via Instant UPI / AutoPay'), findsOneWidget);
      expect(find.text('Instant NPCI 24x7 settlements & recurring mandates'), findsOneWidget);

      // Verify Manage Active AutoPay & Mandates quick CTA link
      expect(find.byKey(const Key('manage_autopay_mandates_link')), findsOneWidget);

      // Verify AppBar button for AutoPay
      expect(find.byKey(const Key('appbar_autopay_mandates_button')), findsOneWidget);
    });

    testWidgets('Bank selection modal contains + Add Bank Account via Phone Number / UPI CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final upiAccount = const AccountModel(
        id: 'acc_upi_01',
        title: 'HDFC Current',
        bankName: 'HDFC Bank',
        accountNumberLast4: '9876',
        balance: 75000.0,
        financeType: FinanceType.business,
        ifsc: 'HDFC0009876',
        vpa: 'business@okhdfcbank',
        isUpiLinked: true,
      );

      await tester.pumpWidget(wrapWithTheme(FundTransferScreen(initialAccounts: [upiAccount])));
      await tester.pumpAndSettle();

      // Tap on the source account selector
      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      // Verify "+ Add Bank Account via Phone Number / UPI" is displayed
      expect(find.byKey(const Key('add_bank_via_upi_button')), findsOneWidget);
      expect(find.text('+ Add Bank Account via Phone Number / UPI'), findsOneWidget);
      expect(find.text('Auto-discover linked accounts using phone number'), findsOneWidget);
    });
  });
}
