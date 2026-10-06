import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/account_model.dart';
import '../../models/upi_handle_model.dart';

class ManageUpiHandlesScreen extends StatefulWidget {
  const ManageUpiHandlesScreen({super.key});

  @override
  State<ManageUpiHandlesScreen> createState() => _ManageUpiHandlesScreenState();
}

class _ManageUpiHandlesScreenState extends State<ManageUpiHandlesScreen> {
  final _repository = FinanceModeRepository();
  final _prefixController = TextEditingController();

  List<UpiHandleModel> _handles = [];
  List<String> _suggestedHandles = [];
  List<String> _availableSuffixes = [
    '@enxmoney',
    '@okhdfcbank',
    '@okaxis',
    '@okicici',
    '@oksbi',
  ];

  String _selectedSuffix = '@enxmoney';
  List<AccountModel> _bankAccounts = [];
  AccountModel? _selectedAccount;
  bool _isPrimaryForNew = true;

  // Real-time Availability State
  Timer? _debounceTimer;
  bool _isCheckingAvailability = false;
  UpiHandleCheckResult? _availabilityResult;
  bool _isLoading = true;
  bool _isCreating = false;

  String _userName = 'Revanth';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _prefixController.addListener(_onPrefixChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _prefixController.removeListener(_onPrefixChanged);
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final profile = ProfileRepository().profile;
      if (profile.fullName.isNotEmpty) {
        _userName = profile.fullName;
      }
    } catch (_) {}

    // Load user accounts
    final accounts = await _repository.getAccounts(type: FinanceType.personal);
    final banksOnly = accounts.where((a) => a.accountType.toLowerCase() == 'bank' || a.accountType.toLowerCase() == 'savings' || a.bankName.isNotEmpty).toList();

    // Load UPI handles
    final handlesData = await _repository.getUpiHandles();
    final handlesList = handlesData['handles'] as List<UpiHandleModel>? ?? [];
    final suggested = handlesData['suggestedHandles'] as List<String>? ?? [];
    final suffixes = handlesData['availableSuffixes'] as List<String>? ?? _availableSuffixes;

    if (mounted) {
      setState(() {
        _bankAccounts = banksOnly.isNotEmpty ? banksOnly : accounts;
        if (_bankAccounts.isNotEmpty) {
          _selectedAccount = _bankAccounts.firstWhere(
            (a) => a.isDefault || a.bankName.toLowerCase().contains('state bank'),
            orElse: () => _bankAccounts.first,
          );
        }

        _handles = handlesList;
        _suggestedHandles = suggested;
        if (suffixes.isNotEmpty) _availableSuffixes = suffixes;
        _isLoading = false;
      });

      // Suggest initial prefix if empty
      if (_prefixController.text.isEmpty) {
        final clean = _userName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        _prefixController.text = clean.isNotEmpty ? clean : 'revanth';
      }
    }
  }

  void _onPrefixChanged() {
    _debounceTimer?.cancel();
    final text = _prefixController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _availabilityResult = null;
        _isCheckingAvailability = false;
      });
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _checkAvailability();
    });
  }

  Future<void> _checkAvailability() async {
    final prefix = _prefixController.text.trim().toLowerCase();
    if (prefix.isEmpty) return;

    final targetVpa = '$prefix$_selectedSuffix';
    final result = await _repository.checkHandleAvailability(targetVpa);

    if (mounted) {
      setState(() {
        _isCheckingAvailability = false;
        _availabilityResult = result;
      });
    }
  }

  Future<void> _handleSuffixChanged(String newSuffix) async {
    setState(() {
      _selectedSuffix = newSuffix;
      _isCheckingAvailability = true;
    });
    await _checkAvailability();
  }

  Future<void> _createHandle() async {
    final prefix = _prefixController.text.trim().toLowerCase();
    if (prefix.length < 3) {
      _showToast('Please enter at least 3 characters for the handle prefix.');
      return;
    }

    final targetVpa = '$prefix$_selectedSuffix';
    final bankName = _selectedAccount?.bankName ?? 'State Bank of India';
    final accountId = _selectedAccount?.id ?? '';
    final last4 = _selectedAccount?.accountNumberLast4 ?? '1024';

    setState(() => _isCreating = true);

    try {
      final newHandle = await _repository.createCustomHandle(
        vpa: targetVpa,
        bankName: bankName,
        accountId: accountId,
        accountNumberLast4: last4,
        isPrimary: _isPrimaryForNew,
      );

      if (newHandle != null && mounted) {
        _showToast('UPI handle ${newHandle.vpa} linked successfully!');
        await _loadInitialData();

        // Automatically show digital QR code dialog for the newly created handle
        _showQrCodeDialog(newHandle);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to create handle: ${e.toString().replaceAll("Exception:", "")}');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _setAsPrimary(UpiHandleModel handle) async {
    try {
      final updated = await _repository.setPrimaryHandle(handle.id);
      if (updated != null && mounted) {
        _showToast('${updated.vpa} is now your primary UPI handle.');
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error: ${e.toString().replaceAll("Exception:", "")}');
      }
    }
  }

  Future<void> _toggleStatus(UpiHandleModel handle, bool isActive) async {
    try {
      final updated = await _repository.toggleHandleStatus(handle.id, isActive);
      if (updated != null && mounted) {
        _showToast('${handle.vpa} set to ${isActive ? "Active" : "Inactive"}.');
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        _showToast(e.toString().replaceAll("Exception:", ""));
        setState(() {}); // Rebuild to restore toggle switch position
      }
    }
  }

  Future<void> _deleteHandle(UpiHandleModel handle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete UPI Handle?'),
        content: Text('Are you sure you want to remove ${handle.vpa}? You will no longer receive payments via this alias.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _repository.deleteHandle(handle.id);
        if (success && mounted) {
          _showToast('UPI handle deleted.');
          await _loadInitialData();
        }
      } catch (e) {
        if (mounted) {
          _showToast(e.toString().replaceAll("Exception:", ""));
        }
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showQrCodeDialog(UpiHandleModel handle) {
    final isDark = ThemeController().isDarkTheme(context);
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.brandBlue, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Direct Payment QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Scan using any UPI App (GPay, PhonePe, Paytm, BHIM)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: sub),
              ),
              const SizedBox(height: 24),

              // Crisp QR Code Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: handle.qrData,
                      version: QrVersions.auto,
                      size: 210.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      handle.vpa,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Linked to ${handle.bankName} (•••• ${handle.accountNumberLast4})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons: Copy & Share
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? Colors.white24 : AppColors.brandBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy UPI ID'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: handle.vpa));
                        _showToast('Copied ${handle.vpa} to clipboard!');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share QR'),
                      onPressed: () {
                        Share.share(
                          'Pay $_userName on ENX Money via UPI:\n${handle.vpa}\n\nDirect Pay Link: ${handle.qrData}',
                          subject: 'UPI Payment Link',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bg = isDark ? AppColors.background : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Manage UPI IDs & Handles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18),
        actions: [
          IconButton(
            tooltip: 'Refresh handles',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: AppColors.brandBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security / NPCI Compliance Banner
                    _buildSecurityBanner(isDark, cardBg, text, sub, border),

                    const SizedBox(height: 20),

                    // SECTION 1: Handle Selection & Availability Check
                    _buildCustomHandleCreatorCard(isDark, cardBg, text, sub, border),

                    const SizedBox(height: 24),

                    // SECTION 2: Active & Configured Handles List
                    _buildActiveHandlesSection(isDark, cardBg, text, sub, border),

                    const SizedBox(height: 24),

                    // SECTION 3: Suggested Handles
                    if (_suggestedHandles.isNotEmpty)
                      _buildSuggestedHandlesSection(isDark, cardBg, text, sub, border),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecurityBanner(
    bool isDark,
    Color cardBg,
    Color text,
    Color sub,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F233A) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.brandBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NPCI BHIM UPI Verified Routing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Custom handles are bound to your verified bank account via instant PSP settlement.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHandleCreatorCard(
    bool isDark,
    Color cardBg,
    Color text,
    Color sub,
    Color border,
  ) {
    final cleanPrefix = _prefixController.text.trim().toLowerCase();
    final fullVpa = '$cleanPrefix$_selectedSuffix';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.alternate_email_rounded, color: AppColors.brandBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Custom UPI Handle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: text,
                      ),
                    ),
                    Text(
                      'Pick your personalized prefix and suffix',
                      style: TextStyle(fontSize: 12, color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Prefix Input Field
          Text(
            'UPI Prefix',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _availabilityResult == null
                    ? border
                    : (_availabilityResult!.available
                        ? AppColors.success
                        : AppColors.error),
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(Icons.tag_rounded, color: AppColors.brandBlue, size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _prefixController,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text),
                    decoration: const InputDecoration(
                      hintText: 'e.g. revanth',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._-]')),
                    ],
                  ),
                ),
                // Real-time Availability Spinner / Icon
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _isCheckingAvailability
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue),
                        )
                      : (_availabilityResult != null
                          ? Icon(
                              _availabilityResult!.available
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: _availabilityResult!.available
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 22,
                            )
                          : const SizedBox.shrink()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Availability Feedback Text
          if (_availabilityResult != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _availabilityResult!.available
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: _availabilityResult!.available ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _availabilityResult!.message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _availabilityResult!.available ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Suffix Chips Selector
          Text(
            'Partner Handle Suffix',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableSuffixes.map((suffix) {
                final isSelected = _selectedSuffix == suffix;
                final isOfficial = suffix == '@enxmoney';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suffix,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                        if (isOfficial) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white24 : AppColors.brandBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ENX',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.brandBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.brandBlue,
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? AppColors.brandBlue : border,
                    ),
                    onSelected: (val) {
                      if (val) _handleSuffixChanged(suffix);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Suggested variations chips when handle is unavailable or available
          if (_availabilityResult != null &&
              !_availabilityResult!.available &&
              _availabilityResult!.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D1F17) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Alternative Suggestions (Tap to pick):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _availabilityResult!.suggestions.take(4).map((sug) {
                      return InkWell(
                        onTap: () {
                          final parts = sug.split('@');
                          _prefixController.text = parts[0];
                          if (parts.length > 1) {
                            setState(() {
                              _selectedSuffix = '@${parts[1]}';
                            });
                          }
                          _checkAvailability();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF92400E) : const Color(0xFFFCD34D),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, size: 13, color: AppColors.brandBlue),
                              const SizedBox(width: 4),
                              Text(
                                sug,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Dynamic Alias Binding: Bank Account Selection
          Text(
            'Link to Primary Bank Account',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 8),

          if (_bankAccounts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AccountModel>(
                  value: _selectedAccount,
                  isExpanded: true,
                  dropdownColor: cardBg,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandBlue),
                  items: _bankAccounts.map((acc) {
                    return DropdownMenuItem<AccountModel>(
                      value: acc,
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, color: AppColors.brandBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${acc.bankName} (•••• ${acc.accountNumberLast4})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (acc) {
                    if (acc != null) {
                      setState(() => _selectedAccount = acc);
                    }
                  },
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: AppColors.brandBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'State Bank of India (•••• 1024)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Primary Handle Toggle
          Row(
            children: [
              Switch(
                value: _isPrimaryForNew,
                activeColor: AppColors.brandBlue,
                onChanged: (val) => setState(() => _isPrimaryForNew = val),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set as Primary Receiving Alias',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
                    ),
                    Text(
                      'Directs all incoming UPI payments to this handle by default',
                      style: TextStyle(fontSize: 11, color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action CTA Button
          PrimaryButton(
            text: _isCreating
                ? 'Binding Handle...'
                : 'Claim & Bind $fullVpa',
            isLoading: _isCreating,
            onPressed: (_isCheckingAvailability ||
                    (_availabilityResult != null && !_availabilityResult!.available && !_availabilityResult!.alreadyOwned))
                ? null
                : _createHandle,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHandlesSection(
    bool isDark,
    Color cardBg,
    Color text,
    Color sub,
    Color border,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Handles (${_handles.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text),
            ),
            Text(
              'Linked to Bank',
              style: TextStyle(fontSize: 12, color: sub),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_handles.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                'No custom handles created yet. Claim your first handle above!',
                style: TextStyle(fontSize: 13, color: sub),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _handles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final handle = _handles[idx];
              return _buildHandleCard(handle, isDark, cardBg, text, sub, border);
            },
          ),
      ],
    );
  }

  Widget _buildHandleCard(
    UpiHandleModel handle,
    bool isDark,
    Color cardBg,
    Color text,
    Color sub,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: handle.isPrimary ? AppColors.brandBlue.withOpacity(0.5) : border,
          width: handle.isPrimary ? 1.5 : 1,
        ),
        boxShadow: [
          if (handle.isPrimary)
            BoxShadow(
              color: AppColors.brandBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (handle.isPrimary ? AppColors.brandBlue : (isDark ? Colors.white12 : const Color(0xFFF1F5F9))),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alternate_email_rounded,
                  color: handle.isPrimary ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // VPA & Bank details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            handle.vpa,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: text,
                            ),
                          ),
                        ),
                        if (handle.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${handle.bankName} (•••• ${handle.accountNumberLast4})',
                      style: TextStyle(fontSize: 12, color: sub),
                    ),
                  ],
                ),
              ),

              // Active / Inactive switch
              Switch(
                value: handle.isActive,
                activeColor: AppColors.brandBlue,
                onChanged: (val) => _toggleStatus(handle, val),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action row: QR Code, Set Primary, Copy, Delete
          Row(
            children: [
              // Digital QR Code Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.qr_code_rounded, size: 18),
                label: const Text('View QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showQrCodeDialog(handle),
              ),

              const Spacer(),

              // Copy VPA
              IconButton(
                tooltip: 'Copy UPI ID',
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: sub,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: handle.vpa));
                  _showToast('Copied ${handle.vpa} to clipboard!');
                },
              ),

              // Set as Primary button if not primary
              if (!handle.isPrimary)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('Set as Primary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () => _setAsPrimary(handle),
                ),

              // Delete button if not primary
              if (!handle.isPrimary)
                IconButton(
                  tooltip: 'Delete handle',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: AppColors.error,
                  onPressed: () => _deleteHandle(handle),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedHandlesSection(
    bool isDark,
    Color cardBg,
    Color text,
    Color sub,
    Color border,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Partner Handles',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: text),
        ),
        const SizedBox(height: 4),
        Text(
          'Instant 1-tap claim across Google Pay, HDFC, SBI and Axis Bank',
          style: TextStyle(fontSize: 12, color: sub),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestedHandles.map((sug) {
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final parts = sug.split('@');
                _prefixController.text = parts[0];
                if (parts.length > 1) {
                  setState(() => _selectedSuffix = '@${parts[1]}');
                }
                _checkAvailability();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.brandBlue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      sug,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
