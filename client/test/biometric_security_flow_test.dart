import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/types/auth_messages.dart';
import 'package:enx_money/features/auth/data/biometric_service.dart';
import 'package:enx_money/core/services/app_lock_service.dart';
import 'package:enx_money/core/services/secure_credential_vault.dart';
import 'package:enx_money/features/profile/data/profile_repository.dart';
import 'package:enx_money/features/auth/presentation/screens/app_lock_pin_screen.dart';
import 'package:enx_money/core/widgets/inputs/numeric_keypad.dart';
import 'package:enx_money/core/widgets/inputs/pin_dot_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BiometricService Requirements', () {
    test('Exact unenrolled toast message matches required specification', () {
      expect(
        BiometricService.notEnrolledMessage,
        equals('No biometrics enrolled. Please set up Fingerprint/Face ID in your device settings.'),
      );
    });

    test('BiometricStatus enum values are correctly defined', () {
      expect(BiometricStatus.values, contains(BiometricStatus.available));
      expect(BiometricStatus.values, contains(BiometricStatus.notEnrolled));
      expect(BiometricStatus.values, contains(BiometricStatus.notSupported));
    });

    test('Returns notSupported when hardware is absent', () async {
      final service = BiometricService.createForTesting(MockAuthNotSupported());
      final status = await service.checkBiometricStatus();
      expect(status, equals(BiometricStatus.notSupported));
      expect(await service.isBiometricAvailable(), isFalse);
    });

    test('Returns notEnrolled when hardware is present but no prints are enrolled', () async {
      final service = BiometricService.createForTesting(MockAuthNotEnrolled());
      final status = await service.checkBiometricStatus();
      expect(status, equals(BiometricStatus.notEnrolled));
      expect(await service.isBiometricAvailable(), isFalse);
    });

    test('Returns available when hardware is present and biometrics are enrolled', () async {
      final service = BiometricService.createForTesting(MockAuthAvailable());
      final status = await service.checkBiometricStatus();
      expect(status, equals(BiometricStatus.available));
      expect(await service.isBiometricAvailable(), isTrue);
    });
  });

  group('AppLockService Biometric Lifecycle & State', () {
    test('setBiometricEnabled updates state and activates lock tracking', () async {
      final service = AppLockService.instance;
      await service.init();

      expect(service.isBiometricEnabled, isFalse);
      expect(service.isAnyLockActive, isFalse);

      await service.setBiometricEnabled(true);
      expect(service.isBiometricEnabled, isTrue);
      expect(service.isAnyLockActive, isTrue);

      // Verify lockNow and lockSilently work when biometric is enabled
      service.lockNow();
      expect(service.isLocked, isTrue);

      service.unlock();
      expect(service.isLocked, isFalse);

      service.lockSilently();
      expect(service.isLocked, isTrue);

      service.unlock();
    });

    test('onAppPaused and onAppResumed enforce 30-minute background session timeout and isAppUnlocked state', () async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_data': '{"id":"u1","name":"User","email":"user@test.com"}',
      });
      final service = AppLockService.instance;
      await service.init();
      await service.setBiometricEnabled(true);

      // On cold launch, unlock sets isAppUnlocked = true
      service.unlock();
      expect(service.isAppUnlocked, isTrue);
      expect(service.isLocked, isFalse);

      // Transition to background: records lastActiveTimestamp
      final startMs = DateTime.now().millisecondsSinceEpoch;
      service.onAppPaused();
      expect(service.lastActiveTimestamp, isNotNull);

      // Case A: Resume after 10 minutes (< 30 min grace period)
      // Must keep isAppUnlocked = true and remain unlocked without prompt
      final tenMinutesLaterMs = startMs + (10 * 60 * 1000);
      await service.onAppResumed(mockCurrentTimeMs: tenMinutesLaterMs);

      expect(service.isAppUnlocked, isTrue);
      expect(service.isLocked, isFalse);
      expect(service.lastActiveTimestamp, isNull);

      // Case B: Transition to background again and resume after 35 minutes (>= 30 min)
      service.onAppPaused();
      final pauseTimeMs = service.lastActiveTimestamp!;
      final thirtyFiveMinutesLaterMs = pauseTimeMs + (35 * 60 * 1000);
      await service.onAppResumed(mockCurrentTimeMs: thirtyFiveMinutesLaterMs);

      // Must lock view, set isAppUnlocked = false, and require fingerprint prompt
      expect(service.isAppUnlocked, isFalse);
      expect(service.isLocked, isTrue);

      // Unlock resets state
      service.unlock();
      expect(service.isAppUnlocked, isTrue);
      expect(service.isLocked, isFalse);

      // Manual Logout resets isAppUnlocked = false
      service.onLogout();
      expect(service.isAppUnlocked, isFalse);
      expect(service.isLocked, isFalse);
    });

    test('setBiometricPromptActive suppresses lifecycle auto-lock and prevents authentication loop', () async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_data': '{"id":"u1","name":"User","email":"user@test.com"}',
      });
      final service = AppLockService.instance;
      await service.init();
      await service.setBiometricEnabled(true);
      await service.setAutoLockDuration('Immediately');

      // Emulate user on unlocked session opening native biometric scan
      service.unlock();
      expect(service.isLocked, isFalse);
      expect(service.isAuthenticated, isTrue);

      service.setBiometricPromptActive(true);
      expect(service.isAuthenticatingBiometric, isTrue);

      // System pauses activity to show native fingerprint prompt
      service.onAppPaused();
      // System resumes activity when native dialog completes
      await service.onAppResumed();

      // Because biometric prompt was active, it should NOT auto-lock or loop
      expect(service.isLocked, isFalse);

      // Conclude biometric prompt
      service.setBiometricPromptActive(false);
      expect(service.isAuthenticatingBiometric, isFalse);
    });

    test('Dual verification triggers: both PIN and Biometrics set isAuthenticated and unlock session', () async {
      final service = AppLockService.instance;
      await service.init();
      await service.enablePin('1234');

      // Start locked
      service.lockNow();
      expect(service.isLocked, isTrue);
      expect(service.isAuthenticated, isFalse);

      // Verify PIN unlock path
      final isPinValid = await service.verifyPin('1234');
      expect(isPinValid, isTrue);
      expect(service.isLocked, isFalse);
      expect(service.isAuthenticated, isTrue);

      // Re-lock
      service.lockNow();
      expect(service.isLocked, isTrue);
      expect(service.isAuthenticated, isFalse);

      // Verify Biometric unlock path
      service.unlock();
      expect(service.isLocked, isFalse);
      expect(service.isAuthenticated, isTrue);
    });
  });


  group('ProfileRepository Biometric Security Synchronization', () {
    test('updateSecurity persists isBiometricEnabled and syncs with AppLockService', () async {
      final repo = ProfileRepository();
      await repo.loadProfile(fetchFromApi: false);

      await repo.updateSecurity(isBiometricEnabled: true);
      expect(repo.profile.isBiometricEnabled, isTrue);
      expect(AppLockService.instance.isBiometricEnabled, isTrue);

      await repo.updateSecurity(isBiometricEnabled: false);
      expect(repo.profile.isBiometricEnabled, isFalse);
      expect(AppLockService.instance.isBiometricEnabled, isFalse);
    });
  });

  group('SecureCredentialVault Multi-User & MPIN Security', () {
    test('MPIN is saved as salted cryptographic hash and never stored as plaintext', () async {
      final vault = SecureCredentialVault.instance;
      final saved = await vault.saveMpin('user_123', '4321');
      expect(saved, isTrue);

      final prefs = await SharedPreferences.getInstance();
      // Verify raw PIN '4321' is NOT stored anywhere in preferences
      for (final key in prefs.getKeys()) {
        final val = prefs.get(key).toString();
        expect(val.contains('4321'), isFalse, reason: 'Plaintext MPIN must never be stored');
      }

      // Verify correct verification
      final resValid = await vault.verifyMpin('user_123', '4321');
      expect(resValid.isSuccess, isTrue);

      // Verify incorrect verification
      final resInvalid = await vault.verifyMpin('user_123', '9999');
      expect(resInvalid.isSuccess, isFalse);
      expect(resInvalid.remainingAttempts, equals(4));
    });

    test('Brute force protection: 5 consecutive failed attempts locks out user', () async {
      final vault = SecureCredentialVault.instance;
      await vault.saveMpin('user_brute', '5555');

      for (int i = 1; i <= 4; i++) {
        final res = await vault.verifyMpin('user_brute', '0000');
        expect(res.isSuccess, isFalse);
        expect(res.isLockedOut, isFalse);
        expect(res.remainingAttempts, equals(5 - i));
      }

      // 5th attempt triggers lockout
      final lockedRes = await vault.verifyMpin('user_brute', '0000');
      expect(lockedRes.isSuccess, isFalse);
      expect(lockedRes.isLockedOut, isTrue);
      expect(lockedRes.lockoutSeconds, greaterThan(0));

      // Even entering correct MPIN during lockout period is rejected
      final blockedCorrect = await vault.verifyMpin('user_brute', '5555');
      expect(blockedCorrect.isSuccess, isFalse);
      expect(blockedCorrect.isLockedOut, isTrue);
    });

    test('Multi-user isolation: User A credentials cannot unlock User B session', () async {
      final vault = SecureCredentialVault.instance;
      await vault.saveMpin('user_A', '1111');
      await vault.saveMpin('user_B', '2222');

      // User A entering their own PIN succeeds
      final userAPass = await vault.verifyMpin('user_A', '1111');
      expect(userAPass.isSuccess, isTrue);

      // User A's PIN tested against User B fails
      final crossUserFail = await vault.verifyMpin('user_B', '1111');
      expect(crossUserFail.isSuccess, isFalse);
    });
  });

  group('App Lock Dual-Verification & Direct Home Flow', () {
    testWidgets('Case 1 & 5 & 6: App locked -> fingerprint correct -> Home directly, MPIN never appears, no second prompt', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_data': '{"id":"u1","name":"User","email":"user@test.com"}',
        'enx_biometric_enabled': true,
        'enx_app_lock_enabled': true,
      });

      BiometricService.instance = BiometricService.createForTesting(MockAuthSuccess());
      final lockService = AppLockService.instance;
      await lockService.init();
      await lockService.setBiometricEnabled(true);
      lockService.lockNow();

      expect(lockService.isLocked, isTrue);
      expect(lockService.isAuthenticated, isFalse);

      bool unlockedCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockPinScreen(
            onUnlocked: () {
              unlockedCallbackCalled = true;
            },
          ),
        ),
      );

      // Verify that MPIN keypad and dot indicators are NOT rendered on initial mount
      expect(find.byType(NumericKeypad), findsNothing, reason: 'MPIN keypad must NOT appear when biometric is available');
      expect(find.byType(PinDotIndicator), findsNothing, reason: 'MPIN dots must NOT appear when biometric is available');

      // Let post-frame callbacks and biometric auto-prompt complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify immediate unlock without showing MPIN
      expect(unlockedCallbackCalled, isTrue, reason: 'Successful fingerprint must trigger unlock immediately');
      expect(lockService.isAuthenticated, isTrue, reason: 'isAuthenticated must be true after biometric success');
      expect(lockService.isLocked, isFalse, reason: 'isLocked must be false after biometric success');
      expect(find.byType(NumericKeypad), findsNothing, reason: 'MPIN keypad must never appear after biometric success');
      expect(find.byType(PinDotIndicator), findsNothing, reason: 'MPIN dots must never appear after biometric success');
    });

    testWidgets('Case 2: App locked -> fingerprint cancelled -> MPIN shown', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_data': '{"id":"u1","name":"User","email":"user@test.com"}',
        'enx_biometric_enabled': true,
      });

      BiometricService.instance = BiometricService.createForTesting(MockAuthCancelled());
      final lockService = AppLockService.instance;
      await lockService.init();
      await lockService.setBiometricEnabled(true);
      lockService.lockNow();

      bool unlockedCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockPinScreen(
            onUnlocked: () {
              unlockedCallbackCalled = true;
            },
          ),
        ),
      );

      // Auto-prompt runs and user cancels
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify unlock was NOT called
      expect(unlockedCallbackCalled, isFalse);
      expect(lockService.isAuthenticated, isFalse);

      // Verify 4-digit MPIN fallback is NOW displayed
      expect(find.byType(NumericKeypad), findsOneWidget, reason: 'Numeric keypad must appear when biometric cancelled');
      expect(find.byType(PinDotIndicator), findsOneWidget, reason: 'Pin dots must appear when biometric cancelled');
      expect(find.text('Enter 4-digit MPIN'), findsOneWidget);
    });

    testWidgets('Case 4: App locked -> no biometric available -> MPIN shown', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_data': '{"id":"u1","name":"User","email":"user@test.com"}',
        'enx_biometric_enabled': true,
      });

      BiometricService.instance = BiometricService.createForTesting(MockAuthNotSupported());
      final lockService = AppLockService.instance;
      await lockService.init();
      lockService.lockNow();

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockPinScreen(
            onUnlocked: () {},
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify 4-digit MPIN is shown immediately when biometric is not supported
      expect(find.byType(NumericKeypad), findsOneWidget);
      expect(find.byType(PinDotIndicator), findsOneWidget);
    });
  });
}

class MockAuthNotSupported extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => false;
  @override
  Future<bool> isDeviceSupported() async => false;
}

class MockAuthNotEnrolled extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [];
}

class MockAuthAvailable extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [BiometricType.fingerprint];
}

class MockAuthSuccess extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [BiometricType.fingerprint];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async => true;
}

class MockAuthCancelled extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [BiometricType.fingerprint];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async => false;
}

