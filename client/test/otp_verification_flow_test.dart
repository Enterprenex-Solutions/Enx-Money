import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:enx_money/features/auth/models/user_model.dart';
import 'package:enx_money/features/profile/data/profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OTP Verification Flow Tests', () {
    testWidgets('OtpVerificationScreen renders header and email RichText', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(
            email: 'testuser@enxmoney.com',
            phone: '9876543210',
            isRegistration: true,
            name: 'Priya Sharma',
            registrationData: {
              'name': 'Priya Sharma',
              'businessName': 'Sharma Textiles',
              'email': 'testuser@enxmoney.com',
              'mobile': '9876543210',
              'password': 'Password123!',
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('testuser@enxmoney.com'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });

    test('ProfileRepository correctly synchronizes verified user status', () async {
      final user = UserModel(
        id: 'usr_verified_123',
        fullName: 'Priya Sharma',
        email: 'priya@enxmoney.com',
        mobileNumber: '+919876543210',
        isEmailVerified: true,
        kycStatus: 'VERIFIED',
      );

      ProfileRepository().syncFromUser(user);

      expect(ProfileRepository().profile.isEmailVerified, true);
      expect(ProfileRepository().profile.kycTier, 'VERIFIED');
      expect(ProfileRepository().profile.fullName, 'Priya Sharma');
      expect(ProfileRepository().profile.email, 'priya@enxmoney.com');
    });
  });
}
