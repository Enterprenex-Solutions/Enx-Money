import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ENX Money App initial render smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ENXMoneyApp());
    expect(find.text('ENX MONEY'), findsOneWidget);
    // Settle splash timer and animation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Verify Onboarding screen or initial screen renders
    expect(find.byType(ENXMoneyApp), findsOneWidget);
  });
}
