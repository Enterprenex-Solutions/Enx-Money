import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/app_lock_service.dart';
import '../models/user_model.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/kyc_repository.dart';
import 'biometric_service.dart';

/// Thrown when login attempt requires approval from a primary device
class DeviceApprovalRequiredException implements Exception {
  final String approvalRequestId;
  final String verificationCode;
  final String deviceName;
  final String deviceId;
  final String message;
  final String identifier;

  DeviceApprovalRequiredException({
    required this.approvalRequestId,
    required this.verificationCode,
    required this.deviceName,
    required this.deviceId,
    required this.message,
    required this.identifier,
  });

  @override
  String toString() => message;
}

/// Thrown when login requires email OTP verification
class OtpVerificationRequiredException implements Exception {
  final String email;
  final String message;

  OtpVerificationRequiredException({
    required this.email,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Thrown when an email or mobile is already registered in ENX Money
class AlreadyRegisteredException implements Exception {
  final String message;
  final String? field; // 'email' | 'phone' | 'both'
  final dynamic data;

  AlreadyRegisteredException({
    this.message = 'This account is already registered.',
    this.field,
    this.data,
  });

  @override
  String toString() => message;
}

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final ApiClient _apiClient = ApiClient();
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  // Local storage keys
  static const _userKey = 'user_data';
  static const _loggedInKey = 'is_logged_in';

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // ─── Registration & Login ────────────────────────────────────────────

  /// Checks whether an email or phone number is already registered.
  /// Throws [AlreadyRegisteredException] if duplicate found.
  Future<bool> checkAccountAvailability({
    String? email,
    String? phone,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhone = phone?.trim();

    try {
      final body = <String, dynamic>{};
      if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
        body['email'] = normalizedEmail;
      }
      if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        body['phone'] = normalizedPhone;
      }

      final response = await _apiClient.post(
        ApiConfig.checkRegistered,
        body: body,
      );
      final data = response['data'] as Map<String, dynamic>?;
      final isRegistered = data?['isRegistered'] as bool? ?? false;
      if (isRegistered) {
        throw AlreadyRegisteredException(
          message: response['message'] as String? ?? 'This account is already registered.',
          field: data?['field'] as String?,
          data: data,
        );
      }
      return true;
    } on ConflictException catch (e) {
      throw AlreadyRegisteredException(
        message: e.message,
        field: e.field,
        data: e.data,
      );
    }
  }

  /// Registers a new user via backend API after OTP is verified.
  Future<UserModel> register({
    required String name,
    String? businessName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedMobile = mobile.trim();
    final trimmedName = name.trim();
    final trimmedBusinessName = (businessName ?? '').trim();
    final devicePayload = await DeviceService.getDevicePayload();

    try {
      final response = await _apiClient.post(
        ApiConfig.register,
        body: {
          'name': trimmedName,
          'businessName': trimmedBusinessName.isNotEmpty ? trimmedBusinessName : '$trimmedName\'s Enterprise',
          'email': normalizedEmail,
          'phone': normalizedMobile,
          'password': password,
          ...devicePayload,
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String?;

      if (accessToken != null) {
        _apiClient.setAuthToken(accessToken);
      }

      _currentUser = UserModel.fromJson(userJson, token: accessToken);
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      final userData = _currentUser!.toJson();
      await prefs.setString(_userKey, jsonEncode(userData));
      await prefs.setBool(_loggedInKey, true);
      return _currentUser!;
    } on ConflictException catch (e) {
      throw AlreadyRegisteredException(
        message: e.message,
        field: e.field,
        data: e.data,
      );
    }
  }

  /// Logs in with email/mobile and password via backend API.
  Future<bool> loginWithPassword(String emailOrMobile, String password) async {
    final input = emailOrMobile.trim();
    final devicePayload = await DeviceService.getDevicePayload();

    final response = await _apiClient.post(
      ApiConfig.login,
      body: {
        'identifier': input,
        'password': password,
        ...devicePayload,
      },
    );

    final data = (response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : response;

    if (data['requiresDeviceApproval'] == true) {
      throw DeviceApprovalRequiredException(
        approvalRequestId: data['approvalRequestId'] ?? '',
        verificationCode: data['verificationCode'] ?? '',
        deviceName: data['deviceName'] ?? devicePayload['deviceName'] ?? '',
        deviceId: data['deviceId'] ?? devicePayload['deviceId'] ?? '',
        message: response['message'] ?? 'Device approval required from your primary device.',
        identifier: input,
      );
    }

    if (data['requiresOtpVerification'] == true || response['requiresOtpVerification'] == true) {
      throw OtpVerificationRequiredException(
        email: (data['email'] as String?) ?? input,
        message: (response['message'] as String?) ?? 'Please verify your email address to continue.',
      );
    }

    final userJson = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : (data['user'] != null ? Map<String, dynamic>.from(data['user'] as Map) : null);

    if (userJson == null) {
      throw ApiException(message: response['message'] ?? 'Unable to complete sign in. Please try again.');
    }

    final accessToken = data['accessToken'] as String?;

    if (accessToken != null) {
      _apiClient.setAuthToken(accessToken);
    }

    _currentUser = UserModel.fromJson(userJson, token: accessToken);
    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    final userData = _currentUser!.toJson();
    await prefs.setString(_userKey, jsonEncode(userData));
    await prefs.setBool(_loggedInKey, true);
    return true;
  }

  /// Whether the user is currently logged in (persisted session).
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (loggedIn) {
      final user = await getLocalUser();
      return user != null;
    }
    return false;
  }

  /// Persists the logged-in session flag.
  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
    _isAuthenticated = value;
  }

  /// Loads the locally stored user profile into memory and restores auth token.
  Future<UserModel?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    final userData = jsonDecode(data) as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);
    _currentUser = user;
    _isAuthenticated = true;
    if (user.accessToken != null && user.accessToken!.isNotEmpty) {
      _apiClient.setAuthToken(user.accessToken);
    }
    return user;
  }

  // ─── OTP Authentication ────────────────────────────────────────────

  /// Send OTP to user's email or phone via backend API
  Future<Map<String, dynamic>> sendOtp(
    String? email, {
    String? phone,
    String purpose = 'AUTH',
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    final cleanPhone = phone?.trim();
    final body = <String, dynamic>{
      'purpose': purpose,
    };
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      body['email'] = normalizedEmail;
    }
    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      body['phone'] = cleanPhone;
    }

    try {
      final response = await _apiClient.post(
        ApiConfig.sendOtp,
        body: body,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {'email': normalizedEmail};
      return data;
    } on ConflictException catch (e) {
      throw AlreadyRegisteredException(
        message: e.message,
        field: e.field,
        data: e.data,
      );
    }
  }

  /// Resend OTP with cooldown handling via backend API
  Future<Map<String, dynamic>> resendOtp(
    String email, {
    String? phone,
    String purpose = 'AUTH',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final body = <String, dynamic>{
      'email': normalizedEmail,
      'purpose': purpose,
    };
    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }
    final response = await _apiClient.post(
      ApiConfig.resendOtp,
      body: body,
    );
    return response['data'] as Map<String, dynamic>? ?? {'email': normalizedEmail};
  }

  /// Verify 6-digit OTP and obtain JWT access token
  Future<UserModel> verifyOtp(
    String email,
    String otp, {
    String? phone,
    String? name,
    String? businessName,
    String? password,
    String? purpose,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();
    final resolvedPurpose = purpose ?? ((password != null && password.isNotEmpty) ? 'REGISTRATION' : 'AUTH');
    final body = <String, dynamic>{
      'email': normalizedEmail,
      'otp': cleanOtp,
      'purpose': resolvedPurpose,
    };
    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }
    if (businessName != null && businessName.trim().isNotEmpty) {
      body['businessName'] = businessName.trim();
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final devicePayload = await DeviceService.getDevicePayload();
    body.addAll(devicePayload);

    try {
      final response = await _apiClient.post(
        ApiConfig.verifyOtp,
        body: body,
      );

      final data = (response['data'] is Map<String, dynamic>)
          ? response['data'] as Map<String, dynamic>
          : response;

      if (data['requiresDeviceApproval'] == true) {
        throw DeviceApprovalRequiredException(
          approvalRequestId: data['approvalRequestId'] ?? '',
          verificationCode: data['verificationCode'] ?? '',
          deviceName: data['deviceName'] ?? devicePayload['deviceName'] ?? '',
          deviceId: data['deviceId'] ?? devicePayload['deviceId'] ?? '',
          message: response['message'] ?? 'Device approval required from your primary device.',
          identifier: normalizedEmail,
        );
      }

      final userJson = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : <String, dynamic>{
              'id': 'user_${normalizedEmail.hashCode.abs()}',
              'name': normalizedEmail.contains('@') ? normalizedEmail.split('@')[0] : 'User',
              'email': normalizedEmail,
              'phone': phone ?? '',
            };
      final accessToken = data['accessToken'] as String?;

      if (accessToken != null && accessToken.isNotEmpty) {
        _apiClient.setAuthToken(accessToken);
      }

      _currentUser = UserModel.fromJson(userJson, token: accessToken);
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      final userData = _currentUser!.toJson();
      await prefs.setString(_userKey, jsonEncode(userData));
      await prefs.setBool(_loggedInKey, true);

      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  /// Securely fetches authenticated user profile via GET /api/v1/user/profile using active JWT authorization token
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.get(ApiConfig.userProfile);
      final data = response['data'] as Map<String, dynamic>;
      final userJson = (data['user'] as Map<String, dynamic>?) ?? data;
      _currentUser = UserModel.fromJson(userJson);

      final prefs = await SharedPreferences.getInstance();
      final userData = _currentUser!.toJson();
      await prefs.setString(_userKey, jsonEncode(userData));
      return _currentUser!;
    } catch (_) {
      return getMe();
    }
  }

  /// Get current user profile
  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.get(ApiConfig.getMe);
      final data = response['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromJson(userJson);
      return _currentUser!;
    } catch (e) {
      if (_currentUser != null) return _currentUser!;
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch user profile: $e');
    }
  }

  /// Logout user and clear all session data
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConfig.logout);
    } catch (_) {
      // Ignored — always clear local session
    } finally {
      _apiClient.setAuthToken(null);
      _currentUser = null;
      _isAuthenticated = false;
      AppLockService.instance.onLogout();
      ProfileRepository().clear();
      KycRepository().clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, false);
      await prefs.remove(_userKey);
      await prefs.remove('enx_app_lock_pin');
      await prefs.remove('enx_biometric_enabled');
      await prefs.remove('enx_user_profile');
      await prefs.remove('enx_business_profile');
      await prefs.remove('user_full_profile_data');
      await prefs.remove('enx_kyc_status_data');
    }
  }

  /// Delete account on backend and wipe all local credentials (Google Play Policy Compliance)
  Future<void> deleteAccount() async {
    try {
      await _apiClient.delete(ApiConfig.deleteAccount);
    } catch (_) {
      // Ignore network errors to guarantee local wiping
    } finally {
      _apiClient.setAuthToken(null);
      _currentUser = null;
      _isAuthenticated = false;
      AppLockService.instance.onLogout();
      ProfileRepository().clear();
      KycRepository().clear();
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('enx_app_theme_mode');
      final lang = prefs.getString('enx_app_language');
      await prefs.clear();
      if (theme != null) await prefs.setString('enx_app_theme_mode', theme);
      if (lang != null) await prefs.setString('enx_app_language', lang);
      await prefs.setBool(_loggedInKey, false);
    }
  }

  /// Request OTP for forgotten password (accepts email or mobile)
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    final input = identifier.trim();
    final response = await _apiClient.post(
      ApiConfig.forgotPassword,
      body: {'identifier': input, 'email': input},
    );
    return response['data'] as Map<String, dynamic>? ?? {'identifier': input};
  }

  /// Verify OTP for password reset and obtain temporary resetToken
  Future<Map<String, dynamic>> verifyResetOtp(String identifier, String otp) async {
    final input = identifier.trim();
    final response = await _apiClient.post(
      ApiConfig.verifyResetOtp,
      body: {
        'identifier': input,
        'email': input,
        'otp': otp.trim(),
      },
    );
    return response['data'] as Map<String, dynamic>? ?? {'identifier': input};
  }

  /// Reset user password using verified resetToken or OTP
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    String? identifier,
    String? otp,
    String? resetToken,
    required String newPassword,
  }) async {
    final input = (identifier ?? email).trim();
    final body = <String, dynamic>{
      'identifier': input,
      'email': input,
      'newPassword': newPassword,
    };
    if (resetToken != null && resetToken.isNotEmpty) {
      body['resetToken'] = resetToken;
    }
    if (otp != null && otp.isNotEmpty) {
      body['otp'] = otp.trim();
    }

    final response = await _apiClient.post(
      ApiConfig.resetPassword,
      body: body,
    );
    return response['data'] as Map<String, dynamic>? ?? {'identifier': input};
  }

  // ─── Multi-Device Management & Approval ────────────────────────────

  /// Check approval status of a pending device login request
  Future<Map<String, dynamic>> checkDeviceApprovalStatus(String requestId) async {
    final response = await _apiClient.get(ApiConfig.deviceApprovalStatus(requestId));
    final data = (response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : response;

    if (data['status'] == 'APPROVED' && data['accessToken'] != null) {
      final accessToken = data['accessToken'] as String;
      _apiClient.setAuthToken(accessToken);
      final userJson = data['user'] as Map<String, dynamic>? ?? {};
      _currentUser = UserModel.fromJson(userJson, token: accessToken);
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      await prefs.setBool(_loggedInKey, true);
    }
    return data;
  }

  /// Get pending device approvals for the current user
  Future<List<Map<String, dynamic>>> getPendingDeviceApprovals() async {
    final response = await _apiClient.get(ApiConfig.pendingDeviceApprovals);
    final data = response['data'];
    if (data is Map<String, dynamic> && data['pendingApprovals'] is List) {
      return (data['pendingApprovals'] as List).cast<Map<String, dynamic>>();
    }
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Approve a pending device login request
  Future<bool> approveDevice(String requestId) async {
    final response = await _apiClient.post(
      ApiConfig.approveDevice,
      body: {'requestId': requestId},
    );
    return response['success'] == true;
  }

  /// Reject a pending device login request
  Future<bool> rejectDevice(String requestId) async {
    final response = await _apiClient.post(
      ApiConfig.rejectDevice,
      body: {'requestId': requestId},
    );
    return response['success'] == true;
  }

  /// Get all registered devices for the current user
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    final response = await _apiClient.get(ApiConfig.userDevices);
    final data = response['data'];
    if (data is Map<String, dynamic> && data['devices'] is List) {
      return (data['devices'] as List).cast<Map<String, dynamic>>();
    }
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Revoke an approved device
  Future<bool> revokeDevice(String deviceId) async {
    final response = await _apiClient.delete(ApiConfig.revokeDevice(deviceId));
    return response['success'] == true;
  }

  /// App lock PIN verification — delegates to AppLockService (salted SHA-256)
  Future<bool> verifyPin(String pin) async {
    return AppLockService.instance.verifyPin(pin);
  }

  /// Update app lock PIN — delegates to AppLockService (salted SHA-256)
  Future<void> setAppLockPin(String pin) async {
    await AppLockService.instance.enablePin(pin);
  }

  /// Local biometric authentication verification
  Future<bool> verifyBiometric({String reason = 'Authenticate to access ENX Money'}) async {
    return BiometricService.instance.authenticate(reason: reason);
  }

  /// Verifies current account password against backend
  Future<bool> verifyPassword(String password) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.verifyPassword,
        body: {'password': password},
      );
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Security Questions
  // ─────────────────────────────────────────────────────────────────────

  /// Fetch the standard security question catalog
  Future<List<Map<String, dynamic>>> fetchSecurityQuestionsCatalog() async {
    final response = await _apiClient.get(ApiConfig.securityQuestionsCatalog);
    final questions = response['data']?['questions'] as List<dynamic>? ?? [];
    return questions.cast<Map<String, dynamic>>();
  }

  /// Setup security questions for the current authenticated user
  Future<void> setupSecurityQuestions(
    List<Map<String, String>> questionsAndAnswers,
  ) async {
    await _apiClient.post(
      ApiConfig.securityQuestionsSetup,
      body: {'questions': questionsAndAnswers},
    );
  }

  /// Fetch configured security questions for a given email / phone (no auth needed)
  Future<List<Map<String, dynamic>>> fetchQuestionsForUser(String identifier) async {
    final response = await _apiClient.post(
      ApiConfig.securityQuestionsForUser,
      body: {'identifier': identifier},
    );
    final questions = response['data']?['questions'] as List<dynamic>? ?? [];
    return questions.cast<Map<String, dynamic>>();
  }

  /// Verify security question answers and obtain a short-lived resetToken
  Future<String> verifySecurityAnswers({
    required String identifier,
    required List<Map<String, String>> answers,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.securityQuestionsVerify,
      body: {'identifier': identifier, 'answers': answers},
    );
    final token = response['data']?['resetToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Verification failed. Please check your answers.');
    }
    return token;
  }

  /// Changes the user's account password with their current password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.changePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return response['success'] == true;
  }
}
