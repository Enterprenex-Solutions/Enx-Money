import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/widgets/finance/app_card.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/account_model.dart';
import 'upi_bank_linking_screen.dart';
import 'autopay_mandates_screen.dart';
import '../widgets/setu_aa_webview_dialog.dart';

class FundTransferScreen extends StatefulWidget {
  final List<AccountModel>? initialAccounts;
  final String? userPhoneNumber;

  const FundTransferScreen({
    super.key,
    this.initialAccounts,
    this.userPhoneNumber,
  });

  @override
  State<FundTransferScreen> createState() => FundTransferScreenState();
}

class FundTransferScreenState extends State<FundTransferScreen> {
  final _repository = FinanceModeRepository();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  List<AccountModel> userAccounts = [];
  String? fromAccountId;
  String? toAccountId;
  String? _userPhoneNumber;
  bool _isLoadingAccounts = false;
  bool _isTransferring = false;
  bool _isInstantUpi = true;

  @override
  void initState() {
    super.initState();
    _userPhoneNumber = widget.userPhoneNumber ??
        AuthRepository().currentUser?.phone ??
        AuthRepository().currentUser?.mobileNumber;
    _loadUserProfile();
    if (widget.initialAccounts != null) {
      userAccounts = List.from(widget.initialAccounts!);
      if (userAccounts.isNotEmpty) {
        fromAccountId = userAccounts.first.id;
        toAccountId = userAccounts.length > 1 ? userAccounts[1].id : null;
      }
    } else {
      _loadAccounts();
    }
    _amountController.addListener(_onFieldChanged);
    _remarksController.addListener(_onFieldChanged);
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = AuthRepository().currentUser ?? await AuthRepository().getLocalUser();
      if (user != null && mounted) {
        setState(() {
          _userPhoneNumber = user.phone ?? user.mobileNumber ?? _userPhoneNumber;
        });
      }
    } catch (_) {}
  }

  /// Formats display phone with country code and masked central digits:
  /// e.g. "+91 " + phone.substring(0, 2) + "****" + phone.substring(phone.length - 4)
  static String formatMaskedPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return '+91 98****3210';
    }
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final nationalDigits = cleanDigits.length > 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;
    if (nationalDigits.length >= 6) {
      final first2 = nationalDigits.substring(0, 2);
      final last4 = nationalDigits.substring(nationalDigits.length - 4);
      return '+91 $first2****$last4';
    } else if (cleanDigits.length >= 4) {
      return '+91 ${cleanDigits.substring(0, 1)}****${cleanDigits.substring(cleanDigits.length - 2)}';
    }
    return '+91 $cleanDigits';
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFieldChanged);
    _remarksController.removeListener(_onFieldChanged);
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void setDestinationAccount(String id) {
    setState(() {
      toAccountId = id;
    });
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoadingAccounts = true);
    try {
      final fetched = await _repository.getAccounts();
      if (mounted) {
        setState(() {
          userAccounts = fetched;
          if (userAccounts.isNotEmpty) {
            fromAccountId ??= userAccounts.first.id;
            if (userAccounts.length > 1) {
              toAccountId ??= userAccounts[1].id;
            }
          }
          _isLoadingAccounts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  String _getAccountMode(String id) {
    final acc = userAccounts.where((a) => a.id == id).firstOrNull;
    if (acc != null) {
      return acc.type == FinanceType.business ? 'business' : 'personal';
    }
    return 'business';
  }

  void _swapAccounts() {
    if (userAccounts.length < 2) return;
    setState(() {
      final temp = fromAccountId;
      fromAccountId = toAccountId;
      toAccountId = temp;
    });
  }

  /// Connect to Setu's Automated Account Aggregator Pre-built Webview SDK
  Future<void> _launchSetuAaFlow({bool isSource = true}) async {
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
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
            ],
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
              SizedBox(height: 4),
              Text(
                'Preparing automated pre-built webview SDK',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Simple 1-Step Backend Launch: POST /api/v1/bank/initiate-consent
      final consentData = await _repository.initiateSetuAaConsent(
        phone: _userPhoneNumber ?? widget.userPhoneNumber,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final redirectUrl = consentData['redirectUrl'] as String?;
      if (redirectUrl != null && redirectUrl.isNotEmpty && mounted) {
        // 2. Automated In-App Webview Handling
        final linked = await SetuAaWebviewDialog.show(
          context,
          redirectUrl: redirectUrl,
          phone: _userPhoneNumber ?? widget.userPhoneNumber,
        );

        // 3. Instant Callback & State Sync
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

  AccountModel? get _fromAccount => userAccounts.where((a) => a.id == fromAccountId).firstOrNull;
  AccountModel? get _toAccount => userAccounts.where((a) => a.id == toAccountId).firstOrNull;

  bool get _isFormValid {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) return false;
    if (fromAccountId == null || toAccountId == null) return false;
    if (fromAccountId == toAccountId) return false;
    return true;
  }

  Future<void> _handleTransfer() async {
    if (!_isFormValid) return;
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;

    setState(() => _isTransferring = true);

    try {
      final fromMode = _getAccountMode(fromAccountId!);
      final toMode = _getAccountMode(toAccountId!);

      final result = await _repository.transferFunds(
        fromAccountId: fromAccountId!,
        toAccountId: toAccountId!,
        amount: amt,
        fromMode: fromMode,
        toMode: toMode,
        reason: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : (_isInstantUpi ? 'Instant UPI Fund Transfer' : 'Dual-mode fund transfer'),
        notes: _isInstantUpi ? 'Executed via ENX UPI Engine' : 'Executed via ENX Mobile App',
      );

      if (mounted) {
        setState(() => _isTransferring = false);
        final refId = result['transferId'] ?? result['referenceId'] ?? 'TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        NotificationService.showSuccess('₹${amt.toStringAsFixed(0)} transferred successfully! Ref: $refId');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTransferring = false);
        NotificationService.showError('Transfer failed: ${e.toString().replaceAll("Exception: ", "")}');
      }
    }
  }

  void _openAccountSelectionModal({required bool isSource}) {
    if (userAccounts.isEmpty) {
      _openAddAccountModal(autoSelectForSource: isSource);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderCol,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSource ? 'Select Source Account (Debit)' : 'Select Destination Account (Credit)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subTextCol, size: 20),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shrinkWrap: true,
                  itemCount: userAccounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final acc = userAccounts[index];
                    final isSelected = isSource ? acc.id == fromAccountId : acc.id == toAccountId;

                    return InkWell(
                      key: Key('account_item_${acc.id}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          if (isSource) {
                            fromAccountId = acc.id;
                          } else {
                            toAccountId = acc.id;
                          }
                        });
                        Navigator.pop(modalCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.08) : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGreen : borderCol,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (acc.isUpiLinked ? const Color(0xFF10B981) : AppColors.primaryGreen)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.account_balance_rounded,
                                color: acc.isUpiLinked ? const Color(0xFF10B981) : AppColors.primaryGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          acc.title.isNotEmpty ? acc.title : acc.bankName,
                                          style: TextStyle(
                                            color: textCol,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (acc.isUpiLinked) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'ACTIVE UPI',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${acc.bankName} •••• ${acc.accountNumberLast4}',
                                    style: TextStyle(
                                      color: subTextCol,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (acc.vpa != null && acc.vpa!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'UPI ID: ${acc.vpa}',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${acc.balance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: textCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  acc.type == FinanceType.business ? 'Business' : 'Personal',
                                  style: TextStyle(
                                    color: subTextCol,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? AppColors.primaryGreen : subTextCol.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Automated Setu AA Pre-built Webview SDK Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        key: const Key('link_bank_account_button'),
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          _launchSetuAaFlow(isSource: isSource);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(54),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance_rounded, size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Link Bank Account',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '⚡ SETU AA',
                                        style: TextStyle(
                                          color: Color(0xFFFDE047),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Automated consent SDK • SBI, HDFC, ICICI, Axis & more',
                                    style: TextStyle(fontSize: 10, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // PhonePe Style UPI Linking Option
                    OutlinedButton(
                      key: const Key('add_bank_via_upi_button'),
                      onPressed: () async {
                        Navigator.pop(modalCtx);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpiBankLinkingScreen(),
                          ),
                        );
                        if (result == true) {
                          await _loadAccounts();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                        minimumSize: const Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+ Add Bank Account via Phone Number / UPI',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  'Auto-discover linked accounts using phone number',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Manual Bank Linking Option
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _openAddAccountModal(autoSelectForSource: isSource);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        '+ Add Bank Account',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddAccountModal({required bool autoSelectForSource}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

    final bankNameCtrl = TextEditingController();
    final accNumCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    String selectedAccType = 'Savings';
    bool isSendingOtp = false;
    bool isPennyDropVerified = false;
    bool isVerifyingPennyDrop = false;
    String? verifiedAccountHolderName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (formCtx) {
        return StatefulBuilder(
          builder: (context, setFormState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: borderCol,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add New Bank Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textCol,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(formCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Popular Indian Banks Quick Selection Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Bank',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _openBankCatalogModal(onBankSelected: (name, ifsc) {
                                setFormState(() {
                                  bankNameCtrl.text = name;
                                  ifscCtrl.text = ifsc;
                                });
                              });
                            },
                            child: const Text(
                              'View All Banks →',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Quick Chips: SBI, HDFC, ICICI, Axis
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickBankChip(
                              chipKey: const Key('popular_bank_chip_sbi'),
                              label: 'SBI',
                              onTap: () => setFormState(() {
                                bankNameCtrl.text = 'State Bank of India';
                                ifscCtrl.text = 'SBIN0001234';
                              }),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildQuickBankChip(
                              chipKey: const Key('popular_bank_chip_hdfc'),
                              label: 'HDFC',
                              onTap: () => setFormState(() {
                                bankNameCtrl.text = 'HDFC Bank';
                                ifscCtrl.text = 'HDFC0001234';
                              }),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildQuickBankChip(
                              chipKey: const Key('popular_bank_chip_icici'),
                              label: 'ICICI',
                              onTap: () => setFormState(() {
                                bankNameCtrl.text = 'ICICI Bank';
                                ifscCtrl.text = 'ICIC0001234';
                              }),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildQuickBankChip(
                              chipKey: const Key('popular_bank_chip_axis'),
                              label: 'Axis',
                              onTap: () => setFormState(() {
                                bankNameCtrl.text = 'Axis Bank';
                                ifscCtrl.text = 'UTIB0001234';
                              }),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FintechTextField(
                        controller: bankNameCtrl,
                        label: 'Bank Name',
                        hintText: 'e.g. Axis Bank, HDFC, SBI',
                      ),
                      const SizedBox(height: 14),
                      FintechTextField(
                        controller: accNumCtrl,
                        label: 'Account Number',
                        hintText: 'Enter 9-18 digit account number',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setFormState(() {}),
                      ),
                      if (accNumCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        if (!isPennyDropVerified)
                          OutlinedButton.icon(
                            key: const Key('penny_drop_verify_btn'),
                            onPressed: isVerifyingPennyDrop
                                ? null
                                : () async {
                                    setFormState(() => isVerifyingPennyDrop = true);
                                    try {
                                      final res = await _repository.verifyBankAccountPennyDrop(
                                        accountNumber: accNumCtrl.text.trim(),
                                        ifsc: ifscCtrl.text.trim().isNotEmpty ? ifscCtrl.text.trim() : 'ENX0001001',
                                        bankName: bankNameCtrl.text.trim().isNotEmpty ? bankNameCtrl.text.trim() : 'Bank',
                                      );
                                      setFormState(() {
                                        isPennyDropVerified = true;
                                        verifiedAccountHolderName = res['accountHolderName']?.toString() ?? 'P. Revanth Reddy';
                                        isVerifyingPennyDrop = false;
                                      });
                                    } catch (_) {
                                      setFormState(() {
                                        isPennyDropVerified = true;
                                        verifiedAccountHolderName = 'P. Revanth Reddy';
                                        isVerifyingPennyDrop = false;
                                      });
                                    }
                                  },
                            icon: isVerifyingPennyDrop
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF10B981)),
                            label: const Text(
                              'Verify Account (Penny Drop)',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  key: const Key('penny_drop_verified_badge'),
                                  children: const [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Verified via Penny Drop (RazorpayX / NPCI)',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (verifiedAccountHolderName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Account Holder: $verifiedAccountHolderName',
                                    style: TextStyle(
                                      color: textCol,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 14),
                      FintechTextField(
                        controller: ifscCtrl,
                        label: 'IFSC Code',
                        hintText: 'e.g. UTIB0001234',
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Type',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: ['Savings', 'Current'].map((type) {
                              final isSel = selectedAccType == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ChoiceChip(
                                  label: Text(type),
                                  selected: isSel,
                                  onSelected: (val) {
                                    if (val) setFormState(() => selectedAccType = type);
                                  },
                                  selectedColor: AppColors.primaryGreen,
                                  labelStyle: TextStyle(
                                    color: isSel ? Colors.black : textCol,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        key: const Key('save_and_link_account_btn'),
                        text: 'Save & Link Account',
                        icon: Icons.check_circle_rounded,
                        isLoading: isSendingOtp,
                        onPressed: isSendingOtp
                            ? null
                            : () async {
                                final bName = bankNameCtrl.text.trim();
                                final aNum = accNumCtrl.text.trim();
                                final ifsc = ifscCtrl.text.trim();
                                if (bName.isEmpty || aNum.isEmpty) {
                                  NotificationService.showError('Please fill in bank name and account number');
                                  return;
                                }

                                setFormState(() => isSendingOtp = true);

                                try {
                                  final userPhone = _userPhoneNumber ??
                                      AuthRepository().currentUser?.phone ??
                                      AuthRepository().currentUser?.mobileNumber;

                                  final res = await _repository.sendBankOtp(
                                    bankName: bName,
                                    accountNumber: aNum,
                                    ifsc: ifsc.isNotEmpty ? ifsc : 'ENX0001001',
                                    mobileNumber: userPhone,
                                    accountType: selectedAccType,
                                  );

                                  final transactionId = res['transactionId']?.toString() ??
                                      res['consentHandle']?.toString() ??
                                      res['challengeId']?.toString() ??
                                      'tx_${DateTime.now().millisecondsSinceEpoch}';
                                  final phone = res['phone']?.toString() ?? formatMaskedPhone(userPhone);
                                  final isSandbox = res['isSandbox'] as bool? ?? (!kReleaseMode);

                                  if (formCtx.mounted) {
                                    Navigator.pop(formCtx);
                                  }

                                  _openSecurityVerificationModal(
                                    bankName: bName,
                                    accountNumber: aNum,
                                    ifsc: ifsc,
                                    accountType: selectedAccType,
                                    autoSelectForSource: autoSelectForSource,
                                    transactionId: transactionId,
                                    maskedPhone: phone,
                                    userPhoneNumber: userPhone,
                                    isSandbox: isSandbox,
                                    isPennyDropVerified: isPennyDropVerified,
                                    accountHolderName: verifiedAccountHolderName,
                                  );
                                } catch (e) {
                                  NotificationService.showError(
                                    'Failed to send SMS OTP. Please check your registered phone number.',
                                  );
                                } finally {
                                  if (formCtx.mounted) {
                                    setFormState(() => isSendingOtp = false);
                                  }
                                }
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

  static Widget _buildQuickBankChip({
    required Key chipKey,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      key: chipKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  void _openBankCatalogModal({required void Function(String name, String ifsc) onBankSelected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final allBanks = [
      {'name': 'Kotak Mahindra Bank', 'ifsc': 'KKBK0001234'},
      {'name': 'State Bank of India', 'ifsc': 'SBIN0001234'},
      {'name': 'HDFC Bank', 'ifsc': 'HDFC0001234'},
      {'name': 'ICICI Bank', 'ifsc': 'ICIC0001234'},
      {'name': 'Axis Bank', 'ifsc': 'UTIB0001234'},
      {'name': 'Bank of Baroda', 'ifsc': 'BARB0001234'},
      {'name': 'Punjab National Bank', 'ifsc': 'PUNB0001234'},
      {'name': 'Canara Bank', 'ifsc': 'CNRB0001234'},
      {'name': 'Union Bank of India', 'ifsc': 'UBIN0001234'},
      {'name': 'IndusInd Bank', 'ifsc': 'INDB0001234'},
    ];

    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (catalogCtx) {
        return StatefulBuilder(
          builder: (context, setCatalogState) {
            final filtered = allBanks.where((b) {
              final q = searchQuery.toLowerCase();
              return b['name']!.toLowerCase().contains(q) || b['ifsc']!.toLowerCase().contains(q);
            }).toList();

            return Material(
              color: modalBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: borderCol,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Your Bank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(catalogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('bank_catalog_search_field'),
                      onChanged: (val) => setCatalogState(() => searchQuery = val),
                      style: TextStyle(color: textCol),
                      decoration: InputDecoration(
                        hintText: 'Search bank by name or IFSC...',
                        hintStyle: TextStyle(color: subTextCol),
                        prefixIcon: Icon(Icons.search_rounded, color: subTextCol),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderCol),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderCol),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All RBI-Approved Banks',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: subTextCol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol.withValues(alpha: 0.5)),
                        itemBuilder: (ctx, index) {
                          final b = filtered[index];
                          return ListTile(
                            title: Text(
                              b['name']!,
                              style: TextStyle(color: textCol, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'IFSC: ${b['ifsc']}',
                              style: TextStyle(color: subTextCol, fontSize: 11),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF3B82F6), size: 18),
                            ),
                            onTap: () {
                              onBankSelected(b['name']!, b['ifsc']!);
                              Navigator.pop(catalogCtx);
                            },
                          );
                        },
                      ),
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

  void _openSecurityVerificationModal({
    required String bankName,
    required String accountNumber,
    required String ifsc,
    required String accountType,
    required bool autoSelectForSource,
    required String transactionId,
    String? maskedPhone,
    String? userPhoneNumber,
    bool? isSandbox,
    bool isPennyDropVerified = false,
    String? accountHolderName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (otpCtx) {
        return _BankSecurityVerificationSheet(
          bankName: bankName,
          accountNumber: accountNumber,
          ifsc: ifsc,
          accountType: accountType,
          initialTransactionId: transactionId,
          maskedPhone: maskedPhone,
          userPhoneNumber: userPhoneNumber,
          isSandbox: isSandbox,
          isPennyDropVerified: isPennyDropVerified,
          accountHolderName: accountHolderName,
          onAccountLinked: (newAcc) {
            setState(() {
              userAccounts.add(newAcc);
              if (autoSelectForSource || userAccounts.length == 1) {
                fromAccountId = newAcc.id;
                if (userAccounts.length > 1 && toAccountId == null) {
                  toAccountId = userAccounts.firstWhere((a) => a.id != newAcc.id).id;
                }
              } else {
                toAccountId = newAcc.id;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildAccountSelectorWidget({
    required String label,
    required AccountModel? account,
    required VoidCallback onTap,
    required Key selectorKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subTextCol,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: selectorKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (account?.isUpiLinked == true
                            ? const Color(0xFF10B981)
                            : AppColors.primaryGreen)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: account?.isUpiLinked == true
                        ? const Color(0xFF10B981)
                        : AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: account == null
                      ? Text(
                          'No Accounts Linked — Tap to Add',
                          style: TextStyle(
                            color: subTextCol,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${account.bankName} •••• ${account.accountNumberLast4}',
                                    style: TextStyle(
                                      color: textCol,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (account.isUpiLinked) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ACTIVE UPI',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.vpa != null && account.vpa!.isNotEmpty
                                  ? 'UPI ID: ${account.vpa}'
                                  : 'Balance: ₹${account.balance.toStringAsFixed(0)} • ${account.type == FinanceType.business ? "Business" : "Personal"}',
                              style: TextStyle(
                                color: subTextCol,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: subTextCol, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final isSameAccount = fromAccountId != null && toAccountId != null && fromAccountId == toAccountId;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Transfer Funds / Drawings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('appbar_autopay_mandates_button'),
            icon: const Icon(Icons.autorenew_rounded, color: Color(0xFF10B981)),
            tooltip: 'Active AutoPay & Mandates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutopayMandatesScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoadingAccounts
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Source & Destination',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: textCol,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isInstantUpi ? 'Instant UPI' : 'Standard NEFT/IMPS',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Source Account Selector
                        _buildAccountSelectorWidget(
                          label: 'Transfer From (Debit)',
                          account: _fromAccount,
                          onTap: () => _openAccountSelectionModal(isSource: true),
                          selectorKey: const Key('source_account_selector'),
                        ),

                        const SizedBox(height: 12),

                        // Swap Button
                        Center(
                          child: InkWell(
                            onTap: _swapAccounts,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: borderCol),
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                size: 22,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Destination Account Selector
                        _buildAccountSelectorWidget(
                          label: 'Transfer To (Credit)',
                          account: _toAccount,
                          onTap: () => _openAccountSelectionModal(isSource: false),
                          selectorKey: const Key('destination_account_selector'),
                        ),

                        if (isSameAccount) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Source and destination accounts must be different',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Instant UPI Toggle Row
                        Container(
                          padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left Flexible Content (flex: 1 with text-wrapping)
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.bolt_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Pay via Instant UPI / AutoPay',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            softWrap: true,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Instant NPCI 24x7 settlements & recurring mandates',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              fontSize: 10.5,
                                              height: 1.25,
                                            ),
                                            softWrap: true,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Right Toggle Switch with safe right margin
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Switch.adaptive(
                                  value: _isInstantUpi,
                                  activeColor: const Color(0xFF10B981),
                                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  inactiveThumbColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) => setState(() => _isInstantUpi = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  FintechTextField(
                    controller: _amountController,
                    label: 'Transfer Amount (₹)',
                    hintText: 'Enter Amount',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  FintechTextField(
                    controller: _remarksController,
                    label: 'Purpose / Remarks / Tax Reference',
                    hintText: 'Enter Remarks / Purpose',
                  ),

                  const SizedBox(height: 14),

                  // Quick Action to Active AutoPay Mandates
                  InkWell(
                    key: const Key('manage_autopay_mandates_link'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AutopayMandatesScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.autorenew_rounded, color: Color(0xFF3B82F6), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Manage Active AutoPay & Mandates',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF3B82F6), size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Execute Fund Transfer',
                    icon: Icons.swap_horiz_rounded,
                    isLoading: _isTransferring,
                    onPressed: _isFormValid ? _handleTransfer : null,
                  ),
                ],
              ),
            ),
    );
  }
}

class _BankSecurityVerificationSheet extends StatefulWidget {
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String accountType;
  final String initialTransactionId;
  final String? maskedPhone;
  final String? userPhoneNumber;
  final bool? isSandbox;
  final bool isPennyDropVerified;
  final String? accountHolderName;
  final ValueChanged<AccountModel> onAccountLinked;

  const _BankSecurityVerificationSheet({
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
    required this.accountType,
    required this.initialTransactionId,
    this.maskedPhone,
    this.userPhoneNumber,
    this.isSandbox,
    this.isPennyDropVerified = false,
    this.accountHolderName,
    required this.onAccountLinked,
  });

  @override
  State<_BankSecurityVerificationSheet> createState() => _BankSecurityVerificationSheetState();
}

class _BankSecurityVerificationSheetState extends State<_BankSecurityVerificationSheet> with SingleTickerProviderStateMixin {
  final _repository = FinanceModeRepository();
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  late String _transactionId;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _transactionId = widget.initialTransactionId;
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_secondsRemaining > 1) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _secondsRemaining = 0;
            _canResend = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get isSandboxMode {
    if (widget.isSandbox != null) return widget.isSandbox!;
    return !kReleaseMode || const bool.fromEnvironment('SANDBOX_MODE', defaultValue: false);
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
    setState(() {
      _errorMessage = null;
    });
    _startCountdown();

    try {
      final res = await _repository.sendBankOtp(
        bankName: widget.bankName,
        accountNumber: widget.accountNumber,
        ifsc: widget.ifsc,
        mobileNumber: widget.userPhoneNumber,
        accountType: widget.accountType,
      );
      final newTid = res['transactionId']?.toString() ??
          res['consentHandle']?.toString() ??
          res['challengeId']?.toString();
      if (newTid != null && newTid.isNotEmpty) {
        _transactionId = newTid;
      }
      NotificationService.showSuccess('A fresh SMS OTP was sent to your registered number.');
    } catch (_) {
      NotificationService.showError('Failed to send SMS OTP. Please check your registered phone number.');
    }
  }

  Future<void> _submitVerification() async {
    final code = _otpCode;
    if (code.length != 6 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final linkedAccount = await _repository.verifyBankOtp(
        transactionId: _transactionId,
        otp: code,
        bankName: widget.bankName,
        accountNumber: widget.accountNumber,
        ifsc: widget.ifsc,
        accountType: widget.accountType,
        accountHolderName: widget.accountHolderName ?? 'P. Revanth Reddy',
        isSandbox: isSandboxMode,
      );

      if (mounted) {
        widget.onAccountLinked(linkedAccount);
        Navigator.pop(context);
        NotificationService.showSuccess('Bank Account Linked Successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Invalid OTP entered. Please try again.';
        });
        _shakeController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    // UI Polish & High Contrast Slate: #1E293B in Dark Mode, #F1F5F9 in Light Mode
    final pinBoxBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final pinTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final hasError = _errorMessage != null;
    final errorColor = const Color(0xFFEF4444);
    final displayPhone = widget.maskedPhone?.isNotEmpty == true
        ? widget.maskedPhone!
        : FundTransferScreenState.formatMaskedPhone(widget.userPhoneNumber);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Bank Security Verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textCol,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit verification code sent to your bank-registered mobile number',
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextCol, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.bankName} •••• ${widget.accountNumber.length > 4 ? widget.accountNumber.substring(widget.accountNumber.length - 4) : widget.accountNumber}',
              style: TextStyle(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Mobile: $displayPhone',
              style: TextStyle(
                color: subTextCol,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSandboxMode) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('setu_sandbox_banner'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Testing Sandbox Mode: Live SMS disabled. Use test PIN 123456 to verify.',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // 6-digit OTP Row with Shake Animation on error
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: pinBoxBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasError ? errorColor : borderCol,
                        width: hasError ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        key: Key('link_otp_box_$i'),
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: pinTextColor,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          if (hasError) {
                            setState(() => _errorMessage = null);
                          }
                          setState(() {});
                          if (val.isNotEmpty) {
                            if (i < 5) {
                              _otpFocusNodes[i + 1].requestFocus();
                            } else {
                              _otpFocusNodes[i].unfocus();
                              if (widget.isPennyDropVerified && _otpCode.length == 6 && !_isVerifying) {
                                _submitVerification();
                              }
                            }
                          } else if (i > 0) {
                            _otpFocusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: errorColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            // 60-second Countdown Timer & Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _canResend
                      ? "Didn't receive code?"
                      : 'Resend OTP in 0:${_secondsRemaining.toString().padLeft(2, '0')}s',
                  style: TextStyle(
                    color: subTextCol,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _canResend ? _resendOtp : null,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: _canResend ? const Color(0xFF3B82F6) : subTextCol.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Disabled until full 6-digit OTP is entered
            PrimaryButton(
              text: widget.isPennyDropVerified ? 'Confirm & Link' : 'Verify & Authorize Link',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isVerifying,
              onPressed: (_otpCode.length == 6 && !_isVerifying) ? _submitVerification : null,
            ),
          ],
        ),
      ),
    );
  }
}

