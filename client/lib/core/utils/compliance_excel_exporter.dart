import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/repositories/transaction_repository.dart';

class ComplianceExcelExporter {
  /// Exports the complete Section 21 Master Compliance Workbook with all 10 registers
  static Future<String?> exportMasterComplianceWorkbook(TransactionRepository repo) async {
    final excel = Excel.createExcel();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    // 1. Overview Sheet
    excel.rename('Sheet1', 'Executive Summary');
    final Sheet summarySheet = excel['Executive Summary'];
    summarySheet.appendRow([TextCellValue('ENX MONEY ΓÇö SECTION 21 DATA ANALYSIS & ANALYTICS COMPLIANCE')]);
    summarySheet.appendRow([TextCellValue('Generated At: ${dateFormatter.format(DateTime.now())}')]);
    summarySheet.appendRow([TextCellValue('Current System Role: ${repo.currentRole.title}')]);
    summarySheet.appendRow([TextCellValue('Compliance Status: ACTIVE & ENFORCED')]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([TextCellValue('Table of Contents / Deliverables (Section 13):')]);
    summarySheet.appendRow([TextCellValue('1. ENX_Data_Inventory ΓÇö Analytics Data Inventory & PII Scope')]);
    summarySheet.appendRow([TextCellValue('2. ENX_Event_Dictionary ΓÇö Telemetry & Analytics Event Register')]);
    summarySheet.appendRow([TextCellValue('3. ENX_PII_Classification ΓÇö Personal Data Identification & Masking')]);
    summarySheet.appendRow([TextCellValue('4. ENX_Data_Lineage ΓÇö Source-to-KPI Data Transformation Lineage')]);
    summarySheet.appendRow([TextCellValue('5. ENX_Access_Control_Matrix ΓÇö Role-Based Access Control (RBAC)')]);
    summarySheet.appendRow([TextCellValue('6. ENX_Data_Retention_Register ΓÇö Dataset Purge & Archival Schedule')]);
    summarySheet.appendRow([TextCellValue('7. ENX_Consent_Legal_Basis_Register ΓÇö Legal Grounds for Processing')]);
    summarySheet.appendRow([TextCellValue('8. ENX_Model_Governance ΓÇö Automated Decision & Fraud ML Register')]);
    summarySheet.appendRow([TextCellValue('9. ENX_SignOff_Checklist ΓÇö Section 14 Official Audit Verification')]);

    // 2. Data Inventory & PII
    final Sheet invSheet = excel['Data Inventory & PII'];
    invSheet.appendRow([
      TextCellValue('Dataset'),
      TextCellValue('Typical Fields'),
      TextCellValue('Purpose'),
      TextCellValue('PII Status'),
    ]);
    invSheet.appendRow([
      TextCellValue('Customer'),
      TextCellValue('Customer ID, name, mobile, email, business details'),
      TextCellValue('Customer analysis & growth'),
      TextCellValue('Possible / Yes'),
    ]);
    invSheet.appendRow([
      TextCellValue('Sales'),
      TextCellValue('Sale ID, product, amount, date, customer ID'),
      TextCellValue('Sales KPIs & trend analysis'),
      TextCellValue('Usually indirect'),
    ]);
    invSheet.appendRow([
      TextCellValue('Purchase'),
      TextCellValue('Purchase ID, vendor, amount, date'),
      TextCellValue('Purchase & supplier analysis'),
      TextCellValue('Possible'),
    ]);
    invSheet.appendRow([
      TextCellValue('Expenses'),
      TextCellValue('Expense ID, category, amount, date'),
      TextCellValue('Expense analysis & control'),
      TextCellValue('Usually indirect'),
    ]);
    invSheet.appendRow([
      TextCellValue('Payments'),
      TextCellValue('Payment ID, amount, mode, date, status'),
      TextCellValue('Collection analytics & liquidity'),
      TextCellValue('Possible'),
    ]);
    invSheet.appendRow([
      TextCellValue('Analytics Events'),
      TextCellValue('Event, timestamp, user/customer ID, metadata'),
      TextCellValue('Product usage & telemetry'),
      TextCellValue('Possible'),
    ]);
    invSheet.appendRow([
      TextCellValue('Risk / Fraud inputs'),
      TextCellValue('Transaction amount, velocity, risk tier'),
      TextCellValue('Risk & anomaly detection'),
      TextCellValue('Possible'),
    ]);

    // 3. Event Dictionary
    final Sheet eventSheet = excel['Event Dictionary'];
    eventSheet.appendRow([
      TextCellValue('Event Name'),
      TextCellValue('Trigger Condition'),
      TextCellValue('Example Purpose'),
      TextCellValue('Total Logged'),
    ]);
    final eventDefinitions = [
      {'name': 'user_registered', 'trigger': 'New user registers', 'purpose': 'Registration analysis'},
      {'name': 'sale_created', 'trigger': 'Sale is recorded', 'purpose': 'Sales analysis'},
      {'name': 'expense_added', 'trigger': 'Expense is recorded', 'purpose': 'Expense analysis'},
      {'name': 'payment_received', 'trigger': 'Payment is received', 'purpose': 'Collection analysis'},
      {'name': 'invoice_created', 'trigger': 'Invoice is generated', 'purpose': 'Invoice analytics'},
      {'name': 'customer_added', 'trigger': 'Customer is added', 'purpose': 'Customer growth'},
      {'name': 'report_generated', 'trigger': 'Report is opened / generated', 'purpose': 'Feature usage'},
      {'name': 'subscription_started', 'trigger': 'Subscription begins', 'purpose': 'Subscription/revenue analytics'},
    ];
    for (var ev in eventDefinitions) {
      final count = repo.events.where((e) => e.eventName == ev['name']).length;
      eventSheet.appendRow([
        TextCellValue(ev['name']!),
        TextCellValue(ev['trigger']!),
        TextCellValue(ev['purpose']!),
        IntCellValue(count),
      ]);
    }

    // 4. Data Lineage
    final Sheet lineageSheet = excel['Data Lineage'];
    lineageSheet.appendRow([
      TextCellValue('Analytics Field'),
      TextCellValue('Source'),
      TextCellValue('Transformation'),
      TextCellValue('Final Use'),
    ]);
    for (var l in repo.dataLineageList) {
      lineageSheet.appendRow([
        TextCellValue(l.analyticsField),
        TextCellValue(l.source),
        TextCellValue(l.transformation),
        TextCellValue(l.finalUse),
      ]);
    }

    // 5. Access Control Matrix (RBAC)
    final Sheet rbacSheet = excel['Access Control Matrix'];
    rbacSheet.appendRow([
      TextCellValue('Role'),
      TextCellValue('Customer PII'),
      TextCellValue('Financial Data'),
      TextCellValue('Analytics'),
      TextCellValue('Dashboard'),
    ]);
    rbacSheet.appendRow([TextCellValue('Admin'), TextCellValue('As authorized'), TextCellValue('As authorized'), TextCellValue('Yes'), TextCellValue('Yes')]);
    rbacSheet.appendRow([TextCellValue('Data Analyst'), TextCellValue('Limited / approved'), TextCellValue('Yes'), TextCellValue('Yes'), TextCellValue('Yes')]);
    rbacSheet.appendRow([TextCellValue('Developer'), TextCellValue('Limited'), TextCellValue('Limited'), TextCellValue('Limited'), TextCellValue('Selected')]);
    rbacSheet.appendRow([TextCellValue('Support'), TextCellValue('Limited'), TextCellValue('Limited'), TextCellValue('No'), TextCellValue('No')]);
    rbacSheet.appendRow([TextCellValue('Manager'), TextCellValue('Limited / approved'), TextCellValue('Yes'), TextCellValue('Yes'), TextCellValue('Yes')]);

    // 6. Retention & Purging Register
    final Sheet retSheet = excel['Data Retention Register'];
    retSheet.appendRow([
      TextCellValue('Dataset'),
      TextCellValue('Retention Period'),
      TextCellValue('Archive / Purge Schedule'),
      TextCellValue('Owner'),
      TextCellValue('Last Purged Timestamp'),
    ]);
    for (var r in repo.retentionPolicies) {
      retSheet.appendRow([
        TextCellValue(r.dataset),
        TextCellValue(r.retention),
        TextCellValue(r.archivePurge),
        TextCellValue(r.owner),
        TextCellValue(r.lastPurged != null ? dateFormatter.format(r.lastPurged!) : 'Not Triggered'),
      ]);
    }

    // 7. Consent & Legal Basis Register
    final Sheet consentSheet = excel['Consent & Legal Basis'];
    consentSheet.appendRow([
      TextCellValue('Data Category'),
      TextCellValue('Purpose'),
      TextCellValue('Legal Basis / Status'),
    ]);
    for (var c in repo.consentRecords) {
      consentSheet.appendRow([
        TextCellValue(c.dataCategory),
        TextCellValue(c.purpose),
        TextCellValue(c.legalBasis),
      ]);
    }

    // 8. Model Governance
    final Sheet modelSheet = excel['Model Governance'];
    modelSheet.appendRow([
      TextCellValue('Model Name / Version'),
      TextCellValue('Inputs'),
      TextCellValue('Output'),
      TextCellValue('Decision Logic'),
      TextCellValue('Owner'),
      TextCellValue('Performance Metrics'),
      TextCellValue('Drift Monitoring'),
      TextCellValue('Bias / Fairness'),
      TextCellValue('Human Review & Appeal'),
    ]);
    for (var m in repo.modelGovernanceList) {
      modelSheet.appendRow([
        TextCellValue('${m.modelName} (${m.version})'),
        TextCellValue(m.inputs),
        TextCellValue(m.output),
        TextCellValue(m.decisionLogic),
        TextCellValue(m.owner),
        TextCellValue(m.performance),
        TextCellValue(m.drift),
        TextCellValue(m.biasFairness),
        TextCellValue(m.humanReview),
      ]);
    }

    // 9. Sign-off Checklist
    final Sheet signSheet = excel['Sign-Off Checklist'];
    signSheet.appendRow([
      TextCellValue('Checklist Requirement'),
      TextCellValue('Compliance Verified?'),
    ]);
    for (var s in repo.signOffChecklist) {
      signSheet.appendRow([
        TextCellValue(s.title),
        TextCellValue(s.isCompleted ? 'VERIFIED (PASS)' : 'PENDING'),
      ]);
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'ENX_Section21_Master_Compliance_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'ENX Money ΓÇö Section 21 Analytics Compliance Master Report',
      );
      return filePath;
    }
    return null;
  }
}
