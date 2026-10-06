import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/auth/presentation/screens/security_questions_setup_screen.dart';
import 'package:enx_money/features/profile/presentation/screens/security_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Security & Recovery Questions Feature Tests', () {
    testWidgets('SecurityRecoveryQuestionsScreen renders header, dropdowns, inputs, and CTA in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const SecurityRecoveryQuestionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header verification
      expect(find.text('Security & Recovery Questions'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // 2. Question slots
      expect(find.text('QUESTION 1'), findsOneWidget);
      expect(find.text('QUESTION 2'), findsOneWidget);
      expect(find.text('ANSWER 1'), findsOneWidget);
      expect(find.text('ANSWER 2'), findsOneWidget);

      // 3. Dropdown presence
      expect(find.byType(DropdownButton<String>), findsNWidgets(2));

      // 4. High-contrast answer input boxes
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // 5. Save CTA button
      expect(find.text('Save Recovery Questions'), findsOneWidget);

      // 6. Type answer in Slot 1 and verify 100% visibility (not obscured by default)
      await tester.enterText(textFields.first, 'St. Michael High School');
      await tester.pumpAndSettle();

      final firstField = tester.widget<TextField>(textFields.first);
      expect(firstField.obscureText, false);
      expect(firstField.style?.color, const Color(0xFF0F172A)); // Light mode visible text
    });

    testWidgets('SecurityRecoveryQuestionsScreen adapts to Dark Mode with #FFFFFF text and #0F172A background', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SecurityRecoveryQuestionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0F172A));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.last, 'Bangalore');
      await tester.pumpAndSettle();

      final secondField = tester.widget<TextField>(textFields.last);
      expect(secondField.obscureText, false);
      expect(secondField.style?.color, const Color(0xFFFFFFFF)); // Dark mode visible text
    });

    testWidgets('SecuritySettingsScreen card & chevron touch handler navigates to SecurityRecoveryQuestionsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            splashFactory: NoSplash.splashFactory,
          ),
          routes: {
            '/security-recovery-questions': (_) => const SecurityRecoveryQuestionsScreen(),
          },
          home: const SecuritySettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Locate the List Item card for Security & Recovery Questions
      final itemFinder = find.widgetWithText(InkWell, 'Security & Recovery Questions').first;
      expect(itemFinder, findsOneWidget);

      // Tap on the card
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Target screen should now be visible
      expect(find.text('Account Recovery Setup'), findsOneWidget);
      expect(find.text('Save Recovery Questions'), findsOneWidget);
    });
  });
}
