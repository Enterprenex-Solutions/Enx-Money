import 'package:flutter/foundation.dart';

/// Global event broadcaster for live financial and Khata data synchronization.
/// Triggered whenever a customer, transaction, ledger entry, or invoice is mutated.
class DataSyncService extends ChangeNotifier {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  int _changeCount = 0;
  int get changeCount => _changeCount;

  /// Call after any successful Sale, Payment, Customer creation, or Ledger update
  void notifyDataChanged() {
    _changeCount++;
    notifyListeners();
  }
}
