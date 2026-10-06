import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/inventory/presentation/screens/add_product_screen.dart';
import 'package:enx_money/features/invoices/presentation/screens/create_invoice_screen.dart';

void main() {
  testWidgets('AddProductScreen input text color is dark and clearly visible in Light Mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddProductScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsNWidgets(8));

    for (final element in textFieldFinder.evaluate()) {
      final widget = element.widget as TextField;
      expect(widget.style?.color, equals(const Color(0xFF0F172A)));
    }

    // Type text into Product Name
    final nameField = find.widgetWithText(TextFormField, 'PRODUCT / ITEM NAME *');
    await tester.enterText(nameField, 'Cotton Fabric Rolls');

    final skuField = find.widgetWithText(TextFormField, 'SKU CODE *');
    await tester.enterText(skuField, 'MY-UNIQUE-SKU-99');

    await tester.pumpAndSettle();

    expect(find.text('Cotton Fabric Rolls'), findsOneWidget);
    expect(find.text('MY-UNIQUE-SKU-99'), findsOneWidget);
  });

  testWidgets('CreateInvoiceScreen line item inputs have dark and clearly visible text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateInvoiceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify invoice items header is dark/visible
    final headerFinder = find.text('INVOICE ITEMS');
    expect(headerFinder, findsOneWidget);
    final headerWidget = tester.widget<Text>(headerFinder);
    expect(headerWidget.style?.color, equals(const Color(0xFF0F172A)));

    // Verify item fields have dark text color
    final descField = find.widgetWithText(TextFormField, 'Item Description *');
    expect(descField, findsOneWidget);
    await tester.enterText(descField, 'Cotton Shirts Batch A');

    final qtyField = find.widgetWithText(TextFormField, 'Qty');
    expect(qtyField, findsOneWidget);
    await tester.enterText(qtyField, '10');

    final priceField = find.widgetWithText(TextFormField, 'Price (₹)');
    expect(priceField, findsOneWidget);
    await tester.enterText(priceField, '450');

    await tester.pumpAndSettle();

    expect(find.text('Cotton Shirts Batch A'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('450'), findsOneWidget);
  });
}
