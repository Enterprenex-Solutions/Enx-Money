import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/personal_dashboard_screen.dart';
import 'package:enx_money/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Business Financial Overview Dashboard displays high-contrast metrics and business rebranding', (WidgetTester tester) async {
    // Set a large display size to avoid overflow during tests
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', 'US'),
        ],
        home: PersonalDashboardScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header Verification
    expect(find.text('Business Financial Overview'), findsOneWidget);
    expect(find.text('FINANCE MODE: BUSINESS'), findsOneWidget);

    // 2. Top KPI Cards Verification
    expect(find.text('Monthly Revenue Credited'), findsWidgets);
    expect(find.text('Operating Margin'), findsOneWidget);
    expect(find.text('65.8%'), findsOneWidget);
    expect(find.text('65.8% Gross Margin'), findsOneWidget);

    // 3. Operating Cash Velocity
    expect(find.text('Operating Cash Velocity'), findsOneWidget);

    // 4. Quick Business Actions Section
    expect(find.text('Quick Business Actions'), findsOneWidget);
    expect(find.text('Add Invoice / Expense'), findsOneWidget);
    expect(find.text('Manage Vendor Accounts'), findsOneWidget);
    expect(find.text('Business Cash Flow'), findsOneWidget);
    expect(find.text('Wire / Fund Transfer'), findsOneWidget);
    expect(find.text('Operating Budget'), findsOneWidget);
    expect(find.text('Consolidated P&L'), findsOneWidget);

    // 5. Scheduled Payments Card (Business Payables)
    expect(find.text('Scheduled Business Payables'), findsOneWidget);
    expect(find.text('Vendor Payout - Due in 4 days'), findsOneWidget);
    expect(find.text('Office Lease - Due on 5th'), findsOneWidget);
    expect(find.text('Payroll - Due on 12th'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Auto-Debit'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);

    // 6. Targets / Goals Section (Business Goals)
    expect(find.text('Business Targets & Milestones'), findsOneWidget);
    expect(find.text('Q3 Revenue Target: ₹5.00 L'), findsOneWidget);
    expect(find.text('Client Receivable Target: ₹2.50 L'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('48%'), findsOneWidget);
  });
}
