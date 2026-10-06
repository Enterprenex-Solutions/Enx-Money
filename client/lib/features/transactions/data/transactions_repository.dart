import 'dart:async';
import '../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionsRepository {
  static final TransactionsRepository _instance = TransactionsRepository._internal();
  factory TransactionsRepository() => _instance;
  TransactionsRepository._internal();

  final ApiClient _apiClient = ApiClient();

  /// Fetches transactions from real backend API
  Future<List<TransactionItem>> getTransactions({
    TransactionCategory? category,
    String? query,
    String? mode,
  }) async {
    try {
      final queryParams = <String>[];
      if (query != null && query.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(query)}');
      }
      if (category != null) {
        queryParams.add('category=${category.name}');
      }
      if (mode != null && mode.isNotEmpty) {
        queryParams.add('mode=${Uri.encodeComponent(mode)}');
      }

      final endpoint = queryParams.isEmpty ? '/transactions' : '/transactions?${queryParams.join('&')}';
      final res = await _apiClient.get(endpoint);
      final data = res['data'];

      if (data is List) {
        return data.map((json) => TransactionItem.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map && data['transactions'] is List) {
        return (data['transactions'] as List)
            .map((json) => TransactionItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Creates a new transaction via backend API
  Future<TransactionItem?> createTransaction(Map<String, dynamic> body) async {
    try {
      final res = await _apiClient.post('/transactions', body: body);
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : body;
      return TransactionItem.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
