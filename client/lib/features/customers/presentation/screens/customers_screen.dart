import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/customers_repository.dart';
import '../../models/customer_model.dart';
import 'add_customer_screen.dart';
import 'customer_profile_screen.dart';
import '../../../../core/utils/reminder_launcher.dart';
import '../../../../core/services/data_sync_service.dart';
import '../widgets/customer_search_modal.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../../profile/data/profile_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomersRepository _repository = CustomersRepository();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  List<CustomerModel> _customers = [];
  double _totalReceivable = 0.0;
  double _totalPayable = 0.0;
  int _allCount = 0;
  int _duesPendingCount = 0;
  int _settledCount = 0;

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedStatus = 'ALL'; // 'ALL', 'due', 'settled'

  @override
  void initState() {
    super.initState();
    DataSyncService().addListener(_onDataSyncUpdate);
    _fetchCustomers();
  }

  void _onDataSyncUpdate() {
    if (mounted) {
      _fetchCustomers();
    }
  }

  @override
  void dispose() {
    DataSyncService().removeListener(_onDataSyncUpdate);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.getCustomers(
        search: _searchController.text.trim(),
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _customers = res.customers;
          _totalReceivable = res.totalReceivable;
          _totalPayable = res.totalPayable;
          _allCount = res.allCount > 0 ? res.allCount : res.totalCount;
          _duesPendingCount = res.duesPendingCount;
          _settledCount = res.settledCount;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = (err is ApiException)
              ? err.message
              : 'Unable to connect to the server. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _sendReminder(CustomerModel customer) {
    final profile = ProfileRepository().profile;
    final bName = profile.businessProfile.businessName.trim();
    final effectiveBusinessName = bName.isNotEmpty
        ? bName
        : (profile.fullName.trim().isNotEmpty ? profile.fullName.trim() : 'Business');

    ReminderLauncher.showReminderBottomSheet(
      context: context,
      customer: customer,
      repository: _repository,
      businessName: effectiveBusinessName,
    );
  }

  void _showQuickEntryDialog(String defaultType) async {
    CustomerModel? selectedCustomer = _customers.isNotEmpty ? _customers.first : null;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String entryType = defaultType; // 'GAVE' or 'GOT'

    if (selectedCustomer == null) {
      selectedCustomer = await CustomerSearchModal.show(context);
      if (selectedCustomer == null) {
        return; // User cancelled
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entryType == 'GAVE' ? '↑ + Give (Sale / Udhaar)' : '↓ + Got (Payment / Jama)',
                        style: TextStyle(
                          color: entryType == 'GAVE' ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Customer Selector Card
                  const Text('CUSTOMER', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await CustomerSearchModal.show(
                        context,
                        initialCustomer: selectedCustomer,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedCustomer = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2030),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2B3248)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF2B3248),
                            child: Text(
                              (selectedCustomer?.name.isNotEmpty == true)
                                  ? selectedCustomer!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCustomer?.name ?? 'Select Customer',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                if (selectedCustomer != null)
                                  Text(
                                    '${selectedCustomer!.phone.isNotEmpty ? selectedCustomer!.phone : selectedCustomer!.email} • Balance: ₹${selectedCustomer!.currentBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: selectedCustomer!.currentBalance > 0
                                          ? const Color(0xFFFF5252)
                                          : const Color(0xFF00E676),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00E676), size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF00E676)),
                      labelText: 'AMOUNT (₹) *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1B2030),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Description
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'DESCRIPTION / ITEM DETAILS',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'e.g. Invoiced goods, partial settlement',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1B2030),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: entryType == 'GAVE' ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                        foregroundColor: entryType == 'GAVE' ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (selectedCustomer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.amber,
                              content: Text('Please select a customer first.', style: TextStyle(color: Colors.black)),
                            ),
                          );
                          return;
                        }
                        final amt = double.tryParse(amountController.text.trim());
                        if (amt == null || amt <= 0) return;

                        Navigator.pop(context);
                        try {
                          await _repository.addLedgerEntry(selectedCustomer!.id, {
                            'entryType': entryType,
                            'amount': amt,
                            'description': descController.text.trim(),
                            'paymentMode': entryType == 'GAVE' ? 'CREDIT' : 'CASH',
                          });
                          DataSyncService().notifyDataChanged();
                          _fetchCustomers();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: AppColors.error, content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      child: const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
          if (res == true) {
            DataSyncService().notifyDataChanged();
            _fetchCustomers();
          }
        },
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.black),
        label: const Text(
          'Add Customer',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: _fetchCustomers,
              color: const Color(0xFF00E676),
              backgroundColor: cardBg,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Header (ENX Money, Business Name, Menu/Profile)
                  _buildHeader(isDark, textColor),

                  const SizedBox(height: 16),

                  // 2. Top Overview (You Will Get & You Will Give)
                  _buildBalanceOverview(cardBg, borderColor, isDark),

                  const SizedBox(height: 14),

                  // 3. Top Actions: [+ Give (Sale)] & [+ Got (Payment)]
                  _buildTopActions(isDark),

                  const SizedBox(height: 16),

                  // 4. Search Bar
                  _buildSearchBar(cardBg, borderColor, textColor, isDark),

                  const SizedBox(height: 14),

                  // 5. Dynamic Filter Chips: All, Dues Pending, Settled
                  _buildFilterChips(cardBg, borderColor, isDark),

                  const SizedBox(height: 14),

                  // 6. Content / State Handler
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF00E676)),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else if (_customers.isEmpty)
                    _searchController.text.isNotEmpty ? _buildSearchNoResults() : _buildEmptyState()
                  else
                    ..._customers.map((c) => _buildCustomerCard(c, cardBg, borderColor, textColor, isDark)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return ListenableBuilder(
      listenable: ProfileRepository(),
      builder: (context, _) {
        final profile = ProfileRepository().profile;
        final rawBizName = profile.businessProfile.businessName.trim();
        final rawFullName = profile.fullName.trim();
        final businessName = rawBizName.isNotEmpty
            ? rawBizName
            : (rawFullName.isNotEmpty ? rawFullName : 'Business');

        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('EN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$businessName • Customers',
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // PDF Export
        InkWell(
          onTap: () async {
            if (_customers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No customers available to export.')),
              );
              return;
            }

            if (_customers.length == 1) {
              final cust = _customers.first;
              final ledger = await _repository.getCustomerLedger(cust.id);
              if (mounted) {
                await PdfInvoiceService.downloadAndOpenCustomerStatement(cust, ledger, context: context);
              }
              return;
            }

            showModalBottomSheet(
              context: context,
              backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Export Customer Ledger Statement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _customers.length,
                          itemBuilder: (c, idx) {
                            final cst = _customers[idx];
                            return ListTile(
                              leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF00BCD4)),
                              title: Text(cst.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                              subtitle: Text('Balance: ₹${_currencyFormat.format(cst.currentBalance.abs())} ${cst.currentBalance > 0 ? "DUE" : "SETTLED"}'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final ledger = await _repository.getCustomerLedger(cst.id);
                                if (mounted) {
                                  await PdfInvoiceService.downloadAndOpenCustomerStatement(cst, ledger, context: context);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14243B) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBAE6FD)),
            ),
            child: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0284C7), size: 16),
                SizedBox(width: 4),
                Text(
                  'PDF',
                  style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.grey : Colors.black54, size: 22),
          onPressed: _fetchCustomers,
          tooltip: 'Refresh',
        ),
      ],
    );
  },
);
}

  Widget _buildBalanceOverview(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('you_will_get'),
                  style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_currencyFormat.format(_totalReceivable)}',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: borderColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('you_will_give'),
                  style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_currencyFormat.format(_totalPayable)}',
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActions(bool isDark) {
    return Row(
      children: [
        // + Give (Sale) - GREEN
        Expanded(
          child: InkWell(
            onTap: () => _showQuickEntryDialog('GAVE'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E241E) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF13523B) : const Color(0xFF86EFAC)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_upward_rounded, color: isDark ? const Color(0xFF00E676) : const Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('gave_sale'),
                    style: TextStyle(color: isDark ? const Color(0xFF00E676) : const Color(0xFF16A34A), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // + Got (Payment) - RED
        Expanded(
          child: InkWell(
            onTap: () => _showQuickEntryDialog('GOT'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22151B) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF552228) : const Color(0xFFFCA5A5)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_downward_rounded, color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('got_payment'),
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(Color cardBg, Color borderColor, Color textColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _fetchCustomers(),
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search customer by name, mobile, or GSTIN...',
          hintStyle: TextStyle(color: isDark ? Colors.grey : const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E676), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _fetchCustomers();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Color cardBg, Color borderColor, bool isDark) {
    return Row(
      children: [
        _buildChipItem('✓ All ($_allCount)', 'ALL', _selectedStatus == 'ALL', cardBg, borderColor, isDark),
        const SizedBox(width: 8),
        _buildChipItem('Dues Pending ($_duesPendingCount)', 'due', _selectedStatus == 'due', cardBg, borderColor, isDark),
        const SizedBox(width: 8),
        _buildChipItem('Settled ($_settledCount)', 'settled', _selectedStatus == 'settled', cardBg, borderColor, isDark),
      ],
    );
  }

  Widget _buildChipItem(String label, String key, bool isSelected, Color cardBg, Color borderColor, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedStatus = key);
          _fetchCustomers();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E676) : cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E676) : borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : (isDark ? Colors.white : const Color(0xFF0F172A)),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, Color cardBg, Color borderColor, Color textColor, bool isDark) {
    final isDue = customer.currentBalance > 0;
    final isSettled = customer.currentBalance == 0;
    final balanceColor = isSettled
        ? Colors.grey
        : isDue
            ? const Color(0xFFFF5252)
            : const Color(0xFF00A86B);

    final statusText = isSettled
        ? 'SETTLED'
        : isDue
            ? 'DUE'
            : 'ADVANCE';

    final statusBadgeColor = isSettled
        ? Colors.grey
        : isDue
            ? const Color(0xFFFF5252)
            : const Color(0xFF00A86B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerProfileScreen(customer: customer),
              ),
            );
            if (refreshed == true) {
              _fetchCustomers();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circle avatar with first letter
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: Color(0xFF00A86B),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name, Phone & GSTIN
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.phone,
                            style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 12),
                          ),
                          if (customer.gstin.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'GSTIN: ${customer.gstin}',
                              style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11),
                            ),
                          ],
                          if (customer.state.isNotEmpty || customer.district.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    customer.district.isNotEmpty ? '${customer.district}, ${customer.state}' : customer.state,
                                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Balance & Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${_currencyFormat.format(customer.currentBalance.abs())}',
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBadgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusBadgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Reminder Button
                Material(
                  color: isDark ? const Color(0xFF102632) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _sendReminder(customer),
                    borderRadius: BorderRadius.circular(8),
                    splashColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    highlightColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.6) : const Color(0xFF0284C7),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_outlined, color: Color(0xFF0284C7), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Send Reminder',
                            style: TextStyle(
                              color: Color(0xFF0284C7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, color: Colors.grey, size: 44),
            const SizedBox(height: 12),
            const Text(
              'No Customers Added Yet',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click "+ Add Customer" to create your first customer profile.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.grey, size: 44),
            const SizedBox(height: 12),
            Text(
              'No results for "${_searchController.text.trim()}"',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2030),
                foregroundColor: const Color(0xFF00E676),
              ),
              onPressed: () {
                _searchController.clear();
                _fetchCustomers();
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _fetchCustomers,
            ),
          ],
        ),
      ),
    );
  }
}
