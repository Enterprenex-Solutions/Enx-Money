import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  group('Dashboard WhatsApp bot consolidation & responsive grid layout', () {
    final screenWidths = [320.0, 360.0, 390.0, 412.0, 600.0];

    for (final width in screenWidths) {
      testWidgets('Renders cleanly on screen width ${width}px without any overflow', (tester) async {
        tester.view.physicalSize = Size(width * 2.5, 850 * 2.5);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: DashboardScreen(),
          ),
        );
        await tester.pump();

        // Check no RenderFlex overflow
        expect(tester.takeException(), isNull);

        // Verify Quick Action tiles exist
        expect(find.text('Add Customer'), findsOneWidget);
        expect(find.text('Fund Transfer'), findsOneWidget);

        // Verify WhatsApp AI Assistant banner
        expect(find.text('WhatsApp AI Assistant'), findsOneWidget);
        expect(find.text('Chat'), findsOneWidget);
      });
    }
  });
}
