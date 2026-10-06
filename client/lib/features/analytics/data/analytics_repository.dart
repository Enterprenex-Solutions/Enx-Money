import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/analytics_model.dart';
import '../models/kpi_summary_model.dart';

class AnalyticsRepository {
  static final AnalyticsRepository _instance = AnalyticsRepository._internal();
  factory AnalyticsRepository() => _instance;
  AnalyticsRepository._internal();

  final ApiClient _apiClient = ApiClient();
  KpiSummary _cachedKpi = KpiSummary.empty();

  KpiSummary get cachedKpi => _cachedKpi;

  /// Fetch the 7 Core KPI Data Analysis metrics from the backend
  Future<KpiSummary> getKpi({
    String? profileType = 'business',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (profileType != null && profileType.isNotEmpty) {
        queryParams['profile_type'] = profileType;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      String endpoint = ApiConfig.analyticsKpi;
      if (queryParams.isNotEmpty) {
        final query = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
        endpoint = '$endpoint?$query';
      }

      final response = await _apiClient.get(endpoint);
      if (response['success'] == true && response['data'] != null) {
        _cachedKpi = KpiSummary.fromJson(response['data'] as Map<String, dynamic>);
        return _cachedKpi;
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] getKpi error: $e');
    }
    return _cachedKpi;
  }

  /// Fetch Daily Trend for charts
  Future<Map<String, dynamic>> getDailyTrend({
    String? profileType = 'business',
    int days = 7,
  }) async {
    try {
      final endpoint = '${ApiConfig.analyticsDailyTrend}?profile_type=$profileType&days=$days';
      final response = await _apiClient.get(endpoint);
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] getDailyTrend error: $e');
    }
    return {'trend': [], 'totalRevenueInPeriod': 0.0, 'totalExpenseInPeriod': 0.0};
  }

  /// Fetch Category Breakdown
  Future<List<Map<String, dynamic>>> getCategories({
    String? profileType = 'business',
    String type = 'expense',
  }) async {
    try {
      final endpoint = '${ApiConfig.analyticsCategories}?profile_type=$profileType&type=$type';
      final response = await _apiClient.get(endpoint);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data']['categories'] as List?;
        if (list != null) {
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] getCategories error: $e');
    }
    return [];
  }

  /// Fetch Live Business Health Score (0 - 100)
  Future<Map<String, dynamic>?> getHealthScore() async {
    try {
      final response = await _apiClient.get(ApiConfig.analyticsHealthScore);
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] getHealthScore error: $e');
    }
    return null;
  }

  /// Fetch Comprehensive Dashboard Analytics & Charts Dataset
  Future<Map<String, dynamic>?> getDashboardCharts({
    String mode = 'BUSINESS',
    String period = 'THIS_MONTH',
  }) async {
    try {
      final endpoint = '${ApiConfig.analyticsDashboard}?mode=$mode&period=$period';
      final response = await _apiClient.get(endpoint);
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] getDashboardCharts error: $e');
    }
    return null;
  }

  /// Get Monthly Analytics derived from real backend data
  Future<MonthlyExpenseAnalytics> getMonthlyAnalytics() async {
    final kpi = await getKpi();
    final categories = await getCategories(type: 'expense');

    double totalSpent = kpi.totalExpense;
    double monthlyBudget = kpi.totalRevenue > 0 ? kpi.totalRevenue : (totalSpent > 0 ? totalSpent * 1.2 : 100000.0);

    final catMetrics = <SpendingCategoryMetric>[];
    for (final c in categories) {
      final name = c['category']?.toString() ?? 'Other';
      final amt = (c['amount'] is num)
          ? (c['amount'] as num).toDouble()
          : (double.tryParse(c['amount']?.toString() ?? '0') ?? 0.0);
      final pct = totalSpent > 0 ? (amt / totalSpent) : 0.0;
      catMetrics.add(
        SpendingCategoryMetric(
          categoryName: name,
          amount: amt,
          percentage: pct,
          icon: Icons.category_outlined,
          color: AppColors.primaryGreen,
          transactionCount: (c['count'] is int) ? c['count'] as int : 1,
        ),
      );
    }

    return MonthlyExpenseAnalytics(
      totalSpent: totalSpent,
      monthlyBudget: monthlyBudget,
      dailyAverage: totalSpent > 0 ? totalSpent / 30 : 0.0,
      savingsRate: kpi.totalRevenue > 0
          ? (((kpi.totalRevenue - totalSpent) / kpi.totalRevenue) * 100).clamp(0.0, 100.0)
          : 0.0,
      weeklySpends: [totalSpent * 0.25, totalSpent * 0.25, totalSpent * 0.25, totalSpent * 0.25],
      topCategories: catMetrics,
    );
  }
}
