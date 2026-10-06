import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/device_service.dart';
import '../../auth/data/auth_repository.dart';
import 'profile_repository.dart';
import '../models/kyc_identity_model.dart';

class KycRepository extends ChangeNotifier {
  static final KycRepository _instance = KycRepository._internal();
  factory KycRepository() => _instance;
  KycRepository._internal();

  final ApiClient _apiClient = ApiClient();
  KycIdentityModel? _kycStatus;

  KycIdentityModel? get kycStatus => _kycStatus;

  /// Resolves the authenticated user's registered name dynamically
  String _resolveUserName([String? candidate]) {
    if (candidate != null && candidate.trim().isNotEmpty && candidate != 'P. Revanth Reddy' && candidate != 'Verified User') {
      return candidate.trim();
    }
    final authUser = AuthRepository().currentUser;
    if (authUser?.fullName != null && authUser!.fullName.trim().isNotEmpty) {
      return authUser.fullName.trim();
    }
    if (authUser?.name != null && authUser!.name.trim().isNotEmpty) {
      return authUser.name.trim();
    }
    final profileName = ProfileRepository().profile.fullName.trim();
    if (profileName.isNotEmpty && profileName != 'P. Revanth Reddy') {
      return profileName;
    }
    return 'Authorized User';
  }

  /// Generates a consistent 8-digit digital identity tag per user ID
  static String generateDigitalId(String? userId, [String? seed]) {
    final cleanId = (userId != null && userId.isNotEmpty && userId != '0')
        ? userId
        : (seed ?? '1');
    final hash = cleanId.hashCode.abs();
    final p1 = (hash % 9000 + 1000).toString();
    final p2 = ((hash ~/ 9000) % 9000 + 1000).toString();
    return 'ENX-ID-$p1-$p2';
  }

  /// Resolves device tag using native metrics
  Future<String> _resolveDeviceTag() async {
    try {
      final model = await DeviceInfo.getModel();
      if (model.isNotEmpty && model != 'Android Device' && model != 'Mobile Device') {
        return 'DEV-${model.toUpperCase().replaceAll(' ', '-')}';
      }
    } catch (_) {}
    return 'DEV-ANDROID-UNIVERSAL';
  }

  /// Clears in-memory KYC status completely on user logout
  void clear() {
    _kycStatus = null;
    notifyListeners();
  }

  /// 1. Fetch current KYC status from backend
  Future<KycIdentityModel> getKycStatus() async {
    final userId = AuthRepository().currentUser?.id ?? '1';
    final dynamicName = _resolveUserName();
    final dynamicDevice = await _resolveDeviceTag();
    final dynamicId = generateDigitalId(userId, AuthRepository().currentUser?.email);

    try {
      final res = await _apiClient.get('/api/kyc/status');
      if (res['data'] != null) {
        _kycStatus = KycIdentityModel.fromJson(
          res['data'] as Map<String, dynamic>,
          fallbackName: dynamicName,
          fallbackDevice: dynamicDevice,
          fallbackDigitalId: dynamicId,
        );
        notifyListeners();
        return _kycStatus!;
      }
    } catch (e) {
      debugPrint('[KycRepository getKycStatus] Remote API note: $e');
    }

    _kycStatus ??= KycIdentityModel(
      userId: userId,
      tier: 'TIER_1_BASIC',
      kycStatus: 'NOT_VERIFIED',
      digilockerStatus: 'NOT_STARTED',
      aadhaarStatus: 'NOT_VERIFIED',
      panStatus: 'NOT_VERIFIED',
      isAadhaarVerified: false,
      isPanVerified: false,
      isBiometricBound: false,
      isDigilockerConnected: false,
      digitalIdentityNumber: dynamicId,
      verifiedName: dynamicName,
      deviceId: dynamicDevice,
      simSlot: 'SIM 1 (Active)',
      simActive: true,
      hardwareKeystoreBound: false,
    );
    notifyListeners();
    return _kycStatus!;
  }

  /// 2. Start official DigiLocker KYC session
  Future<Map<String, dynamic>> startDigiLockerKyc({String? redirectUri}) async {
    final res = await _apiClient.post('/api/kyc/start', body: {
      if (redirectUri != null) 'redirectUri': redirectUri,
    });
    if (res['data'] != null) {
      final userId = AuthRepository().currentUser?.id ?? '1';
      final dynamicName = _resolveUserName();
      final dynamicDevice = await _resolveDeviceTag();
      final dynamicId = generateDigitalId(userId);

      _kycStatus = KycIdentityModel.fromJson(
        res['data'] as Map<String, dynamic>,
        fallbackName: dynamicName,
        fallbackDevice: dynamicDevice,
        fallbackDigitalId: dynamicId,
      );
      notifyListeners();
    }
    return res;
  }

  /// 3. Initiate Real Aadhaar OTP via Authorized Provider
  Future<Map<String, dynamic>> initiateAadhaarOtp(String aadhaarNumber) async {
    final res = await _apiClient.post('/api/kyc/aadhaar/start', body: {
      'aadhaarNumber': aadhaarNumber,
    });
    return (res['data'] as Map<String, dynamic>?) ?? res;
  }

  /// 4. Verify Real Aadhaar OTP via Authorized Provider
  Future<KycIdentityModel> verifyAadhaarOtp(String requestId, String otp) async {
    final userId = AuthRepository().currentUser?.id ?? _kycStatus?.userId ?? '1';
    final dynamicName = _resolveUserName(_kycStatus?.verifiedName);
    final dynamicDevice = _kycStatus?.deviceId ?? await _resolveDeviceTag();
    final dynamicId = _kycStatus?.digitalIdentityNumber ?? generateDigitalId(userId);

    final res = await _apiClient.post('/api/kyc/aadhaar/verify', body: {
      'requestId': requestId,
      'otp': otp,
    });

    if (res['data'] != null) {
      _kycStatus = KycIdentityModel.fromJson(
        res['data'] as Map<String, dynamic>,
        fallbackName: dynamicName,
        fallbackDevice: dynamicDevice,
        fallbackDigitalId: dynamicId,
      );
      notifyListeners();
      return _kycStatus!;
    }

    throw Exception(res['message'] ?? 'Aadhaar OTP verification failed');
  }

  /// 5. Verify PAN via Authorized Provider
  Future<KycIdentityModel> verifyPan(String panNumber, String fullName) async {
    final userId = AuthRepository().currentUser?.id ?? _kycStatus?.userId ?? '1';
    final dynamicName = _resolveUserName(fullName.isNotEmpty ? fullName : _kycStatus?.verifiedName);
    final dynamicDevice = _kycStatus?.deviceId ?? await _resolveDeviceTag();
    final dynamicId = _kycStatus?.digitalIdentityNumber ?? generateDigitalId(userId);

    final res = await _apiClient.post('/api/kyc/pan/verify', body: {
      'panNumber': panNumber,
      'fullName': dynamicName,
    });

    if (res['data'] != null) {
      _kycStatus = KycIdentityModel.fromJson(
        res['data'] as Map<String, dynamic>,
        fallbackName: dynamicName,
        fallbackDevice: dynamicDevice,
        fallbackDigitalId: dynamicId,
      );
      notifyListeners();
      return _kycStatus!;
    }

    throw Exception(res['message'] ?? 'PAN verification failed');
  }

  /// 6. Fetch verified documents
  Future<List<Map<String, dynamic>>> getVerifiedDocuments() async {
    try {
      final res = await _apiClient.get('/api/kyc/documents');
      if (res['data'] != null && res['data']['documents'] is List) {
        return List<Map<String, dynamic>>.from(res['data']['documents'] as List);
      }
    } catch (e) {
      debugPrint('[KycRepository getVerifiedDocuments] Error: $e');
    }
    return [];
  }

  /// 7. Bind Biometrics
  Future<KycIdentityModel> bindBiometrics({String? mpin}) async {
    final userId = AuthRepository().currentUser?.id ?? _kycStatus?.userId ?? '1';
    final dynamicName = _resolveUserName(_kycStatus?.verifiedName);
    final dynamicDevice = _kycStatus?.deviceId ?? await _resolveDeviceTag();
    final dynamicId = _kycStatus?.digitalIdentityNumber ?? generateDigitalId(userId);

    final res = await _apiClient.post('/api/finance/kyc/biometric/bind', body: {
      'deviceSignature': 'SECURE_KEYSTORE_FIDO2_TAG',
      'mpin': mpin ?? '1234',
    });

    if (res['data'] != null) {
      _kycStatus = KycIdentityModel.fromJson(
        res['data'] as Map<String, dynamic>,
        fallbackName: dynamicName,
        fallbackDevice: dynamicDevice,
        fallbackDigitalId: dynamicId,
      );
      notifyListeners();
      return _kycStatus!;
    }

    return _kycStatus!;
  }

  /// 8. Submit Free & Fast Manual KYC for Launch (₹0 API Fee)
  Future<KycIdentityModel> submitManualKyc({
    required String panNumber,
    String? businessName,
    String? applicantName,
    String? documentType,
    String? phone,
  }) async {
    final userId = AuthRepository().currentUser?.id ?? _kycStatus?.userId ?? '1';
    final dynamicName = _resolveUserName(applicantName ?? _kycStatus?.verifiedName);
    final dynamicDevice = _kycStatus?.deviceId ?? await _resolveDeviceTag();
    final dynamicId = _kycStatus?.digitalIdentityNumber ?? generateDigitalId(userId);

    final res = await _apiClient.post('/api/kyc/submit-manual', body: {
      'userId': userId,
      'panNumber': panNumber,
      'businessName': businessName ?? 'Registered Merchant',
      'applicantName': dynamicName,
      'documentType': documentType ?? 'PAN_CARD',
      'phone': phone,
    });

    if (res['data'] != null) {
      _kycStatus = KycIdentityModel.fromJson(
        res['data'] as Map<String, dynamic>,
        fallbackName: dynamicName,
        fallbackDevice: dynamicDevice,
        fallbackDigitalId: dynamicId,
      );
      notifyListeners();
      return _kycStatus!;
    }

    throw Exception(res['message'] ?? 'Manual KYC submission failed');
  }
}
