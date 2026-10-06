import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/dashboard/data/dashboard_repository.dart';

void main() {
  group('DashboardMetrics & Live Calculation Tests', () {
    test('1. DashboardMetrics.fromJson parses valid live data correctly', () {
      final json = {
        'totalBusinessBalance': 50000.0,
        'totalInflow': 50000.0,
        'totalOutflow': 10000.0,
        'sales': 45000.0,
        'expenses': 10000.0,
        'netProfit': 35000.0,
        'outstandingReceivables': 50000.0,
        'outstandingPayables': 5000.0,
        'bankLedgerTotal': 25000.0,
      };

      final metrics = DashboardMetrics.fromJson(json);

      expect(metrics.totalBusinessBalance, equals(50000.0));
      expect(metrics.totalInflow, equals(50000.0));
      expect(metrics.totalOutflow, equals(10000.0));
      expect(metrics.sales, equals(45000.0));
      expect(metrics.expenses, equals(10000.0));
      expect(metrics.netProfit, equals(35000.0));
      expect(metrics.outstandingReceivables, equals(50000.0));
      expect(metrics.outstandingPayables, equals(5000.0));
      expect(metrics.bankLedgerTotal, equals(25000.0));
    });

    test('2. DashboardMetrics handles empty / fallback calculations correctly', () {
      final metrics = DashboardMetrics.empty();
      expect(metrics.totalBusinessBalance, equals(0.0));
      expect(metrics.totalInflow, equals(0.0));
      expect(metrics.totalOutflow, equals(0.0));
      expect(metrics.sales, equals(0.0));
      expect(metrics.expenses, equals(0.0));
      expect(metrics.netProfit, equals(0.0));
    });

    test('3. Balance formula computes Inflow - Outflow when balance not explicitly provided', () {
      final json = {
        'totalInflow': 60000.0,
        'totalOutflow': 15000.0,
        'sales': 60000.0,
        'expenses': 15000.0,
      };

      final metrics = DashboardMetrics.fromJson(json);
      expect(metrics.totalBusinessBalance, equals(45000.0));
      expect(metrics.netProfit, equals(45000.0));
    });

    test('4. Bank ledger fallback activates when inflow and outflow are 0 but bank accounts exist', () {
      final json = {
        'totalInflow': 0.0,
        'totalOutflow': 0.0,
        'sales': 0.0,
        'expenses': 0.0,
        'bankLedgerTotal': 75000.0,
      };

      final metrics = DashboardMetrics.fromJson(json);
      expect(metrics.totalBusinessBalance, equals(75000.0));
    });
  });
}
