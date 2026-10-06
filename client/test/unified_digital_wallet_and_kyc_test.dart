import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/profile/presentation/screens/digital_identity_kyc_screen.dart';
import 'package:enx_money/features/wallet/presentation/screens/central_wallet_dashboard.dart';
import 'package:enx_money/features/wallet/presentation/screens/add_money_screen.dart';
import 'package:enx_money/features/wallet/presentation/screens/settlement_pipeline_screen.dart';
import 'package:enx_money/features/analytics/presentation/screens/audit_reporting_screen.dart';
import 'package:enx_money/core/widgets/modals/transaction_auth_modal.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
    home: child,
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Module 1: DigitalIdentityKycScreen displays tier badges and identity verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp(const DigitalIdentityKycScreen()));
    await tester.pumpAndSettle();

    // Verify KYC header & identity card
    expect(find.text('Digital Identity & KYC'), findsOneWidget);
    expect(find.text('ENX DIGITAL IDENTITY'), findsOneWidget);
    expect(find.text('Aadhaar e-KYC (UIDAI)'), findsOneWidget);
    expect(find.text('PAN Card Verification (NSDL)'), findsOneWidget);
    expect(find.text('Fast-Track with DigiLocker'), findsOneWidget);
    expect(find.text('Biometric & Hardware Keystore Binding'), findsOneWidget);
  });

  testWidgets('Module 2 & 3: CentralWalletDashboard displays consolidated balance and 7-in-1 action grid', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp(const CentralWalletDashboard()));
    await tester.pumpAndSettle();

    // Verify Header & Consolidated balance
    expect(find.text('Digital Wallet & Assets'), findsOneWidget);
    expect(find.text('CONSOLIDATED LIQUID BALANCE'), findsOneWidget);
    expect(find.byKey(const Key('wallet_add_money_btn')), findsOneWidget);
    expect(find.byKey(const Key('wallet_convert_btn')), findsOneWidget);

    // Verify 7-in-1 Action Grid labels
    expect(find.text('Pay'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Invest'), findsOneWidget);
    expect(find.text('Borrow'), findsOneWidget);
    expect(find.text('Convert'), findsNWidgets(2));

    // Verify Multi-Asset Breakdown items
    expect(find.text('Fiat Primary Account (INR)'), findsOneWidget);
    expect(find.text('Digital Rupee (RBI CBDC)'), findsOneWidget);
    expect(find.text('24K Pure Digital Gold'), findsOneWidget);
    expect(find.text('Regulated Stablecoins (USDC)'), findsOneWidget);
  });

  testWidgets('Module 2: AddMoneyScreen allows method selection and deposit processing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp(const AddMoneyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Add Money to Wallet'), findsOneWidget);
    expect(find.text('Deposit Fiat (₹ INR)'), findsOneWidget);
    expect(find.text('Deposit CBDC (e₹ Digital)'), findsOneWidget);

    // Tap quick chip +₹10000
    await tester.tap(find.text('+₹10000'));
    await tester.pumpAndSettle();

    // Check deposit onramp methods
    expect(find.text('Linked Bank Account'), findsOneWidget);
    expect(find.text('Salary Direct Deposit'), findsOneWidget);
    expect(find.text('Cash Deposit (Store / CDM)'), findsOneWidget);
    expect(find.text('Debit / Credit Card'), findsOneWidget);
    expect(find.text('Govt DBT & Business Payout'), findsOneWidget);

    // Select Salary Direct Deposit
    await tester.tap(find.text('Salary Direct Deposit'));
    await tester.pumpAndSettle();

    // Tap Deposit button
    await tester.tap(find.byKey(const Key('proceed_deposit_btn')));
    await tester.pumpAndSettle();

    // Verify Deposit Success Bottom Sheet appears
    expect(find.text('Deposit Successful!'), findsOneWidget);
    expect(find.text('INSTANTLY SETTLED'), findsOneWidget);
  });

  testWidgets('Module 4: TransactionAuthModal performs risk scan and accepts 4-digit MPIN', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool authenticatedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              key: const Key('open_auth_modal_btn'),
              onPressed: () {
                TransactionAuthModal.show(
                  ctx,
                  amount: 2500.0,
                  recipient: 'Sunita Mehra',
                  assetType: 'INR',
                  onAuthenticated: (method, pin) async {
                    authenticatedCalled = true;
                  },
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_auth_modal_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // risk scan delay

    expect(find.text('Authorize Transaction'), findsOneWidget);
    expect(find.text('Transferring to Sunita Mehra'), findsOneWidget);
    expect(find.text('₹2500.00'), findsOneWidget);
    expect(find.text('Risk Assessment: Low Risk (Trust Score: 98/100)'), findsOneWidget);

    // Tap keys 1, 2, 3, 4
    await tester.tap(find.byKey(const Key('auth_key_1')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('auth_key_2')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('auth_key_3')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('auth_key_4')));
    await tester.pumpAndSettle();

    expect(authenticatedCalled, isTrue);
  });

  testWidgets('Module 5: SettlementPipelineScreen runs 5-step pipeline and displays receipt', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockData = {
      'amount': 3200.00,
      'assetType': 'INR',
      'recipientName': 'Vikram Enterprises',
      'utr': 'ENX789012345',
      'receipt': {
        'utr': 'ENX789012345',
        'fee': 0.00,
      },
    };

    await tester.pumpWidget(createTestApp(SettlementPipelineScreen(settlementData: mockData)));

    // Let pipeline finish all steps
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Transfer Completed!'), findsOneWidget);
    expect(find.text('₹3200.0 sent to Vikram Enterprises'), findsOneWidget);

    // Tap view receipt
    expect(find.byKey(const Key('view_digital_receipt_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('view_digital_receipt_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Official Digital Receipt'), findsOneWidget);
    expect(find.text('PAID & SETTLED'), findsOneWidget);
    expect(find.text('ENX789012345'), findsOneWidget);
    expect(find.byKey(const Key('download_pdf_receipt_btn')), findsOneWidget);
  });

  testWidgets('Module 6: AuditReportingScreen displays tax summary and filters', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp(const AuditReportingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Audit & Tax Reporting'), findsOneWidget);
    expect(find.text('TAX RECORDS & GST SUMMARY'), findsOneWidget);
    expect(find.text('Total Volume'), findsOneWidget);
    expect(find.text('GST Liability'), findsOneWidget);
    expect(find.text('TDS Withheld'), findsOneWidget);

    // Test asset chip filter
    expect(find.text('CBDC'), findsOneWidget);
    await tester.tap(find.text('CBDC'));
    await tester.pumpAndSettle();

    // Test CSV export button
    expect(find.byKey(const Key('export_csv_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('export_csv_btn')));
    await tester.pumpAndSettle();
  });
}
