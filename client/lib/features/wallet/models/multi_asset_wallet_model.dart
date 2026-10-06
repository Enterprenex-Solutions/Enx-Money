class MultiAssetWalletModel {
  final String userId;
  final double fiatInr;
  final double fiatUsd;
  final double cbdcBalance;
  final String cbdcWalletId;
  final double goldGrams;
  final double goldRatePerGram;
  final double goldTotalValue;
  final double stablecoinsUsdc;
  final double totalConsolidatedInr;
  final List<SavingVaultModel> vaults;

  const MultiAssetWalletModel({
    required this.userId,
    required this.fiatInr,
    required this.fiatUsd,
    required this.cbdcBalance,
    required this.cbdcWalletId,
    required this.goldGrams,
    required this.goldRatePerGram,
    required this.goldTotalValue,
    required this.stablecoinsUsdc,
    required this.totalConsolidatedInr,
    required this.vaults,
  });

  factory MultiAssetWalletModel.fromJson(Map<String, dynamic> json) {
    final fiat = json['fiat'] as Map<String, dynamic>? ?? {};
    final inr = fiat['inr'] as Map<String, dynamic>? ?? {};
    final usd = fiat['usd'] as Map<String, dynamic>? ?? {};
    final cbdc = json['cbdc'] as Map<String, dynamic>? ?? {};
    final da = json['digitalAssets'] as Map<String, dynamic>? ?? {};
    final gold = da['gold'] as Map<String, dynamic>? ?? {};
    final stable = da['stablecoins'] as Map<String, dynamic>? ?? {};
    final rawVaults = json['vaults'] as List<dynamic>? ?? [];

    return MultiAssetWalletModel(
      userId: json['userId']?.toString() ?? '1',
      fiatInr: (inr['balance'] as num?)?.toDouble() ?? 148500.50,
      fiatUsd: (usd['balance'] as num?)?.toDouble() ?? 2450.00,
      cbdcBalance: (cbdc['balance'] as num?)?.toDouble() ?? 15400.00,
      cbdcWalletId: cbdc['walletId'] as String? ?? 'CBDC-IND-891024',
      goldGrams: (gold['grams'] as num?)?.toDouble() ?? 14.85,
      goldRatePerGram: (gold['liveRatePerGram'] as num?)?.toDouble() ?? 7250.00,
      goldTotalValue: (gold['totalValue'] as num?)?.toDouble() ?? 107662.50,
      stablecoinsUsdc: (stable['balance'] as num?)?.toDouble() ?? 1250.00,
      totalConsolidatedInr: (json['totalConsolidatedInr'] as num?)?.toDouble() ?? 476188.00,
      vaults: rawVaults.map((v) => SavingVaultModel.fromJson(v as Map<String, dynamic>)).toList(),
    );
  }
}

class SavingVaultModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String yieldApy;

  const SavingVaultModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.yieldApy,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory SavingVaultModel.fromJson(Map<String, dynamic> json) {
    return SavingVaultModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      yieldApy: json['yieldApy'] as String? ?? '6.5% p.a.',
    );
  }
}
