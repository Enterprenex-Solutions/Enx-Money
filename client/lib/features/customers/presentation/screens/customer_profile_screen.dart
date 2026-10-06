import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/customers_repository.dart';
import '../../models/customer_model.dart';
import '../../models/ledger_entry_model.dart';
import '../../../../core/utils/reminder_launcher.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../../profile/data/profile_repository.dart';

class CustomerProfileScreen extends StatefulWidget {
  final CustomerModel customer;
  const CustomerProfileScreen({super.key, required this.customer});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> with SingleTickerProviderStateMixin {
  final CustomersRepository _repository = CustomersRepository();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  late CustomerModel _customer;
  List<LedgerEntryModel> _ledgerEntries = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final updatedCust = await _repository.getCustomerById(_customer.id);
      final entries = await _repository.getCustomerLedger(_customer.id);
      if (mounted) {
        setState(() {
          _customer = updatedCust;
          _ledgerEntries = entries;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEntryDialog(String defaultType) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String entryType = defaultType; // 'GAVE' or 'GOT'
    String paymentMode = 'CASH';

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
                        entryType == 'GAVE'
                            ? "↑ Give / Sale (Udhaar)"
                            : "↓ Got / Payment (Jama)",
                        style: TextStyle(
                          color: entryType == 'GAVE' ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                          fontSize: 18,
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

                  // Entry Type Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: entryType == 'GAVE'
                                ? const Color(0xFF00E676)
                                : const Color(0xFF1B2030),
                            foregroundColor: entryType == 'GAVE' ? Colors.black : Colors.white,
                          ),
                          onPressed: () => setModalState(() => entryType = 'GAVE'),
                          child: const Text("Give / Sale"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: entryType == 'GOT'
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF1B2030),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => setModalState(() => entryType = 'GOT'),
                          child: const Text("Got / Payment"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Payment mode
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    dropdownColor: const Color(0xFF1B2030),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'PAYMENT MODE',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1B2030),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay / PhonePe / Paytm)')),
                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer (NEFT/RTGS)')),
                      DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                      DropdownMenuItem(value: 'CREDIT', child: Text('Credit Sale')),
                    ],
                    onChanged: (val) => setModalState(() => paymentMode = val ?? 'CASH'),
                  ),

                  const SizedBox(height: 14),

                  // Description
                  TextField(
                    controller: descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'DESCRIPTION / ITEM DETAILS',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'e.g. Sales Invoice #102, cotton fabrics',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1B2030),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        final amt = double.tryParse(amountController.text.trim());
                        if (amt == null || amt <= 0) return;

                        Navigator.pop(context);
                        try {
                          await _repository.addLedgerEntry(_customer.id, {
                            'entryType': entryType,
                            'amount': amt,
                            'paymentMode': paymentMode,
                            'description': descriptionController.text.trim(),
                          });
                          DataSyncService().notifyDataChanged();
                          _loadData();
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

  void _showEditCustomerDialog() {
    final nameCtrl = TextEditingController(text: _customer.name);
    final phoneCtrl = TextEditingController(text: _customer.phone);
    final gstinCtrl = TextEditingController(text: _customer.gstin);
    final creditCtrl = TextEditingController(text: _customer.creditLimit.toString());
    final addressCtrl = TextEditingController(text: _customer.address);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141824),
          title: const Text('Edit Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Customer Name *', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Mobile Number *', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: gstinCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'GSTIN', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: creditCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Credit Limit (₹)', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  await _repository.updateCustomer(_customer.id, {
                    'name': name,
                    'phone': phone,
                    'gstin': gstinCtrl.text.trim(),
                    'creditLimit': double.tryParse(creditCtrl.text.trim()) ?? 0.0,
                    'address': addressCtrl.text.trim(),
                  });
                  _loadData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppColors.error, content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _sendReminder() {
    final profile = ProfileRepository().profile;
    final bName = profile.businessProfile.businessName.trim();
    final effectiveBusinessName = bName.isNotEmpty
        ? bName
        : (profile.fullName.trim().isNotEmpty ? profile.fullName.trim() : 'Business');

    ReminderLauncher.showReminderBottomSheet(
      context: context,
      customer: _customer,
      repository: _repository,
      businessName: effectiveBusinessName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDue = _customer.currentBalance > 0;
    final isSettled = _customer.currentBalance == 0;
    final balanceColor = isSettled
        ? Colors.grey
        : isDue
            ? const Color(0xFFFF5252)
            : const Color(0xFF00E676);

    final statusText = isSettled
        ? 'SETTLED'
        : isDue
            ? 'DUE'
            : 'ADVANCE';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        elevation: 0,
        title: Text(
          _customer.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
            tooltip: 'Edit Customer',
            onPressed: _showEditCustomerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF00BCD4)),
            tooltip: 'Export Statement',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating Customer Ledger Statement PDF...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await PdfInvoiceService.downloadAndOpenCustomerStatement(
                _customer,
                _ledgerEntries,
                context: context,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Responsive max width
                child: Column(
                  children: [
                    // Top Customer Profile Details Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121622),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1F2638)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _customer.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '📱 ${_customer.phone}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    if (_customer.gstin.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '🏛️ GSTIN: ${_customer.gstin}',
                                        style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                                      ),
                                    ],
                                    if (_customer.creditLimit > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '⚡ Credit Limit: ₹${_currencyFormat.format(_customer.creditLimit)}',
                                        style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Outstanding Balance & Status Pill
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: balanceColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: balanceColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_currencyFormat.format(_customer.currentBalance.abs())}',
                                    style: TextStyle(
                                      color: balanceColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFF1F2638), height: 1),
                          const SizedBox(height: 12),

                          // Total Sales vs Total Payments Summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem('Total Sales', '₹${_currencyFormat.format(_customer.totalSales)}', const Color(0xFF00E676)),
                              Container(width: 1, height: 30, color: const Color(0xFF1F2638)),
                              _buildMetricItem('Total Payments', '₹${_currencyFormat.format(_customer.totalPayments)}', const Color(0xFFFF5252)),
                              Container(width: 1, height: 30, color: const Color(0xFF1F2638)),
                              _buildMetricItem('Balance Due', '₹${_currencyFormat.format(_customer.currentBalance.abs())}', balanceColor),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab Bar (Khata Ledger vs Transactions/Invoices)
                    Container(
                      color: const Color(0xFF0B0E14),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF00E676),
                        labelColor: const Color(0xFF00E676),
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(icon: Icon(Icons.menu_book_rounded), text: 'Khata / Ledger'),
                          Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Transactions / Invoices'),
                        ],
                      ),
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLedgerTab(),
                          _buildInvoicesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLedgerTab() {
    if (_ledgerEntries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 10),
            Text('No Ledger Entries Yet', style: TextStyle(color: Colors.white, fontSize: 15)),
            SizedBox(height: 4),
            Text('Record an entry using Give / Got buttons below.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _ledgerEntries.length,
      itemBuilder: (context, idx) {
        final entry = _ledgerEntries[idx];
        final isGave = entry.isGave;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141824),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F2638)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGave
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : const Color(0xFFFF5252).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGave ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isGave ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description.isNotEmpty ? entry.description : (isGave ? 'Credit Sale / Udhaar' : 'Payment Received / Jama'),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.entryDate} • Mode: ${entry.paymentMode}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isGave ? '+' : '-'} ₹${_currencyFormat.format(entry.amount)}',
                    style: TextStyle(
                      color: isGave ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bal: ₹${_currencyFormat.format(entry.balanceAfter)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInvoiceCard('INV-2026-0042', '16 Aug 2026', 30000.00, 'UNPAID', const Color(0xFFFF5252)),
        _buildInvoiceCard('INV-2026-0038', '02 Aug 2026', 15000.00, 'PARTIAL', Colors.orange),
        _buildInvoiceCard('INV-2026-0021', '12 Jul 2026', 25000.00, 'PAID', const Color(0xFF00E676)),
      ],
    );
  }

  Widget _buildInvoiceCard(String invNo, String date, double amount, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2638)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invNo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 3),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${_currencyFormat.format(amount)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF121622),
        border: Border(top: BorderSide(color: Color(0xFF1F2638))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Remind Button
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00E676)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00E676), size: 18),
                label: const Text('Remind', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                onPressed: _sendReminder,
              ),
            ),
            const SizedBox(width: 10),
            // Give / Sale - GREEN
            Expanded(
              flex: 1,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddEntryDialog('GAVE'),
                child: const Text('Give / Sale', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            // Got / Payment - RED
            Expanded(
              flex: 1,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddEntryDialog('GOT'),
                child: const Text('Got / Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
