import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/fund_transfer_screen.dart';
import 'package:enx_money/features/finance_mode/models/account_model.dart';
import 'package:enx_money/core/widgets/buttons/primary_button.dart';
import 'package:enx_money/core/widgets/inputs/fintech_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidgetUnderTest({List<AccountModel>? initialAccounts}) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: FundTransferScreen(initialAccounts: initialAccounts),
    );
  }

  group('FundTransferScreen Bank Selection & Add Account Tests', () {
    testWidgets('Initial state displays clean blank inputs and correct placeholders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(
        initialAccounts: [
          const AccountModel(
            id: 'acc_01',
            title: 'HDFC Business',
            bankName: 'HDFC Bank',
            accountNumberLast4: '1234',
            balance: 50000.0,
            financeType: FinanceType.business,
            ifsc: 'HDFC0001234',
          ),
          const AccountModel(
            id: 'acc_02',
            title: 'SBI Personal',
            bankName: 'SBI',
            accountNumberLast4: '5678',
            balance: 10000.0,
            financeType: FinanceType.personal,
            ifsc: 'SBIN0005678',
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Transfer Funds / Drawings'), findsOneWidget);

      // Verify Clean Placeholders
      expect(find.text('Enter Amount'), findsOneWidget);
      expect(find.text('Enter Remarks / Purpose'), findsOneWidget);

      // Verify that the Amount and Remarks text fields start completely blank
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      for (final tf in textFields) {
        expect(tf.controller?.text, isEmpty);
      }

      // Verify "Execute Fund Transfer" button is disabled initially because amount is blank (0)
      final primaryButton = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(primaryButton.onPressed, isNull);
    });

    testWidgets('Validation: Disables Execute button when amount is 0 or source == dest, enables when valid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(
        initialAccounts: [
          const AccountModel(
            id: 'acc_01',
            title: 'HDFC Business',
            bankName: 'HDFC Bank',
            accountNumberLast4: '1234',
            balance: 50000.0,
            financeType: FinanceType.business,
            ifsc: 'HDFC0001234',
          ),
          const AccountModel(
            id: 'acc_02',
            title: 'SBI Personal',
            bankName: 'SBI',
            accountNumberLast4: '5678',
            balance: 10000.0,
            financeType: FinanceType.personal,
            ifsc: 'SBIN0005678',
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Button still disabled because amount is empty
      var btn = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(btn.onPressed, isNull);

      // Enter a valid amount
      await tester.enterText(find.widgetWithText(FintechTextField, 'Transfer Amount (₹)'), '1500');
      await tester.pumpAndSettle();

      // Now button is enabled!
      btn = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(btn.onPressed, isNotNull);

      // Make source == destination
      final state = tester.state<FundTransferScreenState>(find.byType(FundTransferScreen));
      state.setDestinationAccount('acc_01');
      await tester.pumpAndSettle();

      // Error banner shows and button becomes disabled
      expect(find.text('Source and destination accounts must be different'), findsOneWidget);
      btn = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('Zero-State: Displays "No Accounts Linked — Tap to Add" when accounts list is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialAccounts: []));
      await tester.pumpAndSettle();

      // Both selectors show the zero-state label
      expect(find.text('No Accounts Linked — Tap to Add'), findsNWidgets(2));

      // Tapping opens the "+ Add Bank Account" modal
      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      expect(find.text('Add New Bank Account'), findsOneWidget);
      expect(find.text('Bank Name'), findsOneWidget);
      expect(find.text('Account Number'), findsOneWidget);
      expect(find.text('IFSC Code'), findsOneWidget);
      expect(find.text('Account Type'), findsOneWidget);
      expect(find.text('Save & Link Account'), findsOneWidget);
    });

    testWidgets('Modal Account Selection and in-modal "+ Add Bank Account" CTA flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(
        initialAccounts: [
          const AccountModel(
            id: 'acc_h1',
            title: 'HDFC Current',
            bankName: 'HDFC Bank',
            accountNumberLast4: '4321',
            balance: 75000.0,
            financeType: FinanceType.business,
            ifsc: 'HDFC0009999',
          ),
          const AccountModel(
            id: 'acc_i1',
            title: 'ICICI Savings',
            bankName: 'ICICI Bank',
            accountNumberLast4: '8765',
            balance: 25000.0,
            financeType: FinanceType.personal,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Tap on Transfer From selector using its unique Key
      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Select Source Account (Debit)'), findsOneWidget);
      expect(find.text('HDFC Current'), findsOneWidget);
      expect(find.text('ICICI Savings'), findsOneWidget);
      expect(find.text('+ Add Bank Account'), findsOneWidget);

      // Tap "+ Add Bank Account" CTA in modal
      await tester.tap(find.text('+ Add Bank Account'));
      await tester.pumpAndSettle();

      // Add New Bank Account modal is opened seamlessly
      expect(find.text('Add New Bank Account'), findsOneWidget);
      expect(find.text('Save & Link Account'), findsOneWidget);
    });

    testWidgets('Submitting a new bank account in modal updates state and auto-selects', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialAccounts: []));
      await tester.pumpAndSettle();

      // Tap on first account selector (Source)
      await tester.tap(find.byKey(const Key('source_account_selector')));
      await tester.pumpAndSettle();

      // Fill in Bank Name & Account Number
      await tester.enterText(find.widgetWithText(FintechTextField, 'Bank Name'), 'Axis Bank');
      await tester.enterText(find.widgetWithText(FintechTextField, 'Account Number'), '919010012345678');
      await tester.enterText(find.widgetWithText(FintechTextField, 'IFSC Code'), 'UTIB0001234');
      await tester.pumpAndSettle();

      // Tap "Save & Link Account" to launch 6-digit OTP verification modal
      await tester.tap(find.text('Save & Link Account'));
      await tester.pumpAndSettle();

      // Verify OTP modal appears and enter 6-digit OTP (123456)
      expect(find.text('Bank Security Verification'), findsOneWidget);
      final digits = ['1', '2', '3', '4', '5', '6'];
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('link_otp_box_$i')), digits[i]);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Explicitly tap "Verify & Authorize Link" (automatic submit on typing disabled)
      await tester.tap(find.widgetWithText(PrimaryButton, 'Verify & Authorize Link'));
      await tester.pumpAndSettle();

      // Verify the new account is immediately appended and selected for Source!
      final state = tester.state<FundTransferScreenState>(find.byType(FundTransferScreen));
      expect(state.userAccounts.length, 1);
      expect(state.userAccounts.first.bankName, 'Axis Bank');
      expect(state.fromAccountId, state.userAccounts.first.id);

      // Verify on-screen selector now displays Axis Bank •••• 5678
      expect(find.text('Axis Bank •••• 5678'), findsOneWidget);
    });
  });
}
