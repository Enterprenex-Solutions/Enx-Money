import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/suppliers_repository.dart';
import '../../models/supplier_model.dart';
import 'add_supplier_screen.dart';

class SuppliersScreen extends StatefulWidget {
  final SuppliersRepository? repository;
  const SuppliersScreen({super.key, this.repository});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final SuppliersRepository _repository = widget.repository ?? SuppliersRepository();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final TextEditingController _searchController = TextEditingController();

  List<SupplierModel> _suppliers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuppliers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _repository.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = list;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = (err is ApiException)
              ? err.message
              : 'Unable to connect to server. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  List<SupplierModel> get _filteredSuppliers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _suppliers;
    return _suppliers.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.contactNumber.contains(query) ||
          s.companyName.toLowerCase().contains(query) ||
          s.gstin.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalPayable = _suppliers.fold<double>(0.0, (sum, s) => sum + s.outstandingPayable);

    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final isDark = ThemeController().isDarkTheme(context);
        final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
        final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
        final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: textPrimary,
            iconTheme: IconThemeData(color: textPrimary),
            title: Text(
              'Suppliers & Vendors',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                color: textPrimary,
                onPressed: _fetchSuppliers,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 6,
            highlightElevation: 10,
            icon: const Icon(Icons.add_business_rounded, color: Colors.white),
            label: const Text(
              'Add Supplier',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
              );
              if (created == true) {
                _fetchSuppliers();
              }
            },
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchSuppliers,
              color: const Color(0xFF2563EB),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Summary Banner Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL YOU WILL GIVE (PAYABLE)',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${_currencyFormat.format(totalPayable)}',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2638) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_suppliers.length} Vendors',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search Bar with High-Contrast Accessibility
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                      cursorWidth: 2.0,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search suppliers by name or phone...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Supplier List
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _fetchSuppliers,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredSuppliers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Suppliers Found',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + Add Supplier to record purchases and payables.',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filteredSuppliers.map((supplier) {
                      final hasLocation = supplier.city.isNotEmpty || supplier.district.isNotEmpty || supplier.state.isNotEmpty;
                      final locationText = [
                        if (supplier.city.isNotEmpty) supplier.city else if (supplier.mandal.isNotEmpty) supplier.mandal,
                        if (supplier.district.isNotEmpty) supplier.district,
                        if (supplier.state.isNotEmpty) supplier.state,
                      ].join(', ');

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showSupplierDetails(context, supplier),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1C2433) : const Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.4) : const Color(0xFF93C5FD),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0066FF),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  supplier.name,
                                                  style: TextStyle(
                                                    color: textPrimary,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (supplier.companyName.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              supplier.companyName,
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone_outlined, size: 12, color: textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                supplier.contactNumber,
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${_currencyFormat.format(supplier.outstandingPayable)}',
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF33161C) : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'PAYABLE',
                                            style: TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (supplier.gstin.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0C2A4D) : const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified_outlined, size: 11, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'GST: ${supplier.gstin}',
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (hasLocation)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 11, color: textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              locationText,
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (supplier.dueDate != null && supplier.dueDate!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF3B1E08) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              supplier.dueReminderEnabled ? Icons.notifications_active_outlined : Icons.calendar_today_outlined,
                                              size: 11,
                                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due: ${supplier.dueDate}',
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSupplierDetails(BuildContext context, SupplierModel supplier) {
    final isDark = ThemeController().isDarkTheme(context);
    final sheetBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (supplier.companyName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              supplier.companyName,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Financial Highlight Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT OUTSTANDING PAYABLE',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_currencyFormat.format(supplier.outstandingPayable)}',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU OWE',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Detail Rows
                _buildInfoTile('Phone', supplier.contactNumber, Icons.phone_outlined, textPrimary, textSecondary, cardBg, borderColor),
                if (supplier.email.isNotEmpty)
                  _buildInfoTile('Email', supplier.email, Icons.email_outlined, textPrimary, textSecondary, cardBg, borderColor),
                if (supplier.gstin.isNotEmpty)
                  _buildInfoTile('GSTIN', supplier.gstin, Icons.verified_user_outlined, textPrimary, textSecondary, cardBg, borderColor),

                // Full Address Hierarchy
                _buildInfoTile(
                  'Address Hierarchy',
                  [
                    if (supplier.address.isNotEmpty) supplier.address,
                    if (supplier.city.isNotEmpty) 'City/Mandal: ${supplier.city}',
                    if (supplier.district.isNotEmpty) 'District: ${supplier.district}',
                    if (supplier.state.isNotEmpty) 'State: ${supplier.state}',
                    if (supplier.pincode.isNotEmpty) 'Pincode: ${supplier.pincode}',
                    'Country: ${supplier.country}',
                  ].join('\n'),
                  Icons.location_city_outlined,
                  textPrimary,
                  textSecondary,
                  cardBg,
                  borderColor,
                ),

                // Payment Terms & Reminder
                _buildInfoTile(
                  'Payment Terms & Due Date',
                  'Terms: ${supplier.paymentTerms}\n'
                  'Due Date: ${supplier.dueDate ?? "Not set"}\n'
                  'Due Reminder: ${supplier.dueReminderEnabled ? "Enabled (Reminder on ${supplier.reminderDate ?? supplier.dueDate})" : "Disabled"}',
                  Icons.calendar_month_outlined,
                  textPrimary,
                  textSecondary,
                  cardBg,
                  borderColor,
                ),

                if (supplier.notes.isNotEmpty)
                  _buildInfoTile('Notes', supplier.notes, Icons.notes_outlined, textPrimary, textSecondary, cardBg, borderColor),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

