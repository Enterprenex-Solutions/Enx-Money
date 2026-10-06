import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../../../core/widgets/feedback/stat_badge.dart';
import '../../data/analytics_repository.dart';
import '../../models/analytics_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  MonthlyExpenseAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final data = await _analyticsRepo.getMonthlyAnalytics();
    if (mounted) {
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    final data = _analytics!;
    final budgetPercent = (data.totalSpent / data.monthlyBudget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FintechAppBar(
        title: 'Spending Insights',
        subtitle: 'MONTH OF AUGUST',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Card
            FintechCard(
              hasGlow: true,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL MONTHLY OUTFLOW',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      StatBadge(
                        text: '${data.savingsRate}% SAVINGS RATE',
                        type: StatBadgeType.positive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(data.totalSpent),
                    style: AppTypography.currencyLarge.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Average: ${CurrencyFormatter.format(data.dailyAverage, showDecimals: false)}/day',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        'Budget: ${CurrencyFormatter.format(data.monthlyBudget, showDecimals: false)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: budgetPercent,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weekly Spends Bar Chart
            Text(
              'WEEKLY SPEND TRENDS',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),

            FintechCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(data.weeklySpends.length, (index) {
                      final amount = data.weeklySpends[index];
                      const maxSpend = 35000.0;
                      final barHeight = (amount / maxSpend * 100).clamp(20.0, 100.0);
                      final isCurrentWeek = index == 3;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatCompact(amount),
                            style: AppTypography.badge.copyWith(
                              fontSize: 10,
                              color: isCurrentWeek ? AppColors.primaryGreen : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 38,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isCurrentWeek
                                  ? AppColors.primaryGreen
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentWeek
                                    ? AppColors.primaryGreen
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'W${index + 1}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isCurrentWeek ? AppColors.pureWhite : AppColors.textTertiary,
                              fontWeight: isCurrentWeek ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Spending Categories
            Text(
              'CATEGORY BREAKDOWN',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),

            ...data.topCategories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FintechCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat.icon, size: 20, color: cat.color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.categoryName, style: AppTypography.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '${cat.transactionCount} transactions',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(cat.amount),
                                style: AppTypography.currencySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(cat.percentage * 100).toStringAsFixed(1)}%',
                                style: AppTypography.badge.copyWith(
                                  color: cat.color,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cat.percentage,
                          minHeight: 4,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
