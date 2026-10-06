import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/auth_repository.dart';

/// Production-grade App Lock & PIN Security Service
/// Enforces salted cryptographic hashing, zero-plaintext PIN storage,
/// lifecycle background/foreground auto-locking, and secure state management.
class AppLockService extends ChangeNotifier {
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  static AppLockService get instance => _instance;

  static const String _prefEnabledKey = 'enx_app_lock_enabled';
  static const String _prefHashKey = 'enx_app_lock_pin_hash';
  static const String _prefSaltKey = 'enx_app_lock_salt';
  static const String _prefDurationKey = 'enx_auto_lock_duration';
  static const String _prefBiometricKey = 'enx_biometric_enabled';

  /// Strict 30-Minute background session timeout in minutes
  static const double sessionGracePeriodMinutes = 30.0;

  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isLocked = false;
  bool _isAuthenticated = false;
  bool _isAppUnlocked = false; // Global auth session unlock state
  bool _isAuthenticatingBiometric = false;
  String _autoLockDuration = '30 Minutes';
  String? _storedHash;
  String? _storedSalt;
  int? lastActiveTimestamp; // in millisecondsSinceEpoch
  bool _isInitialized = false;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool get isLockEnabled => _isLockEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAnyLockActive => _isLockEnabled || _isBiometricEnabled;
  bool get isLocked => _isLocked;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAppUnlocked => _isAppUnlocked;
  bool get isAuthenticatingBiometric => _isAuthenticatingBiometric;
  String get autoLockDuration => _autoLockDuration;
  bool get isInitialized => _isInitialized;

  set isAppUnlocked(bool val) {
    _isAppUnlocked = val;
    if (val) {
      _isLocked = false;
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  /// Sets whether the native biometric scanner prompt is actively open on screen.
  /// When active, Android activity pause/resume events will NOT trigger session auto-lock.
  void setBiometricPromptActive(bool active) {
    _isAuthenticatingBiometric = active;
    if (active) {
      lastActiveTimestamp = null;
    }
  }

  /// Sets authenticated state directly
  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    if (value) {
      _isAppUnlocked = true;
      _isLocked = false;
      lastActiveTimestamp = null;
      _isAuthenticatingBiometric = false;
    } else {
      _isAppUnlocked = false;
    }
    notifyListeners();
  }

  /// Loads security state from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLockEnabled = prefs.getBool(_prefEnabledKey) ?? false;
    _isBiometricEnabled = prefs.getBool(_prefBiometricKey) ?? false;
    _storedHash = prefs.getString(_prefHashKey);
    _storedSalt = prefs.getString(_prefSaltKey);
    _autoLockDuration = prefs.getString(_prefDurationKey) ?? '30 Minutes';
    lastActiveTimestamp = null;
    _isLocked = false;
    _isAppUnlocked = false; // Reset on cold start / app kill

    // Fallback sync with profile cache if biometric key wasn't written yet
    if (!_isBiometricEnabled) {
      final profileStr = prefs.getString('user_full_profile_data');
      if (profileStr != null && profileStr.contains('"isBiometricEnabled":true')) {
        _isBiometricEnabled = true;
        await prefs.setBool(_prefBiometricKey, true);
      }
    }

    // If PIN enabled but missing credentials, reset for security
    if (_isLockEnabled && (_storedHash == null || _storedSalt == null)) {
      _isLockEnabled = false;
      await prefs.setBool(_prefEnabledKey, false);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Sets biometric lock preference
  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBiometricKey, enabled);
    notifyListeners();
  }

  /// Cryptographically hashes a PIN using SHA-256 with a unique random salt
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin:enx_money_secure_lock');
    return sha256.convert(bytes).toString();
  }

  /// Generates a cryptographically secure 32-character random salt
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(24, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Enables App Lock with a newly chosen 4-digit PIN
  Future<bool> enablePin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return false;
    }

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, true);
    await prefs.setString(_prefSaltKey, salt);
    await prefs.setString(_prefHashKey, hash);

    _isLockEnabled = true;
    _storedSalt = salt;
    _storedHash = hash;
    _isLocked = false;

    notifyListeners();
    return true;
  }

  /// Verifies entered PIN against the salted hash in constant-time
  Future<bool> verifyPin(String enteredPin) async {
    if (!_isLockEnabled || _storedSalt == null || _storedHash == null) {
      return false;
    }

    final enteredHash = _hashPin(enteredPin, _storedSalt!);
    final isMatch = _constantTimeCompare(enteredHash, _storedHash!);

    if (isMatch) {
      _isAppUnlocked = true;
      _isLocked = false;
      _isAuthenticated = true;
      lastActiveTimestamp = null;
      _isAuthenticatingBiometric = false;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Changes the existing PIN after verifying the current PIN
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final isCurrentValid = await verifyPin(currentPin);
    if (!isCurrentValid) {
      return false;
    }

    return await enablePin(newPin);
  }

  /// Disables App Lock after verifying the current PIN
  Future<bool> disablePin(String currentPin) async {
    final isCurrentValid = await verifyPin(currentPin);
    if (!isCurrentValid) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, false);
    await prefs.remove(_prefSaltKey);
    await prefs.remove(_prefHashKey);

    _isLockEnabled = false;
    _storedSalt = null;
    _storedHash = null;
    _isLocked = false;
    _isAppUnlocked = true;

    notifyListeners();
    return true;
  }

  /// Updates Auto-Lock duration setting
  Future<void> setAutoLockDuration(String duration) async {
    _autoLockDuration = duration;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDurationKey, duration);
    notifyListeners();
  }

  /// Immediately puts the app into a locked state (if enabled)
  void lockNow() {
    if (isAnyLockActive) {
      _isAppUnlocked = false;
      _isLocked = true;
      _isAuthenticated = false;
      lastActiveTimestamp = null;
      notifyListeners();
    }
  }

  /// Marks the app as locked without broadcasting to listeners.
  /// Use during app startup / splash to avoid race conditions where the
  /// main.dart listener and the splash navigator both push a lock screen.
  void lockSilently() {
    if (isAnyLockActive) {
      _isAppUnlocked = false;
      _isLocked = true;
      _isAuthenticated = false;
      lastActiveTimestamp = null;
      // intentionally no notifyListeners()
    }
  }

  /// Unlocks the session upon correct PIN or biometric challenge.
  /// Once successfully unlocked, sets isAppUnlocked = true to allow
  /// completely unrestricted access to all internal screens and actions.
  void unlock() {
    _isAppUnlocked = true;
    _isLocked = false;
    _isAuthenticated = true;
    lastActiveTimestamp = null;
    _isAuthenticatingBiometric = false;
    notifyListeners();
  }

  /// App lifecycle: app transitions to 'background' or 'inactive'.
  /// Records the exact timestamp (Date.now()) for grace period calculation.
  void onAppPaused() {
    if (_isAuthenticatingBiometric) {
      return;
    }
    if (isAnyLockActive) {
      lastActiveTimestamp = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// App lifecycle: app transitions back to 'active' (Resume).
  /// Strictly enforces a 30-minute background session timeout:
  /// - If elapsed time < 30 minutes: keep isAppUnlocked = true and return to active screen immediately.
  /// - If elapsed time >= 30 minutes: set isAppUnlocked = false, lock the view, and prompt for fingerprint authentication.
  Future<void> onAppResumed({int? mockCurrentTimeMs}) async {
    if (_isAuthenticatingBiometric) {
      return;
    }

    if (!isAnyLockActive) {
      _isAppUnlocked = true;
      _isLocked = false;
      _isAuthenticated = true;
      lastActiveTimestamp = null;
      return;
    }

    final isLoggedIn = await AuthRepository().isLoggedIn();
    if (!isLoggedIn) {
      _isAppUnlocked = false;
      _isLocked = false;
      _isAuthenticated = false;
      lastActiveTimestamp = null;
      return;
    }

    // If app wasn't backgrounded or no timestamp was recorded, retain current unlocked state
    if (lastActiveTimestamp == null) {
      return;
    }

    final nowMs = mockCurrentTimeMs ?? DateTime.now().millisecondsSinceEpoch;
    final minutesInBg = (nowMs - lastActiveTimestamp!) / (1000 * 60);

    debugPrint('[AppLockService] onAppResumed: $minutesInBg min in background. Threshold: $sessionGracePeriodMinutes min. Previous isAppUnlocked: $_isAppUnlocked');

    if (minutesInBg < sessionGracePeriodMinutes) {
      // 30-Minute Grace Period: Keep isAppUnlocked = true and return to active screen immediately
      _isAppUnlocked = true;
      _isLocked = false;
      _isAuthenticated = true;
      lastActiveTimestamp = null;
      // Return cleanly to active screen WITHOUT prompting for fingerprint
      return;
    }

    // Exceeded 30 minutes: Set isAppUnlocked = false, lock the view, and prompt for fingerprint authentication
    _isAppUnlocked = false;
    _isLocked = true;
    _isAuthenticated = false;
    lastActiveTimestamp = null;
    notifyListeners();
  }

  /// Reset isAppUnlocked = false ONLY when the user explicitly logs out or completely closes (kills) the application process.
  void onLogout() {
    _isAppUnlocked = false;
    _isLocked = false;
    _isAuthenticated = false;
    lastActiveTimestamp = null;
    _isAuthenticatingBiometric = false;
    notifyListeners();
  }
}
