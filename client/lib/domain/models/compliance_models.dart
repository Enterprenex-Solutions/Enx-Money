/// Section 5: Analytics Event Item
class AnalyticsEventItem {
  final String id;
  final String eventName;
  final DateTime timestamp;
  final String? userId;
  final String? customerId;
  final String purpose;
  final Map<String, dynamic> metadata;

  const AnalyticsEventItem({
    required this.id,
    required this.eventName,
    required this.timestamp,
    this.userId,
    this.customerId,
    required this.purpose,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventName': eventName,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'customerId': customerId,
    'purpose': purpose,
    'metadata': metadata,
  };
}

/// Section 6: Data Lineage Register Item
class DataLineageItem {
  final String analyticsField;
  final String source;
  final String transformation;
  final String finalUse;

  const DataLineageItem({
    required this.analyticsField,
    required this.source,
    required this.transformation,
    required this.finalUse,
  });
}

/// Section 7: User Roles for Role-Based Access Control (RBAC)
enum AppUserRole {
  admin('Admin', 'Full administrative authority across all modules'),
  dataAnalyst('Data Analyst', 'Analytics, reporting, and model oversight'),
  developer('Developer', 'Application maintenance and limited debugging'),
  support('Support', 'Customer operational assistance with masked PII'),
  manager('Manager', 'Executive financial and operational KPI oversight');

  final String title;
  final String description;
  const AppUserRole(this.title, this.description);
}

class RolePermission {
  final AppUserRole role;
  final String customerPii; // e.g. "As authorized", "Limited/approved", "Limited"
  final String financialData; // e.g. "As authorized", "Yes", "Limited"
  final bool analytics;
  final bool dashboard;

  const RolePermission({
    required this.role,
    required this.customerPii,
    required this.financialData,
    required this.analytics,
    required this.dashboard,
  });
}

/// Section 8: Consent & Legal Basis Register Item
class ConsentRecord {
  final String dataCategory;
  final String purpose;
  final String legalBasis;
  final String status;

  const ConsentRecord({
    required this.dataCategory,
    required this.purpose,
    required this.legalBasis,
    required this.status,
  });
}

/// Section 9: Retention & Purging Register Item
class RetentionPolicyItem {
  final String dataset;
  final String retention;
  final String archivePurge;
  final String owner;
  final DateTime? lastPurged;

  const RetentionPolicyItem({
    required this.dataset,
    required this.retention,
    required this.archivePurge,
    required this.owner,
    this.lastPurged,
  });

  RetentionPolicyItem copyWith({DateTime? lastPurged}) {
    return RetentionPolicyItem(
      dataset: dataset,
      retention: retention,
      archivePurge: archivePurge,
      owner: owner,
      lastPurged: lastPurged ?? this.lastPurged,
    );
  }
}

/// Section 11: Automated Decision / Fraud Model Governance Item
class ModelGovernanceItem {
  final String modelName;
  final String version;
  final String inputs;
  final String output;
  final String decisionLogic;
  final String owner;
  final String performance;
  final String drift;
  final String biasFairness;
  final String humanReview;

  const ModelGovernanceItem({
    required this.modelName,
    required this.version,
    required this.inputs,
    required this.output,
    required this.decisionLogic,
    required this.owner,
    required this.performance,
    required this.drift,
    required this.biasFairness,
    required this.humanReview,
  });
}

/// Section 12: Data Analysis Compliance Register Item
class ComplianceRegisterItem {
  final String id;
  final String datasetOrModel;
  final String piiStatus;
  final String consentLegalBasis;
  final String retention;
  final bool isReviewed;

  const ComplianceRegisterItem({
    required this.id,
    required this.datasetOrModel,
    required this.piiStatus,
    required this.consentLegalBasis,
    required this.retention,
    this.isReviewed = true,
  });

  ComplianceRegisterItem copyWith({bool? isReviewed}) {
    return ComplianceRegisterItem(
      id: id,
      datasetOrModel: datasetOrModel,
      piiStatus: piiStatus,
      consentLegalBasis: consentLegalBasis,
      retention: retention,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}

/// Section 14: Sign-Off Checklist Item
class SignOffChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;

  const SignOffChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = true,
  });

  SignOffChecklistItem copyWith({bool? isCompleted}) {
    return SignOffChecklistItem(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
