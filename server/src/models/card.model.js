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
    const cardNumber = `${p1}  ${p2}  ${p3}  ${p4}`;

    // Expiry date (5 years from now)
    const now = new Date();
    const expMonth = String((now.getMonth() + 1)).padStart(2, '0');
    const expYear = String((now.getFullYear() + 5)).slice(-2);
    const expiryDate = `${expMonth}/${expYear}`;

    // CVV
    const cvv = String(Math.floor(100 + Math.random() * 900));

    const card = {
      id: `card_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
      userId,
      cardHolderName: (cardHolderName || 'ENX MEMBER').toUpperCase().trim(),
      cardNumber,
      lastFourDigits: p4,
      expiryDate,
      cvv,
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
   * Helper for tests to clear store
   */
  static _clearStore() {
    _cardsStore.clear();
  }
}

module.exports = CardModel;
