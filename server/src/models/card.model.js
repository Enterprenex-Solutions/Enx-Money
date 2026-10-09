const crypto = require('crypto');
const uuidv4 = () => crypto.randomUUID();

// In-Memory User Card Store (keyed by card ID)
const _cardsStore = new Map();

class CardModel {
  /**
   * Find all cards belonging strictly to a specific user
   */
  static async findByUserId(userId) {
    const userCards = [];
    for (const card of _cardsStore.values()) {
      if (card.userId === userId) {
        userCards.push({ ...card });
      }
    }
    // Sort newest first
    return userCards.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  /**
   * Find a card by ID and verify ownership
   */
  static async findByIdAndUser(cardId, userId) {
    const card = _cardsStore.get(cardId);
    if (!card || card.userId !== userId) {
      return null;
    }
    return { ...card };
  }

  /**
   * Create a new card for the authenticated user
   */
  static async createCard({
    userId,
    cardHolderName,
    cardTier = 'Black Metal',
    network = 'Visa',
    limit = 500000.00,
    balance = 150000.00,
  }) {
    // Generate realistic formatted 16-digit card number
    const prefix = network === 'Mastercard' ? '5' : '4';
    const randPart = () => Math.floor(1000 + Math.random() * 9000).toString();
    const p1 = `${prefix}${Math.floor(100 + Math.random() * 900)}`;
    const p2 = randPart();
    const p3 = randPart();
    const p4 = randPart();
    const futureYear = (new Date().getFullYear() + 3).toString().slice(-2);
    const futureMonth = String(new Date().getMonth() + 1).padStart(2, '0');
    const expiryDate = `${futureMonth}/${futureYear}`;

    // Under RBI Card-on-File Tokenization (CoFT) and DPDP Act 2023 Section 8(5),
    // CVV must NEVER be stored in memory or persistent storage.
    // Full 16-digit card numbers must be masked, providing a secure token reference.
    const maskedCardNumber = `${prefix}•••  ••••  ••••  ${p4}`;
    const tokenRef = `tok_card_${uuidv4().replace(/-/g, '').slice(0, 16)}`;

    const card = {
      id: `card_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
      userId,
      cardHolderName: (cardHolderName || 'ENX MEMBER').toUpperCase().trim(),
      cardNumber: maskedCardNumber,
      lastFourDigits: p4,
      tokenRef,
      expiryDate,
      cardTier,
      network,
      balance: Number(balance),
      limit: Number(limit),
      spentThisMonth: 0.00,
      isFrozen: false,
      isBlackEdition: cardTier.toLowerCase().includes('black'),
      isContactlessActive: true,
      isInternationalActive: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    _cardsStore.set(card.id, card);
    return { ...card };
  }

  /**
   * Toggle card freeze state with ownership verification
   */
  static async toggleFreeze(cardId, userId) {
    const card = _cardsStore.get(cardId);
    if (!card || card.userId !== userId) {
      return null;
    }
    card.isFrozen = !card.isFrozen;
    card.updatedAt = new Date().toISOString();
    _cardsStore.set(card.id, card);
    return { ...card };
  }

  /**
   * Update contactless & international controls with ownership verification
   */
  static async updateControls(cardId, userId, { isContactlessActive, isInternationalActive }) {
    const card = _cardsStore.get(cardId);
    if (!card || card.userId !== userId) {
      return null;
    }
    if (typeof isContactlessActive === 'boolean') {
      card.isContactlessActive = isContactlessActive;
    }
    if (typeof isInternationalActive === 'boolean') {
      card.isInternationalActive = isInternationalActive;
    }
    card.updatedAt = new Date().toISOString();
    _cardsStore.set(card.id, card);
    return { ...card };
  }

  /**
   * DPDP Act 2023 Section 12 (Right to Erasure):
   * Purge all cards belonging to the deleted user
   */
  static async purgeByUserId(userId) {
    for (const [id, card] of _cardsStore.entries()) {
      if (card.userId === userId) {
        _cardsStore.delete(id);
      }
    }
  }

  /**
   * Helper for tests to clear store
   */
  static _clearStore() {
    _cardsStore.clear();
  }
}

module.exports = CardModel;
