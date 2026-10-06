import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard consolidates WhatsApp bot into single primary banner and cleans top header & quick actions', (tester) async {
    // Provide a standard phone surface (1080 x 2400 @ 2.75x ~ 392 x 872 logical)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );
    await tester.pump();

    // 1. Verify Super Admin and AI Bot pill buttons are NOT present in top header
    expect(find.byIcon(Icons.admin_panel_settings_rounded), findsNothing);
    expect(find.text('AI Bot'), findsNothing);

    // 2. Verify clean header elements
    expect(find.text('ENX MONEY'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // 3. Verify "WhatsApp Bot" tile is removed from Quick Actions matrix
    expect(find.text('WhatsApp Bot'), findsNothing);

    // 4. Verify the 7 consolidated Quick Actions are present
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Add Supplier'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Create Sale / GST'), findsOneWidget);
    expect(find.text('Add Payment'), findsOneWidget);
    expect(find.text('Khata / Outstanding'), findsOneWidget);
    expect(find.text('Fund Transfer'), findsOneWidget);

    // 5. Verify the single primary "WhatsApp AI Assistant" banner is retained with Chat button
    expect(find.text('WhatsApp AI Assistant'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
