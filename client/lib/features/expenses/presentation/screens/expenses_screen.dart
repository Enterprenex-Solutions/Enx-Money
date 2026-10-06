import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/expenses_repository.dart';
import '../../models/expense_model.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ExpensesScreen({super.key, this.onOpenDrawer});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpensesRepository _repository = ExpensesRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ExpenseItem> _expenses = [];
  ExpenseSummary _summary = const ExpenseSummary();
  List<String> _categories = ['All'];

  String _selectedCategory = 'All';
  String _selectedSort = 'NEWEST';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryFuture = _repository.getExpenseSummary(mode: 'BUSINESS');
      final expensesFuture = _repository.getExpenses(
        mode: 'BUSINESS',
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );
      final categoriesFuture = _repository.getCategories();

      final results = await Future.wait([summaryFuture, expensesFuture, categoriesFuture]);

      final summary = results[0] as ExpenseSummary;
      final expenses = results[1] as List<ExpenseItem>;
      final rawCats = results[2] as List<String>;

      if (mounted) {
        setState(() {
          _summary = summary;
          _expenses = expenses;
          _categories = ['All', ...rawCats];
          _sortExpenses();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _sortExpenses() {
    if (_selectedSort == 'NEWEST') {
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedSort == 'OLDEST') {
      _expenses.sort((a, b) => a.date.compareTo(b.date));
    } else if (_selectedSort == 'AMOUNT_HIGH') {
      _expenses.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_selectedSort == 'AMOUNT_LOW') {
      _expenses.sort((a, b) => a.amount.compareTo(b.amount));
    }
  }

  void _onCategorySelected(String cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _loadData();
  }

  void _onSearchChanged(String query) {
    _loadData();
  }

  Future<void> _navigateToAddExpense([ExpenseItem? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(initialExpense: item),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _showExpenseDetails(ExpenseItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.brandText;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.brandTextSecondary;
    final borderColor = isDark ? AppColors.border : AppColors.brandBorder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
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

              // Title and Amount Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.categoryIcon, color: item.categoryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),

              // Details Grid
              _buildDetailRow('Date', item.date.split('T')[0], textSecondary, textPrimary),
              _buildDetailRow('Status', item.status, textSecondary, item.isPaid ? AppColors.success : AppColors.warning),
              if (item.accountName != null && item.accountName!.isNotEmpty)
                _buildDetailRow('Account Debited', item.accountName!, textSecondary, textPrimary),
              _buildDetailRow('Payment Mode', item.paymentMode.replaceAll('_', ' '), textSecondary, textPrimary),

              if (item.supplierName != null && item.supplierName!.isNotEmpty)
                _buildDetailRow('Vendor / Supplier', item.supplierName!, textSecondary, AppColors.brandBlue),
              if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty)
                _buildDetailRow('Bill / Invoice #', item.invoiceNumber!, textSecondary, textPrimary),

              if (item.gstRate != null && item.gstRate! > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.brandBlue.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      if (item.gstin != null && item.gstin!.isNotEmpty)
                        _buildDetailRow('Vendor GSTIN', item.gstin!, textSecondary, textPrimary),
                      _buildDetailRow('GST Rate', '${item.gstRate!.toInt()}%', textSecondary, textPrimary),
                      if (item.taxableAmount != null)
                        _buildDetailRow('Taxable Value', CurrencyFormatter.format(item.taxableAmount!), textSecondary, textPrimary),
                      if (item.totalGst != null)
                        _buildDetailRow('Total GST', CurrencyFormatter.format(item.totalGst!), textSecondary, const Color(0xFF6C63FF)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons: Edit & Delete
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateToAddExpense(item);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('Edit Expense', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.15),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDeleteExpense(item);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteExpense(ExpenseItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('Delete Expense?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Deleting this expense of ${CurrencyFormatter.format(item.amount)} will refund the debited amount back to your business account.\n\nAre you sure?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete & Refund', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await _repository.deleteExpense(item.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Expense deleted and balance refunded successfully!'),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.error, content: Text('Error deleting expense: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.brandBackground;
    final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.brandText;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.brandTextSecondary;
    final borderColor = isDark ? AppColors.border : AppColors.brandBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onOpenDrawer,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Text(
              'Operating expenses, vendor bills & outflows',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.brandBlue),
            onPressed: () => _navigateToAddExpense(),
            tooltip: 'Add Expense',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _navigateToAddExpense(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.brandBlue,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 4 Summary Metrics Cards
            _buildSummaryCards(cardBg, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 16),

            // Search & Sort Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search title, vendor, invoice...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 12),
                        prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadData();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: _onSearchChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      icon: Icon(Icons.sort_rounded, color: textSecondary, size: 18),
                      dropdownColor: cardBg,
                      style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'NEWEST', child: Text('Newest')),
                        DropdownMenuItem(value: 'OLDEST', child: Text('Oldest')),
                        DropdownMenuItem(value: 'AMOUNT_HIGH', child: Text('Highest ₹')),
                        DropdownMenuItem(value: 'AMOUNT_LOW', child: Text('Lowest ₹')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSort = val;
                            _sortExpenses();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.brandBlue,
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.brandBlue : borderColor),
                    onSelected: (_) => _onCategorySelected(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Expense Items List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                      const SizedBox(height: 10),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_expenses.isEmpty)
              _buildEmptyState(textPrimary, textSecondary)
            else
              ..._expenses.map((item) => _buildExpenseCard(item, cardBg, borderColor, textPrimary, textSecondary)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricTile(
                    'TOTAL EXPENSES',
                    CurrencyFormatter.format(_summary.totalExpenses),
                    '${_summary.expenseCount} vouchers recorded',
                    Icons.account_balance_wallet_rounded,
                    AppColors.brandBlue,
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricTile(
                    'THIS MONTH',
                    CurrencyFormatter.format(_summary.thisMonthExpenses),
                    'Current cycle burn',
                    Icons.calendar_today_rounded,
                    const Color(0xFF6C63FF),
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricTile(
                    'TODAY',
                    CurrencyFormatter.format(_summary.todayExpenses),
                    'Daily operational cash',
                    Icons.today_rounded,
                    const Color(0xFF10B981),
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricTile(
                    'PENDING / UNPAID',
                    CurrencyFormatter.format(_summary.pendingExpenses),
                    'Accrued liabilities',
                    Icons.hourglass_bottom_rounded,
                    const Color(0xFFF59E0B),
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color accentColor,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(
    ExpenseItem item,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showExpenseDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.categoryIcon, color: item.categoryColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Title & Subtitles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            item.date.split('T')[0],
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                          if (item.supplierName != null && item.supplierName!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: textSecondary, fontSize: 10)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.supplierName!,
                                style: const TextStyle(fontSize: 11, color: AppColors.brandBlue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Account badge
                          if (item.accountName != null && item.accountName!.isNotEmpty)
                            _buildMiniBadge(item.accountName!, textSecondary.withOpacity(0.2), textSecondary),
                          // GST badge
                          if (item.gstRate != null && item.gstRate! > 0)
                            _buildMiniBadge('GST ${item.gstRate!.toInt()}%', const Color(0xFF6C63FF).withOpacity(0.15), const Color(0xFF6C63FF)),
                          // Status badge
                          _buildMiniBadge(
                            item.status,
                            item.isPaid ? AppColors.success.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                            item.isPaid ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${CurrencyFormatter.format(item.amount)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.brandBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'No Business Expenses Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Record operational costs, vendor invoices & bills\nto balance your company accounts and P&L.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _navigateToAddExpense(),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add First Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
