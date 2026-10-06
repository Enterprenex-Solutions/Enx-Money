class MandateModel {
  final String id;
  final String name;
  final String frequency; // 'Weekly', 'Monthly', 'Quarterly', 'As Presented'
  final double maxLimit;
  final String startDate;
  final String endDate;
  final bool isUntilCancelled;
  final String status; // 'Active', 'Paused', 'Completed', 'Revoked'
  final String sourceAccountId;
  final String sourceBankName;
  final String vpa;
  final String createdAt;

  const MandateModel({
    required this.id,
    required this.name,
    this.frequency = 'Monthly',
    required this.maxLimit,
    required this.startDate,
    this.endDate = '2028-12-31',
    this.isUntilCancelled = true,
    this.status = 'Active',
    this.sourceAccountId = '',
    this.sourceBankName = 'Primary Bank',
    this.vpa = 'enxmoney@bank',
    required this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isPaused => status.toLowerCase() == 'paused';
  bool get isRevoked => status.toLowerCase() == 'revoked' || status.toLowerCase() == 'completed';

  factory MandateModel.fromJson(Map<String, dynamic> json) {
    return MandateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Recurring Mandate',
      frequency: json['frequency'] as String? ?? 'Monthly',
      maxLimit: (json['maxLimit'] is num) ? (json['maxLimit'] as num).toDouble() : 0.0,
      startDate: json['startDate'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
      endDate: json['endDate'] as String? ?? '2028-12-31',
      isUntilCancelled: json['isUntilCancelled'] as bool? ?? true,
      status: json['status'] as String? ?? 'Active',
      sourceAccountId: json['sourceAccountId'] as String? ?? '',
      sourceBankName: json['sourceBankName'] as String? ?? 'Primary Bank',
      vpa: json['vpa'] as String? ?? 'enxmoney@bank',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'maxLimit': maxLimit,
      'startDate': startDate,
      'endDate': endDate,
      'isUntilCancelled': isUntilCancelled,
      'status': status,
      'sourceAccountId': sourceAccountId,
      'sourceBankName': sourceBankName,
      'vpa': vpa,
      'createdAt': createdAt,
    };
  }

  MandateModel copyWith({
    String? id,
    String? name,
    String? frequency,
    double? maxLimit,
    String? startDate,
    String? endDate,
    bool? isUntilCancelled,
    String? status,
    String? sourceAccountId,
    String? sourceBankName,
    String? vpa,
    String? createdAt,
  }) {
    return MandateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      maxLimit: maxLimit ?? this.maxLimit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isUntilCancelled: isUntilCancelled ?? this.isUntilCancelled,
      status: status ?? this.status,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      sourceBankName: sourceBankName ?? this.sourceBankName,
      vpa: vpa ?? this.vpa,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
