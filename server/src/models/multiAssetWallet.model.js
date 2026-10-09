const { generateUuid } = require('../utils/crypto.util');

class MultiAssetWalletModel {
  static _wallets = new Map();

  static _getWallet(userId) {
    if (!this._wallets.has(userId)) {
      this._wallets.set(userId, {
        userId,
        fiat: {
          inr: { currency: 'INR', symbol: '₹', balance: 148500.50, accountType: 'Primary Savings Account' },
          usd: { currency: 'USD', symbol: '$', balance: 2450.00, accountType: 'Global Multi-Currency Vault' },
        },
        cbdc: {
          currency: 'e₹',
          name: 'Digital Rupee (RBI CBDC)',
          symbol: 'e₹',
          balance: 15400.00,
          walletId: `CBDC-IND-${Math.floor(100000 + Math.random() * 900000)}`,
          denominations: {
            '2000': 4,
            '500': 10,
            '200': 10,
            '100': 4,
          },
        },
        digitalAssets: {
          gold: {
            name: '24K 99.9% Pure Digital Gold',
            symbol: 'GOLD',
            grams: 14.85,
            liveRatePerGram: 7250.00, // ₹7,250 / gram
            totalValue: 14.85 * 7250.00,
            vaultPartner: 'Augmont Gold / MMTC-PAMP',
          },
          stablecoins: {
            name: 'Regulated USD Stablecoins (USDC)',
            symbol: 'USDC',
            balance: 1250.00,
            exchangeRateInr: 83.50,
            totalValueInr: 1250.00 * 83.50,
          },
        },
        vaults: [
          { id: 'v_emergency', name: 'Emergency Liquid Fund', targetAmount: 100000.00, currentAmount: 65000.00, yieldApy: '7.1% p.a.' },
          { id: 'v_roundup', name: 'Auto Round-Up Savings', targetAmount: 25000.00, currentAmount: 12450.00, yieldApy: '6.5% p.a.' },
        ],
        updatedAt: new Date().toISOString(),
      });
    }
    return this._wallets.get(userId);
  }

  static getWallet(userId) {
    const wallet = this._getWallet(userId);
    // Recalculate live total consolidated portfolio value in INR
    const fiatInr = wallet.fiat.inr.balance;
    const fiatUsdInInr = wallet.fiat.usd.balance * 83.50;
    const cbdcInr = wallet.cbdc.balance;
    const goldInr = wallet.digitalAssets.gold.grams * wallet.digitalAssets.gold.liveRatePerGram;
    const stablecoinsInr = wallet.digitalAssets.stablecoins.balance * wallet.digitalAssets.stablecoins.exchangeRateInr;

    const totalConsolidatedInr = fiatInr + fiatUsdInInr + cbdcInr + goldInr + stablecoinsInr;

    return {
      ...wallet,
      totalConsolidatedInr,
    };
  }

  /**
   * Add Money / Cash-In Portal
   * Methods: 'BANK_UPI_IMPS', 'SALARY_DIRECT', 'CASH_DEPOSIT', 'CARD_GATEWAY', 'GOVT_PAYOUT'
   */
  static addMoney(userId, { method, amount, assetType = 'INR', sourceDetails = {} }) {
    const depositAmount = parseFloat(amount);
    if (isNaN(depositAmount) || depositAmount <= 0) {
      throw new Error('Deposit amount must be a positive valid number.');
    }

    const wallet = this._getWallet(userId);
    const txnId = `DEP-${Date.now().toString(36).toUpperCase()}-${generateUuid().slice(0, 4).toUpperCase()}`;

    if (assetType === 'CBDC') {
      wallet.cbdc.balance += depositAmount;
    } else {
      wallet.fiat.inr.balance += depositAmount;
    }

    wallet.updatedAt = new Date().toISOString();

    return {
      success: true,
      transactionId: txnId,
      method,
      amount: depositAmount,
      assetType,
      newBalance: assetType === 'CBDC' ? wallet.cbdc.balance : wallet.fiat.inr.balance,
      timestamp: new Date().toISOString(),
      status: 'SETTLED',
      receipt: {
        utr: `ENX${Date.now()}`,
        source: sourceDetails.sourceName || method,
        depositType: method,
        fee: 0.00,
      },
    };
  }

  /**
   * Convert between Fiat (INR) and CBDC (Digital Rupee e₹) or Digital Gold
   */
  static convertAssets(userId, { fromAsset, toAsset, amount }) {
    const convAmount = parseFloat(amount);
    if (isNaN(convAmount) || convAmount <= 0) {
      throw new Error('Conversion amount must be a positive number.');
    }

    const wallet = this._getWallet(userId);

    // 1. Fiat INR -> CBDC e₹
    if (fromAsset === 'INR' && toAsset === 'CBDC') {
      if (wallet.fiat.inr.balance < convAmount) {
        throw new Error(`Insufficient INR balance. Available: ₹${wallet.fiat.inr.balance.toFixed(2)}`);
      }
      wallet.fiat.inr.balance -= convAmount;
      wallet.cbdc.balance += convAmount;
    }
    // 2. CBDC e₹ -> Fiat INR
    else if (fromAsset === 'CBDC' && toAsset === 'INR') {
      if (wallet.cbdc.balance < convAmount) {
        throw new Error(`Insufficient Digital Rupee (e₹) balance. Available: e₹${wallet.cbdc.balance.toFixed(2)}`);
      }
      wallet.cbdc.balance -= convAmount;
      wallet.fiat.inr.balance += convAmount;
    }
    // 3. Fiat INR -> 24K Digital Gold
    else if (fromAsset === 'INR' && toAsset === 'GOLD') {
      if (wallet.fiat.inr.balance < convAmount) {
        throw new Error(`Insufficient INR balance. Available: ₹${wallet.fiat.inr.balance.toFixed(2)}`);
      }
      const gramsPurchased = convAmount / wallet.digitalAssets.gold.liveRatePerGram;
      wallet.fiat.inr.balance -= convAmount;
      wallet.digitalAssets.gold.grams += gramsPurchased;
      wallet.digitalAssets.gold.totalValue = wallet.digitalAssets.gold.grams * wallet.digitalAssets.gold.liveRatePerGram;
    } else {
      throw new Error(`Conversion from ${fromAsset} to ${toAsset} is currently not supported.`);
    }

    wallet.updatedAt = new Date().toISOString();

    return {
      success: true,
      conversionId: `CONV-${Date.now().toString(36).toUpperCase()}`,
      fromAsset,
      toAsset,
      amountConverted: convAmount,
      fiatInrBalance: wallet.fiat.inr.balance,
      cbdcBalance: wallet.cbdc.balance,
      goldGrams: wallet.digitalAssets.gold.grams,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * DPDP Act 2023 Section 12 (Right to Erasure):
   * Purge wallet for user
   */
  static purgeUserData(userId) {
    this._wallets.delete(userId);
  }

  static _clearStore() {
    this._wallets.clear();
  }
}

module.exports = MultiAssetWalletModel;
