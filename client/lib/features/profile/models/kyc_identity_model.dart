class KycIdentityModel {
  final String userId;
  final String tier; // 'TIER_1_BASIC' | 'TIER_2_GOVT_ID' | 'TIER_3_FULL_BIOMETRIC'
  final String kycStatus; // 'NOT_VERIFIED' | 'IN_PROGRESS' | 'VERIFIED' | 'FAILED'
  final String digilockerStatus; // 'NOT_STARTED' | 'IN_PROGRESS' | 'LINKED' | 'FAILED'
  final String aadhaarStatus; // 'NOT_VERIFIED' | 'OTP_SENT' | 'VERIFIED' | 'FAILED'
  final String panStatus; // 'NOT_VERIFIED' | 'VERIFIED' | 'FAILED'
  final bool isAadhaarVerified;
  final String? maskedAadhaar;
  final bool isPanVerified;
  final String? panNumber;
  final String? panLast4;
  final bool isBiometricBound;
  final String? biometricBoundAt;
  final bool isDigilockerConnected;
  final String digitalIdentityNumber;
  final String verifiedName;
  final String? verifiedDob;
  final String? verifiedMobile;
  final String deviceId;
  final String simSlot;
  final bool simActive;
  final bool hardwareKeystoreBound;
  final String? failureReason;
  final bool isConfigured;
  final String provider;

  const KycIdentityModel({
    required this.userId,
    required this.tier,
    this.kycStatus = 'NOT_VERIFIED',
    this.digilockerStatus = 'NOT_STARTED',
    this.aadhaarStatus = 'NOT_VERIFIED',
    this.panStatus = 'NOT_VERIFIED',
    required this.isAadhaarVerified,
    this.maskedAadhaar,
    required this.isPanVerified,
    this.panNumber,
    this.panLast4,
    required this.isBiometricBound,
    this.biometricBoundAt,
    required this.isDigilockerConnected,
    required this.digitalIdentityNumber,
    required this.verifiedName,
    this.verifiedDob,
    this.verifiedMobile,
    required this.deviceId,
    required this.simSlot,
    required this.simActive,
    required this.hardwareKeystoreBound,
    this.failureReason,
    this.isConfigured = false,
    this.provider = 'UNCONFIGURED',
  });

  bool get isTier3Full => tier == 'TIER_3_FULL_BIOMETRIC';
  bool get isTier2Govt => tier == 'TIER_2_GOVT_ID' || isTier3Full || isFullyVerified;
  bool get isFullyVerified =>
      kycStatus == 'VERIFIED' ||
      (isAadhaarVerified && isPanVerified) ||
      (aadhaarStatus == 'VERIFIED' && panStatus == 'VERIFIED');
  bool get isInProgress => kycStatus == 'IN_PROGRESS' || digilockerStatus == 'IN_PROGRESS';
  bool get isFailed => kycStatus == 'FAILED' || digilockerStatus == 'FAILED';

  KycIdentityModel copyWith({
    String? userId,
    String? tier,
    String? kycStatus,
    String? digilockerStatus,
    String? aadhaarStatus,
    String? panStatus,
    bool? isAadhaarVerified,
    String? maskedAadhaar,
    bool? isPanVerified,
    String? panNumber,
    String? panLast4,
    bool? isBiometricBound,
    String? biometricBoundAt,
    bool? isDigilockerConnected,
    String? digitalIdentityNumber,
    String? verifiedName,
    String? verifiedDob,
    String? verifiedMobile,
    String? deviceId,
    String? simSlot,
    bool? simActive,
    bool? hardwareKeystoreBound,
    String? failureReason,
    bool? isConfigured,
    String? provider,
  }) {
    return KycIdentityModel(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      kycStatus: kycStatus ?? this.kycStatus,
      digilockerStatus: digilockerStatus ?? this.digilockerStatus,
      aadhaarStatus: aadhaarStatus ?? this.aadhaarStatus,
      panStatus: panStatus ?? this.panStatus,
      isAadhaarVerified: isAadhaarVerified ?? this.isAadhaarVerified,
      maskedAadhaar: maskedAadhaar ?? this.maskedAadhaar,
      isPanVerified: isPanVerified ?? this.isPanVerified,
      panNumber: panNumber ?? this.panNumber,
      panLast4: panLast4 ?? this.panLast4,
      isBiometricBound: isBiometricBound ?? this.isBiometricBound,
      biometricBoundAt: biometricBoundAt ?? this.biometricBoundAt,
      isDigilockerConnected: isDigilockerConnected ?? this.isDigilockerConnected,
      digitalIdentityNumber: digitalIdentityNumber ?? this.digitalIdentityNumber,
      verifiedName: verifiedName ?? this.verifiedName,
      verifiedDob: verifiedDob ?? this.verifiedDob,
      verifiedMobile: verifiedMobile ?? this.verifiedMobile,
      deviceId: deviceId ?? this.deviceId,
      simSlot: simSlot ?? this.simSlot,
      simActive: simActive ?? this.simActive,
      hardwareKeystoreBound: hardwareKeystoreBound ?? this.hardwareKeystoreBound,
      failureReason: failureReason ?? this.failureReason,
      isConfigured: isConfigured ?? this.isConfigured,
      provider: provider ?? this.provider,
    );
  }

  factory KycIdentityModel.fromJson(Map<String, dynamic> json, {String? fallbackName, String? fallbackDevice, String? fallbackDigitalId}) {
    final dev = json['deviceBinding'] as Map<String, dynamic>? ?? {};
    final rawName = json['verifiedName'] as String?;
    final cleanName = (rawName != null && rawName.trim().isNotEmpty && rawName != 'P. Revanth Reddy')
        ? rawName.trim()
        : (fallbackName ?? 'Verified User');

    final rawDeviceId = dev['deviceId'] as String?;
    final cleanDeviceId = (rawDeviceId != null && rawDeviceId.trim().isNotEmpty && rawDeviceId != 'DEV-PIXEL-8-PRO-IND')
        ? rawDeviceId.trim()
        : (fallbackDevice ?? 'Mobile Device');

    final rawDigitalId = (json['digitalIdentityNumber'] ?? json['enxId']) as String?;
    final cleanDigitalId = (rawDigitalId != null && rawDigitalId.trim().isNotEmpty && rawDigitalId != 'ENX-ID-9102-4821')
        ? rawDigitalId.trim()
        : (fallbackDigitalId ?? 'ENX-ID-VERIFIED');

    final rawKycStatus = (json['kycStatus'] as String?)?.toUpperCase() ?? 'NOT_VERIFIED';
    final rawDigilockerStatus = (json['digilockerStatus'] as String?)?.toUpperCase() ?? 'NOT_STARTED';
    final rawAadhaarStatus = (json['aadhaarStatus'] as String?)?.toUpperCase() ??
        (json['isAadhaarVerified'] == true ? 'VERIFIED' : 'NOT_VERIFIED');
    final rawPanStatus = (json['panStatus'] as String?)?.toUpperCase() ??
        (json['isPanVerified'] == true ? 'VERIFIED' : 'NOT_VERIFIED');

    final isAadhaar = rawAadhaarStatus == 'VERIFIED' || json['isAadhaarVerified'] == true;
    final isPan = rawPanStatus == 'VERIFIED' || json['isPanVerified'] == true;
    final isDigilocker = rawDigilockerStatus == 'LINKED' || json['isDigilockerConnected'] == true;

    return KycIdentityModel(
      userId: json['userId']?.toString() ?? '1',
      tier: json['tier'] as String? ?? (isAadhaar && isPan ? 'TIER_2_GOVT_ID' : 'TIER_1_BASIC'),
      kycStatus: rawKycStatus,
      digilockerStatus: rawDigilockerStatus,
      aadhaarStatus: rawAadhaarStatus,
      panStatus: rawPanStatus,
      isAadhaarVerified: isAadhaar,
      maskedAadhaar: json['maskedAadhaar'] as String?,
      isPanVerified: isPan,
      panNumber: json['panNumber'] as String?,
      panLast4: json['panLast4'] as String?,
      isBiometricBound: json['isBiometricBound'] as bool? ?? false,
      biometricBoundAt: json['biometricBoundAt'] as String?,
      isDigilockerConnected: isDigilocker,
      digitalIdentityNumber: cleanDigitalId,
      verifiedName: cleanName,
      verifiedDob: json['verifiedDob'] as String?,
      verifiedMobile: json['verifiedMobile'] as String?,
      deviceId: cleanDeviceId,
      simSlot: dev['simSlot'] as String? ?? 'SIM 1 (Active)',
      simActive: dev['simActive'] as bool? ?? true,
      hardwareKeystoreBound: dev['hardwareKeystoreBound'] as bool? ?? false,
      failureReason: json['failureReason'] as String?,
      isConfigured: json['isConfigured'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'UNCONFIGURED',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'tier': tier,
    'kycStatus': kycStatus,
    'digilockerStatus': digilockerStatus,
    'aadhaarStatus': aadhaarStatus,
    'panStatus': panStatus,
    'isAadhaarVerified': isAadhaarVerified,
    'maskedAadhaar': maskedAadhaar,
    'isPanVerified': isPanVerified,
    'panNumber': panNumber,
    'panLast4': panLast4,
    'isBiometricBound': isBiometricBound,
    'biometricBoundAt': biometricBoundAt,
    'isDigilockerConnected': isDigilockerConnected,
    'digitalIdentityNumber': digitalIdentityNumber,
    'verifiedName': verifiedName,
    'verifiedDob': verifiedDob,
    'verifiedMobile': verifiedMobile,
    'failureReason': failureReason,
    'isConfigured': isConfigured,
    'provider': provider,
    'deviceBinding': {
      'deviceId': deviceId,
      'simSlot': simSlot,
      'simActive': simActive,
      'hardwareKeystoreBound': hardwareKeystoreBound,
    },
  };
}
