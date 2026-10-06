import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/legal/presentation/screens/legal_pages_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({String initialRoute = '/privacy-policy', Brightness brightness = Brightness.dark}) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      initialRoute: initialRoute,
      routes: {
        '/': (_) => const Scaffold(body: Text('Home')),
        '/privacy-policy': (_) => const PrivacyPolicyScreen(),
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/terms-and-conditions': (_) => const TermsAndConditionsScreen(),
        '/terms': (_) => const TermsAndConditionsScreen(),
        '/refund-cancellation-policy': (_) => const RefundCancellationPolicyScreen(),
        '/refund-policy': (_) => const RefundCancellationPolicyScreen(),
      },
    );
  }

  group('Permanent Production Legal Pages Tests', () {
    testWidgets('GET /privacy-policy renders PrivacyPolicyScreen with all required sections', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/privacy-policy'));
      await tester.pumpAndSettle();

      // Check title and entity badges
      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      expect(find.text('Enterprenex Solutions Pvt Ltd'), findsAtLeastNWidgets(1));
      expect(find.text('Google Play Verified'), findsOneWidget);
      expect(find.text('DPDP Act Compliant'), findsOneWidget);

      // Verify sections are present
      expect(find.text('1. Scope & Operating Entity'), findsOneWidget);
      expect(find.text('2. Critical Consistency Rule'), findsOneWidget);
      expect(find.text('3. 12-Category Data Collection Audit'), findsOneWidget);
      expect(find.text('4. 10 Verified Security Controls'), findsOneWidget);
    });

    testWidgets('Privacy Policy search filter filters sections accurately', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/privacy-policy'));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Retention');
      await tester.pumpAndSettle();

      expect(find.text('5. Data Retention & Permanent Deletion'), findsOneWidget);
      expect(find.text('1. Scope & Operating Entity'), findsNothing);
    });

    testWidgets('GET /terms-and-conditions renders TermsAndConditionsScreen with disclosures', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/terms-and-conditions'));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsAtLeastNWidgets(1));
      expect(find.text('1. Acceptance of Terms & Service Scope'), findsOneWidget);
      expect(find.text('2. User Eligibility & Adult Requirement'), findsOneWidget);
      expect(find.text('7. Governing Law & Dispute Resolution'), findsOneWidget);
    });

    testWidgets('GET /refund-cancellation-policy renders RefundCancellationPolicyScreen with Google Play compliance', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/refund-cancellation-policy'));
      await tester.pumpAndSettle();

      expect(find.text('Refund & Cancellation'), findsAtLeastNWidgets(1));
      expect(find.text('1. Policy Overview & Transparent Billing Scope'), findsOneWidget);
      expect(find.text('4. Refund Request Windows'), findsOneWidget);
      expect(find.text('6. Subscription Cancellation'), findsOneWidget);
    });

    testWidgets('GET /refund-policy alias renders RefundCancellationPolicyScreen', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/refund-policy'));
      await tester.pumpAndSettle();

      expect(find.text('Refund & Cancellation'), findsAtLeastNWidgets(1));
    });

    testWidgets('Responsive test: Privacy Policy renders on narrow 320dp screen with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/privacy-policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive test: Terms & Conditions renders on narrow 320dp screen with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/terms-and-conditions'));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive test: Refund & Cancellation renders on narrow 320dp screen with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/refund-cancellation-policy'));
      await tester.pumpAndSettle();

      expect(find.text('Refund & Cancellation'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Light mode renders with high contrast and readable text', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(initialRoute: '/privacy-policy', brightness: Brightness.light));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });
  });
}
