// ENX Money — Subscription Plan Model
class PlanFeature {
  final String featureCode;
  final String featureName;
  final bool isEnabled;
  final int? limitValue; // null = unlimited
  final String limitType; // BOOLEAN, COUNT, UNLIMITED

  const PlanFeature({
    required this.featureCode,
    required this.featureName,
    required this.isEnabled,
    this.limitValue,
    required this.limitType,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      featureCode: json['feature_code'] as String? ?? '',
      featureName: json['feature_name'] as String? ?? '',
      isEnabled: (json['is_enabled'] == true || json['is_enabled'] == 1),
      limitValue: json['limit_value'] as int?,
      limitType: json['limit_type'] as String? ?? 'BOOLEAN',
    );
  }

  String get displayLimit {
    if (limitType == 'UNLIMITED' || (limitValue != null && limitValue! >= 999999)) return 'Unlimited';
    if (limitValue != null) return limitValue.toString();
    return isEnabled ? '✓' : '—';
  }
}

class PlanModel {
  final String id;
  final String name; // FREE, BASIC, PRO, ADVANCED, BUSINESS
  final String displayName;
  final String description;
  final double priceMonthly;
  final double priceYearly;
  final String currency;
  final int trialDays;
  final bool isActive;
  final int sortOrder;
  final List<PlanFeature> features;

  const PlanModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.priceMonthly,
    required this.priceYearly,
    this.currency = 'INR',
    this.trialDays = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.features = const [],
  });

  double get savingsAmount => priceMonthly * 12 - priceYearly;
  double get savingsPercent => priceMonthly > 0 ? (savingsAmount / (priceMonthly * 12)) * 100 : 0;

  bool get isFree => name == 'FREE';

  String priceFormatted(String cycle) {
    final price = cycle == 'YEARLY' ? priceYearly : priceMonthly;
    if (price == 0) return '₹0 / month';
    return cycle == 'YEARLY' ? '₹${price.toInt()} / year' : '₹${price.toInt()} / month';
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final featuresList = (json['features'] as List<dynamic>? ?? [])
        .map((f) => PlanFeature.fromJson(f as Map<String, dynamic>))
        .toList();
    return PlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceMonthly: (json['price_monthly'] as num?)?.toDouble() ?? 0.0,
      priceYearly: (json['price_yearly'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      trialDays: json['trial_days'] as int? ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      features: featuresList,
    );
  }

  /// Get feature value for a specific code
  PlanFeature? getFeature(String code) {
    try {
      return features.firstWhere((f) => f.featureCode == code);
    } catch (_) {
      return null;
    }
  }

  bool hasFeature(String code) => getFeature(code)?.isEnabled == true;

  static List<PlanModel> get defaultPlans => [
    const PlanModel(
      id: 'plan-free',
      name: 'FREE',
      displayName: 'Free Plan',
      description: 'Core personal expense & income tracking',
      priceMonthly: 0,
      priceYearly: 0,
      currency: 'INR',
      sortOrder: 1,
      features: [
        PlanFeature(featureCode: 'EXPENSE_TRACKING', featureName: 'Expense Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INCOME_TRACKING', featureName: 'Income Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'BANK_ACCOUNT', featureName: 'Bank Accounts', isEnabled: true, limitValue: 1, limitType: 'COUNT'),
      ],
    ),
    const PlanModel(
      id: 'plan-basic',
      name: 'BASIC',
      displayName: 'Basic — Personal Plus',
      description: 'Personal budgeting, transfers & UPI integration',
      priceMonthly: 199,
      priceYearly: 1999,
      currency: 'INR',
      sortOrder: 2,
      features: [
        PlanFeature(featureCode: 'EXPENSE_TRACKING', featureName: 'Expense Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INCOME_TRACKING', featureName: 'Income Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'CUSTOM_CATEGORIES', featureName: 'Custom Categories', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'BANK_ACCOUNT', featureName: 'Bank Accounts', isEnabled: true, limitValue: 3, limitType: 'COUNT'),
        PlanFeature(featureCode: 'ACCOUNT_TRANSFER', featureName: 'Account Transfers', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'BUSINESS_EXPENSE', featureName: 'Business Expenses', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'UPI', featureName: 'UPI Integration', isEnabled: true, limitType: 'BOOLEAN'),
      ],
    ),
    const PlanModel(
      id: 'plan-pro',
      name: 'PRO',
      displayName: 'Pro — Smart Finance',
      description: 'WhatsApp AI Assistant, settlements, loans & analytics',
      priceMonthly: 499,
      priceYearly: 4999,
      currency: 'INR',
      sortOrder: 3,
      features: [
        PlanFeature(featureCode: 'EXPENSE_TRACKING', featureName: 'Expense Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INCOME_TRACKING', featureName: 'Income Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'CUSTOM_CATEGORIES', featureName: 'Custom Categories', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'ADVANCED_REPORTS', featureName: 'Advanced Reports', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'BANK_ACCOUNT', featureName: 'Bank Accounts', isEnabled: true, limitValue: 10, limitType: 'COUNT'),
        PlanFeature(featureCode: 'SETTLEMENT', featureName: 'Settlement Engine', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'AUTOPAY', featureName: 'Autopay Mandates', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'LOAN_MANAGEMENT', featureName: 'Loan Management', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'WHATSAPP_CHATBOT', featureName: 'WhatsApp AI Chatbot', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'ADVANCED_ANALYTICS', featureName: 'Advanced Analytics', isEnabled: true, limitType: 'BOOLEAN'),
      ],
    ),
    const PlanModel(
      id: 'plan-advanced',
      name: 'ADVANCED',
      displayName: 'Advanced — Business',
      description: 'GST reports, invoicing suite & team collaboration',
      priceMonthly: 999,
      priceYearly: 9999,
      currency: 'INR',
      sortOrder: 4,
      features: [
        PlanFeature(featureCode: 'EXPENSE_TRACKING', featureName: 'Expense Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INCOME_TRACKING', featureName: 'Income Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'BANK_ACCOUNT', featureName: 'Bank Accounts', isEnabled: true, limitValue: 25, limitType: 'COUNT'),
        PlanFeature(featureCode: 'WHATSAPP_CHATBOT', featureName: 'WhatsApp AI Chatbot', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'GST_REPORT', featureName: 'GST Reports', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INVOICE_MANAGEMENT', featureName: 'Invoice Management', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'TEAM_MEMBER', featureName: 'Team Members', isEnabled: true, limitValue: 10, limitType: 'COUNT'),
        PlanFeature(featureCode: 'ROLE_MANAGEMENT', featureName: 'Role Management', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'ADMIN_DASHBOARD', featureName: 'Admin Dashboard', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'API_ACCESS', featureName: 'API Access', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'PRIORITY_SUPPORT', featureName: 'Priority Support', isEnabled: true, limitType: 'BOOLEAN'),
      ],
    ),
    const PlanModel(
      id: 'plan-business',
      name: 'BUSINESS',
      displayName: 'Business Suite',
      description: 'Unlimited banks, 25 team seats, dedicated API',
      priceMonthly: 1999,
      priceYearly: 19999,
      currency: 'INR',
      sortOrder: 5,
      features: [
        PlanFeature(featureCode: 'EXPENSE_TRACKING', featureName: 'Expense Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INCOME_TRACKING', featureName: 'Income Tracking', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'BANK_ACCOUNT', featureName: 'Bank Accounts', isEnabled: true, limitValue: 999999, limitType: 'UNLIMITED'),
        PlanFeature(featureCode: 'WHATSAPP_CHATBOT', featureName: 'WhatsApp AI Chatbot', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'GST_REPORT', featureName: 'GST Reports', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'INVOICE_MANAGEMENT', featureName: 'Invoice Management', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'TEAM_MEMBER', featureName: 'Team Members', isEnabled: true, limitValue: 25, limitType: 'COUNT'),
        PlanFeature(featureCode: 'ROLE_MANAGEMENT', featureName: 'Role Management', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'ADMIN_DASHBOARD', featureName: 'Admin Dashboard', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'API_ACCESS', featureName: 'API Access', isEnabled: true, limitType: 'BOOLEAN'),
        PlanFeature(featureCode: 'PRIORITY_SUPPORT', featureName: 'Priority Support', isEnabled: true, limitType: 'BOOLEAN'),
      ],
    ),
  ];
}
