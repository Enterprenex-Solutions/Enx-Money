import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../data/invoices_repository.dart';
import '../../models/invoice_model.dart';
import 'create_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final InvoicesRepository _repository = InvoicesRepository();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final TextEditingController _searchController = TextEditingController();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _repository.getInvoices();
      if (mounted) {
        setState(() {
          _invoices = list;
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

  List<InvoiceModel> get _filteredInvoices {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _invoices;
    return _invoices.where((inv) {
      return inv.invoiceNumber.toLowerCase().contains(query) ||
          inv.customerName.toLowerCase().contains(query) ||
          inv.customerGstin.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalInvoiced = _invoices.fold<double>(0.0, (sum, inv) => sum + inv.grandTotal);
    final totalDue = _invoices.fold<double>(0.0, (sum, inv) => sum + inv.balanceDue);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('GST Invoices & Billing', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('Create Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
          if (created == true) {
            _fetchInvoices();
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchInvoices,
          color: AppColors.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Summary Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL INVOICED', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_currencyFormat.format(totalInvoiced)}',
                          style: const TextStyle(color: Color(0xFF00E676), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 35, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('UNPAID DUES', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_currencyFormat.format(totalDue)}',
                          style: const TextStyle(color: Color(0xFFFF5252), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                decoration: InputDecoration(
                  hintText: 'Search invoice #, customer name, GSTIN...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Invoice List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _fetchInvoices,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredInvoices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 40),
                        const SizedBox(height: 12),
                        Text('No Invoices Created Yet', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Tap + Create Invoice to generate tax invoices with automatic stock deduction.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredInvoices.map((inv) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.invoiceNumber,
                              style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              inv.invoiceDate,
                              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.customerName,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${_currencyFormat.format(inv.grandTotal)}',
                              style: const TextStyle(color: Color(0xFF00E676), fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (inv.customerGstin.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('GSTIN: ${inv.customerGstin}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${inv.items.length} item(s) • Taxable: ₹${_currencyFormat.format(inv.taxableTotal)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00BCD4), size: 20),
                              tooltip: 'Download PDF Invoice',
                              onPressed: () => PdfInvoiceService.downloadAndOpenInvoicePdf(inv, context: context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
