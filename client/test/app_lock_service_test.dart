import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/core/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLockService.instance.init();
  });

  group('AppLockService - Core PIN Security Tests', () {
    test('Initial state has lock disabled and unlocked', () async {
      final service = AppLockService.instance;
      await service.init();
      expect(service.isLockEnabled, false);
      expect(service.isLocked, false);
      expect(service.autoLockDuration, 'Immediately');
    });

    test('enablePin validates length and digits', () async {
      final service = AppLockService.instance;

      // Reject too short
      expect(await service.enablePin('12'), false);
      expect(await service.enablePin('123'), false);

      // Reject too long
      expect(await service.enablePin('12345'), false);

      // Reject non-numeric
      expect(await service.enablePin('abcd'), false);
      expect(await service.enablePin('12a4'), false);

      // Valid 4-digit PIN
      expect(await service.enablePin('7291'), true);
      expect(service.isLockEnabled, true);
    });

    test('Never stores PIN in plain text', () async {
      final service = AppLockService.instance;
      await service.enablePin('8426');

      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('enx_app_lock_pin_hash');
      final storedSalt = prefs.getString('enx_app_lock_salt');

      expect(storedHash, isNotNull);
      expect(storedSalt, isNotNull);

      // Plaintext must NOT appear in preferences
      expect(storedHash, isNot(contains('8426')));
      expect(storedSalt, isNot(contains('8426')));
      expect(prefs.getString('enx_app_lock_pin'), isNull);
    });

    test('verifyPin accepts correct PIN and rejects wrong PIN', () async {
      final service = AppLockService.instance;
      await service.enablePin('3590');

      service.lockNow();
      expect(service.isLocked, true);

      // Incorrect PIN
      final wrongResult = await service.verifyPin('0000');
      expect(wrongResult, false);
      expect(service.isLocked, true);

      // Another wrong PIN
      expect(await service.verifyPin('1234'), false);
      expect(service.isLocked, true);

      // Correct PIN
      final correctResult = await service.verifyPin('3590');
      expect(correctResult, true);
      expect(service.isLocked, false);
    });

    test('changePin updates PIN securely only with valid current PIN', () async {
      final service = AppLockService.instance;
      await service.enablePin('1111');

      // Attempt change with wrong current PIN
      final failChange = await service.changePin(
        currentPin: '9999',
        newPin: '2222',
      );
      expect(failChange, false);
      expect(await service.verifyPin('1111'), true);
      expect(await service.verifyPin('2222'), false);

      // Successful change
      final successChange = await service.changePin(
        currentPin: '1111',
        newPin: '2222',
      );
      expect(successChange, true);

      // Old PIN must no longer work
      expect(await service.verifyPin('1111'), false);
      // New PIN must work
      expect(await service.verifyPin('2222'), true);
    });

    test('disablePin removes credentials only with valid current PIN', () async {
      final service = AppLockService.instance;
      await service.enablePin('4567');
      expect(service.isLockEnabled, true);

      // Wrong PIN cannot disable
      final failDisable = await service.disablePin('0000');
      expect(failDisable, false);
      expect(service.isLockEnabled, true);

      // Correct PIN disables
      final successDisable = await service.disablePin('4567');
      expect(successDisable, true);
      expect(service.isLockEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('enx_app_lock_enabled'), false);
      expect(prefs.getString('enx_app_lock_pin_hash'), isNull);
      expect(prefs.getString('enx_app_lock_salt'), isNull);
    });

    test('setAutoLockDuration persists duration', () async {
      final service = AppLockService.instance;
      await service.setAutoLockDuration('5 Minutes');

      expect(service.autoLockDuration, '5 Minutes');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('enx_auto_lock_duration'), '5 Minutes');
    });

    test('onLogout resets session lock state safely', () async {
      final service = AppLockService.instance;
      await service.enablePin('9876');
      service.lockNow();
      expect(service.isLocked, true);

      service.onLogout();
      expect(service.isLocked, false);
      // Persistent security settings are maintained
      expect(service.isLockEnabled, true);
    });
  });
}
