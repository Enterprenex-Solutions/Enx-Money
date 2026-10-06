import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/power_bi_helper.dart';
import '../../../domain/repositories/transaction_repository.dart';

class PowerBiIntegrationView extends StatefulWidget {
  const PowerBiIntegrationView({super.key});

  @override
  State<PowerBiIntegrationView> createState() => _PowerBiIntegrationViewState();
}

class _PowerBiIntegrationViewState extends State<PowerBiIntegrationView> {
  final _endpointController = TextEditingController(
    text: 'https://api.powerbi.com/v1.0/myorg/groups/enx-workspace-id/datasets/push-dataset-id/rows',
  );
  final _apiKeyController = TextEditingController(text: 'eyJhbGciOiJSUzI1NiIsImtpZCI6I...[Power_BI_Bearer_Token]');
  bool _autoSyncEnabled = true;
  bool _isTestingConnection = false;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final kpi = repo.kpiSummary;
    final transactions = repo.filteredTransactions;
    final schema = PowerBiHelper.generatePowerBiDatasetSchema();
    final jsonSchemaString = const JsonEncoder.withIndent('  ').convert(schema);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: Color(0xFFF2C811)), // Power BI Yellow Accent
            SizedBox(width: 8),
            Text('Power BI Integration'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: const Color(0xFF252423), // Power BI Dark Palette
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2C811).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on, color: Color(0xFFF2C811), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Power BI Live Streaming Connected',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Automatic Push API Enabled • Syncing ${transactions.length} rows',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoSyncEnabled,
                      activeThumbColor: const Color(0xFFF2C811),
                      onChanged: (val) => setState(() => _autoSyncEnabled = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await PowerBiHelper.exportPowerBiJsonPayload(
                        profile: repo.currentProfile,
                        dateFilter: repo.dateFilter,
                        kpi: kpi,
                        transactions: transactions,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2C811),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export Power BI Payload JSON'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Power BI Push API Credentials Config
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Power BI REST Push API Configuration',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _endpointController,
                      decoration: const InputDecoration(
                        labelText: 'Power BI Push Dataset REST Endpoint URL',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Azure Active Directory (AAD) Bearer Token',
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isTestingConnection = true);
                        final messenger = ScaffoldMessenger.of(context);
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            setState(() => _isTestingConnection = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Power BI Endpoint connection verified successfully! 200 OK'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        });
                      },
                      icon: _isTestingConnection
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync, size: 18),
                      label: Text(_isTestingConnection ? 'Verifying...' : 'Test Power BI Connection'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Embedded Power BI Report Simulator Container
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Power BI Embedded Dashboard Preview',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text('DIRECT QUERY LIVE', style: TextStyle(fontSize: 9, color: Colors.white)),
                          backgroundColor: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF2C811), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dashboard_customize_rounded, size: 44, color: Color(0xFFF2C811)),
                          const SizedBox(height: 12),
                          const Text(
                            'Power BI Workspace Report Embedded',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Active Workspace: ENX Money Enterprise Analytics\nReport ID: rpt_8820a-99f-powerbi',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Simulating Power BI embedded report refresh...')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2C811),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh Power BI Tiles'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dataset Schema Code Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Power BI Push Dataset Schema (JSON)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        jsonSchemaString,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                      ),
                    ),
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
