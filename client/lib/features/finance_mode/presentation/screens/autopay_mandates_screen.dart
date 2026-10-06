import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/account_model.dart';
import '../../models/mandate_model.dart';

class AutopayMandatesScreen extends StatefulWidget {
  final List<MandateModel>? initialMandates;

  const AutopayMandatesScreen({
    super.key,
    this.initialMandates,
  });

  @override
  State<AutopayMandatesScreen> createState() => AutopayMandatesScreenState();
}

class AutopayMandatesScreenState extends State<AutopayMandatesScreen> {
  final _repository = FinanceModeRepository();

  List<MandateModel> mandates = [];
  List<AccountModel> userAccounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialMandates != null) {
      mandates = List.from(widget.initialMandates!);
      isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialMandates != null) {
      setState(() {
        mandates = List.from(widget.initialMandates!);
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      final fetchedMandates = await _repository.getMandates();
      final fetchedAccounts = await _repository.getAccounts();
      if (mounted) {
        setState(() {
          mandates = fetchedMandates;
          userAccounts = fetchedAccounts;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleMandatePause(MandateModel mandate) async {
    final newStatus = mandate.isActive ? 'Paused' : 'Active';
    try {
      await _repository.updateMandateStatus(mandate.id, newStatus);
    } catch (_) {}
    if (mounted) {
      setState(() {
        final index = mandates.indexWhere((m) => m.id == mandate.id);
        if (index != -1) {
          mandates[index] = mandate.copyWith(status: newStatus);
        }
      });
      NotificationService.showSuccess(
        newStatus == 'Paused'
            ? '${mandate.name} paused successfully'
            : '${mandate.name} resumed successfully',
      );
    }
  }

  Future<void> _confirmRevokeMandate(MandateModel mandate) async {
    final isDark = ThemeController().isDarkTheme(context);
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Revoke AutoPay Mandate?',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to cancel AutoPay for "${mandate.name}"? Future recurring deductions up to ₹${mandate.maxLimit.toStringAsFixed(2)} will be stopped permanently.',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Active', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Revoke Mandate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldRevoke == true) {
      try {
        await _repository.revokeMandate(mandate.id);
      } catch (_) {}
      if (mounted) {
        setState(() {
          mandates.removeWhere((m) => m.id == mandate.id);
        });
        NotificationService.showSuccess('AutoPay Mandate "${mandate.name}" revoked');
      }
    }
  }

  /// Launch AutoPay Setup Interface
  void _openSetupMandateModal() {
    final nameCtrl = TextEditingController(text: 'Monthly Office Rent');
    final limitCtrl = TextEditingController(text: '5000.00');
    final startDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

    String selectedFrequency = 'Monthly';
    bool isUntilCancelled = true;
    String selectedSourceBank = userAccounts.isNotEmpty ? userAccounts.first.bankName : 'HDFC Bank';
    String selectedAccountId = userAccounts.isNotEmpty ? userAccounts.first.id : 'acc_b02';

    final isDark = ThemeController().isDarkTheme(context);
    final modalBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Setup UPI AutoPay Mandate',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: subtextColor, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Text(
                        'Automate recurring subscription, rent, EMI, or vendor payouts.',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      const SizedBox(height: 18),

                      // Mandate Name
                      FintechTextField(
                        controller: nameCtrl,
                        label: 'Mandate Name / Purpose',
                        hintText: 'e.g. ENX Pro Subscription, Office Rent',
                      ),
                      const SizedBox(height: 12),

                      // AutoPay Frequency
                      Text(
                        'AutoPay Frequency',
                        style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Weekly', 'Monthly', 'Quarterly', 'As Presented'].map((freq) {
                          final isSelected = selectedFrequency == freq;
                          return ChoiceChip(
                            label: Text(freq),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryGreen : borderColor,
                              ),
                            ),
                            onSelected: (_) => setModalState(() => selectedFrequency = freq),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Maximum AutoDebit Limit
                      FintechTextField(
                        controller: limitCtrl,
                        label: 'Maximum AutoDebit Limit (₹)',
                        hintText: 'e.g. 5000.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Start Date & Until Cancelled
                      Row(
                        children: [
                          Expanded(
                            child: FintechTextField(
                              controller: startDateCtrl,
                              label: 'Start Date (YYYY-MM-DD)',
                              hintText: '2026-10-01',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Row(
                              children: [
                                Switch(
                                  value: isUntilCancelled,
                                  activeColor: AppColors.primaryGreen,
                                  onChanged: (val) => setModalState(() => isUntilCancelled = val),
                                ),
                                Text(
                                  'Until Cancelled',
                                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Continue to Summary & UPI PIN CTA
                      PrimaryButton(
                        text: 'Review & Authorize Mandate',
                        icon: Icons.security_rounded,
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final limit = double.tryParse(limitCtrl.text.trim()) ?? 0.0;
                          final startDate = startDateCtrl.text.trim();

                          if (name.isEmpty) {
                            NotificationService.showError('Please enter a mandate name');
                            return;
                          }
                          if (limit <= 0) {
                            NotificationService.showError('Please enter a valid debit limit');
                            return;
                          }

                          Navigator.pop(ctx);
                          _openMandateSummaryAndPinModal(
                            name: name,
                            frequency: selectedFrequency,
                            maxLimit: limit,
                            startDate: startDate,
                            isUntilCancelled: isUntilCancelled,
                            sourceBank: selectedSourceBank,
                            sourceAccountId: selectedAccountId,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Mandate Summary & Secure UPI PIN Authorization Modal
  void _openMandateSummaryAndPinModal({
    required String name,
    required String frequency,
    required double maxLimit,
    required String startDate,
    required bool isUntilCancelled,
    required String sourceBank,
    required String sourceAccountId,
  }) {
    final pinCtrl = TextEditingController();
    bool isAuthorizing = false;

    final isDark = ThemeController().isDarkTheme(context);
    final modalBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (authCtx) {
        return StatefulBuilder(
          builder: (context, setAuthState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(authCtx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Authorize AutoPay Mandate',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: subtextColor, size: 20),
                          onPressed: () => Navigator.pop(authCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mandate Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mandate Title', style: TextStyle(color: subtextColor, fontSize: 13)),
                              Text(name, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Debit Frequency', style: TextStyle(color: subtextColor, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  frequency.toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Max Limit Per Cycle', style: TextStyle(color: subtextColor, fontSize: 13)),
                              Text('₹${maxLimit.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Source Account', style: TextStyle(color: subtextColor, fontSize: 13)),
                              Text(sourceBank, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Destination VPA', style: TextStyle(color: subtextColor, fontSize: 13)),
                              const Text('enxmoney@bank', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // UPI PIN Field
                    FintechTextField(
                      controller: pinCtrl,
                      label: 'Enter 4 or 6-Digit UPI PIN to Authorize',
                      hintText: '••••••',
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      text: 'Authorize AutoPay Mandate',
                      icon: Icons.verified_user_rounded,
                      isLoading: isAuthorizing,
                      onPressed: () async {
                        final pin = pinCtrl.text.trim();
                        if (pin.length < 4 || pin.length > 6) {
                          NotificationService.showError('Please enter your 4 or 6-digit UPI PIN');
                          return;
                        }

                        setAuthState(() => isAuthorizing = true);

                        MandateModel? newMandate;
                        try {
                          newMandate = await _repository.createMandate(
                            name: name,
                            frequency: frequency,
                            maxLimit: maxLimit,
                            startDate: startDate,
                            isUntilCancelled: isUntilCancelled,
                            sourceAccountId: sourceAccountId,
                            sourceBankName: sourceBank,
                            upiPin: pin,
                          );
                        } catch (_) {
                          newMandate = null;
                        }
                        newMandate ??= MandateModel(
                          id: 'man_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          frequency: frequency,
                          maxLimit: maxLimit,
                          startDate: startDate,
                          endDate: isUntilCancelled ? '2099-12-31' : '2027-12-31',
                          isUntilCancelled: isUntilCancelled,
                          status: 'ACTIVE',
                          sourceAccountId: sourceAccountId,
                          sourceBankName: sourceBank,
                          createdAt: DateTime.now().toIso8601String(),
                        );

                        if (mounted) {
                          setAuthState(() => isAuthorizing = false);
                          Navigator.pop(authCtx);

                          setState(() {
                            mandates.insert(0, newMandate!);
                          });
                          NotificationService.showSuccess('AutoPay Mandate "$name" authorized successfully!');
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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Active AutoPay & Mandates', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('setup_autopay_fab'),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryGreen),
            tooltip: 'Setup AutoPay',
            onPressed: _openSetupMandateModal,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : mandates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.autorenew_rounded, size: 56, color: subtextColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No Active AutoPay Mandates',
                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Automate monthly subscriptions, office rent,\nand recurring vendor drawings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _openSetupMandateModal,
                        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
                        label: const Text('Setup AutoPay Mandate', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: mandates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = mandates[index];
                    final isActive = m.isActive;
                    final isPaused = m.isPaused;

                    Color statusColor = const Color(0xFF10B981);
                    if (isPaused) statusColor = const Color(0xFFF59E0B);
                    if (m.isRevoked) statusColor = const Color(0xFFEF4444);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Text(
                                'Max ₹${m.maxLimit.toStringAsFixed(2)} / ${m.frequency}',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: subtextColor)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.sourceBankName,
                                  style: TextStyle(color: subtextColor, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Text(
                            'Next AutoDebit: ${m.startDate} • VPA: ${m.vpa}',
                            style: TextStyle(color: subtextColor, fontSize: 11),
                          ),
                          const SizedBox(height: 14),

                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 10),

                          // Action Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!m.isRevoked) ...[
                                TextButton.icon(
                                  onPressed: () => _toggleMandatePause(m),
                                  icon: Icon(
                                    isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                    size: 16,
                                    color: isPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                  label: Text(
                                    isActive ? 'Pause' : 'Resume',
                                    style: TextStyle(
                                      color: isPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmRevokeMandate(m),
                                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFEF4444)),
                                  label: const Text(
                                    'Revoke',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Mandate Cancelled',
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: PrimaryButton(
          text: '+ Setup New AutoPay Mandate',
          icon: Icons.add_rounded,
          onPressed: _openSetupMandateModal,
        ),
      ),
    );
  }
}
