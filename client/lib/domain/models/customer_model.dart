class CustomerModel {
  final String id;
  final String name;
  final String? companyName;
  final String? phone;
  final String? email;
  final String? address;
  final double totalInvoiced;
  final double outstandingBalance;
  final DateTime createdAt;
  final String status; // 'active' or 'inactive' (Section 6 & 10)
  final String customerType; // 'Enterprise', 'SMB', 'Retail' (Section 4)
  final String businessCategory; // 'Technology', 'Healthcare', 'Retail', etc.

  const CustomerModel({
    required this.id,
    required this.name,
    this.companyName,
    this.phone,
    this.email,
    this.address,
    this.totalInvoiced = 0.0,
    this.outstandingBalance = 0.0,
    required this.createdAt,
    this.status = 'active',
    this.customerType = 'Enterprise',
    this.businessCategory = 'Technology & Services',
  });

  bool get isActive => status.toLowerCase() == 'active';

  CustomerModel copyWith({
    String? id,
    String? name,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    double? totalInvoiced,
    double? outstandingBalance,
    DateTime? createdAt,
    String? status,
    String? customerType,
    String? businessCategory,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalInvoiced: totalInvoiced ?? this.totalInvoiced,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      customerType: customerType ?? this.customerType,
      businessCategory: businessCategory ?? this.businessCategory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'companyName': companyName,
        'phone': phone,
        'email': email,
        'address': address,
        'totalInvoiced': totalInvoiced,
        'outstandingBalance': outstandingBalance,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'customerType': customerType,
        'businessCategory': businessCategory,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        name: json['name'] as String,
        companyName: json['companyName'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        totalInvoiced: (json['totalInvoiced'] as num?)?.toDouble() ?? 0.0,
        outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: (json['status'] as String?) ?? 'active',
        customerType: (json['customerType'] as String?) ?? 'Enterprise',
        businessCategory: (json['businessCategory'] as String?) ?? 'Technology & Services',
      );
}
