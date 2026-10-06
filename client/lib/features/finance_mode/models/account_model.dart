enum FinanceType { business, personal }

/// Bank and wallet account entity in ENX MONEY
class AccountModel {
  final String id;
  final String title;
  final String bankName;
  final String accountNumberLast4;
  final double balance;
  final FinanceType financeType;
  final bool isDefault;
  final String? upiId;
  final String? ifsc;
  final String? vpa;
  final bool isUpiLinked;
  final bool hasUpiPin;
  final String accountType;
  final String? accountHolderName;
  final String? bankLogo;

  const AccountModel({
    required this.id,
    String? title,
    String? accountName,
    required this.bankName,
    String? accountNumberLast4,
    String? accountNumber,
    required this.balance,
    FinanceType? financeType,
    FinanceType? type,
    this.isDefault = false,
    this.upiId,
    this.ifsc,
    String? vpa,
    this.isUpiLinked = false,
    this.hasUpiPin = true,
    this.accountType = 'Savings',
    this.accountHolderName,
    this.bankLogo,
  })  : title = title ?? accountName ?? '',
        accountNumberLast4 = accountNumberLast4 ?? accountNumber ?? '0000',
        financeType = financeType ?? type ?? FinanceType.business,
        vpa = vpa ?? upiId;

  // Convenience Aliases for screen compatibility
  String get accountName => title;
  String get accountNumber => accountNumberLast4;
  FinanceType get type => financeType;

  bool get isBusiness => financeType == FinanceType.business;
  bool get isPersonal => financeType == FinanceType.personal;

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final rawUpi = json['vpa'] as String? ?? json['upiId'] as String?;
    return AccountModel(
      id: json['id'] as String? ?? json['accountId'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? json['accountName'] as String? ?? '',
      bankName: json['bankName'] as String? ?? json['bank'] as String? ?? 'Bank',
      accountNumberLast4: json['accountNumberLast4'] as String? ?? json['accountNumber'] as String? ?? '0000',
      balance: (json['balance'] is num) ? (json['balance'] as num).toDouble() : 0.0,
      financeType: (json['financeType'] == 'personal' || json['mode'] == 'PERSONAL')
          ? FinanceType.personal
          : FinanceType.business,
      isDefault: json['isDefault'] as bool? ?? false,
      upiId: rawUpi,
      vpa: rawUpi,
      ifsc: json['ifsc'] as String?,
      isUpiLinked: json['isUpiLinked'] as bool? ?? (rawUpi != null && rawUpi.isNotEmpty),
      hasUpiPin: json['hasUpiPin'] as bool? ?? true,
      accountType: json['accountType'] as String? ?? 'Savings',
      accountHolderName: json['accountHolderName'] as String?,
      bankLogo: json['bankLogo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'bankName': bankName,
      'accountNumberLast4': accountNumberLast4,
      'balance': balance,
      'financeType': financeType == FinanceType.business ? 'business' : 'personal',
      'isDefault': isDefault,
      'upiId': upiId ?? vpa,
      'vpa': vpa ?? upiId,
      'ifsc': ifsc,
      'isUpiLinked': isUpiLinked,
      'hasUpiPin': hasUpiPin,
      'accountType': accountType,
      'accountHolderName': accountHolderName,
      'bankLogo': bankLogo,
    };
  }

  AccountModel copyWith({
    String? id,
    String? title,
    String? bankName,
    String? accountNumberLast4,
    double? balance,
    FinanceType? financeType,
    bool? isDefault,
    String? upiId,
    String? ifsc,
    String? vpa,
    bool? isUpiLinked,
    bool? hasUpiPin,
    String? accountType,
    String? accountHolderName,
    String? bankLogo,
  }) {
    return AccountModel(
      id: id ?? this.id,
      title: title ?? this.title,
      bankName: bankName ?? this.bankName,
      accountNumberLast4: accountNumberLast4 ?? this.accountNumberLast4,
      balance: balance ?? this.balance,
      financeType: financeType ?? this.financeType,
      isDefault: isDefault ?? this.isDefault,
      upiId: upiId ?? this.upiId,
      ifsc: ifsc ?? this.ifsc,
      vpa: vpa ?? this.vpa,
      isUpiLinked: isUpiLinked ?? this.isUpiLinked,
      hasUpiPin: hasUpiPin ?? this.hasUpiPin,
      accountType: accountType ?? this.accountType,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankLogo: bankLogo ?? this.bankLogo,
    );
  }
}
