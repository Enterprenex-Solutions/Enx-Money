import '../../../../core/network/api_client.dart';
import '../models/expense_model.dart';

class ExpensesRepository {
  static final ExpensesRepository _instance = ExpensesRepository._internal();
  factory ExpensesRepository() => _instance;
  ExpensesRepository._internal();

  final ApiClient _apiClient = ApiClient();

  Future<List<ExpenseItem>> getExpenses({
    String? category,
    String? search,
    String? status,
    String? supplierId,
    String? accountId,
    String? startDate,
    String? endDate,
    String mode = 'BUSINESS',
  }) async {
    final queryParams = <String, String>{
      'mode': mode,
    };

    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status;
    }
    if (supplierId != null && supplierId.isNotEmpty) {
      queryParams['supplierId'] = supplierId;
    }
    if (accountId != null && accountId.isNotEmpty) {
      queryParams['accountId'] = accountId;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final endpoint = '/expenses${queryString.isNotEmpty ? '?$queryString' : ''}';
    final res = await _apiClient.get(endpoint);

    final data = res['data'];
    if (data is List) {
      return data
          .map((item) => ExpenseItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ExpenseSummary> getExpenseSummary({String mode = 'BUSINESS'}) async {
    try {
      final res = await _apiClient.get('/expenses/summary?mode=$mode');
      if (res['data'] is Map<String, dynamic>) {
        return ExpenseSummary.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      // Fallback empty summary
    }
    return const ExpenseSummary();
  }

  Future<ExpenseItem> createExpense(Map<String, dynamic> body) async {
    final res = await _apiClient.post('/expenses', body: body);
    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : body;
    return ExpenseItem.fromJson(data);
  }

  Future<ExpenseItem> updateExpense(String id, Map<String, dynamic> body) async {
    final res = await _apiClient.put('/expenses/$id', body: body);
    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : body;
    return ExpenseItem.fromJson(data);
  }

  Future<bool> deleteExpense(String id) async {
    final res = await _apiClient.delete('/expenses/$id');
    return res['success'] == true;
  }

  Future<List<String>> getCategories() async {
    try {
      final res = await _apiClient.get('/expenses/categories');
      if (res['data'] is List) {
        return (res['data'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [
      'Rent & Facility',
      'Salaries & Wages',
      'Utilities & Bills',
      'Raw Materials & Inventory',
      'Vendor & Supplier',
      'Logistics & Shipping',
      'Marketing & Advertising',
      'Office Supplies & Equipment',
      'Legal & Professional Services',
      'Maintenance & Repairs',
      'Travel & Entertainment',
      'Taxes & Licenses',
      'Software & Tech Subscriptions',
      'Insurance',
      'Bank Fees & Charges',
      'Miscellaneous',
    ];
  }
}
