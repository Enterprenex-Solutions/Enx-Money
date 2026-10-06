import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  final bool isDark;

  const ExpenseTrendChart({
    super.key,
    required this.monthlyData,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN');
    final surfaceColor = isDark ? const Color(0xFF141824) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    double maxVal = 1000.0;
    bool hasData = false;
    final spots = <FlSpot>[];

    for (int i = 0; i < monthlyData.length; i++) {
      final exp = (monthlyData[i]['expense'] as num?)?.toDouble() ?? 0.0;
      if (exp > 0) hasData = true;
      if (exp > maxVal) maxVal = exp;
      spots.add(FlSpot(i.toDouble(), exp));
    }
    maxVal = (maxVal * 1.25).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPENSE TREND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly Expense Outflow',
                    style: TextStyle(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_down_rounded, size: 12, color: Color(0xFFFF5252)),
                    SizedBox(width: 4),
                    Text(
                      'Outflow',
                      style: TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (!hasData || spots.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart_rounded, size: 36, color: subtextColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'No expenses recorded yet.',
                    style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Record an expense to monitor spending trends.',
                    style: TextStyle(color: subtextColor.withValues(alpha: 0.7), fontSize: 10),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => isDark ? const Color(0xFF1E2638) : const Color(0xFF0F172A),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final monthName = idx >= 0 && idx < monthlyData.length
                              ? (monthlyData[idx]['month'] ?? '')
                              : '';
                          final val = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
                              .format(spot.y);
                          return LineTooltipItem(
                            '$monthName\nExpense: $val',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Text(
                            currency.format(val),
                            style: TextStyle(color: subtextColor, fontSize: 9),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < monthlyData.length) {
                            final m = monthlyData[idx];
                            final label = m['shortMonth'] ?? m['month']?.toString().split(' ')[0] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label,
                                style: TextStyle(color: subtextColor, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFFFF5252),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFFFF5252),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFF5252).withValues(alpha: 0.28),
                            const Color(0xFFFF5252).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
