import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

class DashboardMetrics {
  final double totalBusinessBalance;
  final double totalInflow;
  final double totalOutflow;
  final double sales;
  final double expenses;
  final double netProfit;
  final double outstandingReceivables;
  final double outstandingPayables;
  final double bankLedgerTotal;

  const DashboardMetrics({
    required this.totalBusinessBalance,
    required this.totalInflow,
    required this.totalOutflow,
    required this.sales,
    required this.expenses,
    required this.netProfit,
    required this.outstandingReceivables,
    required this.outstandingPayables,
    required this.bankLedgerTotal,
  });

  factory DashboardMetrics.empty() {
    return const DashboardMetrics(
      totalBusinessBalance: 0.0,
      totalInflow: 0.0,
      totalOutflow: 0.0,
      sales: 0.0,
      expenses: 0.0,
      netProfit: 0.0,
      outstandingReceivables: 0.0,
      outstandingPayables: 0.0,
      bankLedgerTotal: 0.0,
    );
  }

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final inflow = (json['totalInflow'] as num?)?.toDouble() ??
        (json['totalRevenue'] as num?)?.toDouble() ??
        0.0;
    final outflow = (json['totalOutflow'] as num?)?.toDouble() ??
        (json['totalExpense'] as num?)?.toDouble() ??
        0.0;
    final sales = (json['sales'] as num?)?.toDouble() ??
        (json['totalSales'] as num?)?.toDouble() ??
        inflow;
    final expenses = (json['expenses'] as num?)?.toDouble() ?? outflow;
    final netProfit = (json['netProfit'] as num?)?.toDouble() ?? (sales - expenses);
    final bankLedger = (json['bankLedgerTotal'] as num?)?.toDouble() ?? 0.0;

    double balance = (json['totalBusinessBalance'] as num?)?.toDouble() ?? (inflow - outflow);
    if (balance == 0.0 && bankLedger > 0) {
      balance = bankLedger;
    }

    return DashboardMetrics(
      totalBusinessBalance: balance,
      totalInflow: inflow,
      totalOutflow: outflow,
      sales: sales,
      expenses: expenses,
      netProfit: netProfit,
      outstandingReceivables: (json['outstandingReceivables'] as num?)?.toDouble() ?? 0.0,
      outstandingPayables: (json['outstandingPayables'] as num?)?.toDouble() ?? 0.0,
      bankLedgerTotal: bankLedger,
    );
  }
}

class DashboardRepository {
  static final DashboardRepository _instance = DashboardRepository._internal();
  factory DashboardRepository() => _instance;
  DashboardRepository._internal();

  final ApiClient _apiClient = ApiClient();
  DashboardMetrics _cachedMetrics = DashboardMetrics.empty();

  DashboardMetrics get cachedMetrics => _cachedMetrics;

  /// Fetch live business metrics from backend /dashboard/metrics
  Future<DashboardMetrics> getMetrics({double fallbackReceivable = 0.0}) async {
    try {
      final response = await _apiClient.get(ApiConfig.dashboardMetrics);
      if (response['success'] == true && response['data'] != null) {
        _cachedMetrics = DashboardMetrics.fromJson(response['data'] as Map<String, dynamic>);
        return _cachedMetrics;
      }
    } catch (e) {
      debugPrint('[DashboardRepository] getMetrics error: $e');
    }

    // Fallback: If backend is offline or customer receivable is positive while metrics are 0
    if (_cachedMetrics.sales == 0.0 && fallbackReceivable > 0.0) {
      _cachedMetrics = DashboardMetrics(
        totalBusinessBalance: fallbackReceivable,
        totalInflow: fallbackReceivable,
        totalOutflow: 0.0,
        sales: fallbackReceivable,
        expenses: 0.0,
        netProfit: fallbackReceivable,
        outstandingReceivables: fallbackReceivable,
        outstandingPayables: 0.0,
        bankLedgerTotal: 0.0,
      );
    }

    return _cachedMetrics;
  }
}
