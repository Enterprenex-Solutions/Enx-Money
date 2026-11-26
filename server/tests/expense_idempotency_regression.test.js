const request = require('supertest');
const { randomUUID } = require('crypto');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const FinanceProfileModel = require('../src/models/financeProfile.model');

describe('Expense Idempotency Regression Tests', () => {
  let accountA, accountB, tokenA, tokenB, key;

  beforeEach(async () => {
    key = randomUUID();

    tokenA = TokenService.signAccessToken({
      id: 88001,
      email: 'idempotency.a@example.com',
    });

    tokenB = TokenService.signAccessToken({
      id: 88002,
      email: 'idempotency.b@example.com',
    });

    accountA = await FinanceProfileModel.createAccount(88001, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    accountB = await FinanceProfileModel.createAccount(88002, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 20000,
    });
  });

  function createExpense(token, accountId) {
    const req = request(app)
      .post('/api/v1/expenses')
      .set('Idempotency-Key', key);

    if (token) {
      req.set('Authorization', `Bearer ${token}`);
    }

    return req.send({
      title: 'Idempotency Regression Test',
      amount: 1000,
      category: 'Office Supplies & Equipment',
      accountId,
      status: 'PAID',
      mode: 'BUSINESS',
    });
  }

  test('Duplicate expense request must debit balance only once', async () => {
    const first = await createExpense(tokenA, accountA.id);
    const second = await createExpense(tokenA, accountA.id);

    expect(first.statusCode).toBe(201);
    expect(second.statusCode).toBe(201);
    expect(second.body.data.id).toBe(first.body.data.id);
    expect(accountA.balance).toBe(9000);
  });

  test('Different users must have isolated idempotency caches', async () => {
    const first = await createExpense(tokenA, accountA.id);
    const second = await createExpense(tokenB, accountB.id);

    expect(first.statusCode).toBe(201);
    expect(second.statusCode).toBe(201);
    expect(second.body.data.id).not.toBe(first.body.data.id);
    expect(accountA.balance).toBe(9000);
    expect(accountB.balance).toBe(19000);
  });

  test('Unauthenticated request must not receive cached expense response', async () => {
    const first = await createExpense(tokenA, accountA.id);
    expect(first.statusCode).toBe(201);

    const second = await createExpense(null, accountA.id);

    expect(second.statusCode).toBe(401);
    expect(accountA.balance).toBe(9000);
  });
});

describe('Expense API Alias Security', () => {
  test.each([
    '/expenses',
    '/api/expenses',
    '/v1/expenses',
    '/api/v1/expenses',
    '/api/api/expenses',
    '/v1/v1/expenses',
    '/api/api/v1/expenses',
  ])('Authentication and duplicate protection: %s', async (endpoint) => {
    const key = randomUUID();
    const userId = 88003;

    const token = TokenService.signAccessToken({
      id: userId,
      email: 'alias.test@example.com',
    });

    const account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    const body = {
      title: 'Alias Security Test',
      amount: 1000,
      category: 'Office Supplies & Equipment',
      accountId: account.id,
      status: 'PAID',
      mode: 'BUSINESS',
    };

    const first = await request(app)
      .post(endpoint)
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send(body);

    expect(first.statusCode).toBe(201);

    const retry = await request(app)
      .post(endpoint)
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send(body);

    expect(retry.statusCode).toBe(201);
    expect(retry.body.data.id).toBe(first.body.data.id);

    const unauthorized = await request(app)
      .post(endpoint)
      .set('Idempotency-Key', key)
      .send(body);

    expect(unauthorized.statusCode).toBe(401);
    expect(account.balance).toBe(9000);
  });
});

describe('Cross-alias Expense Idempotency', () => {
  test('Retry through another API alias must not deduct balance twice', async () => {
    const key = randomUUID();
    const userId = 88004;

    const token = TokenService.signAccessToken({
      id: userId,
      email: 'cross.alias@example.com',
    });

    const account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    const body = {
      title: 'Cross Alias Regression Test',
      amount: 1000,
      category: 'Office Supplies & Equipment',
      accountId: account.id,
      status: 'PAID',
      mode: 'BUSINESS',
    };

    const first = await request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send(body);

    expect(first.statusCode).toBe(201);
    expect(account.balance).toBe(9000);

    const retry = await request(app)
      .post('/api/expenses')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send(body);

    expect(retry.statusCode).toBe(201);
    expect(account.balance).toBe(9000);
    expect(retry.body.data.id).toBe(first.body.data.id);
  });
});

describe('Expense Idempotency Payload Validation', () => {
  test('Same key with different expense amount must return 409', async () => {
    const key = randomUUID();
    const userId = 88005;

    const token = TokenService.signAccessToken({
      id: userId,
      email: 'payload.validation@example.com',
    });

    const account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    const body = {
      title: 'Payload Validation Test',
      amount: 1000,
      category: 'Office Supplies & Equipment',
      accountId: account.id,
      status: 'PAID',
      mode: 'BUSINESS',
    };

    const first = await request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send(body);

    expect(first.statusCode).toBe(201);
    expect(account.balance).toBe(9000);

    const second = await request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send({ ...body, amount: 2000 });

    expect(account.balance).toBe(9000);
    expect(second.statusCode).toBe(409);
  });
});

describe('Advanced Expense Idempotency', () => {
  let account, token, key, body;

  beforeEach(async () => {
    key = randomUUID();
    const userId = 88006;

    token = TokenService.signAccessToken({
      id: userId,
      email: 'advanced.idempotency@example.com',
    });

    account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    body = {
      title: 'Advanced Idempotency Test',
      amount: 1000,
      category: 'Office Supplies & Equipment',
      accountId: account.id,
      status: 'PAID',
      mode: 'BUSINESS',
    };
  });

  function submit(payload) {
    return request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', key)
      .send(payload);
  }

  test('Different JSON field order must preserve idempotency', async () => {
    const first = await submit(body);

    const reordered = Object.fromEntries(
      Object.entries(body).reverse()
    );

    const second = await submit(reordered);

    expect(first.statusCode).toBe(201);
    expect(second.statusCode).toBe(201);
    expect(second.body.data.id).toBe(first.body.data.id);
    expect(account.balance).toBe(9000);
  });

  test('Concurrent duplicate requests must debit only once', async () => {
    const responses = await Promise.all(
      Array.from({ length: 5 }, () => submit(body))
    );

    const successful = responses.filter(
      res => res.statusCode === 201
    );

    expect(successful.length).toBeGreaterThanOrEqual(1);

    for (const res of responses) {
      expect([201, 409]).toContain(res.statusCode);
    }

    const ids = new Set(
      successful.map(res => res.body.data.id)
    );

    expect(ids.size).toBe(1);
    expect(account.balance).toBe(9000);
  });
});
