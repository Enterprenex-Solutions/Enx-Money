const request = require('supertest');
const app = require('../src/app');
const CardModel = require('../src/models/card.model');

describe('ENX Money — User-Specific Cards Security & API Tests', () => {
  let tokenUserA = '';
  let tokenUserB = '';
  let cardUserA = null;

  beforeAll(async () => {
    CardModel._clearStore();

    // 1. Register User A (Revanth)
    const resA = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Revanth Polamreddy',
        email: 'revanth@enxmoney.com',
        phone: '9876543210',
        password: 'Password123!',
      });
    tokenUserA = resA.body.data.accessToken;

    // 2. Register User B (Sarah Connor)
    const resB = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Sarah Connor',
        email: 'sarah.connor@enxmoney.com',
        phone: '9876543211',
        password: 'Password123!',
      });
    tokenUserB = resB.body.data.accessToken;
  });

  describe('1. Authentication & Security Enforcement', () => {
    it('should reject unauthenticated GET /api/cards with 401', async () => {
      const res = await request(app).get('/api/cards');
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should reject unauthenticated GET /api/cards/me with 401', async () => {
      const res = await request(app).get('/api/cards/me');
      expect(res.statusCode).toBe(401);
    });

    it('should return empty cards list for new user without cards', async () => {
      const res = await request(app)
        .get('/api/cards/me')
        .set('Authorization', `Bearer ${tokenUserA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.cards).toEqual([]);
      expect(res.body.data.count).toBe(0);
    });
  });

  describe('2. User Card Creation & Dynamic Ownership', () => {
    it('should create a new card for User A with their profile name', async () => {
      const res = await request(app)
        .post('/api/cards')
        .set('Authorization', `Bearer ${tokenUserA}`)
        .send({
          cardTier: 'Black Metal',
          network: 'Visa',
          limit: 500000.0,
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.card).toBeDefined();
      expect(res.body.data.card.cardHolderName).toBe('REVANTH POLAMREDDY');
      expect(res.body.data.card.cardTier).toBe('Black Metal');
      expect(res.body.data.card.isFrozen).toBe(false);
      cardUserA = res.body.data.card;
    });

    it('GET /api/cards/me should return only User A\'s newly created card', async () => {
      const res = await request(app)
        .get('/api/cards/me')
        .set('Authorization', `Bearer ${tokenUserA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.cards.length).toBe(1);
      expect(res.body.data.cards[0].id).toBe(cardUserA.id);
      expect(res.body.data.cards[0].cardHolderName).toBe('REVANTH POLAMREDDY');
    });
  });

  describe('3. Strict User Isolation & Cross-User Security', () => {
    it('User B should see 0 cards and NOT see User A\'s card', async () => {
      const res = await request(app)
        .get('/api/cards/me')
        .set('Authorization', `Bearer ${tokenUserB}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.cards.length).toBe(0);
    });

    it('User B should be blocked (404) from toggling freeze on User A\'s card', async () => {
      const res = await request(app)
        .patch(`/api/cards/${cardUserA.id}/freeze`)
        .set('Authorization', `Bearer ${tokenUserB}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('User B should be blocked (404) from updating controls on User A\'s card', async () => {
      const res = await request(app)
        .patch(`/api/cards/${cardUserA.id}/controls`)
        .set('Authorization', `Bearer ${tokenUserB}`)
        .send({ isContactlessActive: false });

      expect(res.statusCode).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });

  describe('4. Card Controls by Authorized Owner', () => {
    it('User A should be able to toggle freeze on their own card', async () => {
      const res = await request(app)
        .patch(`/api/cards/${cardUserA.id}/freeze`)
        .set('Authorization', `Bearer ${tokenUserA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.card.isFrozen).toBe(true);
    });

    it('User A should be able to update card controls on their own card', async () => {
      const res = await request(app)
        .patch(`/api/cards/${cardUserA.id}/controls`)
        .set('Authorization', `Bearer ${tokenUserA}`)
        .send({ isContactlessActive: false, isInternationalActive: true });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.card.isContactlessActive).toBe(false);
      expect(res.body.data.card.isInternationalActive).toBe(true);
    });

    it('User B creating a card should receive a card under Sarah Connor', async () => {
      const res = await request(app)
        .post('/api/cards')
        .set('Authorization', `Bearer ${tokenUserB}`)
        .send({
          cardTier: 'Platinum',
          network: 'Mastercard',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.data.card.cardHolderName).toBe('SARAH CONNOR');
      expect(res.body.data.card.network).toBe('Mastercard');
    });
  });
});
