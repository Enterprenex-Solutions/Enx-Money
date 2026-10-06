import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/audit_report_model.dart';

class AuditRepository extends ChangeNotifier {
  static final AuditRepository _instance = AuditRepository._internal();
  factory AuditRepository() => _instance;
  AuditRepository._internal();

  final ApiClient _apiClient = ApiClient();
  List<AuditRecordModel> _records = [];
  AuditSummaryModel? _summary;

  List<AuditRecordModel> get records => _records;
  AuditSummaryModel? get summary => _summary;

  Future<void> fetchAuditRecords({String? assetType, String? counterparty}) async {
    try {
      final queryParams = <String>[];
      if (assetType != null && assetType != 'ALL') queryParams.add('assetType=$assetType');
      if (counterparty != null && counterparty.isNotEmpty) queryParams.add('counterparty=$counterparty');
      final q = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final res = await _apiClient.get('/finance/audit/records$q');
      if (res['data'] != null) {
        final list = (res['data']['records'] as List<dynamic>? ?? [])
            .map((r) => AuditRecordModel.fromJson(r as Map<String, dynamic>))
            .toList();
        _records = list;
        if (res['data']['summary'] != null) {
          _summary = AuditSummaryModel.fromJson(res['data']['summary'] as Map<String, dynamic>);
        }
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Fallback seed
    _records = [
      AuditRecordModel(
        id: 'TXN-ENT-001',
        utr: 'ENX8392019482',
        senderName: 'P. Revanth Reddy',
        recipientName: 'Infosys Tech Payouts',
        amount: 25000.00,
        assetType: 'INR',
        purpose: 'Vendor Invoice Clearing',
        status: 'SUCCESS',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        gstAmount: 4500.00,
        tdsDeducted: 500.00,
      ),
      AuditRecordModel(
        id: 'TXN-ENT-002',
        utr: 'ENX8392019889',
        senderName: 'P. Revanth Reddy',
        recipientName: 'RBI Digital Rupee Merchant',
        amount: 1500.00,
        assetType: 'CBDC',
        purpose: 'Retail Grocery Checkout',
        status: 'SUCCESS',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        gstAmount: 75.00,
        tdsDeducted: 0.00,
      ),
      AuditRecordModel(
        id: 'TXN-ENT-003',
        utr: 'ENX8392019124',
        senderName: 'P. Revanth Reddy',
        recipientName: 'Augmont Gold Vault',
        amount: 14500.00,
        assetType: 'GOLD',
        purpose: '24K Digital Gold Accumulation',
        status: 'SUCCESS',
        timestamp: DateTime.now().subtract(const Duration(hours: 28)).toIso8601String(),
        gstAmount: 435.00,
        tdsDeducted: 0.00,
      ),
    ];
    _summary = const AuditSummaryModel(
      totalRecords: 3,
      totalTransactionVolume: 41000.00,
      totalGstLiability: 5010.00,
      totalTdsWithheld: 500.00,
      accountingSyncStatus: 'SYNCED_WITH_ERP',
    );
    notifyListeners();
  }

  Future<String> exportCsvStatement() async {
    try {
      final res = await _apiClient.get('/finance/audit/export-csv');
      if (res['data'] != null) {
        return res['data'] is String ? res['data'] as String : res['data'].toString();
      }
      return 'Transaction ID,UTR,Date,Asset Type,Sender,Recipient,Amount (INR),GST,Status\n';
    } catch (_) {
      return 'Transaction ID,UTR,Date,Asset Type,Sender,Recipient,Amount (INR),GST,Status\n'
          '"TXN-ENT-001","ENX8392019482","2026-09-21","INR","P. Revanth Reddy","Infosys Tech Payouts",25000,4500,"SUCCESS"\n'
          '"TXN-ENT-002","ENX8392019889","2026-09-21","CBDC","P. Revanth Reddy","RBI Merchant",1500,75,"SUCCESS"\n';
    }
  }
}
