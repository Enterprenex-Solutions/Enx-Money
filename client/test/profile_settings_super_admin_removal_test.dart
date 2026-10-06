import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/profile/presentation/screens/profile_screen.dart';
import 'package:enx_money/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SUPER ADMIN & GOVERNANCE section is completely removed from Settings layout and layout reflows smoothly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        home: const ProfileScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify "SUPER ADMIN & GOVERNANCE" section header is completely absent
    expect(find.text('SUPER ADMIN & GOVERNANCE'), findsNothing);

    // 2. Verify "Super Admin & Global Analytics" card & RBAC badge are completely absent
    expect(find.text('Super Admin & Global Analytics'), findsNothing);
    expect(find.text('RBAC SECURED'), findsNothing);
    expect(find.text('Worldwide users, active sessions, geo breakdown & telemetry'), findsNothing);

    // 3. Verify AI Business Advisor and Support & Legal sections are present
    expect(find.text('AI BUSINESS ADVISOR'), findsOneWidget);
    expect(find.text('24/7 Priority Concierge & FAQ'), findsOneWidget);
    expect(find.text('Data & Privacy Dashboard'), findsOneWidget);

    // 4. Verify vertical layout order: Support & Legal appears below AI Business Advisor
    final aiAdvisorY = tester.getBottomLeft(find.text('AI BUSINESS ADVISOR')).dy;
    final supportLegalY = tester.getTopLeft(find.text('24/7 Priority Concierge & FAQ')).dy;
    expect(supportLegalY, greaterThan(aiAdvisorY));
  });
}
