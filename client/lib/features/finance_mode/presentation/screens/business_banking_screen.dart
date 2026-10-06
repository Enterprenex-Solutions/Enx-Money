import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/account_model.dart';

class BusinessBankingScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final List<AccountModel>? initialAccounts;

  const BusinessBankingScreen({
    super.key,
    this.onOpenDrawer,
    this.initialAccounts,
  });

  @override
  State<BusinessBankingScreen> createState() => _BusinessBankingScreenState();
}

class _BusinessBankingScreenState extends State<BusinessBankingScreen> {
  final FinanceModeRepository _repo = FinanceModeRepository();
  List<AccountModel> userConnectedAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialAccounts != null) {
      userConnectedAccounts = widget.initialAccounts!;
      _isLoading = false;
    } else {
      _loadAccounts();
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final list = await _repo.getAccounts(type: FinanceType.business);
      List<AccountModel> bizAccounts = list.where((a) => a.isBusiness).toList();

      // If filtered query returned empty, check all accounts for business-flagged accounts
      if (bizAccounts.isEmpty && list.isEmpty) {
        final all = await _repo.getAccounts();
        bizAccounts = all.where((a) => a.isBusiness).toList();
      }

      if (mounted) {
        setState(() {
          userConnectedAccounts = bizAccounts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          userConnectedAccounts = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final primaryTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    // Dynamic sum calculation from active linked user accounts (₹0.00 if none)
    final double totalFloat = userConnectedAccounts.fold(
      0.0,
      (sum, a) => sum + a.balance,
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Business Banking & Treasury',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onOpenDrawer,
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Account',
            onPressed: () async {
              await Navigator.pushNamed(context, '/account-setup');
              _loadAccounts();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, '/fund-transfer'),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text(
          'Fund Transfer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              color: const Color(0xFF0066FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Treasury Overview Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL BUSINESS LIQUID FLOAT',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(totalFloat),
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  '${userConnectedAccounts.length} Connected Account${userConnectedAccounts.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: userConnectedAccounts.isNotEmpty
                                      ? (isDark
                                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                                          : const Color(0xFFEFF6FF))
                                      : (isDark
                                          ? const Color(0xFF334155).withValues(alpha: 0.4)
                                          : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: userConnectedAccounts.isNotEmpty
                                        ? (isDark
                                            ? const Color(0xFF2563EB).withValues(alpha: 0.5)
                                            : const Color(0xFFBFDBFE))
                                        : (isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Text(
                                  userConnectedAccounts.isNotEmpty
                                      ? 'Live Synced'
                                      : 'Zero Float',
                                  style: TextStyle(
                                    color: userConnectedAccounts.isNotEmpty
                                        ? (isDark
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF1D4ED8))
                                        : secondaryTextColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Connected Accounts & Credit Lines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Account List OR Zero-State Card
                    if (userConnectedAccounts.isNotEmpty)
                      ...userConnectedAccounts.map((acc) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                            : const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Icon(
                                      acc.accountName.toLowerCase().contains('credit') ||
                                              acc.accountName.toLowerCase().contains('od') ||
                                              acc.accountName.toLowerCase().contains('facility')
                                          ? Icons.credit_score_rounded
                                          : Icons.account_balance_rounded,
                                      color: isDark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc.accountName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${acc.bankName.isNotEmpty ? acc.bankName : "Current Account"} ••• ${acc.accountNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Vibrant Blue Badge Accent
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                                            : const Color(0xFF93C5FD),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark
                                                ? const Color(0xFF60A5FA)
                                                : const Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Live API Sync',
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : const Color(0xFF1D4ED8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Divider(
                                height: 1,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(acc.balance),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      // Empty State Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                    : const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                      : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Icon(
                                Icons.account_balance_outlined,
                                size: 28,
                                color: isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bank accounts linked yet.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Connect your business current accounts, overdraft credit lines, or cash registers to monitor liquid treasury float in real time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/account-setup',
                                );
                                _loadAccounts();
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                '+ Add Business Bank Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
