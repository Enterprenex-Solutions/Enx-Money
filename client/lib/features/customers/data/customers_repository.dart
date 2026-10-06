import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/customer_model.dart';
import '../models/ledger_entry_model.dart';

class CustomersResult {
  final List<CustomerModel> customers;
  final int totalCount;
  final int allCount;
  final int duesPendingCount;
  final int settledCount;
  final double totalReceivable;
  final double totalPayable;

  CustomersResult({
    required this.customers,
    required this.totalCount,
    this.allCount = 0,
    this.duesPendingCount = 0,
    this.settledCount = 0,
    required this.totalReceivable,
    required this.totalPayable,
  });
}

class CustomersRepository {
  final ApiClient _apiClient = ApiClient();

  Future<CustomersResult> getCustomers({
    String? search,
    String? category,
    String? status,
    String? balanceType,
  }) async {
    final queryParams = <String>[];
    if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');
    if (category != null && category != 'ALL') queryParams.add('category=$category');
    if (status != null && status != 'ALL' && status.isNotEmpty) queryParams.add('status=$status');
    if (balanceType != null && balanceType != 'ALL') queryParams.add('balanceType=$balanceType');

    final endpoint = queryParams.isEmpty
        ? ApiConfig.customers
        : '${ApiConfig.customers}?${queryParams.join('&')}';

    try {
      final res = await _apiClient.get(endpoint);
      final data = (res['data'] is Map<String, dynamic>) ? (res['data'] as Map<String, dynamic>) : <String, dynamic>{};
      final rawList = data['customers'];
      final List<CustomerModel> list = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              list.add(CustomerModel.fromJson(item));
            } catch (err) {
              // Log but don't drop other valid customers
              // ignore: avoid_print
              print('[CustomersRepository] Error parsing customer item: $err');
            }
          }
        }
      }

      final allCount = data['allCount'] != null ? (int.tryParse(data['allCount'].toString()) ?? list.length) : list.length;
      final duesPendingCount = data['duesPendingCount'] != null
          ? (int.tryParse(data['duesPendingCount'].toString()) ?? list.where((c) => c.currentBalance > 0).length)
          : list.where((c) => c.currentBalance > 0).length;
      final settledCount = data['settledCount'] != null
          ? (int.tryParse(data['settledCount'].toString()) ?? list.where((c) => c.currentBalance <= 0).length)
          : list.where((c) => c.currentBalance <= 0).length;

      final totalCount = data['totalCount'] != null ? (int.tryParse(data['totalCount'].toString()) ?? list.length) : list.length;
      final totalReceivable = CustomerModel.parseDouble(data['totalReceivable']);
      final totalPayable = CustomerModel.parseDouble(data['totalPayable']);

      return CustomersResult(
        customers: list,
        totalCount: totalCount,
        allCount: allCount,
        duesPendingCount: duesPendingCount,
        settledCount: settledCount,
        totalReceivable: totalReceivable,
        totalPayable: totalPayable,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[CustomersRepository] getCustomers exception: $e');
      return CustomersResult(
        customers: [],
        totalCount: 0,
        allCount: 0,
        duesPendingCount: 0,
        settledCount: 0,
        totalReceivable: 0.0,
        totalPayable: 0.0,
      );
    }
  }

  Future<CustomerModel> getCustomerById(String id) async {
    final res = await _apiClient.get(ApiConfig.customerDetails(id));
    return CustomerModel.fromJson(res['data']);
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    final res = await _apiClient.post(ApiConfig.customers, body: data);
    return CustomerModel.fromJson(res['data']);
  }

  Future<CustomerModel> updateCustomer(String id, Map<String, dynamic> data) async {
    final res = await _apiClient.put(ApiConfig.customerDetails(id), body: data);
    return CustomerModel.fromJson(res['data']);
  }

  Future<void> deleteCustomer(String id) async {
    await _apiClient.delete(ApiConfig.customerDetails(id));
  }

  Future<List<LedgerEntryModel>> getCustomerLedger(String customerId) async {
    try {
      final res = await _apiClient.get(ApiConfig.customerLedger(customerId));
      final list = (res['data'] as List<dynamic>?)
              ?.map((e) => LedgerEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addLedgerEntry(String customerId, Map<String, dynamic> data) async {
    final res = await _apiClient.post(ApiConfig.customerLedger(customerId), body: data);
    return res['data'] ?? {};
  }

  Future<String> sendReminder(String customerId) async {
    final res = await _apiClient.post(ApiConfig.customerReminder(customerId));
    return res['message'] ?? 'Reminder sent successfully';
  }
}
