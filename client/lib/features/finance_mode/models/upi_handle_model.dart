class UpiHandleModel {
  final String id;
  final String vpa;
  final String prefix;
  final String suffix;
  final String bankName;
  final String accountId;
  final String accountNumberLast4;
  final bool isPrimary;
  final bool isActive;
  final String qrData;
  final DateTime? createdAt;

  const UpiHandleModel({
    required this.id,
    required this.vpa,
    required this.prefix,
    required this.suffix,
    required this.bankName,
    this.accountId = '',
    this.accountNumberLast4 = '1024',
    this.isPrimary = false,
    this.isActive = true,
    required this.qrData,
    this.createdAt,
  });

  factory UpiHandleModel.fromJson(Map<String, dynamic> json) {
    final vpa = (json['vpa'] ?? '').toString();
    String prefix = (json['prefix'] ?? '').toString();
    String suffix = (json['suffix'] ?? '').toString();
    if ((prefix.isEmpty || suffix.isEmpty) && vpa.contains('@')) {
      final parts = vpa.split('@');
      prefix = parts[0];
      suffix = '@${parts[1]}';
    }

    return UpiHandleModel(
      id: (json['id'] ?? '').toString(),
      vpa: vpa,
      prefix: prefix,
      suffix: suffix,
      bankName: (json['bankName'] ?? 'State Bank of India').toString(),
      accountId: (json['accountId'] ?? '').toString(),
      accountNumberLast4: (json['accountNumberLast4'] ?? '1024').toString(),
      isPrimary: json['isPrimary'] == true,
      isActive: json['isActive'] != false,
      qrData: (json['qrData'] ??
              'upi://pay?pa=$vpa&pn=${Uri.encodeComponent('ENX Money User')}&cu=INR')
          .toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vpa': vpa,
      'prefix': prefix,
      'suffix': suffix,
      'bankName': bankName,
      'accountId': accountId,
      'accountNumberLast4': accountNumberLast4,
      'isPrimary': isPrimary,
      'isActive': isActive,
      'qrData': qrData,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UpiHandleModel copyWith({
    String? id,
    String? vpa,
    String? prefix,
    String? suffix,
    String? bankName,
    String? accountId,
    String? accountNumberLast4,
    bool? isPrimary,
    bool? isActive,
    String? qrData,
    DateTime? createdAt,
  }) {
    return UpiHandleModel(
      id: id ?? this.id,
      vpa: vpa ?? this.vpa,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      bankName: bankName ?? this.bankName,
      accountId: accountId ?? this.accountId,
      accountNumberLast4: accountNumberLast4 ?? this.accountNumberLast4,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      qrData: qrData ?? this.qrData,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UpiHandleCheckResult {
  final bool success;
  final String vpa;
  final String prefix;
  final String suffix;
  final bool available;
  final bool alreadyOwned;
  final String message;
  final List<String> suggestions;

  const UpiHandleCheckResult({
    required this.success,
    required this.vpa,
    this.prefix = '',
    this.suffix = '',
    required this.available,
    this.alreadyOwned = false,
    required this.message,
    this.suggestions = const [],
  });

  factory UpiHandleCheckResult.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    final List<String> list = [];
    if (rawSuggestions is List) {
      for (final s in rawSuggestions) {
        if (s != null) list.add(s.toString());
      }
    }

    return UpiHandleCheckResult(
      success: json['success'] == true,
      vpa: (json['vpa'] ?? '').toString(),
      prefix: (json['prefix'] ?? '').toString(),
      suffix: (json['suffix'] ?? '').toString(),
      available: json['available'] == true,
      alreadyOwned: json['alreadyOwned'] == true,
      message: (json['message'] ?? '').toString(),
      suggestions: list,
    );
  }
}
