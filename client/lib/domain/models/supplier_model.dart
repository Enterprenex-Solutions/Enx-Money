class SupplierModel {
  final String id;
  final String name;
  final String? companyName;
  final String category;
  final String? phone;
  final String? email;
  final String? address;
  final double totalBilled;
  final double outstandingPayable;
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.companyName,
    required this.category,
    this.phone,
    this.email,
    this.address,
    this.totalBilled = 0.0,
    this.outstandingPayable = 0.0,
    required this.createdAt,
  });

  SupplierModel copyWith({
    String? id,
    String? name,
    String? companyName,
    String? category,
    String? phone,
    String? email,
    String? address,
    double? totalBilled,
    double? outstandingPayable,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalBilled: totalBilled ?? this.totalBilled,
      outstandingPayable: outstandingPayable ?? this.outstandingPayable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'companyName': companyName,
        'category': category,
        'phone': phone,
        'email': email,
        'address': address,
        'totalBilled': totalBilled,
        'outstandingPayable': outstandingPayable,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
        id: json['id'] as String,
        name: json['name'] as String,
        companyName: json['companyName'] as String?,
        category: json['category'] as String? ?? 'General Vendor',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0.0,
        outstandingPayable: (json['outstandingPayable'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
