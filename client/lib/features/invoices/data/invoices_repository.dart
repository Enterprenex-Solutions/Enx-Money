import '../../../../core/network/api_client.dart';
import '../models/invoice_model.dart';

class InvoicesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<InvoiceModel>> getInvoices() async {
    final res = await _apiClient.get('/invoices');
    final data = res['data'];
    if (data is List) {
      return data.map((json) => InvoiceModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<InvoiceModel> createInvoice(Map<String, dynamic> body) async {
    final res = await _apiClient.post('/invoices', body: body);
    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : body;
    return InvoiceModel.fromJson(data);
  }
}
