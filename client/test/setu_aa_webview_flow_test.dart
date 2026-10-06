import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/presentation/widgets/setu_aa_webview_dialog.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/fund_transfer_screen.dart';
import 'package:enx_money/features/finance_mode/models/account_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockAccounts = [
    AccountModel(
      id: 'acc_01',
      title: 'HDFC Current Account',
      bankName: 'HDFC Bank',
      accountNumberLast4: '5892',
      balance: 125000.0,
      financeType: FinanceType.business,
      ifsc: 'HDFC0000456',
      isUpiLinked: true,
      hasUpiPin: true,
      vpa: 'business@hdfc',
    ),
  ];

  testWidgets('SetuAaWebviewDialog renders header branding, RBI badge and close button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SetuAaWebviewDialog(
            redirectUrl: 'http://localhost:5000/api/v1/bank/setu-webview',
          ),
        ),
      ),
    );

    // Verify Setu AA Gateway header text
    expect(find.text('Setu AA Gateway'), findsOneWidget);
    expect(find.text('RBI Regulated'), findsOneWidget);
    expect(find.text('Automated Pre-built Webview SDK'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('FundTransferScreen account selection displays Link Bank Account button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: FundTransferScreen(
          initialAccounts: mockAccounts,
          userPhoneNumber: '9876543210',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on source account selector to open modal
    final selectorFinder = find.byKey(const Key('source_account_selector'));
    expect(selectorFinder, findsOneWidget);
    await tester.tap(selectorFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify "Link Bank Account" with Setu AA tag is present in the modal
    expect(find.byKey(const Key('link_bank_account_button')), findsOneWidget);
    expect(find.text('Link Bank Account'), findsOneWidget);
    expect(find.text('⚡ SETU AA'), findsOneWidget);
  });

  testWidgets('Instant UPI Toggle Switch is fully bounded without overflow on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
        ),
        home: FundTransferScreen(
          initialAccounts: mockAccounts,
          userPhoneNumber: '9876543210',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pay via Instant UPI / AutoPay'), findsOneWidget);
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    final switchRect = tester.getRect(switchFinder);
    expect(switchRect.right, lessThanOrEqualTo(360.0));
  });
}
