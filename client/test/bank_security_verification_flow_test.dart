import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/fund_transfer_screen.dart';
import 'package:enx_money/core/widgets/inputs/fintech_text_field.dart';
import 'package:enx_money/core/widgets/buttons/primary_button.dart';

void main() {
  Widget createWidgetUnderTest({bool isDark = true, String? userPhoneNumber}) {
    return MaterialApp(
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        splashFactory: NoSplash.splashFactory,
      ),
      home: FundTransferScreen(initialAccounts: const [], userPhoneNumber: userPhoneNumber),
    );
  }

  group('Bank Security Verification Modal Flow & Theme Contrast Tests', () {
    testWidgets('UI Polish: 6 PIN entry boxes render with high-contrast slate background in Dark and Light mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Dark Mode Test
      await tester.pumpWidget(createWidgetUnderTest(isDark: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(FintechTextField, 'Bank Name'), 'State Bank of India');
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '123456789012');
      await tester.enterText(find.widgetWithText(FintechTextField, 'IFSC Code'), 'SBIN0001234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      // Verify modal is open
      expect(find.text('Bank Security Verification'), findsOneWidget);

      // Verify 6 PIN boxes exist
      for (int i = 0; i < 6; i++) {
        final boxFinder = find.byKey(Key('link_otp_box_$i'));
        expect(boxFinder, findsOneWidget);

        // Check parent container background is #1E293B in Dark Mode
        final containerFinder = find.ancestor(
          of: boxFinder,
          matching: find.byType(Container),
        ).first;
        final containerWidget = tester.widget<Container>(containerFinder);
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFF1E293B));
      }

      // Verify "Verify & Authorize Link" button is DISABLED when 0 digits entered
      final verifyBtn = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Verify & Authorize Link'),
      );
      expect(verifyBtn.onPressed, isNull);

      // Verify 60-second countdown timer is active
      expect(find.textContaining('Resend OTP in 0:'), findsOneWidget);
    });

    testWidgets('Light Mode UI Polish: PIN boxes render with #F1F5F9 slate background', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Light Mode Test
      await tester.pumpWidget(createWidgetUnderTest(isDark: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(FintechTextField, 'Bank Name'), 'HDFC Bank');
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '50200012345678');
      await tester.enterText(find.widgetWithText(FintechTextField, 'IFSC Code'), 'HDFC0001234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      expect(find.text('Bank Security Verification'), findsOneWidget);

      for (int i = 0; i < 6; i++) {
        final boxFinder = find.byKey(Key('link_otp_box_$i'));
        final containerFinder = find.ancestor(
          of: boxFinder,
          matching: find.byType(Container),
        ).first;
        final containerWidget = tester.widget<Container>(containerFinder);
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFFF1F5F9));
      }
    });

    testWidgets('Button remains disabled until full 6 digits entered, invalid OTP keeps modal open and shows red error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(isDark: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(FintechTextField, 'Bank Name'), 'ICICI Bank');
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '001122334455');
      await tester.enterText(find.widgetWithText(FintechTextField, 'IFSC Code'), 'ICIC0001234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      // Enter 4 digits (partial OTP)
      for (int i = 0; i < 4; i++) {
        await tester.enterText(find.byKey(Key('link_otp_box_$i')), '9');
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      // Verify button is STILL DISABLED
      var verifyBtn = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Verify & Authorize Link'),
      );
      expect(verifyBtn.onPressed, isNull);

        // Now enter the remaining 2 digits with invalid OTP '999999'
      await tester.enterText(find.byKey(const Key('link_otp_box_4')), '9');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(find.byKey(const Key('link_otp_box_5')), '9');
      await tester.pumpAndSettle();

      // Typing does NOT auto-submit; button is now enabled
      verifyBtn = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Verify & Authorize Link'),
      );
      expect(verifyBtn.onPressed, isNotNull);

      // Explicitly tap "Verify & Authorize Link"
      await tester.tap(find.widgetWithText(PrimaryButton, 'Verify & Authorize Link'));
      await tester.pumpAndSettle();

      // Verification fails: Modal MUST remain open and display exact error message
      expect(find.text('Bank Security Verification'), findsOneWidget);
      expect(find.text('Invalid OTP entered. Please try again.'), findsOneWidget);

      // Verify PIN boxes are highlighted with red border (#EF4444)
      final box0Finder = find.byKey(const Key('link_otp_box_0'));
      final container0 = tester.widget<Container>(
        find.ancestor(of: box0Finder, matching: find.byType(Container)).first,
      );
      final border = (container0.decoration as BoxDecoration).border as Border;
      expect(border.top.color, const Color(0xFFEF4444));
    });

    testWidgets('Valid 6-digit OTP closes modal, shows success toast, and appends newly linked account to dropdown state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(isDark: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(FintechTextField, 'Bank Name'), 'Axis Bank');
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '919010012345678');
      await tester.enterText(find.widgetWithText(FintechTextField, 'IFSC Code'), 'UTIB0001234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      // Enter valid 6-digit OTP (123456)
      final digits = ['1', '2', '3', '4', '5', '6'];
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('link_otp_box_$i')), digits[i]);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      // User must tap "Verify & Authorize Link" CTA explicitly (no auto-submit)
      await tester.tap(find.widgetWithText(PrimaryButton, 'Verify & Authorize Link'));
      await tester.pumpAndSettle();

      // Modal is now CLOSED
      expect(find.text('Bank Security Verification'), findsNothing);

      // Account is added directly to dropdown state and selected!
      final state = tester.state<FundTransferScreenState>(find.byType(FundTransferScreen));
      expect(state.userAccounts.length, 1);
      expect(state.userAccounts.first.bankName, 'Axis Bank');
      expect(state.fromAccountId, state.userAccounts.first.id);

      // Dropdown UI displays linked account name and last 4 digits
      expect(find.text('Axis Bank •••• 5678'), findsOneWidget);
    });

    test('formatMaskedPhone correctly formats mobile numbers with country code and masked central digits', () {
      expect(FundTransferScreenState.formatMaskedPhone('+919876543210'), '+91 98****3210');
      expect(FundTransferScreenState.formatMaskedPhone('9876543210'), '+91 98****3210');
      expect(FundTransferScreenState.formatMaskedPhone('+919123456789'), '+91 91****6789');
      expect(FundTransferScreenState.formatMaskedPhone('9123456789'), '+91 91****6789');
      expect(FundTransferScreenState.formatMaskedPhone(null), '+91 98****3210');
    });

    testWidgets('Dynamic mobile number and Sandbox testing banner are displayed in test mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(userPhoneNumber: '9123456789'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(FintechTextField, 'Bank Name'), 'Kotak Mahindra Bank');
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '998877665544');
      await tester.enterText(find.widgetWithText(FintechTextField, 'IFSC Code'), 'KKBK0001234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      // Dynamic phone with masked central digits is shown
      expect(find.textContaining('+91 91****6789'), findsOneWidget);

      // Testing mode banner is explicitly displayed
      expect(find.byKey(const Key('setu_sandbox_banner')), findsOneWidget);
      expect(find.text('Testing Sandbox Mode: Live SMS disabled. Use test PIN 123456 to verify.'), findsOneWidget);
    });
  });
}
