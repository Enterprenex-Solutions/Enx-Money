import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/modals/transaction_auth_modal.dart';
import '../../data/wallet_repository.dart';
import '../../models/multi_asset_wallet_model.dart';
import 'add_money_screen.dart';
import 'settlement_pipeline_screen.dart';

class CentralWalletDashboard extends StatefulWidget {
  const CentralWalletDashboard({super.key});

  @override
  State<CentralWalletDashboard> createState() => _CentralWalletDashboardState();
}

class _CentralWalletDashboardState extends State<CentralWalletDashboard> {
  final WalletRepository _walletRepo = WalletRepository();
  bool _isLoading = true;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    await _walletRepo.getWallet();
    if (mounted) setState(() => _isLoading = false);
  }

  MultiAssetWalletModel get wallet =>
      _walletRepo.wallet ??
      const MultiAssetWalletModel(
        userId: '1',
        fiatInr: 148500.50,
        fiatUsd: 2450.00,
        cbdcBalance: 15400.00,
        cbdcWalletId: 'CBDC-IND-891024',
        goldGrams: 14.85,
        goldRatePerGram: 7250.00,
        goldTotalValue: 107662.50,
        stablecoinsUsdc: 1250.00,
        totalConsolidatedInr: 476188.00,
        vaults: [],
      );

  // --- ACTION 1: PAY ---
  void _openPayModal() {
    final amountController = TextEditingController(text: '1500');
    final recipientController = TextEditingController(text: 'Aarav Sharma');
    String assetType = 'INR';

    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text('Pay & Transfer Funds', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 16),
                    FintechTextField(
                      controller: recipientController,
                      label: 'Recipient Name / VPA / Phone',
                      hintText: 'e.g. Aarav Sharma or aarav@upi',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    FintechTextField(
                      controller: amountController,
                      label: 'Transfer Amount',
                      prefixText: assetType == 'CBDC' ? 'e₹ ' : '₹ ',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Fiat INR', style: TextStyle(fontWeight: FontWeight.w700)),
                            selected: assetType == 'INR',
                            onSelected: (_) => setModalState(() => assetType = 'INR'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('CBDC e-Rupee', style: TextStyle(fontWeight: FontWeight.w700)),
                            selected: assetType == 'CBDC',
                            onSelected: (_) => setModalState(() => assetType = 'CBDC'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      key: const Key('initiate_pay_button'),
                      text: 'Authenticate & Pay',
                      icon: Icons.lock_outline_rounded,
                      onPressed: () {
                        final amt = double.tryParse(amountController.text) ?? 0;
                        if (amt <= 0) {
                          NotificationService.showError('Invalid payment amount');
                          return;
                        }
                        Navigator.pop(ctx);
                        // Launch Universal Auth Modal
                        TransactionAuthModal.show(
                          context,
                          amount: amt,
                          recipient: recipientController.text,
                          assetType: assetType,
                          onAuthenticated: (method, pin) async {
                            final res = await _walletRepo.executeSettlement(
                              recipient: recipientController.text,
                              recipientVpa: 'aarav@upi',
                              amount: amt,
                              assetType: assetType,
                              authMethod: method,
                              authPin: pin,
                            );
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettlementPipelineScreen(settlementData: res),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ACTION 2: RECEIVE ---
  void _openReceiveModal() {
    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Receive via QR Code & VPA', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              Text('Scan this QR code using any UPI or CBDC app', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 20),
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Text('VPA: revanth@enxmoney', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'monospace')),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Share Payment Link',
                icon: Icons.share_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  NotificationService.showSuccess('Shareable payment link copied to clipboard');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ACTION 7: CONVERT (FIAT <-> CBDC <-> GOLD) ---
  void _openConvertModal() {
    final amountController = TextEditingController(text: '2000');
    String fromAsset = 'INR';
    String toAsset = 'CBDC';

    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text('Instant Asset Swap & Convert', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text('Convert seamlessly between Fiat INR, RBI CBDC (e₹), and 24K Gold', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromAsset,
                            decoration: InputDecoration(
                              labelText: 'From Asset',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'INR', child: Text('Fiat INR (₹)')),
                              DropdownMenuItem(value: 'CBDC', child: Text('CBDC (e₹)')),
                            ],
                            onChanged: (val) => setModalState(() => fromAsset = val!),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.swap_horiz_rounded)),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toAsset,
                            decoration: InputDecoration(
                              labelText: 'To Asset',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'CBDC', child: Text('CBDC (e₹)')),
                              DropdownMenuItem(value: 'INR', child: Text('Fiat INR (₹)')),
                              DropdownMenuItem(value: 'GOLD', child: Text('24K Gold')),
                            ],
                            onChanged: (val) => setModalState(() => toAsset = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FintechTextField(
                      controller: amountController,
                      label: 'Amount to Convert',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      key: const Key('execute_convert_btn'),
                      text: 'Execute Instant Conversion',
                      icon: Icons.currency_exchange_rounded,
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text) ?? 0;
                        if (amt <= 0) {
                          NotificationService.showError('Invalid amount');
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _walletRepo.convertAssets(
                            fromAsset: fromAsset,
                            toAsset: toAsset,
                            amount: amt,
                          );
                          NotificationService.showSuccess('Conversion from $fromAsset to $toAsset successful!');
                          setState(() {});
                        } catch (e) {
                          NotificationService.showError(e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgCol = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardCol = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text('Digital Wallet & Assets', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: bgCol,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        actions: [
          IconButton(
            icon: Icon(_isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: textCol),
            onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
            tooltip: 'Toggle Balance Visibility',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.pushNamed(context, '/audit-reporting'),
            tooltip: 'Audit Records',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Prominent Consolidated Balance Card
                  _buildMainBalanceCard(isDark, cardCol, textCol, subtextCol, borderCol),

                  const SizedBox(height: 20),

                  // 2. 7-in-1 Quick Action Grid
                  Text('FINANCIAL ACTIONS', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _buildQuickActionGrid(isDark, cardCol, textCol, borderCol),

                  const SizedBox(height: 24),

                  // 3. Multi-Asset Portfolio Cards (Fiat, CBDC, Gold, Stablecoins)
                  Text('MULTI-ASSET BREAKDOWN', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _buildAssetCards(isDark, cardCol, textCol, subtextCol, borderCol),

                  const SizedBox(height: 24),

                  // 4. Auto-Save Vaults Section
                  Text('ACTIVE SAVING VAULTS', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _buildVaultsSection(isDark, cardCol, textCol, subtextCol, borderCol),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMainBalanceCard(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CONSOLIDATED LIQUID BALANCE', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('RBI & NPCI COMPLIANT', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isBalanceVisible ? '₹${wallet.totalConsolidatedInr.toStringAsFixed(2)}' : '••••••••',
            style: TextStyle(color: textCol, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('wallet_add_money_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('+ Add Money', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                    );
                    _loadWallet();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('wallet_convert_btn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textCol,
                    side: BorderSide(color: borderCol),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.swap_vert_rounded, size: 20),
                  label: const Text('Convert', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  onPressed: _openConvertModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid(bool isDark, Color cardCol, Color textCol, Color borderCol) {
    final actions = [
      {'label': 'Pay', 'icon': Icons.qr_code_scanner_rounded, 'color': const Color(0xFF10B981), 'action': _openPayModal},
      {'label': 'Receive', 'icon': Icons.qr_code_2_rounded, 'color': const Color(0xFF3B82F6), 'action': _openReceiveModal},
      {'label': 'Transfer', 'icon': Icons.send_rounded, 'color': const Color(0xFF8B5CF6), 'action': _openPayModal},
      {'label': 'Save', 'icon': Icons.savings_rounded, 'color': const Color(0xFFF59E0B), 'action': () => NotificationService.showSuccess('Smart Savings Vault: Auto-roundups active')},
      {'label': 'Invest', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF06B6D4), 'action': _openConvertModal},
      {'label': 'Borrow', 'icon': Icons.credit_score_rounded, 'color': const Color(0xFFEC4899), 'action': () => NotificationService.showSuccess('Pre-approved credit line: ₹5,00,000 available')},
      {'label': 'Convert', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFF14B8A6), 'action': _openConvertModal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) {
        final item = actions[i];
        return GestureDetector(
          onTap: item['action'] as VoidCallback,
          child: Container(
            decoration: BoxDecoration(
              color: cardCol,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssetCards(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Column(
      children: [
        _buildAssetRow(
          title: 'Fiat Primary Account (INR)',
          subtitle: 'HDFC Bank & Cash Vault',
          value: _isBalanceVisible ? '₹${wallet.fiatInr.toStringAsFixed(2)}' : '••••••',
          icon: Icons.currency_rupee_rounded,
          iconBg: const Color(0xFF10B981),
          isDark: isDark,
          cardCol: cardCol,
          textCol: textCol,
          subtextCol: subtextCol,
          borderCol: borderCol,
        ),
        const SizedBox(height: 10),
        _buildAssetRow(
          title: 'Digital Rupee (RBI CBDC)',
          subtitle: 'Tokens: ₹2000, ₹500, ₹200',
          value: _isBalanceVisible ? 'e₹${wallet.cbdcBalance.toStringAsFixed(2)}' : '••••••',
          icon: Icons.account_balance_wallet_rounded,
          iconBg: const Color(0xFF3B82F6),
          isDark: isDark,
          cardCol: cardCol,
          textCol: textCol,
          subtextCol: subtextCol,
          borderCol: borderCol,
        ),
        const SizedBox(height: 10),
        _buildAssetRow(
          title: '24K Pure Digital Gold',
          subtitle: '${wallet.goldGrams}g @ ₹${wallet.goldRatePerGram.toStringAsFixed(0)}/g',
          value: _isBalanceVisible ? '₹${wallet.goldTotalValue.toStringAsFixed(2)}' : '••••••',
          icon: Icons.stars_rounded,
          iconBg: const Color(0xFFF59E0B),
          isDark: isDark,
          cardCol: cardCol,
          textCol: textCol,
          subtextCol: subtextCol,
          borderCol: borderCol,
        ),
        const SizedBox(height: 10),
        _buildAssetRow(
          title: 'Regulated Stablecoins (USDC)',
          subtitle: 'Backed 1:1 with USD Reserves',
          value: _isBalanceVisible ? '\$${wallet.stablecoinsUsdc.toStringAsFixed(2)}' : '••••••',
          icon: Icons.monetization_on_rounded,
          iconBg: const Color(0xFF8B5CF6),
          isDark: isDark,
          cardCol: cardCol,
          textCol: textCol,
          subtextCol: subtextCol,
          borderCol: borderCol,
        ),
      ],
    );
  }

  Widget _buildAssetRow({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color iconBg,
    required bool isDark,
    required Color cardCol,
    required Color textCol,
    required Color subtextCol,
    required Color borderCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconBg, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: subtextCol, fontSize: 11)),
              ],
            ),
          ),
          Text(value, style: TextStyle(color: textCol, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVaultsSection(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    if (wallet.vaults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardCol, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
        child: Center(child: Text('No vaults created yet. Tap + to start auto-saving.', style: TextStyle(color: subtextCol, fontSize: 12))),
      );
    }

    return Column(
      children: wallet.vaults.map((vault) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardCol, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(vault.name, style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(vault.yieldApy, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: vault.progress,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved: ₹${vault.currentAmount.toStringAsFixed(0)}', style: TextStyle(color: subtextCol, fontSize: 11)),
                  Text('Target: ₹${vault.targetAmount.toStringAsFixed(0)}', style: TextStyle(color: subtextCol, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
