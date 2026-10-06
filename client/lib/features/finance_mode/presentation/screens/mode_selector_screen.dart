import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/finance_mode/finance_mode_service.dart';
import '../../../../core/widgets/finance/mode_toggle_switch.dart';
import '../../../../core/widgets/finance/app_card.dart';
import '../../../../core/services/notification_service.dart';

class ModeSelectorScreen extends StatefulWidget {
  const ModeSelectorScreen({super.key});

  @override
  State<ModeSelectorScreen> createState() => _ModeSelectorScreenState();
}

class _ModeSelectorScreenState extends State<ModeSelectorScreen> {
  late FinanceMode _selectedMode;
  String _selectedBusinessId = 'biz_001';

  final List<Map<String, dynamic>> _businesses = [
    {
      'id': 'biz_001',
      'name': 'Apex Enterprises Ltd.',
      'type': 'Wholesale & Manufacturing',
      'gstin': '27AABCU9603R1ZM',
      'role': 'Primary Admin',
      'branches': 3,
    },
    {
      'id': 'biz_002',
      'name': 'Apex Retail Hub',
      'type': 'Direct Retail & Storefront',
      'gstin': '27AABCU9603R1ZN',
      'role': 'Owner',
      'branches': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMode = FinanceModeService().mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finance Mode & Workspace', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Switcher
            ModeToggleSwitch(
              currentMode: _selectedMode,
              onModeChanged: (mode) {
                setState(() => _selectedMode = mode);
                FinanceModeService().setMode(mode);
                NotificationService.showSuccess(
                  mode == FinanceMode.business
                      ? 'Switched to Business Finance Mode'
                      : 'Switched to Personal Household Mode',
                );
              },
            ),
            const SizedBox(height: 20),

            if (_selectedMode == FinanceMode.business) ...[
              const Text(
                'Registered Businesses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 10),
              ..._businesses.map((b) {
                final isSelected = b['id'] == _selectedBusinessId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    borderColor: isSelected ? AppColors.primaryGreen : AppColors.border,
                    onTap: () {
                      setState(() => _selectedBusinessId = b['id']);
                      NotificationService.showSuccess('Active business set to ${b['name']}');
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGlow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business_rounded, color: AppColors.primaryGreen, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('${b['type']} • GSTIN: ${b['gstin']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              // Personal Mode Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardLuxuryGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGlow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Household & Net Worth', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    const Text('₹ 4,85,320.00', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildPersonalStat('Monthly Salary', '₹ 1.25L'),
                        const SizedBox(width: 16),
                        _buildPersonalStat('Personal EMIs', '₹ 18.5k'),
                        const SizedBox(width: 16),
                        _buildPersonalStat('Monthly Savings', '₹ 82.2k'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                onTap: () => Navigator.pushNamed(context, '/personal-dashboard'),
                child: const Row(
                  children: [
                    Icon(Icons.dashboard_outlined, color: AppColors.primaryGreen),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Open Personal Dashboard', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Track savings, budget, expenses and goals', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Cross-Mode Tools',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 12),

            AppCard(
              onTap: () => Navigator.pushNamed(context, '/consolidated-dashboard'),
              child: const Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, color: AppColors.accentCyan),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consolidated Net Worth View', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Combine Business + Personal assets & obligations', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => Navigator.pushNamed(context, '/fund-transfer'),
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: AppColors.accentPurple),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inter-Account / Drawings Fund Transfer', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Transfer funds between business and personal accounts', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
