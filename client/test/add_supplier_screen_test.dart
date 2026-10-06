import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/suppliers/presentation/screens/add_supplier_screen.dart';

void main() {
  testWidgets('AddSupplierScreen input text color is dark and clearly visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddSupplierScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all TextFields rendered inside TextFormFields have dark text color Color(0xFF0F172A)
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsNWidgets(7));

    for (final element in textFieldFinder.evaluate()) {
      final widget = element.widget as TextField;
      expect(widget.style?.color, equals(const Color(0xFF0F172A)));
    }

    // Type the test values requested by the user:
    // ABC Traders
    // 9876543210
    // ABC Enterprises
    // 25000
    // Tirupati

    // 1. Supplier / Vendor Name
    final nameField = find.widgetWithText(TextFormField, 'SUPPLIER / VENDOR NAME *');
    await tester.enterText(nameField, 'ABC Traders');

    // 2. Contact Phone Number
    final phoneField = find.widgetWithText(TextFormField, 'CONTACT PHONE NUMBER *');
    await tester.enterText(phoneField, '9876543210');

    // 3. Company / Firm
    final companyField = find.widgetWithText(TextFormField, 'COMPANY / FIRM');
    await tester.enterText(companyField, 'ABC Enterprises');

    // 4. Opening Payable
    final balanceField = find.widgetWithText(TextFormField, 'OPENING PAYABLE (₹)');
    await tester.enterText(balanceField, '25000');

    // 5. Business Address / City
    final addressField = find.widgetWithText(TextFormField, 'BUSINESS ADDRESS / CITY');
    await tester.enterText(addressField, 'Tirupati');

    await tester.pumpAndSettle();

    // Confirm that typed text is present in the text fields and legible
    expect(find.text('ABC Traders'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('ABC Enterprises'), findsOneWidget);
    expect(find.text('25000'), findsOneWidget);
    expect(find.text('Tirupati'), findsOneWidget);
  });
}
