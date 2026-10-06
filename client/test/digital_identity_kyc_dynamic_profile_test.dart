import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/auth/data/auth_repository.dart';
import 'package:enx_money/features/auth/models/user_model.dart';
import 'package:enx_money/features/profile/data/profile_repository.dart';
import 'package:enx_money/features/profile/data/kyc_repository.dart';
import 'package:enx_money/features/profile/presentation/screens/digital_identity_kyc_screen.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('1. Verification that hardcoded static profile & device strings are eradicated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Initial mount without user
    await tester.pumpWidget(createTestApp(const DigitalIdentityKycScreen()));
    await tester.pumpAndSettle();

    // Verify static hardcoded strings are nowhere in the rendered UI
    expect(find.text('P. Revanth Reddy'), findsNothing);
    expect(find.text('DEV-PIXEL-8-PRO-IND'), findsNothing);
    expect(find.text('ENX-ID-9102-4821'), findsNothing);
  });

  testWidgets('2. Dynamic Profile Binding: Renders logged-in user name "Rahul Sharma" dynamically', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Set authenticated session to "Rahul Sharma"
    final testUser = UserModel(
      id: 'usr_rahul_999',
      fullName: 'Rahul Sharma',
      email: 'rahul.sharma@example.com',
      mobileNumber: '+919876543210',
    );
    ProfileRepository().syncFromUser(testUser);

    await tester.pumpWidget(createTestApp(const DigitalIdentityKycScreen()));
    await tester.pumpAndSettle();

    // Verify "Rahul Sharma" is dynamically displayed on identity card
    expect(find.text('Rahul Sharma'), findsOneWidget);

    // Verify static text is NOT displayed
    expect(find.text('P. Revanth Reddy'), findsNothing);
    expect(find.text('DEV-PIXEL-8-PRO-IND'), findsNothing);
    expect(find.text('ENX-ID-9102-4821'), findsNothing);
  });

  testWidgets('3. Session Safety: ProfileRepository and KycRepository are cleared completely on logout', (WidgetTester tester) async {
    // Populate session
    final testUser = UserModel(
      id: 'usr_test_123',
      fullName: 'Session Security User',
      email: 'security@example.com',
    );
    ProfileRepository().syncFromUser(testUser);
    expect(ProfileRepository().profile.fullName, 'Session Security User');

    // Trigger logout
    await AuthRepository().logout();

    // Verify in-memory state is completely wiped
    expect(ProfileRepository().profile.fullName, '');
    expect(KycRepository().kycStatus, isNull);
    expect(AuthRepository().currentUser, isNull);
  });
}
