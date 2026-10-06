enum AppFlavor {
  merchant,
  consumer,
  field,
}

class Env {
  Env._();

  /// Primary Production Domains & Endpoints
  static const String webPortalUrl = 'https://enxmoney.enterprenex.solutions';
  static const String productionApiBaseUrl = 'https://api.enxmoney.enterprenex.solutions/api/v1';
  static const String productionApiRoot = 'https://api.enxmoney.enterprenex.solutions/api';
  static const String fallbackWebDomain = 'https://enxmoney.enterprenex.solutions';
  static const String fallbackCloudApiUrl = 'https://enx-money-api.onrender.com/api';
  static const String legalPoliciesHost = 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/';

  /// Corporate Entity & Statutory Contacts
  static const String companyName = 'Enterprenex Solutions Pvt. Ltd.';
  static const String grievanceOfficer = 'Mr. Rohit Pawar';
  static const String billingEmail = 'billing@enterprenex.solutions';
  static const String legalEmail = 'info@enterprenex.solutions';
  static const String supportEmail = 'support@enterprenex.solutions';
  static const String privacyEmail = 'privacy@enxmoney.com';
  static const String supportPhone = '+91-9226860060';
  static const String whatsappPhone = '+91 92268 60060';
  static const String whatsappUrl = 'https://wa.me/919226860060';
  static const String linkedinUrl =
      'https://www.linkedin.com/company/enterprenex-solution-pvt-ltd';
  static const String instagramUrl =
      'https://www.instagram.com/enterprenexsolution?utm_source=ig_web_button_share_sheet&stkn=ZDNlZDc0MzIxNw==';
  static const String registeredAddress =
      'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';

  /// Active flavor for multi-flavor deployment
  static AppFlavor activeFlavor = AppFlavor.merchant;

  static void setFlavor(AppFlavor flavor) {
    activeFlavor = flavor;
  }

  static String get appTitle {
    switch (activeFlavor) {
      case AppFlavor.merchant:
        return 'ENX Money Merchant';
      case AppFlavor.consumer:
        return 'ENX Money';
      case AppFlavor.field:
        return 'ENX Money Field';
    }
  }

  static String get packageName {
    switch (activeFlavor) {
      case AppFlavor.merchant:
        return 'com.enxmoney.merchant';
      case AppFlavor.consumer:
        return 'com.enxmoney.consumer';
      case AppFlavor.field:
        return 'com.enxmoney.field';
    }
  }

  /// Compile-time override or active default API URL
  static String get apiBaseUrl {
    const envApi = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envApi.isNotEmpty) return envApi;
    return productionApiBaseUrl;
  }
}
