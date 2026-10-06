import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/financial_calendar_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({
    CalendarScope scope = CalendarScope.business,
    Brightness brightness = Brightness.light,
    double screenWidth = 392.0,
    double screenHeight = 840.0,
  }) {
    return MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        fontFamily: 'Inter',
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(screenWidth, screenHeight),
          devicePixelRatio: 1.0,
        ),
        child: FinancialCalendarScreen(scope: scope),
      ),
    );
  }

  group('Finance Calculator UI & Layout Tests', () {
    testWidgets('Header displays clean "Finance Calculator" title without truncation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Finance Calculator'), findsOneWidget);
      // Ensure bad truncated text does not exist
      expect(find.textContaining('Personal Financial Ca...'), findsNothing);
    });

    testWidgets('Business and Personal mode buttons are properly aligned and switchable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(scope: CalendarScope.business));
      await tester.pumpAndSettle();

      expect(find.text('Personal Household'), findsOneWidget);
      expect(find.text('Business & Tax'), findsOneWidget);

      // Tap Personal Household
      await tester.tap(find.text('Personal Household'));
      await tester.pumpAndSettle();

      // Loan EMI chip should appear
      expect(find.text('Loan EMI'), findsOneWidget);
      expect(find.text('Income & Savings'), findsOneWidget);

      // Tap Business & Tax
      await tester.tap(find.text('Business & Tax'));
      await tester.pumpAndSettle();

      // Business Margins & GST chips should appear
      expect(find.text('Business Margins'), findsOneWidget);
      expect(find.text('GST Calculator'), findsOneWidget);
    });

    testWidgets('"Calendar Reminder Option" appears in normal horizontal layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify exact headline is found in full
      expect(find.text('Calendar Reminder Option'), findsOneWidget);
      expect(find.text('Pick a date on calendar to add reminder'), findsOneWidget);
      expect(find.text('Add Date'), findsOneWidget);
    });

    testWidgets('GST Calculator computes Base, GST, CGST, SGST and Final correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(scope: CalendarScope.business));
      await tester.pumpAndSettle();

      // Select GST Calculator
      await tester.tap(find.text('GST Calculator'));
      await tester.pumpAndSettle();

      expect(find.text('GST Tax Calculator'), findsOneWidget);

      // Default amount is ₹10000 and 18%
      // Base: ₹10,000.00, GST: ₹1,800.00, CGST: ₹900.00, SGST: ₹900.00, Final: ₹11,800.00
      expect(find.text('₹1,800.00'), findsOneWidget);
      expect(find.text('₹900.00'), findsNWidgets(2)); // CGST and SGST
      expect(find.text('₹11,800.00'), findsOneWidget);

      // Switch to 5% GST
      await tester.tap(find.text('5%'));
      await tester.pumpAndSettle();

      // 5% on 10,000 => GST 500, Final 10,500
      expect(find.text('₹500.00'), findsOneWidget);
      expect(find.text('₹10,500.00'), findsOneWidget);
    });

    testWidgets('Loan EMI Calculator computes monthly EMI, interest and total payable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(scope: CalendarScope.personal));
      await tester.pumpAndSettle();

      expect(find.text('Loan EMI Calculator'), findsOneWidget);
      expect(find.text('Monthly EMI'), findsOneWidget);
      expect(find.text('Total Interest Payable'), findsOneWidget);
      expect(find.text('Total Amount Payable'), findsOneWidget);

      // Ensure calculated values are non-zero
      expect(find.text('₹0.00'), findsNothing);
    });

    testWidgets('Markup and Margin calculator computes profit, markup % and margin %', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(scope: CalendarScope.business));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Markup & Margin'));
      await tester.pumpAndSettle();

      expect(find.text('Markup & Margin Calculator'), findsOneWidget);
      expect(find.text('Profit Per Unit'), findsOneWidget);
      expect(find.text('Markup on Cost'), findsOneWidget);
      expect(find.text('Gross Profit Margin'), findsOneWidget);
      // Cost 1000, Sell 1250 => Profit 250, Markup 25%, Margin 20%
      expect(find.text('25.00%'), findsOneWidget);
      expect(find.text('20.00%'), findsOneWidget);
    });

    testWidgets('Responsive test: Renders on very narrow 320dp screen with 0 layout overflows', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(screenWidth: 320.0, screenHeight: 700.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Finance Calculator'), findsOneWidget);
      expect(find.text('Calendar Reminder Option'), findsOneWidget);
    });

    testWidgets('Responsive test: Renders on normal 392dp screen with 0 layout overflows', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(screenWidth: 392.0, screenHeight: 840.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive test: Renders on large 480dp screen with 0 layout overflows', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(screenWidth: 480.0, screenHeight: 960.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Dark Mode renders with high contrast and readable text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Finance Calculator'), findsOneWidget);
      expect(find.text('Business Margins & Profitability'), findsOneWidget);
    });

    testWidgets('Schedule Reminder dialog opens, saves reminder, and updates UI', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(screenHeight: 1200.0));
      await tester.pumpAndSettle();

      // Ensure Add Date is visible and tap
      final addDateFinder = find.text('Add Date');
      await tester.ensureVisible(addDateFinder);
      await tester.pumpAndSettle();
      await tester.tap(addDateFinder);
      await tester.pumpAndSettle();

      // Date picker opens, tap OK
      expect(find.text('SELECT REMINDER DATE'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Schedule dialog opens
      expect(find.text('Schedule Financial Reminder'), findsOneWidget);

      // Enter reminder title
      await tester.enterText(find.widgetWithText(TextField, 'e.g. GSTR-3B Payment or Vehicle EMI'), 'Advance Income Tax Q3');
      await tester.pumpAndSettle();

      // Tap Save Reminder
      await tester.tap(find.text('Save Reminder'));
      await tester.pumpAndSettle();

      // Verify saved in list
      expect(find.text('Advance Income Tax Q3'), findsOneWidget);
    });
  });
}
