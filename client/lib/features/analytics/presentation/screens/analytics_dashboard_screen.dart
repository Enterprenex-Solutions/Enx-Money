import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/analytics_repository.dart';
import '../../models/kpi_summary_model.dart';
import '../../models/business_health_score_model.dart';
import '../widgets/data_analysis_card.dart';
import '../widgets/business_health_score_card.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  KpiSummary _kpi = KpiSummary.empty();
  BusinessHealthScore? _healthScore = BusinessHealthScore.initial();
  List<Map<String, dynamic>> _trend = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  String _profileType = 'business'; // 'business' or 'personal'
  String _selectedCategoryType = 'expense'; // 'expense' or 'revenue'
  String? _selectedCardKey;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final kpiFuture = _analyticsRepo.getKpi(profileType: _profileType);
      final trendFuture = _analyticsRepo.getDailyTrend(profileType: _profileType, days: 7);
      final catFuture = _analyticsRepo.getCategories(profileType: _profileType, type: _selectedCategoryType);
      final healthFuture = _profileType == 'business'
          ? _analyticsRepo.getHealthScore()
          : Future<Map<String, dynamic>?>.value(null);

      final results = await Future.wait([kpiFuture, trendFuture, catFuture, healthFuture]);
      if (mounted) {
        setState(() {
          _kpi = results[0] as KpiSummary;
          final trendData = results[1] as Map<String, dynamic>;
          _trend = (trendData['trend'] as List? ?? []).cast<Map<String, dynamic>>();
          _categories = (results[2] as List? ?? []).cast<Map<String, dynamic>>();
          final healthData = results[3] as Map<String, dynamic>?;
          if (_profileType == 'business' && healthData != null) {
            _healthScore = BusinessHealthScore.fromJson(healthData);
          } else {
            _healthScore = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9);
    final surfaceColor = isDark ? const Color(0xFF141824) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.analytics_rounded, color: Color(0xFF00E676), size: 22),
            const SizedBox(width: 8),
            Text(
              'Data Analysis & Analytics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            onPressed: _fetchAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : RefreshIndicator(
              onRefresh: _fetchAnalyticsData,
              color: const Color(0xFF00E676),
              backgroundColor: surfaceColor,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 85),
                children: [
                  // Profile Selector (Business / Personal)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _buildProfileTab('Business Analytics', 'business', Icons.business_center_rounded),
                        _buildProfileTab('Personal Analytics', 'personal', Icons.person_rounded),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_profileType == 'business') ...[
                    // Live Business Health Score Card (Requirement 8)
                    if (_healthScore != null) ...[
                      BusinessHealthScoreCard(
                        healthScore: _healthScore!,
                        onRefresh: _fetchAnalyticsData,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Section Header: Core Business KPIs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FINANCIAL HEALTH METRICS',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LIVE API',
                            style: TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 6 Business KPI Cards Grid (Responsive childAspectRatio)
                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final cardWidth = gridConstraints.maxWidth;
                        final ratio = cardWidth < 350 ? 1.20 : (cardWidth < 400 ? 1.25 : 1.30);

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: ratio,
                          children: [
                            DataAnalysisCard(
                              title: 'Total Revenue',
                              amount: _kpi.totalRevenue,
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF00E676),
                              subtitle: 'Gross Inflow',
                              isSelected: _selectedCardKey == 'revenue',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'revenue' ? null : 'revenue'),
                            ),
                            DataAnalysisCard(
                              title: 'Total Expense',
                              amount: _kpi.totalExpense,
                              icon: Icons.trending_down_rounded,
                              color: const Color(0xFFFF5252),
                              subtitle: 'Total Outflow',
                              isSelected: _selectedCardKey == 'expense',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'expense' ? null : 'expense'),
                            ),
                            DataAnalysisCard(
                              title: 'Net Profit',
                              amount: _kpi.netProfit,
                              icon: Icons.account_balance_wallet_rounded,
                              color: _kpi.netProfit >= 0 ? const Color(0xFF2979FF) : const Color(0xFFFF5252),
                              subtitle: _kpi.netProfit >= 0 ? 'Surplus' : 'Deficit',
                              isSelected: _selectedCardKey == 'profit',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'profit' ? null : 'profit'),
                            ),
                            DataAnalysisCard(
                              title: 'Receivables',
                              amount: _kpi.outstandingReceivables,
                              icon: Icons.call_received_rounded,
                              color: const Color(0xFF00E5FF),
                              subtitle: 'Pending Income',
                              isSelected: _selectedCardKey == 'receivables',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'receivables' ? null : 'receivables'),
                            ),
                            DataAnalysisCard(
                              title: 'Payables',
                              amount: _kpi.outstandingPayables,
                              icon: Icons.call_made_rounded,
                              color: const Color(0xFFFF9100),
                              subtitle: 'Pending Bills',
                              isSelected: _selectedCardKey == 'payables',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'payables' ? null : 'payables'),
                            ),
                            DataAnalysisCard(
                              title: 'GST Payable',
                              amount: _kpi.gstPayable,
                              icon: Icons.receipt_long_rounded,
                              color: const Color(0xFF7C4DFF),
                              subtitle: 'Est. Tax Due',
                              isSelected: _selectedCardKey == 'gst',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'gst' ? null : 'gst'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Inventory Valuation full width card
                    DataAnalysisCard(
                      title: 'Inventory Valuation',
                      amount: _kpi.inventoryValue,
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFFFB300),
                      subtitle: 'Total Stock at Cost Price',
                      isSelected: _selectedCardKey == 'inventory',
                      onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'inventory' ? null : 'inventory'),
                    ),

                    const SizedBox(height: 12),

                    // EMI Due This Month full width card
                    DataAnalysisCard(
                      title: 'EMI Due This Month',
                      amount: _kpi.emiDueThisMonth,
                      icon: Icons.credit_card_rounded,
                      color: const Color(0xFFFF1744),
                      subtitle: 'Scheduled Loan Installments',
                      isSelected: _selectedCardKey == 'emi',
                      onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'emi' ? null : 'emi'),
                    ),
                  ] else ...[
                    // Personal Analytics UI - strictly isolated from business metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PERSONAL FINANCIAL SUMMARY',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PERSONAL',
                            style: TextStyle(color: Color(0xFF2979FF), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2 Core Personal KPI Cards (Responsive)
                    LayoutBuilder(
                      builder: (context, personalGridConstraints) {
                        final cardWidth = personalGridConstraints.maxWidth;
                        final ratio = cardWidth < 350 ? 1.20 : (cardWidth < 400 ? 1.25 : 1.30);

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: ratio,
                          children: [
                            DataAnalysisCard(
                              title: 'Personal Inflow',
                              amount: _kpi.totalRevenue,
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF00E676),
                              subtitle: 'Income & Deposits',
                              isSelected: _selectedCardKey == 'revenue',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'revenue' ? null : 'revenue'),
                            ),
                            DataAnalysisCard(
                              title: 'Personal Outflow',
                              amount: _kpi.totalExpense,
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFFF5252),
                              subtitle: 'Living & Personal Expenses',
                              isSelected: _selectedCardKey == 'expense',
                              onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'expense' ? null : 'expense'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Net Savings Card
                    DataAnalysisCard(
                      title: 'Net Savings',
                      amount: _kpi.netProfit,
                      icon: Icons.savings_rounded,
                      color: _kpi.netProfit >= 0 ? const Color(0xFF2979FF) : const Color(0xFFFF5252),
                      subtitle: _kpi.netProfit >= 0 ? 'Surplus / Available Balance' : 'Net Deficit',
                      isSelected: _selectedCardKey == 'profit',
                      onTap: () => setState(() => _selectedCardKey = _selectedCardKey == 'profit' ? null : 'profit'),
                    ),

                    const SizedBox(height: 14),

                    // Informational Message for Personal Analytics
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF2979FF), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Analytics',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Personal finance analytics will be available here. Track individual income, personal expense categories, and monthly savings separate from your business accounts.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Daily Cash Flow Inflow vs Outflow Section
                  _buildDailyTrendSection(),

                  const SizedBox(height: 20),

                  // Category Breakdown Section
                  _buildCategoryBreakdownSection(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTab(String title, String value, IconData icon) {
    final isSelected = _profileType == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _profileType = value);
          _fetchAnalyticsData();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTrendSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY CASH FLOW TREND',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
              ),
              Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF00E676), size: 10),
                  SizedBox(width: 4),
                  Text('Inflow', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  SizedBox(width: 10),
                  Icon(Icons.circle, color: Color(0xFFFF5252), size: 10),
                  SizedBox(width: 4),
                  Text('Outflow', style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_trend.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No cash flow records found for this period.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            Column(
              children: _trend.map((day) {
                final dateStr = day['date'] as String? ?? '';
                final rev = (day['revenue'] as num?)?.toDouble() ?? 0.0;
                final exp = (day['expense'] as num?)?.toDouble() ?? 0.0;
                final maxVal = (rev > exp ? rev : exp);

                DateTime? dt;
                try {
                  dt = DateTime.parse(dateStr);
                } catch (_) {}
                final label = dt != null ? DateFormat('E, dd MMM').format(dt) : dateStr;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 75,
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (rev > 0)
                              Container(
                                height: 8,
                                width: (rev / (maxVal > 0 ? maxVal : 1)) * 140,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            if (exp > 0) ...[
                              const SizedBox(height: 2),
                              Container(
                                height: 8,
                                width: (exp / (maxVal > 0 ? maxVal : 1)) * 140,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                            if (rev == 0 && exp == 0)
                              Container(
                                height: 4,
                                width: 20,
                                color: Colors.white12,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (rev > 0)
                            Text('+${_currencyFormat.format(rev)}', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                          if (exp > 0)
                            Text('-${_currencyFormat.format(exp)}', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold)),
                          if (rev == 0 && exp == 0)
                            const Text('₹0', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CATEGORY BREAKDOWN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
              ),
              Row(
                children: [
                  _buildCatChip('Expense', 'expense'),
                  const SizedBox(width: 6),
                  _buildCatChip('Revenue', 'revenue'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No categorized entries found.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            Column(
              children: _categories.map((cat) {
                final name = cat['category'] as String? ?? 'General';
                final amount = (cat['amount'] as num?)?.toDouble() ?? 0.0;
                final percentage = (cat['percentage'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_currencyFormat.format(amount)} (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceElevated,
                        color: _selectedCategoryType == 'expense' ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, String value) {
    final isSelected = _selectedCategoryType == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedCategoryType = value);
        _fetchAnalyticsData();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF00E676) : Colors.grey.shade800),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E676) : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
