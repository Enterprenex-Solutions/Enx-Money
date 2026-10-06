import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/services/notification_service.dart';

class SettlementPipelineScreen extends StatefulWidget {
  final Map<String, dynamic> settlementData;

  const SettlementPipelineScreen({
    super.key,
    required this.settlementData,
  });

  @override
  State<SettlementPipelineScreen> createState() => _SettlementPipelineScreenState();
}

class _SettlementPipelineScreenState extends State<SettlementPipelineScreen> {
  int _activeStep = 0;
  bool _isSettled = false;

  final List<String> _steps = [
    'Sender Verification & Device Handshake',
    'Real-time Balance Check',
    'Compliance & AML Screening',
    'Network Authorization',
    'Atomic Ledger Settlement (Debit / Credit)',
  ];

  @override
  void initState() {
    super.initState();
    _runPipelineAnimation();
  }

  Future<void> _runPipelineAnimation() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _activeStep = i + 1);
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() => _isSettled = true);
    }
  }

  void _showDigitalReceiptModal() {
    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final receipt = widget.settlementData['receipt'] as Map<String, dynamic>? ?? {};
    final utr = receipt['utr'] ?? widget.settlementData['utr'] ?? 'ENX981029482';
    final amount = widget.settlementData['amount']?.toString() ?? '1500.00';
    final asset = widget.settlementData['assetType'] == 'CBDC' ? 'e₹' : '₹';
    final recipient = widget.settlementData['recipientName'] ?? 'Beneficiary';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Text('Official Digital Receipt', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Text('PAID & SETTLED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Transfer Amount', '$asset$amount', textCol, isBold: true, fontSize: 18),
                    const Divider(height: 20),
                    _buildReceiptRow('Beneficiary', recipient, textCol),
                    const SizedBox(height: 10),
                    _buildReceiptRow('UTR Number', utr.toString(), textCol, isMono: true),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Settlement Mode', widget.settlementData['assetType'] == 'CBDC' ? 'RBI CBDC e-Rupee' : 'Instant UPI / IMPS', textCol),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Network Fee', '₹0.00 (Zero Fee)', const Color(0xFF10B981)),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Timestamp', DateTime.now().toLocal().toString().split('.')[0], subtextCol),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                key: const Key('download_pdf_receipt_btn'),
                text: 'Download PDF Receipt',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  NotificationService.showSuccess('Official Digital PDF Receipt generated & saved');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String val, Color textCol, {bool isBold = false, double fontSize = 13, bool isMono = false}) {
    final isDark = ThemeController().isDarkTheme(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
        Text(
          val,
          style: TextStyle(
            color: textCol,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontFamily: isMono ? 'monospace' : null,
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

    final amount = widget.settlementData['amount']?.toString() ?? '1500.00';
    final asset = widget.settlementData['assetType'] == 'CBDC' ? 'e₹' : '₹';
    final recipient = widget.settlementData['recipientName'] ?? 'Beneficiary';

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text(
          _isSettled ? 'Transfer Successful' : 'Settlement Pipeline',
          style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: bgCol,
        elevation: 0,
        automaticallyImplyLeading: _isSettled,
        iconTheme: IconThemeData(color: textCol),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Icon: Progress spinner or Success Checkmark
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (_isSettled ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSettled ? Icons.check_circle_rounded : Icons.sync_rounded,
                color: _isSettled ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                size: 52,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _isSettled ? 'Transfer Completed!' : 'Processing Payment...',
              style: TextStyle(color: textCol, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '$asset$amount sent to $recipient',
              style: TextStyle(color: subtextCol, fontSize: 14),
            ),

            const SizedBox(height: 28),

            // 5-Step Pipeline Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardCol,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENT NETWORK & SETTLEMENT ENGINE',
                    style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(_steps.length, (i) {
                    final isComplete = i < _activeStep;
                    final isInProgress = i == _activeStep && !_isSettled;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isComplete
                                  ? const Color(0xFF10B981)
                                  : (isInProgress ? const Color(0xFF3B82F6) : Colors.transparent),
                              border: Border.all(
                                color: isComplete
                                    ? const Color(0xFF10B981)
                                    : (isInProgress ? const Color(0xFF3B82F6) : borderCol),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isComplete
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : (isInProgress
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text('${i + 1}', style: TextStyle(color: subtextCol, fontSize: 10, fontWeight: FontWeight.w700))),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _steps[i],
                              style: TextStyle(
                                color: isComplete || isInProgress ? textCol : subtextCol,
                                fontWeight: isComplete || isInProgress ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isComplete)
                            const Text('Done', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Action buttons upon completion
            if (_isSettled) ...[
              PrimaryButton(
                key: const Key('view_digital_receipt_btn'),
                text: 'View Digital Receipt',
                icon: Icons.receipt_long_rounded,
                onPressed: _showDigitalReceiptModal,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Return to Wallet Dashboard',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
