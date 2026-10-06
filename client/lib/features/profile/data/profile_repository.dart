import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/services/app_lock_service.dart';

class ProfileRepository extends ChangeNotifier {
  static final ProfileRepository _instance = ProfileRepository._internal();
  factory ProfileRepository() => _instance;
  ProfileRepository._internal();

  static const String _profileKey = 'user_full_profile_data';
  UserProfileModel _profile = const UserProfileModel();
  bool _isLoaded = false;

  UserProfileModel get profile => _profile;
  bool get isLoaded => _isLoaded;

  /// Loads the profile from local storage and synchronizes with live backend Auth / Me API
  Future<UserProfileModel> loadProfile({bool fetchFromApi = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);

    if (data != null) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _profile = UserProfileModel.fromJson(json);
        _isLoaded = true;
        notifyListeners();
      } catch (_) {}
    }

    // Pre-populate from AuthRepository current user if available in memory
    final authUser = AuthRepository().currentUser ?? await AuthRepository().getLocalUser();
    if (authUser != null) {
      syncFromUser(authUser);
    }

    // Fetch latest authoritative profile from backend /api/v1/user/profile (or /api/auth/me)
    if (fetchFromApi) {
      try {
        final liveUser = await AuthRepository().getUserProfile();
        syncFromUser(liveUser);
      } catch (e) {
        debugPrint('[ProfileRepository] Live profile sync notice: $e');
      }
    }

    if (AppLockService.instance.isLockEnabled && _profile.appLockPin.isEmpty) {
      _profile = _profile.copyWith(appLockPin: '****');
    }

    _isLoaded = true;
    notifyListeners();
    return _profile;
  }

  /// Synchronizes profile state directly from an authenticated UserModel
  void syncFromUser(dynamic user) {
    final isVerified = user.isEmailVerified == true;
    _profile = _profile.copyWith(
      fullName: (user.fullName != null && (user.fullName as String).isNotEmpty)
          ? user.fullName
          : (user.name ?? _profile.fullName),
      email: (user.email != null && (user.email as String).isNotEmpty)
          ? user.email
          : _profile.email,
      mobileNumber: (user.mobileNumber != null && (user.mobileNumber as String).isNotEmpty)
          ? user.mobileNumber!
          : _profile.mobileNumber,
      isEmailVerified: isVerified,
      kycTier: isVerified ? 'VERIFIED' : 'NOT VERIFIED',
    );
    _persist();
    notifyListeners();
  }

  /// Updates personal info fields
  Future<void> updatePersonalInfo({
    required String fullName,
    required String email,
    required String mobileNumber,
    String? profilePhoto,
    String? dateOfBirth,
    String? gender,
    String? addressState,
    String? addressDistrict,
    String? addressCity,
    String? addressPincode,
    String? preferredLanguage,
    String? monthlyIncome,
    String? currency,
  }) async {
    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      mobileNumber: mobileNumber.trim(),
      profilePhoto: profilePhoto ?? _profile.profilePhoto,
      dateOfBirth: dateOfBirth ?? _profile.dateOfBirth,
      gender: gender ?? _profile.gender,
      addressState: addressState ?? _profile.addressState,
      addressDistrict: addressDistrict ?? _profile.addressDistrict,
      addressCity: addressCity ?? _profile.addressCity,
      addressPincode: addressPincode ?? _profile.addressPincode,
      selectedLanguage: preferredLanguage ?? _profile.selectedLanguage,
      monthlyIncome: monthlyIncome ?? _profile.monthlyIncome,
      currency: currency ?? _profile.currency,
    );
    await _persist();
    notifyListeners();
  }

  /// Updates business profile details
  Future<void> updateBusinessProfile(BusinessProfileModel businessProfile) async {
    _profile = _profile.copyWith(
      businessProfile: businessProfile,
    );
    await _persist();
    notifyListeners();
  }

  /// Updates security settings
  Future<void> updateSecurity({
    String? pin,
    bool? hasPasswordSet,
    bool? isBiometricEnabled,
    bool? hasSecurityQuestions,
    String? autoLockDuration,
  }) async {
    if (isBiometricEnabled != null) {
      AppLockService.instance.setBiometricEnabled(isBiometricEnabled);
    }
    _profile = _profile.copyWith(
      appLockPin: pin ?? _profile.appLockPin,
      hasPasswordSet: hasPasswordSet ?? _profile.hasPasswordSet,
      isBiometricEnabled: isBiometricEnabled ?? _profile.isBiometricEnabled,
      hasSecurityQuestions: hasSecurityQuestions ?? _profile.hasSecurityQuestions,
      autoLockDuration: autoLockDuration ?? _profile.autoLockDuration,
    );
    await _persist();
    notifyListeners();
  }

  /// Removes an active login device
  Future<void> revokeDevice(String deviceId) async {
    final updatedList = _profile.activeDevices.where((d) => d.id != deviceId).toList();
    _profile = _profile.copyWith(activeDevices: updatedList);
    await _persist();
    notifyListeners();
  }

  /// Revokes all active devices except current device
  Future<void> revokeOtherDevices() async {
    final currentOnly = _profile.activeDevices.where((d) => d.isCurrent).toList();
    _profile = _profile.copyWith(activeDevices: currentOnly);
    await _persist();
    notifyListeners();
  }

  /// Updates app preferences
  Future<void> updatePreferences({
    bool? pushNotifications,
    bool? emailAlerts,
    bool? smsAlerts,
    String? selectedLanguage,
  }) async {
    _profile = _profile.copyWith(
      pushNotifications: pushNotifications ?? _profile.pushNotifications,
      emailAlerts: emailAlerts ?? _profile.emailAlerts,
      smsAlerts: smsAlerts ?? _profile.smsAlerts,
      selectedLanguage: selectedLanguage ?? _profile.selectedLanguage,
    );
    await _persist();
    notifyListeners();
  }

  /// Completely clears user profile data from memory and storage on logout
  Future<void> clearSession() async {
    _profile = const UserProfileModel();
    _isLoaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    notifyListeners();
  }

  /// In-memory clear
  void clear() {
    _profile = const UserProfileModel();
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_profile.toJson()));
  }
}
