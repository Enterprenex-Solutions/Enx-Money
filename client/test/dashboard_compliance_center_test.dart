import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:enx_money/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Compliance Center block is permanently removed from Home dashboard layout', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
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
        home: const DashboardScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Compliance Center card is permanently deleted
    expect(find.text('Compliance Center'), findsNothing);
    expect(find.text('Sec 21'), findsNothing);
    expect(find.text('Open Hub'), findsNothing);
    expect(find.text('Data lineage, retention schedule, DPDP Act & audit logs'), findsNothing);

    // 2. Verify all tag chips are removed from Home dashboard
    expect(find.text('DPDP Act 2023'), findsNothing);
    expect(find.text('Audit Register'), findsNothing);
    expect(find.text('8-Yr Retention'), findsNothing);
    expect(find.text('Secured Logs'), findsNothing);

    // 3. Verify Quick Actions and Search Bar are present
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.text('Search customer by name, mobile, or GSTIN...'), findsOneWidget);

    // 4. Verify vertical layout order: Search Bar is below Quick Actions
    final quickActionsY = tester.getBottomLeft(find.text('QUICK ACTIONS')).dy;
    final searchBarY = tester.getTopLeft(find.text('Search customer by name, mobile, or GSTIN...')).dy;
    expect(searchBarY, greaterThan(quickActionsY));
  });
}
