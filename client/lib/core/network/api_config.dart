import 'package:flutter/foundation.dart';
import '../../config/env.dart';

class ApiConfig {
  ApiConfig._();

  /// Configurable Base URL via compile-time environment variable:
  /// e.g. flutter build apk --dart-define=API_BASE_URL=https://api.enxmoney.enterprenex.solutions/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Primary Production API Endpoints
  static const String productionApiV1Url = Env.productionApiBaseUrl; // https://api.enxmoney.enterprenex.solutions/api/v1
  static const String productionApiRootUrl = Env.productionApiRoot; // https://api.enxmoney.enterprenex.solutions/api
  static const String publicCloudBaseUrl = 'https://enxmoney.enterprenex.solutions/api';
  static const String apexCloudBaseUrl = 'https://enterprenex.solutions/api';

  /// Fallback cloud endpoint (Render deployment) for high-availability resilience
  static const String fallbackCloudBaseUrl = 'https://enx-money-api.onrender.com/api';

  /// Local development host machine LAN IP (active: 192.168.1.2)
  static const String devHostIp = '192.168.1.2';

  /// Candidate base URLs in order of priority:
  /// - Web/Desktop: localhost -> 127.0.0.1 -> public cloud
  /// - Mobile (Physical Android / iOS):
  ///   1. Custom API_BASE_URL (if provided)
  ///   2. Production API Base URL (api.enxmoney.enterprenex.solutions)
  ///   3. Public Cloud HTTPS (enxmoney.enterprenex.solutions)
  ///   4. Developer LAN IP (for local Wi-Fi debugging)
  ///   5. Android Emulator loopback (10.0.2.2)
  static List<String> get candidateBaseUrls {
    final list = <String>[];

    // In production release builds, strictly use the HTTPS cloud endpoint or explicit --dart-define
    if (kReleaseMode) {
      if (_envBaseUrl.isNotEmpty) {
        list.add(_normalizeUrl(_envBaseUrl));
      } else {
        list.add(productionApiV1Url);
        list.add(productionApiRootUrl);
        list.add(publicCloudBaseUrl);
        list.add(apexCloudBaseUrl);
        list.add(fallbackCloudBaseUrl);
      }
      return list;
    }

    // 1. If explicit API_BASE_URL is provided via --dart-define, prioritize it
    if (_envBaseUrl.isNotEmpty) {
      list.add(_normalizeUrl(_envBaseUrl));
    }

    if (kIsWeb) {
      final webCandidates = <String>[];
      if (_envBaseUrl.isNotEmpty) webCandidates.add(_normalizeUrl(_envBaseUrl));
      try {
        if (Uri.base.origin.isNotEmpty && !Uri.base.origin.startsWith('file:') && !Uri.base.origin.startsWith('null')) {
          webCandidates.add('${Uri.base.origin}/api');
        }
      } catch (_) {}
      webCandidates.add(publicCloudBaseUrl);
      for (final u in webCandidates) {
        if (!list.contains(u)) list.add(u);
      }
      return list;
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      final desktopCandidates = [
        'http://localhost:5000/api',
        'http://127.0.0.1:5000/api',
        publicCloudBaseUrl,
      ];
      for (final u in desktopCandidates) {
        if (!list.contains(u)) list.add(u);
      }
      return list;
    }

    // Physical Android & iOS candidates (Debug only):
    final mobileCandidates = [
      publicCloudBaseUrl,
      'http://$devHostIp:5000/api',
      'http://192.168.1.4:5000/api',
      'http://10.0.2.2:5000/api',
    ];

    for (final u in mobileCandidates) {
      if (!list.contains(u)) list.add(u);
    }

    return list;
  }

  /// Default active base URL
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _normalizeUrl(_envBaseUrl);
    }
    if (kIsWeb) {
      try {
        if (Uri.base.origin.isNotEmpty && !Uri.base.origin.startsWith('file:') && !Uri.base.origin.startsWith('null')) {
          return '${Uri.base.origin}/api';
        }
      } catch (_) {}
      return publicCloudBaseUrl;
    }
    if (kReleaseMode) {
      return publicCloudBaseUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:5000/api';
    }
    return publicCloudBaseUrl;
  }

  static String _normalizeUrl(String url) {
    String trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  // Auth endpoints
  static const String checkRegistered = '/auth/check-registered';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String sendOtp = '/auth/send-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String verifyPassword = '/auth/verify-password';
  static const String getMe = '/auth/me';
  static const String userProfile = '/v1/user/profile';
  static const String kycStatus = '/finance/kyc/status';
  static const String logout = '/auth/logout';
  static const String deleteAccount = '/users/account';

  // Security Questions endpoints
  static const String securityQuestionsCatalog = '/auth/security-questions';
  static const String securityQuestionsSetup = '/auth/security-questions/setup';
  static const String securityQuestionsForUser = '/auth/security-questions/for-user';
  static const String securityQuestionsVerify = '/auth/security-questions/verify';

  // Multi-Device Login & Approval endpoints
  static String deviceApprovalStatus(String requestId) => '/auth/device-approval-status/$requestId';
  static const String pendingDeviceApprovals = '/auth/pending-device-approvals';
  static const String approveDevice = '/auth/approve-device';
  static const String rejectDevice = '/auth/reject-device';
  static const String userDevices = '/auth/devices';
  static String revokeDevice(String deviceId) => '/auth/devices/$deviceId';

  // Loan & EMI endpoints
  static const String loans = '/loans';
  static const String calculateEmi = '/loans/calculate';
  static const String previewSchedule = '/loans/preview-schedule';
  static const String upcomingSchedules = '/loans/schedules/upcoming';

  // Cards endpoints
  static const String cards = '/cards';
  static const String myCards = '/cards/me';

  // Customer Management & Khata endpoints
  static const String customers = '/customers';
  static String customerDetails(String id) => '/customers/$id';
  static String customerLedger(String id) => '/customers/$id/ledger';
  static String customerReminder(String id) => '/customers/$id/remind';

  // Dashboard Metrics endpoint
  static const String dashboardMetrics = '/dashboard/metrics';

  // Data Analysis & Analytics endpoints (Anjali Branch Integration)
  static const String analyticsKpi = '/analytics/kpi';
  static const String analyticsDailyTrend = '/analytics/daily-trend';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsHealthScore = '/analytics/health-score';
  static const String reverseGeocode = '/locations/reverse-geocode';

  // AI Assistant endpoints
  static const String aiChat = '/ai/chat';
  static const String aiHistory = '/ai/history';

  // Centralized Legal & Compliance URLs (Google Play Policy)
  static const String _envPrivacyUrl = String.fromEnvironment('PRIVACY_POLICY_URL', defaultValue: '');
  static const String _envTermsUrl = String.fromEnvironment(
    'TERMS_AND_CONDITIONS_URL',
    defaultValue: String.fromEnvironment('TERMS_URL', defaultValue: ''),
  );
  static const String _envRefundUrl = String.fromEnvironment('REFUND_POLICY_URL', defaultValue: '');
  static const String _envFrontendUrl = String.fromEnvironment('FRONTEND_URL', defaultValue: '');

  /// Permanent production web host domain (custom subdomain)
  static const String productionWebDomain = 'https://enxmoney.enterprenex.solutions';
  static const String productionGitHubPagesLegalHost = 'https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/';

  static String _getWebBaseUrl() {
    if (_envFrontendUrl.isNotEmpty) return _normalizeUrl(_envFrontendUrl);
    if (_envBaseUrl.isNotEmpty) {
      final normalized = _normalizeUrl(_envBaseUrl);
      return normalized.endsWith('/api') ? normalized.substring(0, normalized.length - 4) : normalized;
    }
    return productionWebDomain;
  }

  static String get privacyPolicyUrl {
    if (_envPrivacyUrl.isNotEmpty) return _envPrivacyUrl;
    if (kIsWeb) return '/privacy-policy';
    return '${_getWebBaseUrl()}/privacy-policy';
  }

  static String get termsUrl {
    if (_envTermsUrl.isNotEmpty) return _envTermsUrl;
    if (kIsWeb) return '/terms-and-conditions';
    return '${_getWebBaseUrl()}/terms-and-conditions';
  }

  static String get termsAndConditionsUrl => termsUrl;

  static String get refundPolicyUrl {
    if (_envRefundUrl.isNotEmpty) return _envRefundUrl;
    if (kIsWeb) return '/refund-cancellation-policy';
    return '${_getWebBaseUrl()}/refund-cancellation-policy';
  }

  static String get deleteAccountWebUrl {
    if (kIsWeb) return '/delete-account';
    return '${_getWebBaseUrl()}/delete-account';
  }
}
