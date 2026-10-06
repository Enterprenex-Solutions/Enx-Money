class UserModel {
  final String id;
  final String fullName;
  String get name => fullName;
  final String email;
  final String? mobileNumber;
  String? get phone => mobileNumber;
  final String kycStatus;
  final int enxScore;
  final bool hasPinSet;
  final bool isBiometricEnabled;
  final String avatarUrl;
  final String? accessToken;
  final String status;
  final bool isEmailVerified;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.mobileNumber,
    this.kycStatus = 'VERIFIED (TIER 3)',
    this.enxScore = 842,
    this.hasPinSet = true,
    this.isBiometricEnabled = true,
    this.avatarUrl = '',
    this.accessToken,
    this.status = 'ACTIVE',
    this.isEmailVerified = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final rawName = json['name'] as String? ?? json['fullName'] as String?;
    final emailStr = json['email'] as String? ?? '';
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : (emailStr.isNotEmpty ? emailStr.split('@')[0] : 'ENX User');

    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: name,
      email: emailStr,
      mobileNumber: json['phone'] as String? ?? json['mobileNumber'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      isEmailVerified: json['isEmailVerified'] as bool? ?? json['is_email_verified'] as bool? ?? true,
      kycStatus: json['kycStatus'] as String? ?? 'VERIFIED (TIER 3)',
      enxScore: json['enxScore'] as int? ?? 842,
      hasPinSet: json['hasPinSet'] as bool? ?? true,
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? true,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      accessToken: token ?? json['accessToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'status': status,
      'isEmailVerified': isEmailVerified,
      'kycStatus': kycStatus,
      'enxScore': enxScore,
      'hasPinSet': hasPinSet,
      'isBiometricEnabled': isBiometricEnabled,
      'avatarUrl': avatarUrl,
      'accessToken': accessToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
    String? email,
    String? kycStatus,
    int? enxScore,
    bool? hasPinSet,
    bool? isBiometricEnabled,
    String? avatarUrl,
    String? accessToken,
    String? status,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      kycStatus: kycStatus ?? this.kycStatus,
      enxScore: enxScore ?? this.enxScore,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessToken: accessToken ?? this.accessToken,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
