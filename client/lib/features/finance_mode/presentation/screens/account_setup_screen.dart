import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/widgets/finance/status_badge.dart';
import '../../../../core/services/notification_service.dart';
import '../../models/account_model.dart';
import '../../data/finance_mode_repository.dart';
import '../widgets/setu_aa_webview_dialog.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final FinanceModeRepository _repo = FinanceModeRepository();
  List<AccountModel> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final data = await _repo.getAccounts();
    if (mounted) {
      setState(() {
        _accounts = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchSetuAaFlow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              ),
              SizedBox(height: 16),
              Text(
                'Connecting to Setu AA Gateway...',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final consentData = await _repo.initiateSetuAaConsent();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      final redirectUrl = consentData['redirectUrl'] as String?;
      if (redirectUrl != null && redirectUrl.isNotEmpty && mounted) {
        final linked = await SetuAaWebviewDialog.show(context, redirectUrl: redirectUrl);
        if (linked == true) {
          await _loadAccounts();
          if (mounted) {
            NotificationService.showSuccess('Bank Account Linked Successfully!');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        NotificationService.showError('Unable to initiate Setu flow: $e');
      }
    }
  }

  void _showAddAccountSheet() {
    final titleController = TextEditingController();
    final bankController = TextEditingController();
    final accNumberController = TextEditingController();
    final balanceController = TextEditingController();
    FinanceType selectedType = FinanceType.personal;

    final isDark = ThemeController().isDarkTheme(context);
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Link Bank / Cash Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText)),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Automated Setu AA Quick Link Banner
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _launchSetuAaFlow();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Automated Setu AA Linking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Instant verification with SBI, HDFC, ICICI & more', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FintechTextField(
                    controller: titleController,
                    label: 'Account Nickname',
                    hintText: 'e.g. SBI Salary Account, ICICI Current',
                  ),
                  const SizedBox(height: 12),
                  FintechTextField(
                    controller: bankController,
                    label: 'Bank / Institution Name',
                    hintText: 'e.g. State Bank of India, HDFC Bank',
                  ),
                  const SizedBox(height: 12),
                  FintechTextField(
                    controller: accNumberController,
                    label: 'Account Number',
                    hintText: 'e.g. 50200012345678',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  FintechTextField(
                    controller: balanceController,
                    label: 'Opening Ledger Balance (₹)',
                    hintText: '0.00',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Personal')),
                          selected: selectedType == FinanceType.personal,
                          selectedColor: const Color(0xFF0066FF),
                          labelStyle: TextStyle(
                            color: selectedType == FinanceType.personal ? Colors.white : primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setModalState(() => selectedType = FinanceType.personal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Business')),
                          selected: selectedType == FinanceType.business,
                          selectedColor: const Color(0xFF0066FF),
                          labelStyle: TextStyle(
                            color: selectedType == FinanceType.business ? Colors.white : primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setModalState(() => selectedType = FinanceType.business),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Save & Link Account',
                    onPressed: () async {
                      final name = titleController.text.trim();
                      final bank = bankController.text.trim();
                      final accNo = accNumberController.text.trim();
                      final bal = double.tryParse(balanceController.text.trim()) ?? 0.0;

                      if (name.isEmpty || bank.isEmpty) {
                        NotificationService.showError('Please provide account nickname and bank name');
                        return;
                      }

                      final acc = await _repo.createAccount(
                        accountName: name,
                        bankName: bank,
                        accountNumber: accNo.isNotEmpty ? accNo : '0000',
                        balance: bal,
                        financeType: selectedType,
                      );

                      if (acc != null) {
                        Navigator.pop(ctx);
                        NotificationService.showSuccess('Account linked successfully!');
                        _loadAccounts();
                      } else {
                        NotificationService.showError('Failed to save account to server.');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final isDark = ThemeController().isDarkTheme(context);
        final Color scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final Color cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
        final Color cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        final Color primaryText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
        final Color secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text('Connected Bank Accounts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: primaryText)),
            backgroundColor: scaffoldBg,
            elevation: 0,
            iconTheme: IconThemeData(color: primaryText),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            onPressed: _showAddAccountSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
              : _accounts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_outlined, size: 48, color: secondaryText),
                            const SizedBox(height: 12),
                            Text(
                              'No accounts linked yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryText),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add your bank accounts, wallets, or credit cards to see them on your dashboard.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: secondaryText),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddAccountSheet,
                              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              label: const Text('+ Link New Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAccounts,
                      color: const Color(0xFF0066FF),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final a = _accounts[idx];
                          final isBiz = a.type == FinanceType.business;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isBiz ? const Color(0xFF0066FF) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isBiz ? Icons.business_center_rounded : Icons.person_rounded,
                                    color: isBiz ? const Color(0xFF0066FF) : const Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.accountName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: primaryText)),
                                      const SizedBox(height: 2),
                                      Text('${a.bankName} • ${a.accountNumber}', style: TextStyle(fontSize: 11, color: secondaryText)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(a.balance, showDecimals: false),
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: primaryText),
                                    ),
                                    const SizedBox(height: 2),
                                    StatusBadge(
                                      label: isBiz ? 'Business' : 'Personal',
                                      variant: isBiz ? BadgeVariant.info : BadgeVariant.success,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
