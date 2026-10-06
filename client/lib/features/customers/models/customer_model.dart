class AgingBuckets {
  final double days0To30;
  final double days31To60;
  final double days61To90;
  final double days90Plus;

  const AgingBuckets({
    this.days0To30 = 0.0,
    this.days31To60 = 0.0,
    this.days61To90 = 0.0,
    this.days90Plus = 0.0,
  });

  factory AgingBuckets.fromJson(dynamic json) {
    if (json == null || json is! Map) return const AgingBuckets();
    return AgingBuckets(
      days0To30: CustomerModel.parseDouble(json['days0_30'] ?? json['days0To30']),
      days31To60: CustomerModel.parseDouble(json['days31_60'] ?? json['days31To60']),
      days61To90: CustomerModel.parseDouble(json['days61_90'] ?? json['days61To90']),
      days90Plus: CustomerModel.parseDouble(json['days90Plus'] ?? json['days90_plus']),
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String address;
  final String country;
  final String state;
  final String district;
  final String city;
  final String mandal;
  final String pincode;
  final String addressLine;
  final String gstin;
  final String category; // 'RETAIL', 'WHOLESALE', 'REGULAR', 'VIP'
  final double openingBalance;
  final double currentBalance; // > 0: You'll Get (Receivable), < 0: You'll Give (Payable)
  final double creditLimit;
  final bool blockOnCreditBreach;
  final String notes;
  final List<String> tags;
  final double totalSales;
  final double totalPayments;
  final AgingBuckets aging;
  final DateTime? createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.companyName = '',
    required this.phone,
    this.email = '',
    this.address = '',
    this.country = 'India',
    this.state = '',
    this.district = '',
    this.city = '',
    this.mandal = '',
    this.pincode = '',
    this.addressLine = '',
    this.gstin = '',
    this.category = 'REGULAR',
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.creditLimit = 0.0,
    this.blockOnCreditBreach = false,
    this.notes = '',
    this.tags = const [],
    this.totalSales = 0.0,
    this.totalPayments = 0.0,
    this.aging = const AgingBuckets(),
    this.createdAt,
  });

  static double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.trim()) ?? 0.0;
    return 0.0;
  }

  static bool parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return false;
  }

  bool get willGet => currentBalance > 0;
  bool get willGive => currentBalance < 0;
  bool get isSettled => currentBalance == 0;
  bool get isDue => currentBalance > 0;

  bool get isCreditLimitBreached => creditLimit > 0 && currentBalance > creditLimit;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      companyName: (json['companyName'] ?? json['company_name'])?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: (json['city'] ?? json['district'])?.toString() ?? '',
      mandal: json['mandal']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      addressLine: (json['addressLine'] ?? json['address_line'])?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      category: json['category']?.toString() ?? 'REGULAR',
      openingBalance: parseDouble(json['openingBalance'] ?? json['opening_balance']),
      currentBalance: parseDouble(json['currentBalance'] ?? json['current_balance']),
      creditLimit: parseDouble(json['creditLimit'] ?? json['credit_limit']),
      blockOnCreditBreach: parseBool(json['blockOnCreditBreach'] ?? json['block_on_credit_breach']),
      notes: json['notes']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalSales: parseDouble(json['totalSales'] ?? json['total_sales']),
      totalPayments: parseDouble(json['totalPayments'] ?? json['total_payments']),
      aging: AgingBuckets.fromJson(json['aging']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'category': category,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'creditLimit': creditLimit,
      'blockOnCreditBreach': blockOnCreditBreach,
      'notes': notes,
      'tags': tags,
    };
  }
}
