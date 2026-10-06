import 'package:flutter/material.dart';

enum FinanceMode { business, personal }

/// Centralized Singleton State Manager for Application Finance Mode (Business vs Personal)
class FinanceModeService extends ChangeNotifier {
  static final FinanceModeService _instance = FinanceModeService._internal();
  static FinanceModeService get instance => _instance;
  factory FinanceModeService() => _instance;

  FinanceModeService._internal();

  FinanceMode _currentMode = FinanceMode.business;

  FinanceMode get currentMode => _currentMode;
  FinanceMode get mode => _currentMode;
  bool get isBusiness => _currentMode == FinanceMode.business;
  bool get isPersonal => _currentMode == FinanceMode.personal;

  void setMode(FinanceMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();
  }

  void toggleMode() {
    setMode(_currentMode == FinanceMode.business ? FinanceMode.personal : FinanceMode.business);
  }
}
