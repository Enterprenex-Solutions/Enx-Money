/// Top-level platform telemetry and user counts
class GlobalKpiSummary {
  final int totalWorldwideUsers;
  final double userGrowthPercentage; // e.g. 14.8%
  final int dailyActiveUsers; // DAU
  final int monthlyActiveUsers; // MAU
  final int businessAccountsCount;
  final int personalAccountsCount;
  final int activeLiveSessions; // Online Now

  const GlobalKpiSummary({
    required this.totalWorldwideUsers,
    required this.userGrowthPercentage,
    required this.dailyActiveUsers,
    required this.monthlyActiveUsers,
    required this.businessAccountsCount,
    required this.personalAccountsCount,
    required this.activeLiveSessions,
  });

  double get businessRatio => totalWorldwideUsers > 0
      ? (businessAccountsCount / totalWorldwideUsers) * 100
      : 0.0;

  double get personalRatio => totalWorldwideUsers > 0
      ? (personalAccountsCount / totalWorldwideUsers) * 100
      : 0.0;

  double get dauMauRatio => monthlyActiveUsers > 0
      ? (dailyActiveUsers / monthlyActiveUsers) * 100
      : 0.0;

  factory GlobalKpiSummary.mock() {
    return const GlobalKpiSummary(
      totalWorldwideUsers: 248590,
      userGrowthPercentage: 14.8,
      dailyActiveUsers: 42180,
      monthlyActiveUsers: 184320,
      businessAccountsCount: 86950,
      personalAccountsCount: 161640,
      activeLiveSessions: 1842,
    );
  }

  factory GlobalKpiSummary.fromJson(Map<String, dynamic> json) {
    return GlobalKpiSummary(
      totalWorldwideUsers: json['totalWorldwideUsers'] as int? ?? 248590,
      userGrowthPercentage: (json['userGrowthPercentage'] as num?)?.toDouble() ?? 14.8,
      dailyActiveUsers: json['dailyActiveUsers'] as int? ?? 42180,
      monthlyActiveUsers: json['monthlyActiveUsers'] as int? ?? 184320,
      businessAccountsCount: json['businessAccountsCount'] as int? ?? 86950,
      personalAccountsCount: json['personalAccountsCount'] as int? ?? 161640,
      activeLiveSessions: json['activeLiveSessions'] as int? ?? 1842,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalWorldwideUsers': totalWorldwideUsers,
        'userGrowthPercentage': userGrowthPercentage,
        'dailyActiveUsers': dailyActiveUsers,
        'monthlyActiveUsers': monthlyActiveUsers,
        'businessAccountsCount': businessAccountsCount,
        'personalAccountsCount': personalAccountsCount,
        'activeLiveSessions': activeLiveSessions,
      };
}

/// Geographic breakdown per country with state/province details
class GeoCountryMetric {
  final String countryName;
  final String countryCode; // e.g. IN, US, AE, GB
  final String flagEmoji;
  final int userCount;
  final double percentageShare;
  final int activeNow;
  final List<GeoStateMetric> states;

  const GeoCountryMetric({
    required this.countryName,
    required this.countryCode,
    required this.flagEmoji,
    required this.userCount,
    required this.percentageShare,
    required this.activeNow,
    this.states = const [],
  });

  factory GeoCountryMetric.fromJson(Map<String, dynamic> json) {
    return GeoCountryMetric(
      countryName: json['countryName'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      flagEmoji: json['flagEmoji'] as String? ?? '🌐',
      userCount: json['userCount'] as int? ?? 0,
      percentageShare: (json['percentageShare'] as num?)?.toDouble() ?? 0.0,
      activeNow: json['activeNow'] as int? ?? 0,
      states: (json['states'] as List? ?? [])
          .map((s) => GeoStateMetric.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'countryName': countryName,
        'countryCode': countryCode,
        'flagEmoji': flagEmoji,
        'userCount': userCount,
        'percentageShare': percentageShare,
        'activeNow': activeNow,
        'states': states.map((s) => s.toJson()).toList(),
      };
}

/// Regional sub-state metric
class GeoStateMetric {
  final String stateName;
  final int userCount;
  final double percentage;

  const GeoStateMetric({
    required this.stateName,
    required this.userCount,
    required this.percentage,
  });

  factory GeoStateMetric.fromJson(Map<String, dynamic> json) {
    return GeoStateMetric(
      stateName: json['stateName'] as String? ?? '',
      userCount: json['userCount'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'stateName': stateName,
        'userCount': userCount,
        'percentage': percentage,
      };
}

/// User retention & churn data points over 7D, 30D, 90D
class RetentionDataPoint {
  final DateTime date;
  final int signups;
  final double retentionRate; // %
  final double churnRate; // %

  const RetentionDataPoint({
    required this.date,
    required this.signups,
    required this.retentionRate,
    required this.churnRate,
  });

  factory RetentionDataPoint.fromJson(Map<String, dynamic> json) {
    return RetentionDataPoint(
      date: DateTime.parse(json['date'] as String),
      signups: json['signups'] as int? ?? 0,
      retentionRate: (json['retentionRate'] as num?)?.toDouble() ?? 0.0,
      churnRate: (json['churnRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'signups': signups,
        'retentionRate': retentionRate,
        'churnRate': churnRate,
      };
}

/// Telemetry record for individual active users
class UserTelemetryRecord {
  final String id;
  final String name;
  final String email;
  final String accountType; // 'Personal' or 'Business'
  final int profileCompletion; // 0 to 100
  final String region; // 'Telangana, India'
  final String lastActive; // 'Just now', '2m ago'
  final String status; // 'Active' or 'Suspended'
  final String ipAddress;
  final String platform; // 'Android', 'iOS', 'Web'

  const UserTelemetryRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    required this.profileCompletion,
    required this.region,
    required this.lastActive,
    required this.status,
    required this.ipAddress,
    this.platform = 'Android',
  });

  UserTelemetryRecord copyWith({
    String? id,
    String? name,
    String? email,
    String? accountType,
    int? profileCompletion,
    String? region,
    String? lastActive,
    String? status,
    String? ipAddress,
    String? platform,
  }) {
    return UserTelemetryRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      region: region ?? this.region,
      lastActive: lastActive ?? this.lastActive,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      platform: platform ?? this.platform,
    );
  }

  factory UserTelemetryRecord.fromJson(Map<String, dynamic> json) {
    return UserTelemetryRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accountType: json['accountType'] as String? ?? 'Personal',
      profileCompletion: json['profileCompletion'] as int? ?? 0,
      region: json['region'] as String? ?? '',
      lastActive: json['lastActive'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      ipAddress: json['ipAddress'] as String? ?? '',
      platform: json['platform'] as String? ?? 'Android',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'accountType': accountType,
        'profileCompletion': profileCompletion,
        'region': region,
        'lastActive': lastActive,
        'status': status,
        'ipAddress': ipAddress,
        'platform': platform,
      };
}
