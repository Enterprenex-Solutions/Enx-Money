// ENX Money — Entitlement Repository
import 'package:flutter/foundation.dart';
import 'subscription_repository.dart';
import '../models/subscription_model.dart';

class EntitlementRepository {
  static final EntitlementRepository _instance = EntitlementRepository._internal();
  factory EntitlementRepository() => _instance;
  EntitlementRepository._internal();

  final SubscriptionRepository _subRepo = SubscriptionRepository();

  /// Check if the user is allowed to access a given feature
  Future<bool> canAccess(String featureCode) async {
    return _subRepo.canAccess(featureCode);
  }

  /// Get numeric limit for a feature (null means unlimited or boolean)
  Future<int?> getLimit(String featureCode) async {
    try {
      final entitlements = await _subRepo.getEntitlements();
      final feat = entitlements[featureCode];
      if (feat == null) return null;
      final limit = feat['limit'];
      if (limit == null) return null;
      if (limit is int) return limit;
      return int.tryParse(limit.toString());
    } catch (e) {
      debugPrint('[EntitlementRepo] getLimit error: $e');
      return null;
    }
  }

  /// Fetch full active subscription
  Future<SubscriptionModel> getCurrentSubscription({bool forceRefresh = false}) {
    return _subRepo.getCurrentSubscription(forceRefresh: forceRefresh);
  }

  /// Clear cache upon sign-out or plan upgrade
  void clearCache() {
    _subRepo.clearCache();
  }
}
