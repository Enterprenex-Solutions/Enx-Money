class UserCard {
  final String id;
  final String cardHolderName;
  final String cardNumber;
  final String lastFourDigits;
  final String expiryDate;
  final String cvv;
  final String cardTier; // 'Platinum', 'Black Metal', 'Signature'
  final String network; // 'Visa', 'Mastercard', 'RuPay'
  final double balance;
  final double limit;
  final double spentThisMonth;
  final bool isFrozen;
  final bool isBlackEdition;
  final bool isContactlessActive;
  final bool isInternationalActive;

  const UserCard({
    required this.id,
    required this.cardHolderName,
    required this.cardNumber,
    required this.lastFourDigits,
    required this.expiryDate,
    required this.cvv,
    required this.cardTier,
    required this.network,
    required this.balance,
    required this.limit,
    required this.spentThisMonth,
    this.isFrozen = false,
    this.isBlackEdition = true,
    this.isContactlessActive = true,
    this.isInternationalActive = false,
  });

  UserCard copyWith({
    String? id,
    String? cardHolderName,
    String? cardNumber,
    String? lastFourDigits,
    String? expiryDate,
    String? cvv,
    String? cardTier,
    String? network,
    double? balance,
    double? limit,
    double? spentThisMonth,
    bool? isFrozen,
    bool? isBlackEdition,
    bool? isContactlessActive,
    bool? isInternationalActive,
  }) {
    return UserCard(
      id: id ?? this.id,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumber: cardNumber ?? this.cardNumber,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardTier: cardTier ?? this.cardTier,
      network: network ?? this.network,
      balance: balance ?? this.balance,
      limit: limit ?? this.limit,
      spentThisMonth: spentThisMonth ?? this.spentThisMonth,
      isFrozen: isFrozen ?? this.isFrozen,
      isBlackEdition: isBlackEdition ?? this.isBlackEdition,
      isContactlessActive: isContactlessActive ?? this.isContactlessActive,
      isInternationalActive: isInternationalActive ?? this.isInternationalActive,
    );
  }

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['id'] as String? ?? '',
      cardHolderName: json['cardHolderName'] as String? ?? 'ENX MEMBER',
      cardNumber: json['cardNumber'] as String? ?? '••••  ••••  ••••  0000',
      lastFourDigits: json['lastFourDigits'] as String? ?? '0000',
      expiryDate: json['expiryDate'] as String? ?? '12/29',
      cvv: json['cvv'] as String? ?? '000',
      cardTier: json['cardTier'] as String? ?? 'Black Metal',
      network: json['network'] as String? ?? 'Visa',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      limit: (json['limit'] as num?)?.toDouble() ?? 500000.0,
      spentThisMonth: (json['spentThisMonth'] as num?)?.toDouble() ?? 0.0,
      isFrozen: json['isFrozen'] as bool? ?? false,
      isBlackEdition: json['isBlackEdition'] as bool? ?? true,
      isContactlessActive: json['isContactlessActive'] as bool? ?? true,
      isInternationalActive: json['isInternationalActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'lastFourDigits': lastFourDigits,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardTier': cardTier,
      'network': network,
      'balance': balance,
      'limit': limit,
      'spentThisMonth': spentThisMonth,
      'isFrozen': isFrozen,
      'isBlackEdition': isBlackEdition,
      'isContactlessActive': isContactlessActive,
      'isInternationalActive': isInternationalActive,
    };
  }
}
