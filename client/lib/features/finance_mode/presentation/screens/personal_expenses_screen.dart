import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/models/transaction_model.dart';

class PersonalExpensesScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const PersonalExpensesScreen({super.key, this.onOpenDrawer});

  @override
  State<PersonalExpensesScreen> createState() => _PersonalExpensesScreenState();
}

class _PersonalExpensesScreenState extends State<PersonalExpensesScreen> {
  final TransactionsRepository _repo = TransactionsRepository();
  List<TransactionItem> _expenses = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final list = await _repo.getTransactions(mode: 'PERSONAL');
    if (mounted) {
      setState(() {
        _expenses = list.where((t) => t.type == TransactionType.debit).toList();
        _isLoading = false;
      });
    }
  }

  void _showAddExpenseModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Groceries';

    final isDark = ThemeController().isDarkTheme(context);
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Log Personal Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText)),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FintechTextField(
                    controller: titleCtrl,
                    label: 'Expense Description',
                    hintText: 'e.g. Grocery store, Petrol, Dinner',
                  ),
                  const SizedBox(height: 14),
                  FintechTextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    label: 'Amount (₹)',
                    hintText: '1500',
                  ),
                  const SizedBox(height: 14),
                  Text('Category', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        value: category,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        items: ['Groceries', 'Fuel & Travel', 'Subscriptions', 'Dining Out', 'Healthcare', 'Shopping', 'Utilities', 'Miscellaneous']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: primaryText, fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setModalState(() => category = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Record Expense',
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (title.isEmpty || amt <= 0) {
                        NotificationService.showError('Please enter a description and valid amount');
                        return;
                      }

                      final created = await _repo.createTransaction({
                        'accountType': 'PERSONAL',
                        'type': 'DEBIT',
                        'category': category,
                        'note': title,
                        'amount': amt,
                        'paymentMode': 'UPI',
                      });

                      if (created != null) {
                        Navigator.pop(ctx);
                        NotificationService.showSuccess('Expense of ₹$amt recorded!');
                        _loadExpenses();
                      } else {
                        NotificationService.showError('Failed to record expense.');
                      }
                    },
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
    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final isDark = ThemeController().isDarkTheme(context);
        final Color scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final Color cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
        final Color cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        final Color primaryText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
        final Color secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

        final filtered = _selectedCategory == 'All'
            ? _expenses
            : _expenses.where((e) {
                final catName = e.category.name.toLowerCase();
                final sel = _selectedCategory.toLowerCase();
                return catName.contains(sel) || sel.contains(catName);
              }).toList();

        final categories = ['All', 'Groceries', 'Food', 'Travel', 'Shopping', 'Entertainment', 'Utilities'];

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text('Personal Expenses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: primaryText)),
            backgroundColor: scaffoldBg,
            elevation: 0,
            iconTheme: IconThemeData(color: primaryText),
            leading: widget.onOpenDrawer != null
                ? IconButton(
                    icon: Icon(Icons.menu_rounded, color: primaryText),
                    onPressed: widget.onOpenDrawer,
                  )
                : (Navigator.canPop(context)
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: primaryText),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            onPressed: () => _showAddExpenseModal(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: Column(
            children: [
              // Category Pills
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final c = categories[idx];
                    final isSelected = c == _selectedCategory;
                    return Center(
                      child: ChoiceChip(
                        label: Text(c),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0066FF),
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : secondaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: isSelected ? const Color(0xFF0066FF) : cardBorder),
                        onSelected: (_) => setState(() => _selectedCategory = c),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Expenses List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: secondaryText),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No personal expenses found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryText),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Record daily groceries, travel, dining, or bills to track outflows.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: secondaryText),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddExpenseModal(context),
                                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                    label: const Text('+ Record Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0066FF),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadExpenses,
                            color: const Color(0xFF0066FF),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final item = filtered[idx];

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFEF4444), size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: primaryText),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.category.name.toUpperCase()} • ${item.dateTime.day}/${item.dateTime.month}/${item.dateTime.year}',
                                              style: TextStyle(fontSize: 11, color: secondaryText),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '- ${CurrencyFormatter.format(item.amount, showDecimals: false)}',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFEF4444)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.paymentMethod ?? 'UPI',
                                            style: TextStyle(fontSize: 10, color: secondaryText),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
