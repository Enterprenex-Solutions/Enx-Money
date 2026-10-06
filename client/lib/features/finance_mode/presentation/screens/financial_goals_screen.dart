import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/goal_model.dart';

class FinancialGoalsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const FinancialGoalsScreen({super.key, this.onOpenDrawer});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  final FinanceModeRepository _repo = FinanceModeRepository();
  List<GoalModel> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final data = await _repo.getGoals();
    if (mounted) {
      setState(() {
        _goals = data;
        _isLoading = false;
      });
    }
  }

  void _showAddGoalModal(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController();
    final targetDateController = TextEditingController(text: 'Dec 2027');
    String selectedCategory = 'Safety';

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
                      Text(
                        'Create Financial Goal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FintechTextField(
                    controller: titleController,
                    label: 'Goal Title',
                    hintText: 'e.g. Wedding Savings, House Down Payment',
                  ),
                  const SizedBox(height: 14),
                  FintechTextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    label: 'Target Amount (₹)',
                    hintText: '500000',
                  ),
                  const SizedBox(height: 14),
                  FintechTextField(
                    controller: currentController,
                    keyboardType: TextInputType.number,
                    label: 'Currently Saved (₹)',
                    hintText: '100000',
                  ),
                  const SizedBox(height: 14),
                  FintechTextField(
                    controller: targetDateController,
                    label: 'Target Date / Year',
                    hintText: 'e.g. Dec 2027',
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Save Financial Goal',
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final target = double.tryParse(targetController.text.trim()) ?? 0.0;
                      final current = double.tryParse(currentController.text.trim()) ?? 0.0;
                      final targetDate = targetDateController.text.trim();

                      if (title.isEmpty || target <= 0) {
                        NotificationService.showError('Please enter a goal title and target amount');
                        return;
                      }

                      final goal = await _repo.createGoal({
                        'title': title,
                        'targetAmount': target,
                        'currentAmount': current,
                        'targetDate': targetDate,
                        'category': selectedCategory,
                        'monthlyContribution': target > current ? (target - current) / 12 : 0.0,
                      });

                      if (goal != null) {
                        Navigator.pop(ctx);
                        NotificationService.showSuccess('Goal "$title" created successfully!');
                        _loadGoals();
                      } else {
                        NotificationService.showError('Failed to save goal to server.');
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

        double totalTarget = _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
        double totalCurrent = _goals.fold(0.0, (sum, g) => sum + g.currentAmount);
        double overallPct = totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text(
              'Financial Goals & Corpus',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: primaryText),
            ),
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
            onPressed: () => _showAddGoalModal(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  color: const Color(0xFF0066FF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Goals Progress Card
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
                                    'COMBINED GOALS SAVINGS',
                                    style: TextStyle(
                                      color: Color(0xFFE0E7FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    '${(overallPct * 100).toInt()}% Achieved',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CurrencyFormatter.format(totalCurrent, showDecimals: false),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'of ${CurrencyFormatter.format(totalTarget, showDecimals: false)} aggregate goal target',
                                style: const TextStyle(color: Color(0xFFE0E7FF), fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: overallPct,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Active Milestones (${_goals.length})',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryText),
                        ),
                        const SizedBox(height: 12),

                        if (_goals.isEmpty)
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
                                Icon(Icons.flag_outlined, size: 40, color: secondaryText),
                                const SizedBox(height: 12),
                                Text(
                                  'No financial goals set yet',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: primaryText),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create a target milestone like Emergency Fund, Education, or House Down Payment.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: secondaryText),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddGoalModal(context),
                                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                  label: const Text('+ Create Financial Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          ..._goals.map((goal) {
                            final progress = goal.progress;
                            const color = Color(0xFF0066FF);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
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
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.flag_outlined, color: color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              goal.title,
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: primaryText),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Target: ${goal.targetDate.isNotEmpty ? goal.targetDate : "Ongoing"} • ${goal.category}',
                                              style: TextStyle(fontSize: 11, color: secondaryText),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Saved: ${CurrencyFormatter.formatCompact(goal.currentAmount)}',
                                        style: TextStyle(fontSize: 12, color: secondaryText, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Target: ${CurrencyFormatter.formatCompact(goal.targetAmount)}',
                                        style: TextStyle(fontSize: 12, color: primaryText, fontWeight: FontWeight.w700),
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
      },
    );
  }
}
