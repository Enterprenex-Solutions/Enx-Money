import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../customers/data/customers_repository.dart';
import '../../../customers/models/customer_model.dart';
import '../../../customers/presentation/screens/customer_profile_screen.dart';
import '../../../../core/utils/reminder_launcher.dart';
import '../../../analytics/data/analytics_repository.dart';
import '../../../analytics/models/kpi_summary_model.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../customers/presentation/widgets/customer_search_modal.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../customers/presentation/screens/add_customer_screen.dart';
import '../../../suppliers/presentation/screens/add_supplier_screen.dart';
import '../../../inventory/presentation/screens/add_product_screen.dart';
import '../../../invoices/presentation/screens/create_invoice_screen.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/finance/expandable_fab.dart';
import '../../../../core/widgets/device_approval_dialog.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../ui/features/whatsapp/whatsapp_chatbot_view.dart';
import '../../../../core/widgets/entitlement_guard.dart';
import '../../../finance_mode/presentation/screens/fund_transfer_screen.dart';
import '../../data/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CustomersRepository _customersRepo = CustomersRepository();
  final AuthRepository _authRepo = AuthRepository();
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  final DashboardRepository _dashboardRepo = DashboardRepository();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  String _formatAmount(double amount) => '\u20B9${_currencyFormat.format(amount)}';

  String get _formattedGreetingName {
    if (_userName.trim().isEmpty) return 'Business';
    String name = _userName.trim();
    if (name.contains('@')) {
      name = name.split('@').first;
    }
    return name;
  }

  List<CustomerModel> _customers = [];
  KpiSummary _kpiSummary = KpiSummary.empty();
  DashboardMetrics _dashboardMetrics = DashboardMetrics.empty();
  double _totalReceivable = 0.00;
  double _totalPayable = 0.00;
  bool _isLoading = true;

  String _userName = 'Business';
  String _userInitials = 'EN';
  String _activeFilter = 'ALL'; // 'ALL', 'DUES_PENDING', 'SETTLED'

  @override
  void initState() {
    super.initState();
    DataSyncService().addListener(_onDataSyncUpdate);
    _loadUserAndData();
  }

  void _onDataSyncUpdate() {
    if (mounted) {
      _loadUserAndData();
    }
  }

  @override
  void dispose() {
    DataSyncService().removeListener(_onDataSyncUpdate);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    setState(() => _isLoading = true);

    // 1. Get current logged in user name & initials
    final user = _authRepo.currentUser ?? await _authRepo.getLocalUser();
    if (user != null && user.name.isNotEmpty) {
      _userName = user.name.trim();
      final parts = _userName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        _userInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        _userInitials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    // 2. Fetch Customers, KPIs & Dashboard Metrics concurrently from live backend
    try {
      final custFuture = _customersRepo.getCustomers(
        search: _searchController.text.trim(),
      );
      final kpiFuture = _analyticsRepo.getKpi(
        profileType: 'business',
      );
      final metricsFuture = _dashboardRepo.getMetrics();

      final results = await Future.wait([custFuture, kpiFuture, metricsFuture]);
      final res = results[0] as CustomersResult;
      final kpi = results[1] as KpiSummary;
      final metrics = results[2] as DashboardMetrics;

      // Ensure fallback if metrics.sales is 0 but customer totalReceivable > 0
      final effectiveMetrics = (metrics.sales == 0.0 && res.totalReceivable > 0.0)
          ? DashboardMetrics(
              totalBusinessBalance: res.totalReceivable,
              totalInflow: res.totalReceivable,
              totalOutflow: metrics.totalOutflow,
              sales: res.totalReceivable,
              expenses: metrics.expenses,
              netProfit: res.totalReceivable - metrics.expenses,
              outstandingReceivables: res.totalReceivable,
              outstandingPayables: kpi.outstandingPayables,
              bankLedgerTotal: metrics.bankLedgerTotal,
            )
          : metrics;

      if (mounted) {
        setState(() {
          _customers = res.customers;
          _kpiSummary = kpi;
          _dashboardMetrics = effectiveMetrics;
          _totalReceivable = res.totalReceivable;
          _totalPayable = kpi.outstandingPayables;
          _isLoading = false;
        });

        // 3. Check for pending device approval requests
        _checkPendingDeviceApprovals();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Trigger background refetch of metrics without unmounting or resetting screen
  Future<void> _refetchDashboardMetrics() async {
    try {
      final metricsFuture = _dashboardRepo.getMetrics(fallbackReceivable: _totalReceivable);
      final kpiFuture = _analyticsRepo.getKpi(profileType: 'business');
      final custFuture = _customersRepo.getCustomers(search: _searchController.text.trim());

      final results = await Future.wait([metricsFuture, kpiFuture, custFuture]);
      final metrics = results[0] as DashboardMetrics;
      final kpi = results[1] as KpiSummary;
      final res = results[2] as CustomersResult;

      final effectiveMetrics = (metrics.sales == 0.0 && res.totalReceivable > 0.0)
          ? DashboardMetrics(
              totalBusinessBalance: res.totalReceivable,
              totalInflow: res.totalReceivable,
              totalOutflow: metrics.totalOutflow,
              sales: res.totalReceivable,
              expenses: metrics.expenses,
              netProfit: res.totalReceivable - metrics.expenses,
              outstandingReceivables: res.totalReceivable,
              outstandingPayables: kpi.outstandingPayables,
              bankLedgerTotal: metrics.bankLedgerTotal,
            )
          : metrics;

      if (mounted) {
        setState(() {
          _dashboardMetrics = effectiveMetrics;
          _kpiSummary = kpi;
          _customers = res.customers;
          _totalReceivable = res.totalReceivable;
          _totalPayable = kpi.outstandingPayables;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkPendingDeviceApprovals() async {
    try {
      final pending = await _authRepo.getPendingDeviceApprovals();
      if (pending.isNotEmpty && mounted) {
        DeviceApprovalDialog.show(context, pending.first);
      }
    } catch (_) {}
  }

  List<CustomerModel> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    return _customers.where((c) {
      final matchesSearch = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.phone.contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.gstin.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      if (_activeFilter == 'DUES_PENDING') {
        return c.currentBalance > 0;
      } else if (_activeFilter == 'SETTLED') {
        return c.currentBalance == 0;
      }
      return true;
    }).toList();
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
      repository: _customersRepo,
      businessName: effectiveBusinessName,
    );
  }

  void _showQuickKhataDialog(String defaultType) async {
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
                        entryType == 'GAVE' ? '\u2191 Record Gave \u20B9 (Sale / Udhaar)' : '\u2193 Record Got \u20B9 (Payment / Jama)',
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

                  // Select Customer Selector Card
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
                                    '${selectedCustomer!.phone.isNotEmpty ? selectedCustomer!.phone : selectedCustomer!.email} \u2022 Balance: \u20B9${selectedCustomer!.currentBalance.toStringAsFixed(2)}',
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
                      labelText: 'AMOUNT (\u20B9)',
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
                      hintText: 'e.g. Sales Invoice #102, Cotton shirts',
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
                          await _customersRepo.addLedgerEntry(selectedCustomer!.id, {
                            'entryType': entryType,
                            'amount': amt,
                            'description': descController.text.trim(),
                            'paymentMode': entryType == 'GAVE' ? 'CREDIT' : 'CASH',
                          });
                          DataSyncService().notifyDataChanged();
                          await _loadUserAndData();
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
    final duesCount = _customers.where((c) => c.currentBalance > 0).length;
    final settledCount = _customers.where((c) => c.currentBalance == 0).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: const ExpandableFab(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserAndData,
          color: const Color(0xFF00E676),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Top Custom App Header (Avatar, Enterprenex Business, PDF, Refresh)
              _buildTopHeader(isDark),

              // 1b. Profile Completion Progress Banner (Shows Complete Profile: X% with high-contrast CTA)
              _buildProfileCompletionBanner(isDark),

              const SizedBox(height: 14),

              // 2. Live Total Balance & Income Card
              _buildTotalBalanceAndIncomeCard(isDark),

              const SizedBox(height: 12),

              // 3. 3-Column Live Metrics (Sales | Expenses | Net Profit)
              _buildThreeColumnMetrics(isDark),

              const SizedBox(height: 12),

              // 4. Balance Summary Card (You Will Get / You Will Give)
              _buildBalanceSummaryCard(isDark),

              const SizedBox(height: 14),

              // 5. Quick Actions Business Workflow
              _buildQuickActionsGrid(isDark),

              const SizedBox(height: 12),

              // 5b. WhatsApp AI Assistant Banner
              _buildWhatsAppChatbotBanner(isDark),

              const SizedBox(height: 14),

              // 6. Search Bar (Search customer by name, mobile, or GSTIN...)
              _buildSearchBar(isDark),

              const SizedBox(height: 14),

              // 7. Filter Chips Row: All(N), Dues Pending(N), Settled(0 Balance)
              _buildFilterChips(duesCount, settledCount, isDark),

              const SizedBox(height: 14),

              // 9. Customers List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF00E676)),
                  ),
                )
              else if (_filteredCustomers.isEmpty)
                _buildEmptyCustomerState()
              else
                ..._filteredCustomers.map((c) => _buildCustomerCard(c, isDark)),

              const SizedBox(height: 80), // padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isDark) {
    final Color primaryText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final Color secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: User Avatar circle + User Greeting
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emerald avatar with drawer trigger
              GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _userInitials,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10141D) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_rounded, size: 12, color: Color(0xFF00E676)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // App Title & User Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ENX MONEY',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hi, $_formattedGreetingName',
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Right side: Refresh icon
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.refresh_rounded, color: secondaryText, size: 22),
          onPressed: _refetchDashboardMetrics,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  /// Profile Progress Engine Header Banner (Displays Complete Profile: X% alongside high-contrast CTA)
  Widget _buildProfileCompletionBanner(bool isDark) {
    final repo = ProfileRepository();
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final profile = repo.profile;
        final completion = profile.completionPercentage;
        if (completion >= 100) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00E676).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF00E676), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Complete Profile: $completion%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: completion / 100,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete Now',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: Colors.black, size: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // YOU WILL GET
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('you_will_get'),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatAmount(_totalReceivable),
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
          Container(
            width: 1,
            height: 48,
            color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 16),
          // YOU WILL GIVE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('you_will_give'),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatAmount(_totalPayable),
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

  Widget _buildTotalBalanceAndIncomeCard(bool isDark) {
    // Dynamic live business balance binding
    final double liveInflow = _dashboardMetrics.totalInflow > 0
        ? _dashboardMetrics.totalInflow
        : (_kpiSummary.totalRevenue > 0 ? _kpiSummary.totalRevenue : _totalReceivable);
    final double liveOutflow = _dashboardMetrics.totalOutflow > 0
        ? _dashboardMetrics.totalOutflow
        : _kpiSummary.totalExpense;
    // Formula for Display: Total Business Balance = Total Inflow - Total Outflow (or live aggregated bank ledger total)
    final double netBalance = _dashboardMetrics.totalBusinessBalance != 0.0
        ? _dashboardMetrics.totalBusinessBalance
        : (liveInflow - liveOutflow);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F1E36), const Color(0xFF0B1424)]
              : [const Color(0xFF0066FF), const Color(0xFF0048B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFF2563EB).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0066FF).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'TOTAL BUSINESS BALANCE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'REAL-TIME',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E676) : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(netBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162338) : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_circle_up_rounded, color: Color(0xFF00E676), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Total Inflow: ${_formatAmount(liveInflow)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_circle_down_rounded, color: Color(0xFFFF8A80), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Total Outflow: ${_formatAmount(liveOutflow)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeColumnMetrics(bool isDark) {
    final double liveSales = _dashboardMetrics.sales > 0
        ? _dashboardMetrics.sales
        : (_kpiSummary.totalRevenue > 0 ? _kpiSummary.totalRevenue : _totalReceivable);
    final double liveExpenses = _dashboardMetrics.expenses > 0
        ? _dashboardMetrics.expenses
        : _kpiSummary.totalExpense;
    final double liveNetProfit = _dashboardMetrics.netProfit != 0.0
        ? _dashboardMetrics.netProfit
        : (liveSales - liveExpenses);

    return Row(
      children: [
        // Sales
        Expanded(
          child: _buildMetricTile(
            title: 'SALES',
            amount: liveSales,
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF00E676),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        // Expenses
        Expanded(
          child: _buildMetricTile(
            title: 'EXPENSES',
            amount: liveExpenses,
            icon: Icons.trending_down_rounded,
            color: const Color(0xFFFF5252),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        // Net Profit
        Expanded(
          child: _buildMetricTile(
            title: 'NET PROFIT',
            amount: liveNetProfit,
            icon: Icons.account_balance_wallet_rounded,
            color: liveNetProfit >= 0 ? const Color(0xFF2979FF) : const Color(0xFFFF5252),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsAppBot() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EntitlementGuard(
          featureCode: 'WHATSAPP_CHATBOT',
          child: WhatsAppChatbotView(),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(bool isDark) {
    final row1Actions = [
      _QuickAction(
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF2979FF),
        label: context.tr('add_customer'),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
          _loadUserAndData();
        },
      ),
      _QuickAction(
        icon: Icons.storefront_rounded,
        color: const Color(0xFF00BCD4),
        label: context.tr('add_supplier'),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
          );
          _loadUserAndData();
        },
      ),
      _QuickAction(
        icon: Icons.add_box_rounded,
        color: const Color(0xFFFFB300),
        label: context.tr('add_product'),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          _loadUserAndData();
        },
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF00E676),
        label: context.tr('create_sale_gst'),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
          _loadUserAndData();
        },
      ),
    ];

    final row2Actions = [
      _QuickAction(
        icon: Icons.payment_rounded,
        color: const Color(0xFF7C4DFF),
        label: context.tr('add_payment'),
        onTap: () => _showQuickKhataDialog('GOT'),
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFFF9100),
        label: context.tr('khata_outstanding'),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomersScreen()),
          );
          _loadUserAndData();
        },
      ),
      _QuickAction(
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF10B981),
        label: 'Fund Transfer',
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FundTransferScreen()),
          );
          _loadUserAndData();
        },
      ),
    ];

    Widget buildTile(_QuickAction a) {
      return InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141824) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, color: a.color, size: 20),
                ),
                const SizedBox(height: 5),
                Text(
                  a.label,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < row1Actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 86,
                  child: buildTile(row1Actions[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < row2Actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 86,
                  child: buildTile(row2Actions[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// WhatsApp AI Financial Assistant Banner Card on Dashboard
  Widget _buildWhatsAppChatbotBanner(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0B2417), const Color(0xFF111E2E)]
              : [const Color(0xFFDCFCE7), const Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchWhatsAppBot,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // WhatsApp Icon Badge with pulsing indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF25D366), width: 1),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Color(0xFF25D366),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'WhatsApp AI Assistant',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Color(0xFF25D366), size: 5),
                                SizedBox(width: 3),
                                Text(
                                  'ONLINE',
                                  style: TextStyle(
                                    color: Color(0xFF25D366),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Instant balance, payments, khata reminders & GST queries',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Open Chat CTA Button
                InkWell(
                  onTap: _launchWhatsAppBot,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                      ],
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

  // ----------------------------------------------------------------------
  // Analytics / Chart methods removed - see dedicated Reports screen instead.
  // ----------------------------------------------------------------------

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
        decoration: InputDecoration(
          hintText: 'Search customer by name, mobile, or GSTIN...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips(int duesCount, int settledCount, bool isDark) {
    return Row(
      children: [
        // All
        _buildChipItem('\u2713 All (${_customers.length})', 'ALL', _activeFilter == 'ALL', isDark),
        const SizedBox(width: 8),
        // Dues Pending
        _buildChipItem('Dues Pending ($duesCount)', 'DUES_PENDING', _activeFilter == 'DUES_PENDING', isDark),
        const SizedBox(width: 8),
        // Settled
        _buildChipItem('Settled ($settledCount Balance)', 'SETTLED', _activeFilter == 'SETTLED', isDark),
      ],
    );
  }

  Widget _buildChipItem(String label, String key, bool isSelected, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E676)
                : (isDark ? const Color(0xFF121622) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : (isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1)),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, bool isDark) {
    final isPositive = customer.currentBalance > 0;
    final balanceColor = isPositive ? const Color(0xFFFF5252) : const Color(0xFF00E676);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
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
              _loadUserAndData();
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
                    // Circle letter avatar (E)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18222F) : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name, Phone & Location Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.phone,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (customer.district.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  customer.state.isNotEmpty ? '${customer.district}, ${customer.state}' : customer.district,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Balance & DUE Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatAmount(customer.currentBalance.abs()),
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? (isDark ? const Color(0xFF33161C) : const Color(0xFFFEE2E2))
                                : (isDark ? const Color(0xFF132B20) : const Color(0xFFDCFCE7)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPositive ? 'DUE' : 'SETTLED',
                            style: TextStyle(
                              color: isPositive ? const Color(0xFFFF5252) : const Color(0xFF059669),
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
                InkWell(
                  onTap: () => _sendReminder(customer),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF102632) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF183C4E) : const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, color: Color(0xFF00BCD4), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Reminder',
                          style: TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyCustomerState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, color: Colors.grey, size: 40),
            const SizedBox(height: 12),
            Text(
              'No Customers Found',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Click + Add Customer to record sales and payments.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}
