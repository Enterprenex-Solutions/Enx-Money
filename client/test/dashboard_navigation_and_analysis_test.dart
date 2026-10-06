import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/shell/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:enx_money/core/localization/app_localizations.dart';
import 'package:enx_money/features/analytics/models/kpi_summary_model.dart';
import 'package:enx_money/features/analytics/presentation/widgets/expense_trend_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Navigation Tests - Cards Removal Verification', () {
    testWidgets('CustomBottomNavBar displays Home, Customers, Suppliers, Reports, Settings and NO Cards', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
          ],
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: selectedIndex,
              onTap: (idx) => selectedIndex = idx,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Cards is completely absent
      expect(find.text('Cards'), findsNothing);
      expect(find.byIcon(Icons.credit_card_outlined), findsNothing);

      // Verify the 5 required navigation items exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Suppliers'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });

  group('Data Analysis Widget Tests', () {
    test('KpiSummary accurately models live dynamic metrics without mock values', () {
      final json = {
        'totalRevenue': 125000.50,
        'totalExpense': 42000.00,
        'netProfit': 83000.50,
        'outstandingReceivables': 15000.00,
        'outstandingPayables': 9000.00,
        'gstPayable': 18500.00,
        'emiDueThisMonth': 0.00,
        'totalSales': 125000.50,
        'totalPurchases': 35000.00,
        'collectionRate': 89.28,
      };

      final kpi = KpiSummary.fromJson(json);

      expect(kpi.totalRevenue, 125000.50);
      expect(kpi.totalExpense, 42000.00);
      expect(kpi.netProfit, 83000.50);
      expect(kpi.outstandingReceivables, 15000.00);
      expect(kpi.outstandingPayables, 9000.00);
      expect(kpi.totalSales, 125000.50);
      expect(kpi.totalPurchases, 35000.00);
      expect(kpi.collectionRate, 89.28);
    });

    testWidgets('ExpenseTrendChart renders properly with dynamic trend data', (tester) async {
      final trends = [
        {'month': 'Mar', 'expense': 15000.0},
        {'month': 'Apr', 'expense': 22000.0},
        {'month': 'May', 'expense': 18000.0},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpenseTrendChart(monthlyData: trends),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EXPENSE TREND'), findsOneWidget);
      expect(find.text('Monthly Expense Outflow'), findsOneWidget);
      expect(find.text('SALES VS PURCHASE'), findsNothing);
      expect(find.text('Sales vs Purchase'), findsNothing);
    });
  });
}
