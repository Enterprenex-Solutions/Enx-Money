class AuditRecordModel {
  final String id;
  final String utr;
  final String senderName;
  final String recipientName;
  final double amount;
  final String assetType;
  final String purpose;
  final String status;
  final String timestamp;
  final double gstAmount;
  final double tdsDeducted;

  const AuditRecordModel({
    required this.id,
    required this.utr,
    required this.senderName,
    required this.recipientName,
    required this.amount,
    required this.assetType,
    required this.purpose,
    required this.status,
    required this.timestamp,
    required this.gstAmount,
    required this.tdsDeducted,
  });

  factory AuditRecordModel.fromJson(Map<String, dynamic> json) {
    return AuditRecordModel(
      id: json['id'] as String? ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      utr: json['utr'] as String? ?? 'ENX982104821',
      senderName: json['senderName'] as String? ?? 'P. Revanth Reddy',
      recipientName: json['recipientName'] as String? ?? 'Vendor / Beneficiary',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      assetType: json['assetType'] as String? ?? 'INR',
      purpose: json['purpose'] as String? ?? 'Payment',
      status: json['status'] as String? ?? 'SUCCESS',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      tdsDeducted: (json['tdsDeducted'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AuditSummaryModel {
  final int totalRecords;
  final double totalTransactionVolume;
  final double totalGstLiability;
  final double totalTdsWithheld;
  final String accountingSyncStatus;

  const AuditSummaryModel({
    required this.totalRecords,
    required this.totalTransactionVolume,
    required this.totalGstLiability,
    required this.totalTdsWithheld,
    required this.accountingSyncStatus,
  });

  factory AuditSummaryModel.fromJson(Map<String, dynamic> json) {
    return AuditSummaryModel(
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalTransactionVolume: (json['totalTransactionVolume'] as num?)?.toDouble() ?? 0.0,
      totalGstLiability: (json['totalGstLiability'] as num?)?.toDouble() ?? 0.0,
      totalTdsWithheld: (json['totalTdsWithheld'] as num?)?.toDouble() ?? 0.0,
      accountingSyncStatus: json['accountingSyncStatus'] as String? ?? 'SYNCED_WITH_ERP',
    );
  }
}
