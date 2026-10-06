class EnterpriseModel {
  final String id;
  final String companyName;
  final String gstin;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  const EnterpriseModel({
    required this.id,
    required this.companyName,
    required this.gstin,
    this.email,
    this.phone,
    this.address,
    required this.createdAt,
  });

  EnterpriseModel copyWith({
    String? id,
    String? companyName,
    String? gstin,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return EnterpriseModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      gstin: gstin ?? this.gstin,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyName': companyName,
        'gstin': gstin,
        'email': email,
        'phone': phone,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EnterpriseModel.fromJson(Map<String, dynamic> json) => EnterpriseModel(
        id: json['id'] as String,
        companyName: json['companyName'] as String,
        gstin: json['gstin'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
