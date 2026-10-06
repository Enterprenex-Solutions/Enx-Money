import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/customers/presentation/screens/add_customer_screen.dart';

void main() {
  group('AddCustomerScreen Address Header Responsiveness & Alignment', () {
    testWidgets('Header renders title and Use Current Location button with proper layout constraints', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.5, 800 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false, splashFactory: NoSplash.splashFactory),
          home: const AddCustomerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the location header title
      final titleFinder = find.text('LOCATION & ADMINISTRATIVE ADDRESS');
      expect(titleFinder, findsOneWidget);

      // Find the "Use Current Location" button
      final buttonFinder = find.byKey(const Key('use_current_location_btn'));
      expect(buttonFinder, findsOneWidget);

      final buttonTextFinder = find.text('Use Current Location');
      expect(buttonTextFinder, findsOneWidget);

      // Verify the button text is inside the button container
      expect(find.descendant(of: buttonFinder, matching: buttonTextFinder), findsOneWidget);

      // Check coordinates to verify right margin is >= 16px from the screen edge
      final buttonRect = tester.getRect(buttonFinder);
      const screenWidth = 360.0;
      final rightMargin = screenWidth - buttonRect.right;
      expect(rightMargin, greaterThanOrEqualTo(16.0));
    });

    testWidgets('Header does not overflow or clip across narrow and wide screen widths (320px, 360px, 390px, 412px)', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2.5, 840 * 2.5);
        tester.view.devicePixelRatio = 2.5;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: false,
              splashFactory: NoSplash.splashFactory,
            ),
            home: const AddCustomerScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify button exists and text is visible
        final buttonFinder = find.byKey(const Key('use_current_location_btn'));
        expect(buttonFinder, findsOneWidget);
        expect(find.text('Use Current Location'), findsOneWidget);

        // Verify right margin is >= 16px
        final buttonRect = tester.getRect(buttonFinder);
        final rightMargin = width - buttonRect.right;
        expect(rightMargin, greaterThanOrEqualTo(16.0));

        // Check that button left is strictly greater than title container left
        final titleFinder = find.text('LOCATION & ADMINISTRATIVE ADDRESS');
        final titleRect = tester.getRect(titleFinder);
        expect(buttonRect.left, greaterThan(titleRect.left));

        // Zero overflow assertions
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
