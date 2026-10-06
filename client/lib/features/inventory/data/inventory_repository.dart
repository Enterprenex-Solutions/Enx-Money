import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

class InventoryRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ProductModel>> getProducts() async {
    final res = await _apiClient.get('/inventory/products');
    final data = res['data'];
    if (data is Map && data['products'] is List) {
      return (data['products'] as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    final res = await _apiClient.post('/inventory/products', body: body);
    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : body;
    return ProductModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getInventorySummary() async {
    try {
      final res = await _apiClient.get('/inventory/summary');
      if (res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final res = await _apiClient.delete('/inventory/products/$id');
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
