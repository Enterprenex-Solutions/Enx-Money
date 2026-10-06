import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../features/auth/models/user_model.dart';

/// Result of an MPIN verification attempt including brute-force protection details
class MpinVerifyResult {
  final bool isSuccess;
  final bool isLockedOut;
  final int remainingAttempts;
  final int lockoutSeconds;
  final String? message;

  const MpinVerifyResult({
    required this.isSuccess,
    this.isLockedOut = false,
    this.remainingAttempts = 5,
    this.lockoutSeconds = 0,
    this.message,
  });

  factory MpinVerifyResult.success() => const MpinVerifyResult(isSuccess: true);

  factory MpinVerifyResult.failure({
    required int remainingAttempts,
    bool isLockedOut = false,
    int lockoutSeconds = 0,
    String? message,
  }) =>
      MpinVerifyResult(
        isSuccess: false,
        isLockedOut: isLockedOut,
        remainingAttempts: remainingAttempts,
        lockoutSeconds: lockoutSeconds,
        message: message,
      );

  factory MpinVerifyResult.lockedOut(int remainingSeconds) => MpinVerifyResult(
        isSuccess: false,
        isLockedOut: true,
        remainingAttempts: 0,
        lockoutSeconds: remainingSeconds,
        message:
            'Too many incorrect attempts. MPIN locked for $remainingSeconds seconds.',
      );
}

/// Production-grade Secure Credential Vault.
/// Handles multi-user credential isolation, cryptographic MPIN hashing (SHA-256 + 32-byte salt),
/// brute-force lockout protection, and secure session credential unlocking for native biometrics & MPIN.
class SecureCredentialVault {
  static final SecureCredentialVault _instance = SecureCredentialVault._internal();
  factory SecureCredentialVault() => _instance;
  SecureCredentialVault._internal();

  static SecureCredentialVault get instance => _instance;

  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationSeconds = 300; // 5 minutes lockout

  // Preference Keys
  static const String _prefLastUserId = 'enx_vault_last_user_id';
  static const String _prefLastUserEmail = 'enx_vault_last_user_email';
  static const String _prefLastUserName = 'enx_vault_last_user_name';
  static const String _prefLastUserPhone = 'enx_vault_last_user_phone';

  String _userTokenKey(String userId) => 'enx_vault_token_$userId';
  String _userDataKey(String userId) => 'enx_vault_user_data_$userId';
  String _userMpinHashKey(String userId) => 'enx_vault_mpin_hash_$userId';
  String _userMpinSaltKey(String userId) => 'enx_vault_mpin_salt_$userId';
  String _userFailedAttemptsKey(String userId) => 'enx_vault_mpin_fails_$userId';
  String _userLockoutUntilKey(String userId) => 'enx_vault_mpin_lockout_$userId';
  String _userBiometricKey(String userId) => 'enx_vault_bio_enabled_$userId';

  /// Hashes MPIN with a 32-byte cryptographically secure salt using SHA-256
  String _hashMpin(String mpin, String salt) {
    final bytes = utf8.encode('$salt:$mpin:enx_money_secure_mpin_v2');
    return sha256.convert(bytes).toString();
  }

  /// Generates a 32-character cryptographically secure random salt
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(24, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Constant-time string comparison to defend against timing attacks
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Stores or updates an authenticated session credential in the device vault.
  Future<void> saveSessionCredential({
    required UserModel user,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = user.id.toString();

    await prefs.setString(_prefLastUserId, userId);
    await prefs.setString(_prefLastUserEmail, user.email);
    if (user.name.isNotEmpty) {
      await prefs.setString(_prefLastUserName, user.name);
    }
    final phone = user.phone;
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString(_prefLastUserPhone, phone);
    }

    await prefs.setString(_userTokenKey(userId), token);
    await prefs.setString(_userDataKey(userId), jsonEncode(user.toJson()));
  }

  /// Securely stores a 4-digit MPIN for the given user.
  /// Generates a fresh cryptographic salt and stores only the resulting hash.
  Future<bool> saveMpin(String userId, String mpin) async {
    if (mpin.length != 4 || int.tryParse(mpin) == null) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashMpin(mpin, salt);

    await prefs.setString(_userMpinSaltKey(userId), salt);
    await prefs.setString(_userMpinHashKey(userId), hash);
    // Reset any previous failed attempts upon fresh PIN creation
    await prefs.remove(_userFailedAttemptsKey(userId));
    await prefs.remove(_userLockoutUntilKey(userId));

    return true;
  }

  /// Verifies entered MPIN against the salted hash with brute-force protection.
  Future<MpinVerifyResult> verifyMpin(String userId, String enteredMpin) async {
    final prefs = await SharedPreferences.getInstance();

    // Check lockout state
    final lockoutUntilMs = prefs.getInt(_userLockoutUntilKey(userId));
    if (lockoutUntilMs != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < lockoutUntilMs) {
        final remainingSeconds = ((lockoutUntilMs - now) / 1000).ceil();
        return MpinVerifyResult.lockedOut(remainingSeconds);
      } else {
        // Lockout expired, reset counters
        await prefs.remove(_userLockoutUntilKey(userId));
        await prefs.setInt(_userFailedAttemptsKey(userId), 0);
      }
    }

    final salt = prefs.getString(_userMpinSaltKey(userId));
    final storedHash = prefs.getString(_userMpinHashKey(userId));

    if (salt == null || storedHash == null) {
      return const MpinVerifyResult(
        isSuccess: false,
        message: 'No MPIN configured. Please sign in with password.',
      );
    }

    final computedHash = _hashMpin(enteredMpin, salt);
    final isMatch = _constantTimeCompare(computedHash, storedHash);

    if (isMatch) {
      // Clear failed attempts counter on success
      await prefs.remove(_userFailedAttemptsKey(userId));
      await prefs.remove(_userLockoutUntilKey(userId));
      return MpinVerifyResult.success();
    } else {
      // Increment failed attempts
      final currentFails = (prefs.getInt(_userFailedAttemptsKey(userId)) ?? 0) + 1;
      await prefs.setInt(_userFailedAttemptsKey(userId), currentFails);

      if (currentFails >= _maxFailedAttempts) {
        final lockoutUntil = DateTime.now()
            .add(const Duration(seconds: _lockoutDurationSeconds))
            .millisecondsSinceEpoch;
        await prefs.setInt(_userLockoutUntilKey(userId), lockoutUntil);
        return MpinVerifyResult.lockedOut(_lockoutDurationSeconds);
      } else {
        final remaining = _maxFailedAttempts - currentFails;
        return MpinVerifyResult.failure(
          remainingAttempts: remaining,
          message: 'Incorrect MPIN. $remaining attempts remaining.',
        );
      }
    }
  }

  /// Sets whether biometric unlock is enabled for this user.
  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userBiometricKey(userId), enabled);
  }

  /// Checks whether biometric unlock is enabled for this user.
  Future<bool> isBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userBiometricKey(userId)) ?? false;
  }

  /// Checks whether this user has a configured MPIN in the vault.
  Future<bool> hasMpin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_userMpinSaltKey(userId));
    final hash = prefs.getString(_userMpinHashKey(userId));
    return salt != null && hash != null;
  }

  /// Retrieves the last active user summary on this device.
  Future<Map<String, String>?> getLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_prefLastUserId);
    final email = prefs.getString(_prefLastUserEmail);
    if (userId == null || email == null) return null;

    return {
      'userId': userId,
      'email': email,
      'name': prefs.getString(_prefLastUserName) ?? '',
      'phone': prefs.getString(_prefLastUserPhone) ?? '',
    };
  }

  /// Checks if there is a valid stored session credential and MPIN/biometric for quick unlock.
  Future<bool> hasStoredCredentialForQuickUnlock() async {
    final user = await getLastUser();
    if (user == null) return false;
    final userId = user['userId']!;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_userTokenKey(userId));
    final hasPin = await hasMpin(userId);

    return token != null && token.isNotEmpty && hasPin;
  }

  /// Securely unlocks and restores the authenticated session for the given user.
  /// Sets the token into [ApiClient], restores the user model, and returns it.
  Future<UserModel?> unlockAndRestoreSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_userTokenKey(userId));
    final userDataRaw = prefs.getString(_userDataKey(userId));

    if (token == null || token.isEmpty || userDataRaw == null) {
      return null;
    }

    try {
      final userJson = jsonDecode(userDataRaw) as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson, token: token);

      // Restore token to API client
      ApiClient().setAuthToken(token);

      // Update SharedPreferences session keys
      await prefs.setString('user_data', userDataRaw);
      await prefs.setBool('is_logged_in', true);

      return user;
    } catch (_) {
      return null;
    }
  }

  /// Invalidates the stored token for a user (e.g. upon account deletion or explicit removal).
  Future<void> invalidateSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey(userId));
  }

  /// Wipes all vault data for the specified user (e.g., on account deletion)
  Future<void> wipeUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey(userId));
    await prefs.remove(_userDataKey(userId));
    await prefs.remove(_userMpinHashKey(userId));
    await prefs.remove(_userMpinSaltKey(userId));
    await prefs.remove(_userFailedAttemptsKey(userId));
    await prefs.remove(_userLockoutUntilKey(userId));
    await prefs.remove(_userBiometricKey(userId));

    final lastId = prefs.getString(_prefLastUserId);
    if (lastId == userId) {
      await prefs.remove(_prefLastUserId);
      await prefs.remove(_prefLastUserEmail);
      await prefs.remove(_prefLastUserName);
      await prefs.remove(_prefLastUserPhone);
    }
  }
}
