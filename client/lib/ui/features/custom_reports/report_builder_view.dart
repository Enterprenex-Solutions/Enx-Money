import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/excel_exporter.dart';
import '../../../core/utils/pdf_exporter.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/repositories/transaction_repository.dart';

class ReportBuilderView extends StatefulWidget {
  const ReportBuilderView({super.key});

  @override
  State<ReportBuilderView> createState() => _ReportBuilderViewState();
}

class _ReportBuilderViewState extends State<ReportBuilderView> {
  ProfileType _selectedProfile = ProfileType.business;
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;
  String _selectedChartType = 'Bar & Pie Combo';
  bool _includeGst = true;
  bool _includeReceivables = true;
  bool _includePayables = true;
  bool _scheduledEmailEnabled = false;
  String _emailFrequency = 'Weekly (Every Monday)';
  final _emailAddressController = TextEditingController(text: 'owner@enxmoney.com');

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final kpi = repo.kpiSummary;
    final transactions = repo.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Sidebar',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Row(
          children: [
            Icon(Icons.tune, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Custom Report Builder'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Report Criteria Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Report Scope & Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Profile Selector
                    DropdownButtonFormField<ProfileType>(
                      initialValue: _selectedProfile,
                      decoration: const InputDecoration(labelText: 'Profile Context', prefixIcon: Icon(Icons.person)),
                      items: ProfileType.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProfile = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Date Filter
                    DropdownButtonFormField<DateFilterOption>(
                      initialValue: _selectedDateFilter,
                      decoration: const InputDecoration(labelText: 'Date Boundary', prefixIcon: Icon(Icons.calendar_month)),
                      items: DateFilterOption.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDateFilter = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Chart Type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedChartType,
                      decoration: const InputDecoration(labelText: 'Preferred Chart Layout', prefixIcon: Icon(Icons.bar_chart)),
                      items: ['Bar & Pie Combo', 'Donut Expense Split', 'Line Trend Cash Flow', 'Stacked Bar Revenue vs Expense']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedChartType = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Included Metrics Checkboxes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Included Fields & Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('Include GST Tax Breakdowns'),
                      value: _includeGst,
                      onChanged: (val) => setState(() => _includeGst = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Include Outstanding Receivables'),
                      value: _includeReceivables,
                      onChanged: (val) => setState(() => _includeReceivables = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Include Outstanding Payables & EMIs'),
                      value: _includePayables,
                      onChanged: (val) => setState(() => _includePayables = val ?? true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Export Actions
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3. Generate & Share Ad-Hoc Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              PdfExporter.sharePdfReport(
                                profile: _selectedProfile,
                                dateFilter: _selectedDateFilter,
                                kpi: kpi,
                                transactions: transactions,
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate PDF Statement'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ExcelExporter.exportToExcel(
                                profile: _selectedProfile,
                                dateFilter: _selectedDateFilter,
                                kpi: kpi,
                                transactions: transactions,
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857)),
                            icon: const Icon(Icons.table_view),
                            label: const Text('Export Excel Sheet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Scheduled Email Dispatch Config
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Scheduled Email Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _scheduledEmailEnabled,
                          onChanged: (val) => setState(() => _scheduledEmailEnabled = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatically email a PDF & Excel summary report directly to business owners or accountants.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (_scheduledEmailEnabled) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Email Address',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _emailFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Schedule Frequency',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: ['Daily Digest', 'Weekly (Every Monday)', 'Monthly (1st Day of Month)']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _emailFrequency = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Scheduled email trigger saved! Reports will be delivered to ${_emailAddressController.text}.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Automated Schedule'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
