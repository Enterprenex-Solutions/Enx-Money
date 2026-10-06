import 'package:flutter/material.dart';

class HealthScoreMetric {
  final int score;
  final int max;
  final double? metricValue;
  final String? label;

  const HealthScoreMetric({
    required this.score,
    required this.max,
    this.metricValue,
    this.label,
  });

  factory HealthScoreMetric.fromJson(Map<String, dynamic>? json, {String? defaultLabel}) {
    if (json == null) return const HealthScoreMetric(score: 0, max: 20);
    return HealthScoreMetric(
      score: (json['score'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 20,
      metricValue: (json['profitMargin'] ?? json['expenseRatio'] ?? json['totalReceivable'] ?? json['totalLiabilities'] ?? json['activeCustomers'] as num?)?.toDouble(),
      label: defaultLabel,
    );
  }
}

class BusinessHealthScore {
  final int score;
  final String status;
  final String statusColorHex;
  final bool hasSufficientData;
  final Map<String, HealthScoreMetric> breakdown;
  final List<String> actionableTips;
  final DateTime calculatedAt;

  const BusinessHealthScore({
    required this.score,
    required this.status,
    required this.statusColorHex,
    this.hasSufficientData = true,
    required this.breakdown,
    required this.actionableTips,
    required this.calculatedAt,
  });

  bool get isInsufficientData => status.toUpperCase().contains('INSUFFICIENT') || !hasSufficientData;

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'EXCELLENT':
        return const Color(0xFF00E676);
      case 'HEALTHY':
        return const Color(0xFF00BCD4);
      case 'NEEDS ATTENTION':
        return const Color(0xFFFFB300);
      case 'CRITICAL':
        return const Color(0xFFFF5252);
      case 'INSUFFICIENT DATA':
      case 'INSUFFICIENT_DATA':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF00BCD4);
    }
  }

  factory BusinessHealthScore.initial() {
    return BusinessHealthScore(
      score: 80,
      status: 'HEALTHY',
      statusColorHex: '#00BCD4',
      breakdown: {
        'profitability': const HealthScoreMetric(score: 20, max: 25, label: 'Profit Margin'),
        'collections': const HealthScoreMetric(score: 20, max: 25, label: 'Collection Rate'),
        'expenseControl': const HealthScoreMetric(score: 16, max: 20, label: 'Expense Control'),
        'liabilityCoverage': const HealthScoreMetric(score: 12, max: 15, label: 'Debt Coverage'),
        'customerActivity': const HealthScoreMetric(score: 12, max: 15, label: 'Customer Base'),
      },
      actionableTips: const [
        'Maintain prompt customer invoice follow-ups to maximize collection efficiency.',
      ],
      calculatedAt: DateTime.now(),
    );
  }

  factory BusinessHealthScore.fromJson(Map<String, dynamic> json) {
    final bd = json['breakdown'] as Map<String, dynamic>? ?? {};
    final tips = (json['actionableTips'] as List? ?? []).map((e) => e.toString()).toList();

    return BusinessHealthScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'HEALTHY',
      statusColorHex: (json['statusColor'] as String?) ?? '#00E676',
      hasSufficientData: (json['hasSufficientData'] as bool?) ?? ((json['status'] as String?) != 'INSUFFICIENT DATA'),
      breakdown: {
        'profitability': HealthScoreMetric.fromJson(bd['profitability'] as Map<String, dynamic>?, defaultLabel: 'Profit Margin'),
        'collections': HealthScoreMetric.fromJson(bd['collections'] as Map<String, dynamic>?, defaultLabel: 'Collection Rate'),
        'expenseControl': HealthScoreMetric.fromJson(bd['expenseControl'] as Map<String, dynamic>?, defaultLabel: 'Expense Control'),
        'liabilityCoverage': HealthScoreMetric.fromJson(bd['liabilityCoverage'] as Map<String, dynamic>?, defaultLabel: 'Debt Coverage'),
        'customerActivity': HealthScoreMetric.fromJson(bd['customerActivity'] as Map<String, dynamic>?, defaultLabel: 'Customer Base'),
      },
      actionableTips: tips.isNotEmpty ? tips : ['Operations are steady and functioning within healthy operational benchmarks.'],
      calculatedAt: DateTime.tryParse(json['calculatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
