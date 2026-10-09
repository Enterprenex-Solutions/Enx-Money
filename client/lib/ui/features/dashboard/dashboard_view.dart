import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/excel_exporter.dart';
import '../../../core/utils/pdf_exporter.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/kpi_summary.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../core/date_filter_bar.dart';
import '../../core/empty_state_widget.dart';
import '../../core/kpi_card.dart';
import '../analytics/charts/bar_sales_chart.dart';
import '../analytics/charts/line_trend_chart.dart';
import '../analytics/charts/pie_category_chart.dart';
import '../transactions/add_transaction_dialog.dart';
import '../whatsapp/whatsapp_chatbot_view.dart';


class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedChartTab = 0;
  int _selectedKpiCategory = 0; // 0: Business, 1: Customer, 2: Sales, 3: Expenses, 4: Payments

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final kpi = repo.kpiSummary;
    final transactions = repo.filteredTransactions;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isBusiness = repo.currentProfile == ProfileType.business;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open Menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            // ENX Logo in AppBar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 6)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/enx_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enx money',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Expenses tracker app',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500, letterSpacing: 0.3),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF00A884)),
            tooltip: 'WhatsApp AI Financial Assistant',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WhatsAppChatbotView(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(repo.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle Theme',
            onPressed: () => repo.toggleTheme(),
          ),

          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () => PdfExporter.sharePdfReport(
              profile: repo.currentProfile,
              dateFilter: repo.dateFilter,
              kpi: kpi,
              transactions: transactions,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Export Excel',
            onPressed: () => ExcelExporter.exportToExcel(
              profile: repo.currentProfile,
              dateFilter: repo.dateFilter,
              kpi: kpi,
              transactions: transactions,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'clear') repo.clearAllData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Gradient Profile Switcher Header ─────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1B3E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: ProfileType.values.map((profile) {
                      final isSelected = repo.currentProfile == profile;
                      return Expanded(
                        child: InkWell(
                          onTap: () => repo.switchProfile(profile),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF0D1B3E), Color(0xFF1565C0)],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  profile == ProfileType.business ? Icons.business_center : Icons.person_outline,
                                  size: 16,
                                  color: isSelected ? Colors.white : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  profile.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Date Filter Bar ───────────────────────────────────────
                const DateFilterBar(),

                // ── Drill-down status badge ──────────────────────────────
                if (repo.drillDownType != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                'Filter: ${repo.drillDownType!.label}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => repo.setDrillDownType(null),
                                child: const Icon(Icons.close, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Business Entity Summary Bar ──────────────────────────
                if (isBusiness)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D1B3E), Color(0xFF1565C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEntityCount('Enterprises', repo.enterprises.length, Icons.domain),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildEntityCount('Customers', repo.customers.length, Icons.people),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildEntityCount('Suppliers', repo.suppliers.length, Icons.local_shipping),
                      ],
                    ),
                  ),

                // ── Section 10: Multi-Area KPI Category Selector ────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.analytics_rounded, size: 16, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Key Performance Indicators',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildKpiAreaChip(0, 'Business KPIs', Icons.business_center_rounded),
                            _buildKpiAreaChip(1, 'Customer KPIs', Icons.people_alt_rounded),
                            _buildKpiAreaChip(2, 'Sales KPIs', Icons.trending_up_rounded),
                            _buildKpiAreaChip(3, 'Expense KPIs', Icons.trending_down_rounded),
                            _buildKpiAreaChip(4, 'Payment & Collection', Icons.payments_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Dynamic Section 10 KPI Grid ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.32,
                    children: _buildAreaKpiCards(kpi, repo),
                  ),
                ),

                // ── Charts Card ───────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1B3E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Analytics & Trends',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 0, icon: Icon(Icons.pie_chart_outline, size: 14), label: Text('Category')),
                                ButtonSegment(value: 1, icon: Icon(Icons.show_chart, size: 14), label: Text('Trend')),
                                ButtonSegment(value: 2, icon: Icon(Icons.bar_chart, size: 14), label: Text('Sales')),
                              ],
                              selected: {_selectedChartTab},
                              onSelectionChanged: (set) => setState(() => _selectedChartTab = set.first),
                              style: ButtonStyle(
                                textStyle: WidgetStatePropertyAll(
                                  TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (transactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No data for selected period.\nAdd transactions to see charts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ),
                          )
                        else if (_selectedChartTab == 0)
                          PieCategoryChart(
                            categoryData: repo.categoryBreakdown,
                            onCategoryTap: (cat) => repo.setCategoryFilter(cat),
                          )
                        else if (_selectedChartTab == 1)
                          LineTrendChart(dailyTrend: repo.dailyTrend)
                        else
                          BarSalesChart(dailyTrend: repo.dailyTrend),
                      ],
                    ),
                  ),
                ),

                // ── Recent Transactions ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions (${transactions.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      TextButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const AddTransactionDialog(),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Add Entry'),
                      ),
                    ],
                  ),
                ),

                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: EmptyStateWidget(
                      title: 'No Transactions Yet',
                      message:
                          'Start by adding your first income or expense entry in ${repo.currentProfile.label}.',
                      onAddData: () => showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      final isPositive = item.type == TransactionType.revenue ||
                          item.type == TransactionType.receivable;
                      final color = isPositive ? const Color(0xFF00C853) : const Color(0xFFD50000);

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D1B3E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${item.category}  •  ${DateFormat('dd MMM yyyy').format(item.date)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? "+" : "-"}${currencyFormatter.format(item.amount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                              Text(
                                item.type.label,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AddTransactionDialog(initialItem: item),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddTransactionDialog(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  Widget _buildEntityCount(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiAreaChip(int index, String label, IconData icon) {
    final isSelected = _selectedKpiCategory == index;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: isSelected ? Colors.transparent : theme.dividerColor.withValues(alpha: 0.6),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _selectedKpiCategory = index),
      ),
    );
  }

  List<Widget> _buildAreaKpiCards(KpiSummary kpi, TransactionRepository repo) {
    switch (_selectedKpiCategory) {
      case 1: // Customer KPIs
        return [
          KpiCard(
            title: 'Total Customers',
            amount: 0,
            customDisplayValue: '${kpi.customer.totalCustomers}',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF2979FF),
            subtitle: 'Profiles in Database',
          ),
          KpiCard(
            title: 'Active Customers',
            amount: 0,
            customDisplayValue: '${kpi.customer.activeCustomers}',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF00C853),
            subtitle: 'Active Accounts',
          ),
          KpiCard(
            title: 'New Customers',
            amount: 0,
            customDisplayValue: '${kpi.customer.newCustomers}',
            icon: Icons.person_add_alt_1_rounded,
            color: const Color(0xFFFF6D00),
            subtitle: 'Joined in Filter Range',
          ),
          KpiCard(
            title: 'Retention Rate',
            amount: 0,
            customDisplayValue: '${kpi.customer.retentionRate}%',
            icon: Icons.loop_rounded,
            color: const Color(0xFF6200EA),
            subtitle: 'Active ÷ Total',
          ),
          KpiCard(
            title: 'Customer Growth',
            amount: 0,
            customDisplayValue: '${kpi.customer.growthRate}%',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF00B0FF),
            subtitle: 'Acquisition Ratio',
          ),
        ];

      case 2: // Sales KPIs
        return [
          KpiCard(
            title: 'Total Sales',
            amount: kpi.sales.totalSales,
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF00C853),
            subtitle: 'Gross Volume',
            isSelected: repo.drillDownType == TransactionType.revenue,
            onTap: () => repo.setDrillDownType(
              repo.drillDownType == TransactionType.revenue ? null : TransactionType.revenue,
            ),
          ),
          KpiCard(
            title: 'Monthly Sales',
            amount: kpi.sales.monthlySales,
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFF2979FF),
            subtitle: 'Filtered Window',
          ),
          KpiCard(
            title: 'Average Order Value',
            amount: kpi.sales.averageOrderValue,
            icon: Icons.calculate_outlined,
            color: const Color(0xFFFF9100),
            subtitle: 'AOV per Transaction',
          ),
          KpiCard(
            title: 'Sales Growth',
            amount: 0,
            customDisplayValue: '+${kpi.sales.salesGrowth}%',
            icon: Icons.query_stats_rounded,
            color: const Color(0xFF6200EA),
            subtitle: 'MoM Trend',
          ),
          KpiCard(
            title: 'Top Segment',
            amount: 0,
            customDisplayValue: kpi.sales.topProduct,
            icon: Icons.star_outline_rounded,
            color: const Color(0xFF00B0FF),
            subtitle: 'Leading Product Category',
          ),
          KpiCard(
            title: 'Orders Count',
            amount: 0,
            customDisplayValue: '${kpi.sales.totalOrders}',
            icon: Icons.receipt_outlined,
            color: const Color(0xFF10B981),
            subtitle: 'Total Invoices',
          ),
        ];

      case 3: // Expense KPIs
        return [
          KpiCard(
            title: 'Total Expenses',
            amount: kpi.expensesKpi.totalExpenses,
            icon: Icons.trending_down_rounded,
            color: const Color(0xFFD50000),
            subtitle: 'Gross Outflow',
            isSelected: repo.drillDownType == TransactionType.expense,
            onTap: () => repo.setDrillDownType(
              repo.drillDownType == TransactionType.expense ? null : TransactionType.expense,
            ),
          ),
          KpiCard(
            title: 'Monthly Expense',
            amount: kpi.expensesKpi.monthlyExpense,
            icon: Icons.event_note_outlined,
            color: const Color(0xFFFF5252),
            subtitle: 'Current Burn',
          ),
          KpiCard(
            title: 'Expense Growth',
            amount: 0,
            customDisplayValue: '+${kpi.expensesKpi.expenseGrowth}%',
            icon: Icons.speed_rounded,
            color: const Color(0xFFFF9100),
            subtitle: 'Budget Variance',
          ),
          KpiCard(
            title: 'Top Expense Category',
            amount: 0,
            customDisplayValue: kpi.expensesKpi.topCategory,
            icon: Icons.category_outlined,
            color: const Color(0xFF7C4DFF),
            subtitle: 'Largest Cost Center',
          ),
        ];

      case 4: // Payments KPIs
        return [
          KpiCard(
            title: 'Amount Received',
            amount: kpi.payments.amountReceived,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF00C853),
            subtitle: 'Settled Funds Inflow',
          ),
          KpiCard(
            title: 'Amount Pending',
            amount: kpi.payments.amountPending,
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFFF9100),
            subtitle: 'Outstanding Receivables',
            isSelected: repo.drillDownType == TransactionType.receivable,
            onTap: () => repo.setDrillDownType(
              repo.drillDownType == TransactionType.receivable ? null : TransactionType.receivable,
            ),
          ),
          KpiCard(
            title: 'Collection Rate',
            amount: 0,
            customDisplayValue: '${kpi.payments.collectionRate}%',
            icon: Icons.percent_rounded,
            color: const Color(0xFF2979FF),
            subtitle: 'Received ÷ Due × 100',
          ),
          KpiCard(
            title: 'GST Payable',
            amount: kpi.gstPayable,
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF6200EA),
            subtitle: 'Est. Tax Liability',
          ),
          KpiCard(
            title: 'EMI Due',
            amount: kpi.emiDueThisMonth,
            icon: Icons.credit_card_rounded,
            color: const Color(0xFFB71C1C),
            subtitle: 'This Month Obligation',
            isSelected: repo.drillDownType == TransactionType.emi,
            onTap: () => repo.setDrillDownType(
              repo.drillDownType == TransactionType.emi ? null : TransactionType.emi,
            ),
          ),
        ];

      case 0: // Business KPIs (Default)
      default:
        return [
          KpiCard(
            title: 'Total Revenue',
            amount: kpi.totalRevenue,
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF00C853),
            subtitle: 'Gross Inflow',
            isSelected: repo.drillDownType == TransactionType.revenue,
            onTap: () => repo.setDrillDownType(
              repo.drillDownType == TransactionType.revenue ? null : TransactionType.revenue,
            ),
          ),
          KpiCard(
            title: 'Total Expense',
            amount: kpi.totalExpense,
            icon: Icons.trending_down_rounded,
            color: const Color(0xFFD50000),
            subtitle: 'Total Outflow',
            isSelected: repo.drillDownType == TransactionType.expense,
            onTap: () => repo.setDrillDownType(
              repo.drillDownType == TransactionType.expense ? null : TransactionType.expense,
            ),
          ),
          KpiCard(
            title: 'Net Profit',
            amount: kpi.netProfit,
            icon: Icons.account_balance_rounded,
            color: kpi.netProfit >= 0 ? const Color(0xFF1565C0) : const Color(0xFFD50000),
            subtitle: kpi.netProfit >= 0 ? 'Surplus' : 'Deficit',
          ),
          KpiCard(
            title: 'Profit Margin',
            amount: 0,
            customDisplayValue: '${kpi.business.profitMargin}%',
            icon: Icons.pie_chart_outline_rounded,
            color: const Color(0xFF00B0FF),
            subtitle: 'Profit ÷ Revenue',
          ),
          KpiCard(
            title: 'Cash Inflow',
            amount: kpi.business.cashInflow,
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF10B981),
            subtitle: 'Collected Receipts',
          ),
          KpiCard(
            title: 'Cash Outflow',
            amount: kpi.business.cashOutflow,
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFFF5252),
            subtitle: 'Expenses + EMIs',
          ),
          KpiCard(
            title: 'Net Outstanding',
            amount: kpi.business.outstanding,
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFFFF9100),
            subtitle: 'Receivables - Payables',
          ),
          KpiCard(
            title: 'GST Payable',
            amount: kpi.gstPayable,
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF6200EA),
            subtitle: 'Est. Tax Due',
          ),
        ];
    }
  }
}

