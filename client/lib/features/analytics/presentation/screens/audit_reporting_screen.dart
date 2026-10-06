import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/audit_repository.dart';
import '../../models/audit_report_model.dart';

class AuditReportingScreen extends StatefulWidget {
  const AuditReportingScreen({super.key});

  @override
  State<AuditReportingScreen> createState() => _AuditReportingScreenState();
}

class _AuditReportingScreenState extends State<AuditReportingScreen> {
  final AuditRepository _auditRepo = AuditRepository();
  final TextEditingController _searchController = TextEditingController();
  String _selectedAsset = 'ALL';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAudit() async {
    setState(() => _isLoading = true);
    await _auditRepo.fetchAuditRecords(
      assetType: _selectedAsset,
      counterparty: _searchController.text.trim(),
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _exportCsv() async {
    try {
      final csv = await _auditRepo.exportCsvStatement();
      NotificationService.showSuccess('Audit CSV Statement generated (${csv.length} bytes)');
    } catch (e) {
      NotificationService.showError('Export error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgCol = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardCol = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final summary = _auditRepo.summary;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text('Audit & Tax Reporting', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: bgCol,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        actions: [
          IconButton(
            key: const Key('export_csv_btn'),
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportCsv,
            tooltip: 'Export CSV Statement',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tax & GST Overview Cards
                  if (summary != null) ...[
                    _buildTaxSummaryCard(summary, isDark, cardCol, textCol, subtextCol, borderCol),
                    const SizedBox(height: 20),
                  ],

                  // 2. Search & Tag Filters
                  FintechTextField(
                    controller: _searchController,
                    label: 'Search Transactions',
                    hintText: 'Search by counterparty or UTR',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => _loadAudit(),
                  ),
                  const SizedBox(height: 12),

                  // Asset Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'INR', 'CBDC', 'GOLD'].map((asset) {
                        final isSel = _selectedAsset == asset;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(asset, style: TextStyle(color: isSel ? Colors.black : textCol, fontWeight: FontWeight.w700, fontSize: 12)),
                            selected: isSel,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: cardCol,
                            side: BorderSide(color: isSel ? AppColors.primaryGreen : borderCol),
                            onSelected: (_) {
                              setState(() => _selectedAsset = asset);
                              _loadAudit();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Transactions List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TRANSACTION AUDIT LEDGER', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                      Text('${_auditRepo.records.length} Records', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Records
                  if (_auditRepo.records.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: cardCol, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
                      child: Center(child: Text('No transactions match the filter criteria.', style: TextStyle(color: subtextCol, fontSize: 13))),
                    )
                  else
                    ..._auditRepo.records.map((r) => _buildRecordCard(r, isDark, cardCol, textCol, subtextCol, borderCol)),

                  const SizedBox(height: 24),

                  // Export Statement Action
                  PrimaryButton(
                    text: 'Download Full Audit Statement (CSV / PDF)',
                    icon: Icons.download_rounded,
                    onPressed: _exportCsv,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildTaxSummaryCard(AuditSummaryModel summary, bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TAX RECORDS & GST SUMMARY', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Text('ERP SYNC ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Volume', style: TextStyle(color: subtextCol, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('₹${summary.totalTransactionVolume.toStringAsFixed(0)}', style: TextStyle(color: textCol, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GST Liability', style: TextStyle(color: subtextCol, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('₹${summary.totalGstLiability.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TDS Withheld', style: TextStyle(color: subtextCol, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('₹${summary.totalTdsWithheld.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(AuditRecordModel r, bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.recipientName, style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 14)),
              Text(
                '${r.assetType == 'CBDC' ? 'e₹' : '₹'}${r.amount.toStringAsFixed(2)}',
                style: TextStyle(color: textCol, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.purpose, style: TextStyle(color: subtextCol, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(r.status, style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UTR: ${r.utr}', style: TextStyle(color: subtextCol, fontSize: 11, fontFamily: 'monospace')),
              if (r.gstAmount > 0)
                Text('GST: ₹${r.gstAmount.toStringAsFixed(0)}', style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
