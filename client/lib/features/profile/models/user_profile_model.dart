/// Represents the business details of the user
class BusinessProfileModel {
  final String businessName;
  final String businessType; // Retailer, Wholesaler, Freelancer, Service Business, Manufacturer, Distributor, Other
  final String businessSize; // Freelancer, Small Business, Mid-Level Business, Large Business
  final String businessCategory;
  final bool hasGst;
  final String? gstin;
  final String businessAddress;
  final String businessContactNumber;
  final String businessEmail;
  final String businessLogo;

  const BusinessProfileModel({
    this.businessName = '',
    this.businessType = '',
    this.businessSize = '',
    this.businessCategory = '',
    this.hasGst = false,
    this.gstin,
    this.businessAddress = '',
    this.businessContactNumber = '',
    this.businessEmail = '',
    this.businessLogo = '',
  });

  bool get isComplete {
    if (businessName.trim().isEmpty) return false;
    if (businessType.trim().isEmpty) return false;
    if (businessCategory.trim().isEmpty) return false;
    if (businessAddress.trim().isEmpty) return false;
    if (hasGst && (gstin == null || gstin!.trim().length != 15)) return false;
    return true;
  }

  BusinessProfileModel copyWith({
    String? businessName,
    String? businessType,
    String? businessSize,
    String? businessCategory,
    bool? hasGst,
    String? gstin,
    String? businessAddress,
    String? businessContactNumber,
    String? businessEmail,
    String? businessLogo,
  }) {
    return BusinessProfileModel(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessSize: businessSize ?? this.businessSize,
      businessCategory: businessCategory ?? this.businessCategory,
      hasGst: hasGst ?? this.hasGst,
      gstin: hasGst == false ? null : (gstin ?? this.gstin),
      businessAddress: businessAddress ?? this.businessAddress,
      businessContactNumber: businessContactNumber ?? this.businessContactNumber,
      businessEmail: businessEmail ?? this.businessEmail,
      businessLogo: businessLogo ?? this.businessLogo,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'businessType': businessType,
        'businessSize': businessSize,
        'businessCategory': businessCategory,
        'hasGst': hasGst,
        'gstin': gstin,
        'businessAddress': businessAddress,
        'businessContactNumber': businessContactNumber,
        'businessEmail': businessEmail,
        'businessLogo': businessLogo,
      };

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? 'Service Business',
      businessSize: json['businessSize'] as String? ?? 'Small Business',
      businessCategory: json['businessCategory'] as String? ?? 'Financial Technology & Services',
      hasGst: json['hasGst'] as bool? ?? false,
      gstin: json['gstin'] as String?,
      businessAddress: json['businessAddress'] as String? ?? '',
      businessContactNumber: json['businessContactNumber'] as String? ?? '',
      businessEmail: json['businessEmail'] as String? ?? '',
      businessLogo: json['businessLogo'] as String? ?? '',
    );
  }
}

/// Represents an active device logged into the account
class ActiveDeviceModel {
  final String id;
  final String deviceName;
  final String platform;
  final String location;
  final String lastActive;
  final bool isCurrent;

  const ActiveDeviceModel({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceName': deviceName,
        'platform': platform,
        'location': location,
        'lastActive': lastActive,
        'isCurrent': isCurrent,
      };

  factory ActiveDeviceModel.fromJson(Map<String, dynamic> json) {
    return ActiveDeviceModel(
      id: json['id'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      location: json['location'] as String? ?? '',
      lastActive: json['lastActive'] as String? ?? '',
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

/// Main user profile aggregating personal, business, security and preferences
class UserProfileModel {
  final String fullName;
  final String email;
  final String mobileNumber;
  final String profilePhoto;
  final String dateOfBirth; // e.g. '1995-08-15'
  final String gender; // 'Male', 'Female', 'Other'
  final String addressState;
  final String addressDistrict;
  final String addressCity; // Mandal / City
  final String addressPincode;
  final String monthlyIncome; // e.g. '₹1,50,000 - ₹5,00,000'
  final String currency; // e.g. 'INR (₹)'
  final bool isEmailVerified;
  final bool isMobileVerified;
  final String kycTier;

  // Business Profile (30% total weight - optional for non-business users)
  final BusinessProfileModel businessProfile;

  // Security (10% total weight)
  final bool hasPasswordSet;
  final String appLockPin;
  final bool isBiometricEnabled;
  final bool hasSecurityQuestions;
  final String autoLockDuration; // 'Immediately', '1 Minute', '5 Minutes', '15 Minutes', 'Never'
  final List<ActiveDeviceModel> activeDevices;

  // Preferences
  final bool pushNotifications;
  final bool emailAlerts;
  final bool smsAlerts;
  final String selectedLanguage;

  const UserProfileModel({
    this.fullName = '',
    this.email = '',
    this.mobileNumber = '',
    this.profilePhoto = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.addressState = '',
    this.addressDistrict = '',
    this.addressCity = '',
    this.addressPincode = '',
    this.monthlyIncome = '',
    this.currency = 'INR (₹)',
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    this.kycTier = 'NOT VERIFIED',
    this.businessProfile = const BusinessProfileModel(),
    this.hasPasswordSet = true,
    this.appLockPin = '',
    this.isBiometricEnabled = false,
    this.hasSecurityQuestions = false,
    this.autoLockDuration = 'Never',
    this.activeDevices = const [],
    this.pushNotifications = true,
    this.emailAlerts = true,
    this.smsAlerts = false,
    this.selectedLanguage = 'English (US)',
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (fullName.isNotEmpty) {
      return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'EN';
  }

  /// Personal Profile Progress Score (Max 60%)
  int get personalScore {
    int score = 0;
    if (fullName.trim().isNotEmpty) score += 10;
    if (email.trim().isNotEmpty) score += 10;
    if (mobileNumber.trim().isNotEmpty) score += 10;
    if (dateOfBirth.trim().isNotEmpty) score += 5;
    if (gender.trim().isNotEmpty) score += 5;
    if (addressCity.trim().isNotEmpty && addressState.trim().isNotEmpty) {
      score += 10;
    } else if (addressCity.trim().isNotEmpty || addressState.trim().isNotEmpty) {
      score += 5;
    }
    if (profilePhoto.trim().isNotEmpty) score += 5;
    if (selectedLanguage.trim().isNotEmpty) score += 5;
    return score.clamp(0, 60);
  }

  /// Business Profile Progress Score (Max 30% - Optional for non-business users)
  int get businessScore {
    if (businessProfile.businessName.trim().isEmpty) return 0;
    int score = 0;
    if (businessProfile.businessName.trim().isNotEmpty) score += 5;
    if (businessProfile.businessType.trim().isNotEmpty && businessProfile.businessCategory.trim().isNotEmpty) {
      score += 5;
    } else if (businessProfile.businessType.trim().isNotEmpty || businessProfile.businessCategory.trim().isNotEmpty) {
      score += 3;
    }
    if (businessProfile.businessAddress.trim().isNotEmpty) score += 5;
    if (businessProfile.businessContactNumber.trim().isNotEmpty) score += 5;
    if (businessProfile.businessLogo.trim().isNotEmpty) score += 5;
    if (businessProfile.businessEmail.trim().isNotEmpty || (businessProfile.hasGst && businessProfile.gstin != null && businessProfile.gstin!.isNotEmpty)) {
      score += 5;
    }
    return score.clamp(0, 30);
  }

  /// Security Profile Progress Score (Max 10%)
  int get securityScore {
    int score = 0;
    if (hasPasswordSet) score += 3;
    if (appLockPin.length == 4 || appLockPin.isNotEmpty) score += 3;
    if (isBiometricEnabled) score += 2;
    if (hasSecurityQuestions) score += 2;
    return score.clamp(0, 10);
  }

  /// Total Streamlined Profile Completion Percentage (0 to 100%)
  /// Rule: Personal (60%) + Business (30%) + Security (10%)
  /// Example: Personal (60%) + Security (10%) + partial business (5%) = 75%
  int get completionPercentage => (personalScore + businessScore + securityScore).clamp(0, 100);

  bool get isPersonalComplete => personalScore == 60;
  bool get isBusinessComplete => businessScore == 30;
  bool get isSecurityComplete => securityScore == 10;

  List<String> get missingPersonalFields {
    final list = <String>[];
    if (fullName.trim().isEmpty) list.add('Full Name');
    if (mobileNumber.trim().isEmpty) list.add('Mobile Number');
    if (email.trim().isEmpty) list.add('Email');
    if (profilePhoto.trim().isEmpty) list.add('Profile Photo');
    if (dateOfBirth.trim().isEmpty) list.add('Date of Birth');
    if (gender.trim().isEmpty) list.add('Gender');
    if (addressCity.trim().isEmpty || addressState.trim().isEmpty) list.add('Address');
    if (selectedLanguage.trim().isEmpty) list.add('Language');
    return list;
  }

  List<String> get missingBusinessFields {
    final list = <String>[];
    if (businessProfile.businessName.trim().isEmpty) list.add('Business Name');
    if (businessProfile.businessType.trim().isEmpty || businessProfile.businessCategory.trim().isEmpty) {
      list.add('Business Type / Category');
    }
    if (businessProfile.businessAddress.trim().isEmpty) list.add('Business Address');
    if (businessProfile.businessContactNumber.trim().isEmpty) list.add('Business Contact');
    if (businessProfile.businessLogo.trim().isEmpty) list.add('Business Logo');
    return list;
  }

  List<String> get missingSecurityFields {
    final list = <String>[];
    if (!hasPasswordSet) list.add('Password');
    if (appLockPin.length != 4 && appLockPin.isEmpty) list.add('MPIN / Lock PIN');
    if (!isBiometricEnabled) list.add('Biometrics');
    if (!hasSecurityQuestions) list.add('Security Questions');
    return list;
  }

  List<String> get missingFields => [
    ...missingPersonalFields,
    ...missingBusinessFields,
    ...missingSecurityFields,
  ];

  UserProfileModel copyWith({
    String? fullName,
    String? email,
    String? mobileNumber,
    String? profilePhoto,
    String? dateOfBirth,
    String? gender,
    String? addressState,
    String? addressDistrict,
    String? addressCity,
    String? addressPincode,
    String? monthlyIncome,
    String? currency,
    bool? isEmailVerified,
    bool? isMobileVerified,
    String? kycTier,
    BusinessProfileModel? businessProfile,
    bool? hasPasswordSet,
    String? appLockPin,
    bool? isBiometricEnabled,
    bool? hasSecurityQuestions,
    String? autoLockDuration,
    List<ActiveDeviceModel>? activeDevices,
    bool? pushNotifications,
    bool? emailAlerts,
    bool? smsAlerts,
    String? selectedLanguage,
  }) {
    return UserProfileModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      addressState: addressState ?? this.addressState,
      addressDistrict: addressDistrict ?? this.addressDistrict,
      addressCity: addressCity ?? this.addressCity,
      addressPincode: addressPincode ?? this.addressPincode,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currency: currency ?? this.currency,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      kycTier: kycTier ?? this.kycTier,
      businessProfile: businessProfile ?? this.businessProfile,
      hasPasswordSet: hasPasswordSet ?? this.hasPasswordSet,
      appLockPin: appLockPin ?? this.appLockPin,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      hasSecurityQuestions: hasSecurityQuestions ?? this.hasSecurityQuestions,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      activeDevices: activeDevices ?? this.activeDevices,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailAlerts: emailAlerts ?? this.emailAlerts,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'mobileNumber': mobileNumber,
        'profilePhoto': profilePhoto,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'addressState': addressState,
        'addressDistrict': addressDistrict,
        'addressCity': addressCity,
        'addressPincode': addressPincode,
        'monthlyIncome': monthlyIncome,
        'currency': currency,
        'isEmailVerified': isEmailVerified,
        'isMobileVerified': isMobileVerified,
        'kycTier': kycTier,
        'businessProfile': businessProfile.toJson(),
        'hasPasswordSet': hasPasswordSet,
        'appLockPin': appLockPin,
        'isBiometricEnabled': isBiometricEnabled,
        'hasSecurityQuestions': hasSecurityQuestions,
        'autoLockDuration': autoLockDuration,
        'activeDevices': activeDevices.map((d) => d.toJson()).toList(),
        'pushNotifications': pushNotifications,
        'emailAlerts': emailAlerts,
        'smsAlerts': smsAlerts,
        'selectedLanguage': selectedLanguage,
      };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      addressState: json['addressState'] as String? ?? '',
      addressDistrict: json['addressDistrict'] as String? ?? '',
      addressCity: json['addressCity'] as String? ?? '',
      addressPincode: json['addressPincode'] as String? ?? '',
      monthlyIncome: json['monthlyIncome'] as String? ?? '',
      currency: json['currency'] as String? ?? 'INR (₹)',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isMobileVerified: json['isMobileVerified'] as bool? ?? false,
      kycTier: json['kycTier'] as String? ?? 'NOT VERIFIED',
      businessProfile: json['businessProfile'] != null
          ? BusinessProfileModel.fromJson(json['businessProfile'] as Map<String, dynamic>)
          : const BusinessProfileModel(),
      hasPasswordSet: json['hasPasswordSet'] as bool? ?? true,
      appLockPin: json['appLockPin'] as String? ?? '',
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      hasSecurityQuestions: json['hasSecurityQuestions'] as bool? ?? false,
      autoLockDuration: json['autoLockDuration'] as String? ?? '5 Minutes',
      activeDevices: json['activeDevices'] != null
          ? (json['activeDevices'] as List)
              .map((e) => ActiveDeviceModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailAlerts: json['emailAlerts'] as bool? ?? true,
      smsAlerts: json['smsAlerts'] as bool? ?? false,
      selectedLanguage: json['selectedLanguage'] as String? ?? 'English (US)',
    );
  }
}
