import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/customers_repository.dart';
import '../../models/customer_model.dart';
import '../screens/add_customer_screen.dart';

/// Interactive bottom sheet for searching and selecting a customer
/// dynamically by name, phone, or email.
class CustomerSearchModal extends StatefulWidget {
  final CustomerModel? initialCustomer;
  final Function(CustomerModel) onCustomerSelected;

  const CustomerSearchModal({
    super.key,
    this.initialCustomer,
    required this.onCustomerSelected,
  });

  static Future<CustomerModel?> show(
    BuildContext context, {
    CustomerModel? initialCustomer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CustomerSearchModal(
        initialCustomer: initialCustomer,
        onCustomerSelected: (c) => Navigator.pop(context, c),
      ),
    );
  }

  @override
  State<CustomerSearchModal> createState() => _CustomerSearchModalState();
}

class _CustomerSearchModalState extends State<CustomerSearchModal> {
  final CustomersRepository _repo = CustomersRepository();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({String? query}) async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getCustomers(search: query);
      if (mounted) {
        setState(() {
          _customers = res.customers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    setState(() => _searchQuery = trimmed);

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _fetchCustomers(query: trimmed.length >= 2 ? trimmed : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SizedBox(
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Customer',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search input field
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E676), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  hintText: 'Search by name, mobile, or email...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Results count or quick add
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoading
                      ? 'Searching customers...'
                      : '${_customers.length} customer${_customers.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final created = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                    );
                    if (created == true) {
                      _fetchCustomers();
                    }
                  },
                  child: const Text(
                    '+ Add New Customer',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customers list / loading / empty
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E676)),
                    )
                  : _customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No customer found for "$_searchQuery"'
                                    : 'No customers added yet',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00E676),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  final created = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                                  );
                                  if (created == true) {
                                    _fetchCustomers();
                                  }
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Add Customer Now',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _customers.length,
                          separatorBuilder: (context, index) => Divider(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            height: 1,
                          ),
                          itemBuilder: (context, idx) {
                            final c = _customers[idx];
                            final isSelected = widget.initialCustomer?.id == c.id;
                            final isDue = c.currentBalance > 0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                  style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF00E676) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${c.phone}${c.email.isNotEmpty ? " • ${c.email}" : ""}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${c.currentBalance.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isDue ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    isDue ? 'You will get' : 'Settled',
                                    style: TextStyle(
                                      color: isDue ? const Color(0xFFFF5252).withValues(alpha: 0.7) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => widget.onCustomerSelected(c),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
