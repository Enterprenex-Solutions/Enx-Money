class SupplierModel {
  final String id;
  final String name;
  final String contactNumber;
  final String email;
  final String companyName;
  final String gstin;
  final String address;
  final String country;
  final String state;
  final String district;
  final String city;
  final String mandal;
  final String pincode;
  final double openingBalance;
  final double outstandingPayable;
  final String category;
  final String paymentTerms;
  final String? dueDate;
  final bool dueReminderEnabled;
  final String? reminderDate;
  final String notes;
  final String status;
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    required this.contactNumber,
    this.email = '',
    this.companyName = '',
    this.gstin = '',
    this.address = '',
    this.country = 'India',
    this.state = '',
    this.district = '',
    this.city = '',
    this.mandal = '',
    this.pincode = '',
    this.openingBalance = 0.0,
    this.outstandingPayable = 0.0,
    this.category = 'RAW_MATERIALS',
    this.paymentTerms = 'Net 30',
    this.dueDate,
    this.dueReminderEnabled = false,
    this.reminderDate,
    this.notes = '',
    this.status = 'ACTIVE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    final double opBal = (json['openingBalance'] is num)
        ? (json['openingBalance'] as num).toDouble()
        : (json['opening_balance'] is num ? (json['opening_balance'] as num).toDouble() : 0.0);

    final double outPay = (json['outstandingPayable'] is num)
        ? (json['outstandingPayable'] as num).toDouble()
        : (json['outstanding_payable'] is num
            ? (json['outstanding_payable'] as num).toDouble()
            : (json['currentBalance'] is num
                ? (json['currentBalance'] as num).toDouble()
                : (json['current_balance'] is num
                    ? (json['current_balance'] as num).toDouble()
                    : opBal)));

    DateTime created;
    try {
      created = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now());
    } catch (_) {
      created = DateTime.now();
    }

    return SupplierModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactNumber: (json['contactNumber'] ?? json['phone'] ?? json['contact_number'] ?? '').toString(),
      email: json['email']?.toString() ?? '',
      companyName: (json['companyName'] ?? json['company_name'] ?? '').toString(),
      gstin: json['gstin']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      mandal: json['mandal']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      openingBalance: opBal,
      outstandingPayable: outPay,
      category: json['category']?.toString() ?? 'RAW_MATERIALS',
      paymentTerms: (json['paymentTerms'] ?? json['payment_terms'] ?? 'Net 30').toString(),
      dueDate: json['dueDate']?.toString() ?? json['due_date']?.toString(),
      dueReminderEnabled: json['dueReminderEnabled'] == true || json['due_reminder_enabled'] == true,
      reminderDate: json['reminderDate']?.toString() ?? json['reminder_date']?.toString(),
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactNumber': contactNumber,
      'email': email,
      'companyName': companyName,
      'gstin': gstin,
      'address': address,
      'country': country,
      'state': state,
      'district': district,
      'city': city,
      'mandal': mandal,
      'pincode': pincode,
      'openingBalance': openingBalance,
      'outstandingPayable': outstandingPayable,
      'category': category,
      'paymentTerms': paymentTerms,
      'dueDate': dueDate,
      'dueReminderEnabled': dueReminderEnabled,
      'reminderDate': reminderDate,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
