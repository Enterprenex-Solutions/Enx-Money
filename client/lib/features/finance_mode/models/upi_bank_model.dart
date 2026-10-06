import 'package:flutter/material.dart';

class UpiBankModel {
  final String id;
  final String name;
  final String code;
  final String ifscPrefix;
  final bool isPopular;
  final Color brandColor;
  final IconData icon;

  const UpiBankModel({
    required this.id,
    required this.name,
    required this.code,
    required this.ifscPrefix,
    this.isPopular = false,
    this.brandColor = const Color(0xFF1E293B),
    this.icon = Icons.account_balance_rounded,
  });

  static const List<UpiBankModel> popularBanks = [
    UpiBankModel(
      id: 'hdfc',
      name: 'HDFC Bank',
      code: 'HDFC',
      ifscPrefix: 'HDFC',
      isPopular: true,
      brandColor: Color(0xFF004C8F),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'sbi',
      name: 'State Bank of India',
      code: 'SBI',
      ifscPrefix: 'SBIN',
      isPopular: true,
      brandColor: Color(0xFF280071),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'icici',
      name: 'ICICI Bank',
      code: 'ICICI',
      ifscPrefix: 'ICIC',
      isPopular: true,
      brandColor: Color(0xFFB02A30),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'axis',
      name: 'Axis Bank',
      code: 'AXIS',
      ifscPrefix: 'UTIB',
      isPopular: true,
      brandColor: Color(0xFF97144D),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'kotak',
      name: 'Kotak Mahindra Bank',
      code: 'KOTAK',
      ifscPrefix: 'KKBK',
      isPopular: true,
      brandColor: Color(0xFFED1C24),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'pnb',
      name: 'Punjab National Bank',
      code: 'PNB',
      ifscPrefix: 'PUNB',
      isPopular: true,
      brandColor: Color(0xFFA21D22),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'bob',
      name: 'Bank of Baroda',
      code: 'BOB',
      ifscPrefix: 'BARB',
      isPopular: true,
      brandColor: Color(0xFFF26522),
      icon: Icons.account_balance_rounded,
    ),
    UpiBankModel(
      id: 'indian',
      name: 'Indian Bank',
      code: 'INDIAN',
      ifscPrefix: 'IDIB',
      isPopular: true,
      brandColor: Color(0xFF003A70),
      icon: Icons.account_balance_rounded,
    ),
  ];

  static const List<UpiBankModel> allBanks = [
    ...popularBanks,
    UpiBankModel(
      id: 'idfc',
      name: 'IDFC FIRST Bank',
      code: 'IDFC',
      ifscPrefix: 'IDFB',
      brandColor: Color(0xFF991B1E),
    ),
    UpiBankModel(
      id: 'indusind',
      name: 'IndusInd Bank',
      code: 'INDUS',
      ifscPrefix: 'INDB',
      brandColor: Color(0xFF8B1D2C),
    ),
    UpiBankModel(
      id: 'canara',
      name: 'Canara Bank',
      code: 'CANARA',
      ifscPrefix: 'CNRB',
      brandColor: Color(0xFF0091DA),
    ),
    UpiBankModel(
      id: 'union',
      name: 'Union Bank of India',
      code: 'UNION',
      ifscPrefix: 'UBIN',
      brandColor: Color(0xFF003882),
    ),
    UpiBankModel(
      id: 'yes',
      name: 'Yes Bank',
      code: 'YES',
      ifscPrefix: 'YESB',
      brandColor: Color(0xFF005A9C),
    ),
    UpiBankModel(
      id: 'federal',
      name: 'Federal Bank',
      code: 'FEDERAL',
      ifscPrefix: 'FDRL',
      brandColor: Color(0xFF003A70),
    ),
    UpiBankModel(
      id: 'rbl',
      name: 'RBL Bank',
      code: 'RBL',
      ifscPrefix: 'RATN',
      brandColor: Color(0xFF004990),
    ),
    UpiBankModel(
      id: 'central',
      name: 'Central Bank of India',
      code: 'CENTRAL',
      ifscPrefix: 'CBIN',
      brandColor: Color(0xFF004C8F),
    ),
  ];
}
