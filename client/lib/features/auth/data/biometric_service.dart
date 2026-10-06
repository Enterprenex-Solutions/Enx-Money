import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Status of biometric hardware and enrollment on the user device
enum BiometricStatus {
  available,
  notEnrolled,
  notSupported,
}

/// Production wrapper around the [local_auth] plugin for biometric authentication.
class BiometricService {
  BiometricService._internal({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  static BiometricService instance = BiometricService._internal();
  factory BiometricService() => instance;

  final LocalAuthentication _auth;

  /// User-facing notice when device supports biometrics but none are enrolled
  static const String notEnrolledMessage =
      'No biometrics enrolled. Please set up Fingerprint/Face ID in your device settings.';

  /// Factory for testing with mock [LocalAuthentication]
  @visibleForTesting
  static BiometricService createForTesting(LocalAuthentication auth) {
    return BiometricService._internal(auth: auth);
  }

  /// Whether the device hardware possesses biometric capability
  Future<bool> hasHardware() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has enrolled at least one biometric credential (fingerprint/face)
  Future<bool> isEnrolled() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Full capability and enrollment evaluation:
  /// - [BiometricStatus.notSupported] if no sensor hardware exists
  /// - [BiometricStatus.notEnrolled] if hardware exists but 0 prints/faces enrolled
  /// - [BiometricStatus.available] if hardware exists and is ready to authenticate
  Future<BiometricStatus> checkBiometricStatus() async {
    try {
      final hardwareReady = await hasHardware();
      if (!hardwareReady) {
        return BiometricStatus.notSupported;
      }

      final enrolled = await isEnrolled();
      if (!enrolled) {
        return BiometricStatus.notEnrolled;
      }

      return BiometricStatus.available;
    } catch (_) {
      return BiometricStatus.notSupported;
    }
  }

  /// Convenience check: returns `true` ONLY if biometrics are supported and enrolled
  Future<bool> isBiometricAvailable() async {
    final status = await checkBiometricStatus();
    return status == BiometricStatus.available;
  }

  /// Lists the enrolled biometric types available on this device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Prompts the user with native biometric dialog.
  /// Returns `true` if authentication succeeded.
  /// Returns `false` upon user cancellation or failure without throwing.
  Future<bool> authenticate({
    String reason = 'Authenticate to access ENX Money',
    bool biometricOnly = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

