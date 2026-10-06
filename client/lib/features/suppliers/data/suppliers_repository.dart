import '../../../../core/network/api_client.dart';
import '../models/supplier_model.dart';

class SuppliersRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SupplierModel>> getSuppliers() async {
    final res = await _apiClient.get('/suppliers');
    final data = res['data'];
    if (data is List) {
      return data.map((json) => SupplierModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<SupplierModel> createSupplier(Map<String, dynamic> body) async {
    final res = await _apiClient.post('/suppliers', body: body);
    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : body;
    return SupplierModel.fromJson(data);
  }
}
