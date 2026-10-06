import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/wallet_repository.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final WalletRepository _walletRepo = WalletRepository();
  final TextEditingController _amountController = TextEditingController(text: '5000');
  String _selectedMethod = 'BANK_UPI_IMPS';
  String _targetAsset = 'INR';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processDeposit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
    if (amount <= 0) {
      NotificationService.showError('Please enter a valid deposit amount');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _walletRepo.addMoney(
        method: _selectedMethod,
        amount: amount,
        assetType: _targetAsset,
        sourceDetails: {
          'sourceName': _getMethodName(_selectedMethod),
        },
      );

      if (!mounted) return;
      _showDepositSuccessModal(res);
    } catch (e) {
      NotificationService.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMethodName(String code) {
    switch (code) {
      case 'BANK_UPI_IMPS':
        return 'Linked Bank Account (Instant UPI / IMPS)';
      case 'SALARY_DIRECT':
        return 'Salary Direct Deposit (Virtual Payroll Account)';
      case 'CASH_DEPOSIT':
        return 'Cash-in Deposit (CDM / Partner Store Kiosk)';
      case 'CARD_GATEWAY':
        return 'Debit / Credit Card Gateway';
      case 'GOVT_PAYOUT':
        return 'Government DBT & Business Vendor Payout';
      default:
        return 'Bank Transfer';
    }
  }

  void _showDepositSuccessModal(Map<String, dynamic> data) {
    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final receipt = data['receipt'] as Map<String, dynamic>? ?? {};

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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
              ),
              const SizedBox(height: 14),
              Text('Deposit Successful!', style: TextStyle(color: textCol, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Funds have been credited to your Digital Wallet', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    _buildRow('Amount Credited', '${_targetAsset == 'CBDC' ? 'e₹' : '₹'}${_amountController.text}', textCol, isBold: true),
                    const Divider(height: 16),
                    _buildRow('Deposit Method', _getMethodName(_selectedMethod), textCol),
                    const Divider(height: 16),
                    _buildRow('UTR Reference', receipt['utr']?.toString() ?? 'ENX982109482', textCol),
                    const Divider(height: 16),
                    _buildRow('Status', 'INSTANTLY SETTLED', const Color(0xFF10B981), isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, Color valueCol, {bool isBold = false}) {
    final isDark = ThemeController().isDarkTheme(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valueCol, fontSize: 12, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600),
          ),
        ),
      ],
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
        title: Text('Add Money to Wallet', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: bgCol,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Asset Toggle (Fiat INR vs CBDC Digital Rupee)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardCol,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _targetAsset = 'INR'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _targetAsset == 'INR' ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Deposit Fiat (₹ INR)',
                            style: TextStyle(
                              color: _targetAsset == 'INR' ? Colors.black : textCol,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _targetAsset = 'CBDC'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _targetAsset == 'CBDC' ? const Color(0xFF3B82F6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Deposit CBDC (e₹ Digital)',
                            style: TextStyle(
                              color: _targetAsset == 'CBDC' ? Colors.white : textCol,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Input
            FintechTextField(
              controller: _amountController,
              label: 'Deposit Amount',
              prefixText: _targetAsset == 'CBDC' ? 'e₹ ' : '₹ ',
              keyboardType: TextInputType.number,
              hintText: 'Enter amount',
            ),

            const SizedBox(height: 12),

            // Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['1000', '5000', '10000', '25000'].map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('+₹$amt', style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 12)),
                      backgroundColor: cardCol,
                      side: BorderSide(color: borderCol),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => setState(() => _amountController.text = amt),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Deposit Methods Selector
            Text('CHOOSE CASH-IN / DEPOSIT ONRAMP', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            const SizedBox(height: 12),

            _buildMethodOption(
              code: 'BANK_UPI_IMPS',
              title: 'Linked Bank Account',
              subtitle: 'Instant transfer via UPI, AutoPay, or IMPS',
              icon: Icons.account_balance_rounded,
              isDark: isDark,
              cardCol: cardCol,
              textCol: textCol,
              subtextCol: subtextCol,
              borderCol: borderCol,
            ),
            const SizedBox(height: 10),

            _buildMethodOption(
              code: 'SALARY_DIRECT',
              title: 'Salary Direct Deposit',
              subtitle: 'Virtual account number & IFSC for employer payroll',
              icon: Icons.work_outline_rounded,
              isDark: isDark,
              cardCol: cardCol,
              textCol: textCol,
              subtextCol: subtextCol,
              borderCol: borderCol,
            ),
            const SizedBox(height: 10),

            _buildMethodOption(
              code: 'CASH_DEPOSIT',
              title: 'Cash Deposit (Store / CDM)',
              subtitle: 'Deposit cash at partner kiosks & CDM machines',
              icon: Icons.local_atm_rounded,
              isDark: isDark,
              cardCol: cardCol,
              textCol: textCol,
              subtextCol: subtextCol,
              borderCol: borderCol,
            ),
            const SizedBox(height: 10),

            _buildMethodOption(
              code: 'CARD_GATEWAY',
              title: 'Debit / Credit Card',
              subtitle: 'Visa, Mastercard, RuPay instant checkout',
              icon: Icons.credit_card_rounded,
              isDark: isDark,
              cardCol: cardCol,
              textCol: textCol,
              subtextCol: subtextCol,
              borderCol: borderCol,
            ),
            const SizedBox(height: 10),

            _buildMethodOption(
              code: 'GOVT_PAYOUT',
              title: 'Govt DBT & Business Payout',
              subtitle: 'Direct Benefit Transfer and vendor payouts',
              icon: Icons.account_balance_wallet_rounded,
              isDark: isDark,
              cardCol: cardCol,
              textCol: textCol,
              subtextCol: subtextCol,
              borderCol: borderCol,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              key: const Key('proceed_deposit_btn'),
              text: 'Deposit ${_targetAsset == 'CBDC' ? 'e₹' : '₹'}${_amountController.text}',
              icon: Icons.add_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _processDeposit,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption({
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Color cardCol,
    required Color textCol,
    required Color subtextCol,
    required Color borderCol,
  }) {
    final isSelected = _selectedMethod == code;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = code),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardCol,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : borderCol,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSelected ? AppColors.primaryGreen : const Color(0xFF3B82F6)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primaryGreen : const Color(0xFF3B82F6), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: subtextCol, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryGreen : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
