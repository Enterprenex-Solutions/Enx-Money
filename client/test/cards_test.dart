import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/cards/models/card_model.dart';

void main() {
  group('UserCard Model Tests', () {
    test('1. UserCard fromJson parses dynamic user card data correctly', () {
      final json = {
        'id': 'card_test_123',
        'cardHolderName': 'REVANTH POLAMREDDY',
        'cardNumber': '4532  1234  5678  9012',
        'lastFourDigits': '9012',
        'expiryDate': '08/31',
        'cvv': '999',
        'cardTier': 'Black Metal',
        'network': 'Visa',
        'balance': 250000.0,
        'limit': 1000000.0,
        'spentThisMonth': 45000.0,
        'isFrozen': false,
        'isBlackEdition': true,
        'isContactlessActive': true,
        'isInternationalActive': true,
      };

      final card = UserCard.fromJson(json);

      expect(card.id, 'card_test_123');
      expect(card.cardHolderName, 'REVANTH POLAMREDDY');
      expect(card.lastFourDigits, '9012');
      expect(card.cardTier, 'Black Metal');
      expect(card.limit, 1000000.0);
      expect(card.isInternationalActive, true);
    });

    test('2. UserCard toJson serializes correctly', () {
      const card = UserCard(
        id: 'card_abc',
        cardHolderName: 'ALEX MORGAN',
        cardNumber: '4532  0000  1111  2222',
        lastFourDigits: '2222',
        expiryDate: '11/30',
        cvv: '777',
        cardTier: 'Platinum',
        network: 'Mastercard',
        balance: 50000.0,
        limit: 200000.0,
        spentThisMonth: 10000.0,
        isFrozen: true,
        isBlackEdition: false,
        isContactlessActive: false,
        isInternationalActive: false,
      );

      final json = card.toJson();

      expect(json['id'], 'card_abc');
      expect(json['cardHolderName'], 'ALEX MORGAN');
      expect(json['isFrozen'], true);
      expect(json['network'], 'Mastercard');
    });

    test('3. UserCard copyWith updates freeze state and controls', () {
      const card = UserCard(
        id: 'card_xyz',
        cardHolderName: 'REVANTH POLAMREDDY',
        cardNumber: '4532  9999  8888  7777',
        lastFourDigits: '7777',
        expiryDate: '01/30',
        cvv: '555',
        cardTier: 'Black Metal',
        network: 'Visa',
        balance: 100000.0,
        limit: 500000.0,
        spentThisMonth: 0.0,
      );

      final frozenCard = card.copyWith(isFrozen: true);
      expect(frozenCard.isFrozen, true);
      expect(frozenCard.cardHolderName, 'REVANTH POLAMREDDY');

      final unfrozenCard = frozenCard.copyWith(isFrozen: false, isContactlessActive: false);
      expect(unfrozenCard.isFrozen, false);
      expect(unfrozenCard.isContactlessActive, false);
    });
  });
}
