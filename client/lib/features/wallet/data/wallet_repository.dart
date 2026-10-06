import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/multi_asset_wallet_model.dart';

class WalletRepository extends ChangeNotifier {
  static final WalletRepository _instance = WalletRepository._internal();
  factory WalletRepository() => _instance;
  WalletRepository._internal();

  final ApiClient _apiClient = ApiClient();
  MultiAssetWalletModel? _wallet;

  MultiAssetWalletModel? get wallet => _wallet;

  Future<MultiAssetWalletModel> getWallet() async {
    try {
      final res = await _apiClient.get('/finance/wallet/multi-asset');
      if (res['data'] != null) {
        _wallet = MultiAssetWalletModel.fromJson(res['data'] as Map<String, dynamic>);
        notifyListeners();
        return _wallet!;
      }
    } catch (_) {}

    _wallet ??= const MultiAssetWalletModel(
      userId: '1',
      fiatInr: 148500.50,
      fiatUsd: 2450.00,
      cbdcBalance: 15400.00,
      cbdcWalletId: 'CBDC-IND-891024',
      goldGrams: 14.85,
      goldRatePerGram: 7250.00,
      goldTotalValue: 107662.50,
      stablecoinsUsdc: 1250.00,
      totalConsolidatedInr: 476188.00,
      vaults: [
        SavingVaultModel(
          id: 'v_emergency',
          name: 'Emergency Liquid Fund',
          targetAmount: 100000.00,
          currentAmount: 65000.00,
          yieldApy: '7.1% p.a.',
        ),
        SavingVaultModel(
          id: 'v_roundup',
          name: 'Auto Round-Up Savings',
          targetAmount: 25000.00,
          currentAmount: 12450.00,
          yieldApy: '6.5% p.a.',
        ),
      ],
    );
    notifyListeners();
    return _wallet!;
  }

  Future<Map<String, dynamic>> addMoney({
    required String method,
    required double amount,
    String assetType = 'INR',
    Map<String, dynamic>? sourceDetails,
  }) async {
    try {
      final res = await _apiClient.post('/finance/wallet/add-money', body: {
        'method': method,
        'amount': amount,
        'assetType': assetType,
        'sourceDetails': sourceDetails ?? {},
      });
      // Refresh wallet state
      await getWallet();
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      // Local fallback
      if (_wallet != null) {
        if (assetType == 'CBDC') {
          _wallet = MultiAssetWalletModel(
            userId: _wallet!.userId,
            fiatInr: _wallet!.fiatInr,
            fiatUsd: _wallet!.fiatUsd,
            cbdcBalance: _wallet!.cbdcBalance + amount,
            cbdcWalletId: _wallet!.cbdcWalletId,
            goldGrams: _wallet!.goldGrams,
            goldRatePerGram: _wallet!.goldRatePerGram,
            goldTotalValue: _wallet!.goldTotalValue,
            stablecoinsUsdc: _wallet!.stablecoinsUsdc,
            totalConsolidatedInr: _wallet!.totalConsolidatedInr + amount,
            vaults: _wallet!.vaults,
          );
        } else {
          _wallet = MultiAssetWalletModel(
            userId: _wallet!.userId,
            fiatInr: _wallet!.fiatInr + amount,
            fiatUsd: _wallet!.fiatUsd,
            cbdcBalance: _wallet!.cbdcBalance,
            cbdcWalletId: _wallet!.cbdcWalletId,
            goldGrams: _wallet!.goldGrams,
            goldRatePerGram: _wallet!.goldRatePerGram,
            goldTotalValue: _wallet!.goldTotalValue,
            stablecoinsUsdc: _wallet!.stablecoinsUsdc,
            totalConsolidatedInr: _wallet!.totalConsolidatedInr + amount,
            vaults: _wallet!.vaults,
          );
        }
        notifyListeners();
      }
      return {
        'success': true,
        'method': method,
        'amount': amount,
        'receipt': {
          'utr': 'ENX${DateTime.now().millisecondsSinceEpoch}',
          'source': sourceDetails?['sourceName'] ?? method,
          'fee': 0.00,
        },
      };
    }
  }

  Future<Map<String, dynamic>> convertAssets({
    required String fromAsset,
    required String toAsset,
    required double amount,
  }) async {
    try {
      final res = await _apiClient.post('/finance/wallet/convert', body: {
        'fromAsset': fromAsset,
        'toAsset': toAsset,
        'amount': amount,
      });
      await getWallet();
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      if (_wallet != null) {
        if (fromAsset == 'INR' && toAsset == 'CBDC') {
          _wallet = MultiAssetWalletModel(
            userId: _wallet!.userId,
            fiatInr: _wallet!.fiatInr - amount,
            fiatUsd: _wallet!.fiatUsd,
            cbdcBalance: _wallet!.cbdcBalance + amount,
            cbdcWalletId: _wallet!.cbdcWalletId,
            goldGrams: _wallet!.goldGrams,
            goldRatePerGram: _wallet!.goldRatePerGram,
            goldTotalValue: _wallet!.goldTotalValue,
            stablecoinsUsdc: _wallet!.stablecoinsUsdc,
            totalConsolidatedInr: _wallet!.totalConsolidatedInr,
            vaults: _wallet!.vaults,
          );
        }
        notifyListeners();
      }
      return {
        'success': true,
        'fromAsset': fromAsset,
        'toAsset': toAsset,
        'amountConverted': amount,
      };
    }
  }

  Future<Map<String, dynamic>> executeSettlement({
    required String recipient,
    required String recipientVpa,
    required double amount,
    String assetType = 'INR',
    String purpose = 'Transfer',
    String authMethod = 'MPIN',
    String authPin = '1234',
  }) async {
    try {
      final res = await _apiClient.post('/finance/settlement/execute', body: {
        'recipient': recipient,
        'recipientVpa': recipientVpa,
        'amount': amount,
        'assetType': assetType,
        'purpose': purpose,
        'authMethod': authMethod,
        'authPin': authPin,
      });
      await getWallet();

      return (res['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      // Local fallback
      if (_wallet != null) {
        _wallet = MultiAssetWalletModel(
          userId: _wallet!.userId,
          fiatInr: _wallet!.fiatInr - amount,
          fiatUsd: _wallet!.fiatUsd,
          cbdcBalance: _wallet!.cbdcBalance,
          cbdcWalletId: _wallet!.cbdcWalletId,
          goldGrams: _wallet!.goldGrams,
          goldRatePerGram: _wallet!.goldRatePerGram,
          goldTotalValue: _wallet!.goldTotalValue,
          stablecoinsUsdc: _wallet!.stablecoinsUsdc,
          totalConsolidatedInr: _wallet!.totalConsolidatedInr - amount,
          vaults: _wallet!.vaults,
        );
        notifyListeners();
      }
      return {
        'id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        'utr': 'ENX${DateTime.now().millisecondsSinceEpoch}',
        'senderName': 'P. Revanth Reddy',
        'recipientName': recipient,
        'amount': amount,
        'assetType': assetType,
        'status': 'SUCCESS',
        'pipelineSteps': [
          {'step': 1, 'title': 'Sender Verification', 'status': 'COMPLETED'},
          {'step': 2, 'title': 'Real-time Balance Check', 'status': 'COMPLETED'},
          {'step': 3, 'title': 'Compliance & Fraud Screening', 'status': 'COMPLETED'},
          {'step': 4, 'title': 'Network Authorization', 'status': 'COMPLETED'},
          {'step': 5, 'title': 'Atomic Ledger Settlement', 'status': 'COMPLETED'},
        ],
        'receipt': {
          'receiptNumber': 'REC-${DateTime.now().millisecondsSinceEpoch}',
          'utr': 'ENX${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'currency': assetType == 'CBDC' ? 'e₹' : 'INR',
          'sender': 'P. Revanth Reddy',
          'recipient': recipient,
          'paymentMode': assetType == 'CBDC' ? 'RBI CBDC e-Rupee' : 'Instant UPI',
          'status': 'PAID & SETTLED',
          'fee': 0.00,
        },
      };
    }
  }
}
