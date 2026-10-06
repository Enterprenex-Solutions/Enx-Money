import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LineTrendChart extends StatelessWidget {
  final Map<DateTime, Map<String, double>> dailyTrend;

  const LineTrendChart({super.key, required this.dailyTrend});

  @override
  Widget build(BuildContext context) {
    if (dailyTrend.isEmpty) {
      return const Center(
        child: Text('No cash flow trend data available.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    final sortedDates = dailyTrend.keys.toList()..sort();
    final List<FlSpot> revenueSpots = [];
    final List<FlSpot> expenseSpots = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final rev = dailyTrend[date]?['revenue'] ?? 0.0;
      final exp = dailyTrend[date]?['expense'] ?? 0.0;

      revenueSpots.add(FlSpot(i.toDouble(), rev));
      expenseSpots.add(FlSpot(i.toDouble(), exp));
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedDates.length) return const SizedBox();
                      final date = sortedDates[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: revenueSpots,
                  isCurved: true,
                  color: const Color(0xFF10B981),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  ),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: const Color(0xFFEF4444),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(color: const Color(0xFF10B981), label: 'Revenue Inflow'),
            const SizedBox(width: 16),
            _buildLegend(color: const Color(0xFFEF4444), label: 'Expense Outflow'),
          ],
        )
      ],
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
