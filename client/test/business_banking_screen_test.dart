import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/business_banking_screen.dart';
import 'package:enx_money/features/finance_mode/models/account_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BusinessBankingScreen Dynamic State & Contrast Tests', () {
    testWidgets('Renders zero-state when no accounts are linked (₹0.00 float, empty card, CTA)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const BusinessBankingScreen(initialAccounts: []),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Total Float Header is ₹0.00
      expect(find.text('TOTAL BUSINESS LIQUID FLOAT'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);
      expect(find.text('0 Connected Accounts'), findsOneWidget);

      // 2. Mock accounts should NOT exist
      expect(find.text('HDFC Bank - Primary Current A/C'), findsNothing);
      expect(find.text('ICICI Bank - Working Capital OD'), findsNothing);
      expect(find.text('Axis Bank - Tax & Vendor Escrow'), findsNothing);
      expect(find.text('Business Petty Cash Vault'), findsNothing);
      expect(find.text('₹18,84,120.00'), findsNothing);

      // 3. Zero-state Empty Card & CTA
      expect(find.text('No bank accounts linked yet.'), findsOneWidget);
      expect(find.text('+ Add Business Bank Account'), findsOneWidget);
    });

    testWidgets('Renders dynamic accounts with high-contrast text in Light Mode (#0F172A text)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testAccounts = [
        AccountModel(
          id: 'acc_biz_1',
          accountName: 'State Bank Current A/C',
          bankName: 'SBI',
          accountNumber: '5512',
          balance: 250000.0,
          financeType: FinanceType.business,
        ),
        AccountModel(
          id: 'acc_biz_2',
          accountName: 'Kotak Business OD',
          bankName: 'Kotak',
          accountNumber: '8831',
          balance: 150000.0,
          financeType: FinanceType.business,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const BusinessBankingScreen(initialAccounts: testAccounts),
        ),
      );
      await tester.pumpAndSettle();

      // Float should be 250000 + 150000 = 400000
      expect(find.text('₹4,00,000.00'), findsOneWidget);
      expect(find.text('2 Connected Accounts'), findsOneWidget);

      // Account names should be rendered
      final accountTitleFinder = find.text('State Bank Current A/C');
      expect(accountTitleFinder, findsOneWidget);

      final accountTitleWidget = tester.widget<Text>(accountTitleFinder);
      expect(accountTitleWidget.style?.color, const Color(0xFF0F172A)); // Crisp dark slate in Light Mode

      // Balance amount should be rendered with dark slate color
      final balanceFinder = find.text('₹2,50,000.00');
      expect(balanceFinder, findsOneWidget);
      final balanceWidget = tester.widget<Text>(balanceFinder);
      expect(balanceWidget.style?.color, const Color(0xFF0F172A)); // Crisp dark slate in Light Mode
    });

    testWidgets('Renders dynamic accounts with white text (#FFFFFF) and blue badge accents in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testAccounts = [
        AccountModel(
          id: 'acc_biz_1',
          accountName: 'Canara Enterprise Float',
          bankName: 'Canara Bank',
          accountNumber: '9920',
          balance: 75000.0,
          financeType: FinanceType.business,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const BusinessBankingScreen(initialAccounts: testAccounts),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₹75,000.00'), findsNWidgets(2)); // Header float and account balance
      expect(find.text('1 Connected Account'), findsOneWidget);

      // Account name should be crisp white in Dark Mode
      final titleFinder = find.text('Canara Enterprise Float');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, const Color(0xFFFFFFFF));

      // Balance should be crisp white in Dark Mode
      final balanceFinder = find.text('₹75,000.00').last;
      final balanceWidget = tester.widget<Text>(balanceFinder);
      expect(balanceWidget.style?.color, const Color(0xFFFFFFFF));

      // Vibrant blue badge accent
      expect(find.text('Live API Sync'), findsOneWidget);
    });
  });
}
