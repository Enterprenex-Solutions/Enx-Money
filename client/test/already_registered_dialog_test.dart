import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/core/widgets/already_registered_dialog.dart';

void main() {
  group('AlreadyRegisteredDialog Widget Tests', () {
    testWidgets('renders all required UI texts, elements and branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlreadyRegisteredDialog.show(
                  context,
                  email: 'existing.user@enxmoney.com',
                  phone: '+919876543210',
                  field: 'both',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify exact texts required by user prompt
      expect(find.text('This account is already registered.'), findsOneWidget);
      expect(find.text('Please log in to continue using your ENX Money account.'), findsOneWidget);

      // Verify identifiers
      expect(find.text('existing.user@enxmoney.com'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);

      // Verify buttons
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses popup and triggers onCancel callback', (WidgetTester tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlreadyRegisteredDialog.show(
                  context,
                  email: 'test@enxmoney.com',
                  onCancel: () => cancelCalled = true,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('This account is already registered.'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('This account is already registered.'), findsNothing);
      expect(cancelCalled, isTrue);
    });

    testWidgets('Login button dismisses popup and triggers onLogin callback', (WidgetTester tester) async {
      bool loginCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlreadyRegisteredDialog.show(
                  context,
                  email: 'test@enxmoney.com',
                  onLogin: () => loginCalled = true,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('This account is already registered.'), findsOneWidget);

      // Tap Login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('This account is already registered.'), findsNothing);
      expect(loginCalled, isTrue);
    });

    testWidgets('displays phone-only layout when field is phone', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlreadyRegisteredDialog.show(
                  context,
                  email: 'unregistered.user@gmail.com',
                  phone: '+919440829762',
                  field: 'phone',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Number Already Registered'), findsOneWidget);
      expect(find.text('+919440829762'), findsOneWidget);
      // Unregistered email should NOT be displayed
      expect(find.text('unregistered.user@gmail.com'), findsNothing);
    });
  });
}
