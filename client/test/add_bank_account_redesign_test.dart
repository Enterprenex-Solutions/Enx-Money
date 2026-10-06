import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/fund_transfer_screen.dart';
import 'package:enx_money/features/finance_mode/models/account_model.dart';
import 'package:enx_money/core/widgets/inputs/fintech_text_field.dart';

void main() {
  Widget createWidgetUnderTest({List<AccountModel>? initialAccounts, bool isDark = true}) {
    return MaterialApp(
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        splashFactory: NoSplash.splashFactory,
      ),
      home: FundTransferScreen(
        initialAccounts: initialAccounts ?? [],
      ),
    );
  }

  group('Add New Bank Account Modal Redesign Tests', () {
    testWidgets('Popular Indian Banks quick-chips auto-populate Bank Name and IFSC prefix', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open "+ Add Bank Account" modal from zero-state selector
      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      expect(find.text('Add New Bank Account'), findsOneWidget);
      expect(find.text('Select Bank'), findsOneWidget);
      expect(find.text('View All Banks →'), findsOneWidget);

      // Verify popular bank chips are visible
      expect(find.byKey(const Key('popular_bank_chip_sbi')), findsOneWidget);
      expect(find.byKey(const Key('popular_bank_chip_hdfc')), findsOneWidget);
      expect(find.byKey(const Key('popular_bank_chip_icici')), findsOneWidget);
      expect(find.byKey(const Key('popular_bank_chip_axis')), findsOneWidget);

      // Tap on HDFC Bank chip
      await tester.tap(find.byKey(const Key('popular_bank_chip_hdfc')));
      await tester.pumpAndSettle();

      // Verify Bank Name and IFSC Code are auto-populated
      expect(find.widgetWithText(FintechTextField, 'HDFC Bank'), findsOneWidget);
      expect(find.widgetWithText(FintechTextField, 'HDFC0001234'), findsOneWidget);

      // Tap on SBI chip
      await tester.tap(find.byKey(const Key('popular_bank_chip_sbi')));
      await tester.pumpAndSettle();

      // Verify Bank Name updates to SBI and IFSC prefix updates to SBIN
      expect(find.widgetWithText(FintechTextField, 'State Bank of India'), findsOneWidget);
      expect(find.widgetWithText(FintechTextField, 'SBIN0001234'), findsOneWidget);
    });

    testWidgets('View All Banks opens searchable catalog and filters RBI-approved banks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      // Tap "View All Banks →"
      await tester.tap(find.text('View All Banks →'));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Bank'), findsOneWidget);
      expect(find.byKey(const Key('bank_catalog_search_field')), findsOneWidget);
      expect(find.text('All RBI-Approved Banks'), findsOneWidget);

      // Search for Kotak
      await tester.enterText(find.byKey(const Key('bank_catalog_search_field')), 'Kotak');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Kotak Mahindra Bank'), findsOneWidget);

      // Select Kotak from list
      await tester.tap(find.widgetWithText(ListTile, 'Kotak Mahindra Bank'));
      await tester.pumpAndSettle();

      // Modal closed, bank name & IFSC updated in Add Account modal
      expect(find.widgetWithText(FintechTextField, 'Kotak Mahindra Bank'), findsOneWidget);
      expect(find.widgetWithText(FintechTextField, 'KKBK0001234'), findsOneWidget);
    });

    testWidgets('Real-Time Penny Drop verification displays Account Holder Name and emerald badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      // Select HDFC Bank
      await tester.tap(find.byKey(const Key('popular_bank_chip_hdfc')));
      await tester.pumpAndSettle();

      // Enter account number
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '50200012345678');
      await tester.pumpAndSettle();

      // Penny Drop Verify button appears
      expect(find.byKey(const Key('penny_drop_verify_btn')), findsOneWidget);
      expect(find.text('Verify Account (Penny Drop)'), findsOneWidget);

      // Tap "Verify Account (Penny Drop)"
      await tester.tap(find.byKey(const Key('penny_drop_verify_btn')));
      await tester.pumpAndSettle();

      // Verified badge and Account Holder Name appear
      expect(find.byKey(const Key('penny_drop_verified_badge')), findsOneWidget);
      expect(find.text('Verified via Penny Drop (RazorpayX / NPCI)'), findsOneWidget);
      expect(find.text('Account Holder: P. Revanth Reddy'), findsOneWidget);
    });

    testWidgets('SMS OTP Linking Flow: Clicking Save & Link launches 6-digit OTP modal with 30s timer and completes linking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      // Select ICICI Bank
      await tester.tap(find.byKey(const Key('popular_bank_chip_icici')));
      await tester.pumpAndSettle();

      // Enter Account Number
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '100200300400500');
      await tester.pumpAndSettle();

      // Verify with Penny Drop
      await tester.tap(find.byKey(const Key('penny_drop_verify_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Account Holder: P. Revanth Reddy'), findsOneWidget);

      // Click "Save & Link Account"
      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      // 6-digit OTP verification modal appears
      expect(find.text('Bank Security Verification'), findsOneWidget);
      expect(find.text('Enter the 6-digit verification code sent to your bank-registered mobile number'), findsOneWidget);
      expect(find.textContaining('ICICI Bank •••• 0500'), findsOneWidget);
      expect(find.textContaining('Resend OTP in 0:'), findsOneWidget);
      expect(find.text('Confirm & Link'), findsOneWidget);

      // Verify all 6 individual numeric OTP input boxes exist
      for (int i = 0; i < 6; i++) {
        expect(find.byKey(Key('link_otp_box_$i')), findsOneWidget);
      }

      // Enter 6-digit OTP: 123456 (auto-submits on 6th digit)
      final digits = ['1', '2', '3', '4', '5', '6'];
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('link_otp_box_$i')), digits[i]);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Modals closed, new account added to state and auto-selected
      final state = tester.state<FundTransferScreenState>(find.byType(FundTransferScreen));
      expect(state.userAccounts.length, 1);
      expect(state.userAccounts.first.bankName, 'ICICI Bank');
      expect(state.userAccounts.first.accountHolderName, 'P. Revanth Reddy');
      expect(state.fromAccountId, state.userAccounts.first.id);

      // Screen selector displays the new account
      expect(find.text('ICICI Bank •••• 0500'), findsOneWidget);
    });

    testWidgets('Light Mode UI Theme Contrast consistency', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(isDark: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      expect(find.text('Add New Bank Account'), findsOneWidget);
      expect(find.text('Select Bank'), findsOneWidget);
      expect(find.text('Save & Link Account'), findsOneWidget);
    });
  });
}
