import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/auth/presentation/screens/create_account_screen.dart';

void main() {
  group('Create Account Screen Terms Checkbox & Validation Flow', () {
    testWidgets('1. Checkbox unchecked -> Verify Email disabled; 2. Checkbox checked -> Verify Email enabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const CreateAccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final checkboxTapFinder = find.byKey(const Key('terms_checkbox_tap'));
      final verifyBtnFinder = find.widgetWithText(ElevatedButton, 'Verify Email');

      // Scroll to verify the checkbox
      await tester.ensureVisible(checkboxTapFinder);
      await tester.pumpAndSettle();

      // Checkbox is unchecked by default
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Verify button is disabled when unchecked
      await tester.ensureVisible(verifyBtnFinder);
      await tester.pumpAndSettle();
      ElevatedButton verifyBtn = tester.widget<ElevatedButton>(verifyBtnFinder);
      expect(verifyBtn.onPressed, isNull);

      // Tap checkbox to check it
      await tester.ensureVisible(checkboxTapFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxTapFinder);
      await tester.pumpAndSettle();

      // Checkbox is now checked with checkmark icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Verify button is now ENABLED
      await tester.ensureVisible(verifyBtnFinder);
      await tester.pumpAndSettle();
      verifyBtn = tester.widget<ElevatedButton>(verifyBtnFinder);
      expect(verifyBtn.onPressed, isNotNull);

      // Tap again to uncheck -> button becomes disabled again
      await tester.ensureVisible(checkboxTapFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxTapFinder);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsNothing);
      verifyBtn = tester.widget<ElevatedButton>(verifyBtnFinder);
      expect(verifyBtn.onPressed, isNull);
    });

    testWidgets('3. Tap Terms & Conditions opens modal; 4. Tap Privacy Policy opens modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const CreateAccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Terms & Conditions link
      final termsLink = find.text('Terms & Conditions');
      await tester.ensureVisible(termsLink);
      await tester.pumpAndSettle();
      await tester.tap(termsLink);
      await tester.pumpAndSettle();

      // Dialog with terms content appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsAtLeastNWidgets(1));

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Privacy Policy link
      final privacyLink = find.text('Privacy Policy');
      await tester.ensureVisible(privacyLink);
      await tester.pumpAndSettle();
      await tester.tap(privacyLink);
      await tester.pumpAndSettle();

      // Dialog with privacy policy content appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('5. Responsive test across multiple screen sizes (320px, 360px, 390px, 412px) in light & dark themes', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0];

      for (final isDark in [false, true]) {
        for (final width in widths) {
          tester.view.physicalSize = Size(width * 2.5, 900 * 2.5);
          tester.view.devicePixelRatio = 2.5;

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                useMaterial3: false,
                splashFactory: NoSplash.splashFactory,
              ),
              home: const CreateAccountScreen(),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('terms_checkbox')), findsOneWidget);
          expect(find.text('Verify Email'), findsOneWidget);
        }
      }
    });
  });
}
