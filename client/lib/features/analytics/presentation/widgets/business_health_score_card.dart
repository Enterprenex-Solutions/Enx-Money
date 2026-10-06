import 'package:flutter/material.dart';
import '../../models/business_health_score_model.dart';

class BusinessHealthScoreCard extends StatelessWidget {
  final BusinessHealthScore healthScore;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewDetails;

  const BusinessHealthScoreCard({
    super.key,
    required this.healthScore,
    this.onRefresh,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131824) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final innerTileBg = isDark ? const Color(0xFF1B2232) : const Color(0xFFF8FAFC);

    final statusColor = healthScore.statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 310;

          final badgeWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    healthScore.status.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section - Responsive layout to guarantee no overflow
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.speed_rounded, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BUSINESS HEALTH SCORE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'AI Financial Vitality',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    badgeWidget,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.speed_rounded, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUSINESS HEALTH SCORE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI Financial Vitality',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    badgeWidget,
                  ],
                ),

              const SizedBox(height: 14),

              if (healthScore.isInsufficientData) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: innerTileBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: statusColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Awaiting First Business Activity',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Health Score evaluates real-time profit margins, collection rates, and expense control. Add your first customer or record a transaction to unlock AI financial diagnostics.',
                        softWrap: true,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Score Gauge + Core Pillars Row (Responsive)
                LayoutBuilder(
                  builder: (context, scoreConstraints) {
                    final isCompactScore = scoreConstraints.maxWidth < 300;

                    final radialGauge = SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              value: healthScore.score / 100.0,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${healthScore.score}',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                '/ 100',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final pillarsColumn = Column(
                      children: [
                        _buildMetricRow('Profit Margin', healthScore.breakdown['profitability'], statusColor, isDark),
                        const SizedBox(height: 6),
                        _buildMetricRow('Collection Rate', healthScore.breakdown['collections'], const Color(0xFF00BCD4), isDark),
                        const SizedBox(height: 6),
                        _buildMetricRow('Expense Control', healthScore.breakdown['expenseControl'], const Color(0xFFFFB300), isDark),
                        const SizedBox(height: 6),
                        _buildMetricRow('Debt Coverage', healthScore.breakdown['liabilityCoverage'], const Color(0xFF8B5CF6), isDark),
                      ],
                    );

                    if (isCompactScore) {
                      return Column(
                        children: [
                          Center(child: radialGauge),
                          const SizedBox(height: 12),
                          pillarsColumn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        radialGauge,
                        const SizedBox(width: 16),
                        Expanded(child: pillarsColumn),
                      ],
                    );
                  },
                ),
              ],

              // Actionable Tips Pill
              if (healthScore.actionableTips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: innerTileBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFB300), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          healthScore.actionableTips.first,
                          softWrap: true,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, HealthScoreMetric? metric, Color color, bool isDark) {
    final score = metric?.score ?? 0;
    final max = metric?.max ?? 20;
    final pct = max > 0 ? (score / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score/$max',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
