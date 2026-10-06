import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/global_analytics_model.dart';
import '../../data/super_admin_repository.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final SuperAdminRepository _repo = SuperAdminRepository();
  final TextEditingController _searchController = TextEditingController();

  int _retentionDays = 7; // 7, 30, 90
  String _accountFilter = 'All'; // 'All', 'Personal', 'Business'
  String _statusFilter = 'All'; // 'All', 'Active', 'Suspended'
  int _currentPage = 1;
  static const int _pageSize = 5;

  String? _expandedCountryCode;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _repo.loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.file_download_outlined, color: Color(0xFF00E676), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Export Global Analytics Report',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select report format to download or share executive telemetry logs:',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // CSV Option
                ListTile(
                  tileColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.table_chart_rounded, color: Color(0xFF3B82F6), size: 28),
                  title: Text(
                    'Download Raw Data (CSV)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Complete audit log with all active users & IP telemetry',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _isExporting = true);
                    await _repo.exportCsvReport();
                    if (mounted) {
                      setState(() => _isExporting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV Telemetry Report Exported Successfully!')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                // PDF Option
                ListTile(
                  tileColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 28),
                  title: Text(
                    'Download Executive Summary (PDF)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Formatted printable document with KPI grids & regional summaries',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _isExporting = true);
                    await _repo.exportPdfReport();
                    if (mounted) setState(() => _isExporting = false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        final kpis = _repo.kpis;
        final geoMetrics = _repo.geoMetrics;
        final retentionData = _repo.getRetention(_retentionDays);

        final totalFilteredCount = _repo.getFilteredUsersCount(
          query: _searchController.text,
          accountFilter: _accountFilter,
          statusFilter: _statusFilter,
        );

        final totalPages = (totalFilteredCount / _pageSize).ceil().clamp(1, 999);
        final paginatedUsers = _repo.getFilteredUsers(
          query: _searchController.text,
          accountFilter: _accountFilter,
          statusFilter: _statusFilter,
          page: _currentPage,
          pageSize: _pageSize,
        );

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF0B0E14) : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: primaryTextColor,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Super Admin Console',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'GLOBAL TELEMETRY & AUDIT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Export Button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isExporting ? null : _handleExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.download_rounded, size: 16, color: Colors.black),
                  label: const Text(
                    'Export',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF00E676),
            onRefresh: () => _repo.loadDashboardData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Online Sessions Banner
                  _buildLiveSessionBanner(kpis.activeLiveSessions, isDark),
                  const SizedBox(height: 16),

                  // 1. Top KPI Summary Cards
                  _buildSectionTitle('PLATFORM PERFORMANCE KPIS', isDark),
                  const SizedBox(height: 10),
                  _buildKpiGrid(kpis, isDark),
                  const SizedBox(height: 24),

                  // 2. Global & Regional Analytics
                  _buildSectionTitle('GLOBAL USER DISTRIBUTION', isDark),
                  const SizedBox(height: 10),
                  _buildGeoAnalyticsCard(geoMetrics, isDark),
                  const SizedBox(height: 24),

                  // 3. User Retention & Churn Rate Metrics
                  _buildRetentionSection(retentionData, isDark),
                  const SizedBox(height: 24),

                  // 4. Live User Activity Telemetry Table
                  _buildSectionTitle('LIVE USER ACTIVITY TELEMETRY', isDark),
                  const SizedBox(height: 10),
                  _buildTelemetryTableCard(
                    paginatedUsers: paginatedUsers,
                    totalCount: totalFilteredCount,
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  /// Live Online Session Pulse Banner
  Widget _buildLiveSessionBanner(int activeSessions, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors_rounded, color: Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ONLINE LIVE SESSIONS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'PULSE',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${NumberFormat('#,###').format(activeSessions)} Active Sessions Across 48 Countries',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4 Top KPI Cards (Grid layout)
  Widget _buildKpiGrid(GlobalKpiSummary kpis, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Worldwide Users',
                value: NumberFormat('#,###').format(kpis.totalWorldwideUsers),
                badgeText: '+${kpis.userGrowthPercentage}% MoM',
                isPositive: true,
                icon: Icons.public_rounded,
                accentColor: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Active Users (DAU/MAU)',
                value: '${NumberFormat.compact().format(kpis.dailyActiveUsers)} / ${NumberFormat.compact().format(kpis.monthlyActiveUsers)}',
                badgeText: '${kpis.dauMauRatio.toStringAsFixed(1)}% Ratio',
                isPositive: true,
                icon: Icons.trending_up_rounded,
                accentColor: const Color(0xFF00E676),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Business vs Personal',
                value: '${kpis.businessRatio.toStringAsFixed(0)}% : ${kpis.personalRatio.toStringAsFixed(0)}%',
                badgeText: '${NumberFormat.compact().format(kpis.businessAccountsCount)} Biz',
                isPositive: true,
                icon: Icons.pie_chart_outline_rounded,
                accentColor: const Color(0xFFA855F7),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Active Live Sessions',
                value: NumberFormat('#,###').format(kpis.activeLiveSessions),
                badgeText: 'Online Now',
                isPositive: true,
                icon: Icons.bolt_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String badgeText,
    required bool isPositive,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? const Color(0xFF00E676) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? (isDark ? const Color(0xFF00E676) : const Color(0xFF059669)) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Global & Regional Analytics Section
  Widget _buildGeoAnalyticsCard(List<GeoCountryMetric> geoList, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Countries & Regional Hubs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'TAP TO EXPAND STATES',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...geoList.map((country) {
            final isExpanded = _expandedCountryCode == country.countryCode;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _expandedCountryCode = isExpanded ? null : country.countryCode;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isExpanded
                              ? const Color(0xFF3B82F6)
                              : (isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  country.countryName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                NumberFormat('#,###').format(country.userCount),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${country.percentageShare}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: country.percentageShare / 100,
                              backgroundColor: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable States
                  if (isExpanded && country.states.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141824) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${country.countryName.toUpperCase()} REGIONAL BREAKDOWN',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...country.states.map((st) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      st.stateName,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          NumberFormat('#,###').format(st.userCount),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${st.percentage}%)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF3B82F6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// User Retention & Churn Rate Section
  Widget _buildRetentionSection(List<RetentionDataPoint> retentionList, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Retention vs Churn Rate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              // Duration Toggles: 7D, 30D, 90D
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [7, 30, 90].map((days) {
                    final isSelected = _retentionDays == days;
                    return InkWell(
                      onTap: () => setState(() => _retentionDays = days),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${days}D',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.black : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendPill('Retention Rate (%)', const Color(0xFF00E676)),
              const SizedBox(width: 14),
              _buildLegendPill('Churn Rate (%)', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (retentionList.length / 4).ceilToDouble().clamp(1, 99),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < retentionList.length) {
                          return Text(
                            DateFormat('MM/dd').format(retentionList[idx].date),
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  // Retention Line
                  LineChartBarData(
                    spots: retentionList.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.retentionRate);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF00E676),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    ),
                  ),
                  // Churn Line
                  LineChartBarData(
                    spots: retentionList.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.churnRate);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 4. Live User Activity Telemetry Table
  Widget _buildTelemetryTableCard({
    required List<UserTelemetryRecord> paginatedUsers,
    required int totalCount,
    required int currentPage,
    required int totalPages,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _currentPage = 1),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
            decoration: InputDecoration(
              hintText: 'Search by User ID, Name, Email, or City...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF3B82F6)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _currentPage = 1);
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00E676)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filters: Account Type & Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _accountFilter == 'All', () {
                  setState(() {
                    _accountFilter = 'All';
                    _currentPage = 1;
                  });
                }, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Personal', _accountFilter == 'Personal', () {
                  setState(() {
                    _accountFilter = 'Personal';
                    _currentPage = 1;
                  });
                }, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Business', _accountFilter == 'Business', () {
                  setState(() {
                    _accountFilter = 'Business';
                    _currentPage = 1;
                  });
                }, isDark),
                const SizedBox(width: 16),
                Container(height: 18, width: 1, color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1)),
                const SizedBox(width: 16),
                _buildFilterChip('Active Only', _statusFilter == 'Active', () {
                  setState(() {
                    _statusFilter = _statusFilter == 'Active' ? 'All' : 'Active';
                    _currentPage = 1;
                  });
                }, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Suspended Only', _statusFilter == 'Suspended', () {
                  setState(() {
                    _statusFilter = _statusFilter == 'Suspended' ? 'All' : 'Suspended';
                    _currentPage = 1;
                  });
                }, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Telemetry List
          if (paginatedUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No matching active users found.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paginatedUsers.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (ctx, index) {
                final user = paginatedUsers[index];
                return _buildUserTelemetryRow(user, isDark);
              },
            ),

          const SizedBox(height: 16),

          // Pagination Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${paginatedUsers.length} of $totalCount Users',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                    iconSize: 20,
                  ),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676)
              : (isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E676)
                : (isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.black : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTelemetryRow(UserTelemetryRecord user, bool isDark) {
    final isOnline = user.lastActive.contains('Online') || user.lastActive.contains('Just now');
    final isSuspended = user.status == 'Suspended';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Initials Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: user.accountType == 'Business'
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                    : const Color(0xFF00E676).withValues(alpha: 0.15),
                child: Text(
                  user.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: user.accountType == 'Business' ? const Color(0xFF3B82F6) : const Color(0xFF00E676),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name & User ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.id,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status Toggle Button
              InkWell(
                onTap: () => _repo.toggleUserStatus(user.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isSuspended ? const Color(0xFFEF4444) : const Color(0xFF00E676)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isSuspended ? const Color(0xFFEF4444) : const Color(0xFF00E676)).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuspended ? Icons.block_rounded : Icons.check_circle_rounded,
                        size: 12,
                        color: isSuspended ? const Color(0xFFEF4444) : const Color(0xFF00E676),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isSuspended ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF00E676) : const Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetaPill(
                icon: user.accountType == 'Business' ? Icons.storefront_rounded : Icons.person_rounded,
                label: user.accountType,
                color: user.accountType == 'Business' ? const Color(0xFF3B82F6) : const Color(0xFFA855F7),
                isDark: isDark,
              ),
              _buildMetaPill(
                icon: Icons.pie_chart_rounded,
                label: 'Profile: ${user.profileCompletion}%',
                color: user.profileCompletion == 100
                    ? const Color(0xFF00E676)
                    : (user.profileCompletion >= 75 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)),
                isDark: isDark,
              ),
              _buildMetaPill(
                icon: Icons.location_on_outlined,
                label: user.region,
                color: const Color(0xFF94A3B8),
                isDark: isDark,
              ),
              _buildMetaPill(
                icon: Icons.access_time_rounded,
                label: user.lastActive,
                color: isOnline ? const Color(0xFF00E676) : const Color(0xFF94A3B8),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
