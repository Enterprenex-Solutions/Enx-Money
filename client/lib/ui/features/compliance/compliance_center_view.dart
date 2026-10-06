import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/compliance_excel_exporter.dart';
import '../../../domain/models/compliance_models.dart';
import '../../../domain/repositories/transaction_repository.dart';

class ComplianceCenterView extends StatefulWidget {
  const ComplianceCenterView({super.key});

  @override
  State<ComplianceCenterView> createState() => _ComplianceCenterViewState();
}

class _ComplianceCenterViewState extends State<ComplianceCenterView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TransactionRepository repo;
    try {
      repo = context.watch<TransactionRepository>();
    } catch (_) {
      repo = TransactionRepository();
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Navigator.canPop(context) ? Icons.arrow_back_rounded : Icons.home_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          tooltip: Navigator.canPop(context) ? 'Back' : 'Home',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compliance Center',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Role: ${repo.currentRole.title}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal),
            ),
          ],
        ),
        actions: [
          // Active Role Switcher
          PopupMenuButton<AppUserRole>(
            tooltip: 'Switch Role (${repo.currentRole.title})',
            icon: const Icon(Icons.shield_outlined, color: Colors.teal),
            onSelected: (role) {
              repo.switchRole(role);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to role: ${role.title} (${role.description})'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (_) => AppUserRole.values.map((r) {
              return PopupMenuItem(
                value: r,
                child: Row(
                  children: [
                    Icon(
                      r == repo.currentRole ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 16,
                      color: r == repo.currentRole ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(r.description, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Export Section 13 Deliverables (.XLSX)
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.teal),
            tooltip: 'Export Deliverables (.XLSX)',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting Section 13 Excel Deliverables...')),
              );
              await ComplianceExcelExporter.exportMasterComplianceWorkbook(repo);
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.teal,
          indicatorColor: Colors.teal,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: '1. Workflow'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: '2. Inventory & Minimization'),
            Tab(icon: Icon(Icons.data_object_rounded, size: 18), text: '3. Event Dictionary'),
            Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: '4. Lineage Register'),
            Tab(icon: Icon(Icons.security_rounded, size: 18), text: '5. RBAC & Consent'),
            Tab(icon: Icon(Icons.auto_delete_outlined, size: 18), text: '6. Retention & Purge'),
            Tab(icon: Icon(Icons.smart_toy_outlined, size: 18), text: '7. Model Governance'),
            Tab(icon: Icon(Icons.assignment_turned_in_outlined, size: 18), text: '8. Sign-Off Checklist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkflowTab(context),
          _buildInventoryAndMinimizationTab(context, repo),
          _buildEventDictionaryTab(context, repo),
          _buildLineageTab(context, repo),
          _buildRbacAndConsentTab(context, repo),
          _buildRetentionTab(context, repo),
          _buildModelGovernanceTab(context, repo),
          _buildSignOffTab(context, repo),
        ],
      ),
    );
  }

  // ΓöÇΓöÇ 1. Workflow Tab (Section 2) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildWorkflowTab(BuildContext context) {
    final steps = [
      {'step': 1, 'title': 'ENX Money App / Operational DB', 'desc': 'Raw transactional operations, accounts, customers & suppliers', 'icon': Icons.storage},
      {'step': 2, 'title': 'Analytics Event Collection', 'desc': 'Capture events (sale_created, expense_added, payment_received)', 'icon': Icons.sensors},
      {'step': 3, 'title': 'Data Inventory & PII Classification', 'desc': 'Tag personal identification fields and sensitive financials', 'icon': Icons.fingerprint},
      {'step': 4, 'title': 'Consent / Legal-Basis Validation', 'desc': 'Validate contractual grounds and user opt-in permissions', 'icon': Icons.gavel},
      {'step': 5, 'title': 'ETL/ELT Pipeline & Transformation', 'desc': 'Sanitize, minimize, and transform operational data into analytics models', 'icon': Icons.transform},
      {'step': 6, 'title': 'Analytics Database / Warehouse', 'desc': 'Persist aggregated analytical datasets and dimension tables', 'icon': Icons.cloud_done},
      {'step': 7, 'title': 'Data Quality Checks & KPI Calculations', 'desc': 'Automated validation guards and zero-division safe KPI computing', 'icon': Icons.rule},
      {'step': 8, 'title': 'Backend Power BI & Dashboard Sync', 'desc': 'Automated server-side push datasets, scheduled ETL sync & reports', 'icon': Icons.insights},
      {'step': 9, 'title': 'Access Control, Lineage & Retention', 'desc': 'RBAC enforcement, audit trail logging, and scheduled data purging', 'icon': Icons.lock_clock},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      itemBuilder: (context, i) {
        final s = steps[i];
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal,
                  child: Text(
                    '${s['step']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.teal.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s['icon'] as IconData, color: Colors.teal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s['desc'] as String,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ΓöÇΓöÇ 2. Inventory & Minimization Tab (Section 3 & 4) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildInventoryAndMinimizationTab(BuildContext context, TransactionRepository repo) {
    final inventory = [
      {'dataset': 'Customer', 'fields': 'Customer ID, name, mobile, email, address, business details', 'purpose': 'Customer analysis & segmentation', 'pii': 'Possible / Yes', 'color': Colors.red},
      {'dataset': 'Sales', 'fields': 'Sale ID, product/category, amount, date, customer ID', 'purpose': 'Sales KPIs & revenue tracking', 'pii': 'Usually indirect', 'color': Colors.orange},
      {'dataset': 'Purchase', 'fields': 'Purchase ID, vendor, amount, date, terms', 'purpose': 'Purchase & supplier analysis', 'pii': 'Possible', 'color': Colors.amber},
      {'dataset': 'Expenses', 'fields': 'Expense ID, category, amount, date, notes', 'purpose': 'Expense analysis & cost control', 'pii': 'Usually indirect', 'color': Colors.orange},
      {'dataset': 'Payments', 'fields': 'Payment ID, amount, mode, date, status', 'purpose': 'Payment analytics & cashflow liquidity', 'pii': 'Possible', 'color': Colors.amber},
      {'dataset': 'Analytics Events', 'fields': 'Event, timestamp, user/customer ID, metadata', 'purpose': 'Product usage analysis & telemetry', 'pii': 'Possible', 'color': Colors.amber},
      {'dataset': 'Risk / Fraud inputs', 'fields': 'Transaction amount, velocity, behavioral attributes', 'purpose': 'Risk & anomaly detection', 'pii': 'Possible', 'color': Colors.amber},
    ];

    final minimized = repo.getMinimizedAnalyticsDataset();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 3: Data Inventory Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Section 3: Analytics Data Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                      columns: const [
                        DataColumn(label: Text('Dataset', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Typical Fields', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('PII Classification', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: inventory.map((inv) {
                        return DataRow(cells: [
                          DataCell(Text(inv['dataset'] as String, style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text(inv['fields'] as String)),
                          DataCell(Text(inv['purpose'] as String)),
                          DataCell(Chip(
                            label: Text(inv['pii'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: (inv['color'] as Color).withValues(alpha: 0.15),
                            side: BorderSide(color: (inv['color'] as Color).withValues(alpha: 0.3)),
                            padding: EdgeInsets.zero,
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 4: Data Minimization & Purpose Limitation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Section 4: Data Minimization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('PII STRIPPED IN ANALYTICS', style: TextStyle(color: Colors.teal, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Operational DB carries Name, Mobile, Email, and GST. The analytics layer automatically strips identifiers, maintaining only customer_id, customer_type, business_category, and registration_date.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),

                  minimized.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: const Text('No customers registered yet. Add customer data to view live minimization.', style: TextStyle(color: Colors.grey)),
                        )
                      : Column(
                          children: minimized.map((row) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ID: ${row['customer_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text('Category: ${row['business_category']} • Type: ${row['customer_type']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Reg: ${row['registration_date']}', style: const TextStyle(fontSize: 11)),
                                      Text('Status: ${row['active_status']}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ΓöÇΓöÇ 3. Event Dictionary Tab (Section 5) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildEventDictionaryTab(BuildContext context, TransactionRepository repo) {
    final eventDefinitions = [
      {'event': 'user_registered', 'trigger': 'New user registers', 'purpose': 'Registration analysis'},
      {'event': 'sale_created', 'trigger': 'Sale is recorded', 'purpose': 'Sales analysis'},
      {'event': 'expense_added', 'trigger': 'Expense is recorded', 'purpose': 'Expense analysis'},
      {'event': 'payment_received', 'trigger': 'Payment is received', 'purpose': 'Collection analysis'},
      {'event': 'invoice_created', 'trigger': 'Invoice is generated', 'purpose': 'Invoice analytics'},
      {'event': 'customer_added', 'trigger': 'Customer is added', 'purpose': 'Customer growth'},
      {'event': 'report_generated', 'trigger': 'A report is generated/opened', 'purpose': 'Feature usage'},
      {'event': 'subscription_started', 'trigger': 'Subscription begins', 'purpose': 'Subscription/revenue analytics'},
    ];

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Dictionary Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Section 5: Analytics Event Dictionary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                      columns: const [
                        DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Triggered When', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Example Purpose', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: eventDefinitions.map((ev) {
                        return DataRow(cells: [
                          DataCell(Text(ev['event']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                          DataCell(Text(ev['trigger']!)),
                          DataCell(Text(ev['purpose']!)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline, size: 20, color: Colors.teal),
                              tooltip: 'Simulate & Log Event',
                              onPressed: () {
                                repo.logEvent(ev['event']!, ev['purpose']!, metadata: {'test': true});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Logged telemetry event: ${ev['event']}'), duration: const Duration(seconds: 1)),
                                );
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Event Log
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Live Event Stream (${repo.events.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Log Report'),
                        onPressed: () => repo.logEvent('report_generated', 'Feature usage audit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  repo.events.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No events recorded.')))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: repo.events.length > 10 ? 10 : repo.events.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final e = repo.events[idx];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flash_on, size: 16, color: Colors.teal),
                              ),
                              title: Text(e.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${e.purpose} ΓÇó ${dateFormatter.format(e.timestamp)}', style: const TextStyle(fontSize: 11)),
                              trailing: Chip(
                                label: Text(e.id.split('-').first, style: const TextStyle(fontSize: 9)),
                                padding: EdgeInsets.zero,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ΓöÇΓöÇ 4. Lineage Register Tab (Section 6) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildLineageTab(BuildContext context, TransactionRepository repo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_tree_outlined, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Section 6: Data Lineage Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Full traceability linking operational data sources, mathematical transformations, and final dashboard KPI presentation.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                    columns: const [
                      DataColumn(label: Text('Analytics Field', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Transformation', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Final Use', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: repo.dataLineageList.map((l) {
                      return DataRow(cells: [
                        DataCell(Text(l.analyticsField, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(l.source, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        )),
                        DataCell(Text(l.transformation, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Chip(
                          label: Text(l.finalUse, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                          padding: EdgeInsets.zero,
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ΓöÇΓöÇ 5. RBAC & Consent Tab (Section 7 & 8) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildRbacAndConsentTab(BuildContext context, TransactionRepository repo) {
    final rbac = [
      {'role': 'Admin', 'pii': 'As authorized', 'fin': 'As authorized', 'analytics': 'Yes', 'dash': 'Yes'},
      {'role': 'Data Analyst', 'pii': 'Limited / approved', 'fin': 'Yes', 'analytics': 'Yes', 'dash': 'Yes'},
      {'role': 'Developer', 'pii': 'Limited', 'fin': 'Limited', 'analytics': 'Limited', 'dash': 'Selected'},
      {'role': 'Support', 'pii': 'Limited', 'fin': 'Limited', 'analytics': 'No', 'dash': 'No'},
      {'role': 'Manager', 'pii': 'Limited / approved', 'fin': 'Yes', 'analytics': 'Yes', 'dash': 'Yes'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 7 RBAC
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.badge, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Section 7: Role-Based Access Control', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text('Active: ${repo.currentRole.title}'),
                              backgroundColor: Colors.teal.withValues(alpha: 0.15),
                              side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                      columns: const [
                        DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Customer PII', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Financial Data', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: rbac.map((r) {
                        final isCurrent = r['role'] == repo.currentRole.title;
                        return DataRow(
                          color: isCurrent ? WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.08)) : null,
                          cells: [
                            DataCell(Row(
                              children: [
                                if (isCurrent) const Icon(Icons.check_circle, size: 14, color: Colors.teal),
                                if (isCurrent) const SizedBox(width: 4),
                                Text(r['role']!, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.teal : null)),
                              ],
                            )),
                            DataCell(Text(r['pii']!)),
                            DataCell(Text(r['fin']!)),
                            DataCell(Text(r['analytics']!)),
                            DataCell(Text(r['dash']!)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 8 Consent & Legal Basis Register
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Section 8: Consent & Legal Basis Register', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                      columns: const [
                        DataColumn(label: Text('Data Category', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Basis / Status to Document', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: repo.consentRecords.map((c) {
                        return DataRow(cells: [
                          DataCell(Text(c.dataCategory, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(c.purpose)),
                          DataCell(Chip(
                            label: Text(c.legalBasis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.green.withValues(alpha: 0.12),
                            side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                            padding: EdgeInsets.zero,
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ΓöÇΓöÇ 6. Retention & Purge Tab (Section 9) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildRetentionTab(BuildContext context, TransactionRepository repo) {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_delete, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Section 9: Retention & Purging Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Automated retention policy monitoring with manual execution triggers to satisfy data purging compliance requirements.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                    columns: const [
                      DataColumn(label: Text('Dataset', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Retention', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Archive / Purge', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: repo.retentionPolicies.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.dataset, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(r.retention)),
                        DataCell(Text(r.archivePurge)),
                        DataCell(Text(r.owner)),
                        DataCell(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep, size: 14),
                            label: Text(r.lastPurged == null ? 'Purge Now' : 'Purged (${dateFormatter.format(r.lastPurged!)})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: r.lastPurged == null ? Colors.teal : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              repo.purgeExpiredData(r.dataset);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Purged expired data for: ${r.dataset}')),
                              );
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ΓöÇΓöÇ 7. Model Governance Tab (Section 11) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildModelGovernanceTab(BuildContext context, TransactionRepository repo) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: repo.modelGovernanceList.length,
      itemBuilder: (context, idx) {
        final m = repo.modelGovernanceList[idx];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy, color: Colors.indigo),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.modelName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Version: ${m.version} • Owner: ${m.owner}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('PRODUCTION ML', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildModelRow('Model Inputs', m.inputs),
                _buildModelRow('Output Decision', m.output),
                _buildModelRow('Decision Logic', m.decisionLogic),
                _buildModelRow('Performance Metrics', m.performance),
                _buildModelRow('Drift Monitoring', m.drift),
                _buildModelRow('Bias & Fairness Review', m.biasFairness),
                _buildModelRow('Human Review & Appeal Path', m.humanReview),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ΓöÇΓöÇ 8. Sign-Off Tab (Section 12 & 14) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildSignOffTab(BuildContext context, TransactionRepository repo) {
    final allComplete = repo.signOffChecklist.every((c) => c.isCompleted);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 12 Register
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Section 12: Data Analysis Compliance Register', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.1)),
                      columns: const [
                        DataColumn(label: Text('Dataset / Model', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('PII?', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Consent / Legal Basis', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Retention', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Reviewed?', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: repo.complianceRegisters.map((reg) {
                        return DataRow(cells: [
                          DataCell(Text(reg.datasetOrModel, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(reg.piiStatus)),
                          DataCell(Text(reg.consentLegalBasis)),
                          DataCell(Text(reg.retention)),
                          DataCell(
                            Checkbox(
                              value: reg.isReviewed,
                              activeColor: Colors.teal,
                              onChanged: (_) => repo.toggleComplianceReviewed(reg.id),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 14 Sign-off Checklist
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Section 14: Sign-Off Checklist', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(allComplete ? '100% READY' : 'INCOMPLETE'),
                              backgroundColor: allComplete ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                              side: BorderSide(color: allComplete ? Colors.green : Colors.amber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...repo.signOffChecklist.map((item) {
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.teal,
                      title: Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      value: item.isCompleted,
                      onChanged: (_) => repo.toggleSignOffItem(item.id),
                    );
                  }),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, color: Colors.teal, size: 20),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Section 21 Compliance Attestation',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Certified by Chief Data Officer & Legal Compliance Lead. All audit gates verified against ENX Money data safety standards.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ComplianceExcelExporter.exportMasterComplianceWorkbook(repo);
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download Sign-off Certificate (.XLSX)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
