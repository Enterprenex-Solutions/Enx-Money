import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/budget_model.dart';

class PersonalBudgetScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const PersonalBudgetScreen({super.key, this.onOpenDrawer});

  @override
  State<PersonalBudgetScreen> createState() => _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends State<PersonalBudgetScreen> {
  final FinanceModeRepository _repo = FinanceModeRepository();
  List<BudgetCategoryModel> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final data = await _repo.getBudgets();
    if (mounted) {
      setState(() {
        _budgets = data;
        _isLoading = false;
      });
    }
  }

  void _showAddBudgetModal(BuildContext context) {
    final catController = TextEditingController();
    final limitController = TextEditingController();
    final spentController = TextEditingController();

    final isDark = ThemeController().isDarkTheme(context);
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
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
                  Text('Set Category Budget Limit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText)),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FintechTextField(
                controller: catController,
                label: 'Category Name',
                hintText: 'e.g. Groceries, Entertainment, Fuel',
              ),
              const SizedBox(height: 14),
              FintechTextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                label: 'Monthly Budget Limit (₹)',
                hintText: '15000',
              ),
              const SizedBox(height: 14),
              FintechTextField(
                controller: spentController,
                keyboardType: TextInputType.number,
                label: 'Current Month Spend (₹)',
                hintText: '0.00',
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Budget Limit',
                onPressed: () async {
                  final cat = catController.text.trim();
                  final limit = double.tryParse(limitController.text.trim()) ?? 0.0;
                  final spent = double.tryParse(spentController.text.trim()) ?? 0.0;

                  if (cat.isEmpty || limit <= 0) {
                    NotificationService.showError('Please enter a category name and positive budget limit');
                    return;
                  }

                  final success = await _repo.saveBudget({
                    'categoryName': cat,
                    'budgetLimit': limit,
                    'spentAmount': spent,
                  });

                  if (success) {
                    Navigator.pop(ctx);
                    NotificationService.showSuccess('Budget for "$cat" saved!');
                    _loadBudgets();
                  } else {
                    NotificationService.showError('Failed to save budget.');
                  }
                },
              ),
            ],
          ),
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

        final double totalBudget = _budgets.fold(0.0, (sum, c) => sum + c.budgetLimit);
        final double totalSpent = _budgets.fold(0.0, (sum, c) => sum + c.spentAmount);
        final double remaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
        final double overallPercentage = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text('Personal Monthly Budget', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: primaryText)),
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
            onPressed: () => _showAddBudgetModal(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Limit', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
              : RefreshIndicator(
                  onRefresh: _loadBudgets,
                  color: const Color(0xFF0066FF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF0047BA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'MONTHLY BUDGET ALLOCATION',
                                    style: TextStyle(
                                      color: Color(0xFFE0E7FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(overallPercentage * 100).toInt()}% USED',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                CurrencyFormatter.format(remaining, showDecimals: false),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'remaining of ${CurrencyFormatter.format(totalBudget, showDecimals: false)} budgeted across categories',
                                style: const TextStyle(color: Color(0xFFE0E7FF), fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: overallPercentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    overallPercentage > 0.9 ? const Color(0xFFEF4444) : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Category Limits (${_budgets.length})',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryText),
                        ),
                        const SizedBox(height: 12),

                        if (_budgets.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.pie_chart_outline_rounded, size: 40, color: secondaryText),
                                const SizedBox(height: 12),
                                Text(
                                  'No budget categories configured',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: primaryText),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Set budget limits for groceries, travel, dining, or household utilities.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: secondaryText),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddBudgetModal(context),
                                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                  label: const Text('+ Add Category Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._budgets.map((bgt) {
                            final progress = bgt.progress;
                            final isOver = bgt.isOverBudget;
                            final Color meterColor = isOver
                                ? const Color(0xFFEF4444)
                                : (progress > 0.8 ? const Color(0xFFF59E0B) : bgt.color);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
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
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: meterColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(bgt.icon, color: meterColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bgt.categoryName,
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: primaryText),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Spent: ${CurrencyFormatter.format(bgt.spentAmount, showDecimals: false)} of ${CurrencyFormatter.format(bgt.budgetLimit, showDecimals: false)}',
                                              style: TextStyle(fontSize: 12, color: secondaryText),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: meterColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(meterColor),
                                    ),
                                  ),
                                  if (isOver) ...[
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Over budget limit!',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                    ),
                                  ],
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
      },
    );
  }
}
