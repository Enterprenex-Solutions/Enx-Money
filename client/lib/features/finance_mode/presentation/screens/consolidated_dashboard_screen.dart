import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/finance/app_card.dart';
import '../../data/finance_mode_repository.dart';

class ConsolidatedDashboardScreen extends StatefulWidget {
  const ConsolidatedDashboardScreen({super.key});

  @override
  State<ConsolidatedDashboardScreen> createState() => _ConsolidatedDashboardScreenState();
}

class _ConsolidatedDashboardScreenState extends State<ConsolidatedDashboardScreen> {
  final _repo = FinanceModeRepository();
  bool _isLoading = true;

  double _businessAssets = 0.0;
  double _businessLiabilities = 0.0;
  double _personalAssets = 0.0;
  double _personalLiabilities = 0.0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final data = await _repo.getConsolidatedOverview();
      if (mounted && data.isNotEmpty) {
        setState(() {
          final biz = data['business'] as Map<String, dynamic>?;
          final per = data['personal'] as Map<String, dynamic>?;
          if (biz != null) {
            _businessAssets = (biz['assets'] as num?)?.toDouble() ?? _businessAssets;
            _businessLiabilities = (biz['liabilities'] as num?)?.toDouble() ?? _businessLiabilities;
          }
          if (per != null) {
            _personalAssets = (per['assets'] as num?)?.toDouble() ?? _personalAssets;
            _personalLiabilities = (per['liabilities'] as num?)?.toDouble() ?? _personalLiabilities;
          }
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessNet = _businessAssets - _businessLiabilities;
    final personalNet = _personalAssets - _personalLiabilities;
    final combinedNetWorth = businessNet + personalNet;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consolidated Net Worth', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Fund Transfer',
            onPressed: () => Navigator.pushNamed(context, '/fund-transfer'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Combined Net Worth Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardLuxuryGradient,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderGlow),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL CONSOLIDATED NET WORTH',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(combinedNetWorth, showDecimals: false),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Business + Personal accounts across all connected banks & assets',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Business vs Personal Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildNetCard(
                          title: 'Business Net',
                          amount: businessNet,
                          assets: _businessAssets,
                          liabilities: _businessLiabilities,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNetCard(
                          title: 'Personal Net',
                          amount: personalNet,
                          assets: _personalAssets,
                          liabilities: _personalLiabilities,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Asset Breakdown List
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consolidated Assets & Receivables',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildAssetRow('Bank Liquid Balances', 1845620.0),
                        const Divider(height: 16, color: AppColors.border),
                        _buildAssetRow('Inventory Stock Valuation', 680000.0),
                        const Divider(height: 16, color: AppColors.border),
                        _buildAssetRow('Customer Khata Receivables', 450000.0),
                        const Divider(height: 16, color: AppColors.border),
                        _buildAssetRow('Personal Savings & Mutual Funds', 294380.0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liabilities List
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consolidated Obligations & Payables',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildAssetRow('Supplier Trade Payables', 128500.0, isLiability: true),
                        const Divider(height: 16, color: AppColors.border),
                        _buildAssetRow('Business Equipment Loan Principal', 321500.0, isLiability: true),
                        const Divider(height: 16, color: AppColors.border),
                        _buildAssetRow('Personal Vehicle EMI Principal', 150000.0, isLiability: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildNetCard({
    required String title,
    required double amount,
    required double assets,
    required double liabilities,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'Assets: ${CurrencyFormatter.formatCompact(assets)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            'Liabilities: ${CurrencyFormatter.formatCompact(liabilities)}',
            style: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetRow(String label, double amount, {bool isLiability = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          CurrencyFormatter.format(amount, showDecimals: false),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isLiability ? AppColors.error : Colors.white,
          ),
        ),
      ],
    );
  }
}
