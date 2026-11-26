const request = require('supertest');
const app = require('../src/app');

describe('Business Expense Security Regression Tests', () => {
  test('Missing authentication token should return 401', async () => {
    const res = await request(app)
      .get('/api/v1/expenses');

    expect(res.statusCode).toBe(401);
  });

  test('Invalid authentication token should return 401', async () => {
    const res = await request(app)
      .get('/api/v1/expenses')
      .set('Authorization', 'Bearer invalid-test-token');

    expect(res.statusCode).toBe(401);
  });
});

const TokenService = require('../src/services/token.service');
const FinanceProfileModel = require('../src/models/financeProfile.model');

describe('Expense Account Ownership Validation', () => {
  test('Expense must reject an account belonging to another user', async () => {
    const token = TokenService.signAccessToken({
      id: 99992,
      email: 'expense.security@example.com',
    });

    const account = await FinanceProfileModel.createAccount(99993, {
      mode: 'BUSINESS',
      accountName: 'Security Test Account',
      accountType: 'Bank',
      balance: 10000,
    });

    const res = await request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Ownership Regression Test',
        amount: 1000,
        category: 'Office Supplies & Equipment',
        accountId: account.id,
        status: 'PAID',
        mode: 'BUSINESS',
      });

    const updatedAccount =
      await FinanceProfileModel.getAccountById(account.id, 99993);

    expect({
      status: res.statusCode,
      balance: updatedAccount.balance,
    }).toEqual({
      status: 400,
      balance: 10000,
    });
  });
});

describe('Additional Expense Account Validation', () => {
  const userId = 99994;
  let token;
  let account;

  beforeEach(async () => {
    token = TokenService.signAccessToken({
      id: userId,
      email: 'validation.test@example.com',
    });

    account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });
  });

  function createExpense(accountId) {
    return request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Account Validation Test',
        amount: 1000,
        category: 'Office Supplies & Equipment',
        accountId,
        status: 'PAID',
        mode: 'BUSINESS',
      });
  }

  test('Non-existent account must be rejected', async () => {
    const res = await createExpense('non-existent-test-account');
    expect(res.statusCode).toBe(400);
  });

  test('Inactive account must be rejected', async () => {
    account.status = 'INACTIVE';

    const res = await createExpense(account.id);

    expect(res.statusCode).toBe(400);
    expect(account.balance).toBe(10000);
  });

  test('Personal account cannot fund a business expense', async () => {
    const personalAccount = await FinanceProfileModel.createAccount(userId, {
      mode: 'PERSONAL',
      accountType: 'Bank',
      balance: 10000,
    });

    const res = await createExpense(personalAccount.id);

    expect(res.statusCode).toBe(400);
    expect(personalAccount.balance).toBe(10000);
  });

  test('Switching expense to another users account must be rejected', async () => {
    const otherAccount = await FinanceProfileModel.createAccount(99995, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 20000,
    });

    const created = await createExpense(account.id);
    expect(created.statusCode).toBe(201);
    expect(account.balance).toBe(9000);

    const res = await request(app)
      .put(`/api/v1/expenses/${created.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        accountId: otherAccount.id,
        status: 'PAID',
      });

    expect(res.statusCode).toBe(400);
    expect(account.balance).toBe(9000);
    expect(otherAccount.balance).toBe(20000);
  });
});

describe('Expense Transaction Type Validation', () => {
  const TransactionModel = require('../src/models/transaction.model');
  const userId = 99996;
  let token;
  let account;
  let transaction;

  beforeEach(async () => {
    token = TokenService.signAccessToken({
      id: userId,
      email: 'transaction.security@example.com',
    });

    account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    transaction = await TransactionModel.create({
      userId,
      type: 'CREDIT',
      accountType: 'BUSINESS',
      accountId: account.id,
      amount: 1000,
      status: 'PAID',
      category: 'Sales',
    });
  });

  test('Expense API must not update a CREDIT transaction', async () => {
    const res = await request(app)
      .put(`/api/v1/expenses/${transaction.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 2000 });

    const saved = await TransactionModel.findById(transaction.id);

    expect(res.statusCode).toBe(404);
    expect(saved.amount).toBe(1000);
    expect(account.balance).toBe(11000);
  });

  test('Expense API must not delete a CREDIT transaction', async () => {
    const res = await request(app)
      .delete(`/api/v1/expenses/${transaction.id}`)
      .set('Authorization', `Bearer ${token}`);

    const saved = await TransactionModel.findById(transaction.id);

    expect(res.statusCode).toBe(404);
    expect(saved).not.toBeNull();
    expect(account.balance).toBe(11000);
  });
});

describe('Expense Refund Failure Protection', () => {
  const TransactionModel = require('../src/models/transaction.model');

  test('Expense must not be deleted when balance reversal fails', async () => {
    const userId = 99997;

    const token = TokenService.signAccessToken({
      id: userId,
      email: 'refund.test@example.com',
    });

    const account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    const expense = await TransactionModel.create({
      userId,
      type: 'DEBIT',
      accountType: 'BUSINESS',
      accountId: account.id,
      amount: 1000,
      status: 'SETTLED',
    });

    expect(account.balance).toBe(9000);

    const spy = jest
      .spyOn(FinanceProfileModel, 'updateAccountBalance')
      .mockRejectedValueOnce(new Error('Simulated refund failure'));

    try {
      const res = await request(app)
        .delete(`/api/v1/expenses/${expense.id}`)
        .set('Authorization', `Bearer ${token}`);

      const saved = await TransactionModel.findById(expense.id);

      expect({
        status: res.statusCode,
        expenseExists: Boolean(saved),
        balance: account.balance,
      }).toEqual({
        status: 500,
        expenseExists: true,
        balance: 9000,
      });
    } finally {
      spy.mockRestore();
    }
  });
});

describe('Expense Delete Account Validation', () => {
  const TransactionModel = require('../src/models/transaction.model');

  test.each(['ownership', 'mode', 'inactive'])(
    'Delete must reject invalid linked account: %s',
    async (scenario) => {
      const userId = 99998;

      const token = TokenService.signAccessToken({
        id: userId,
        email: 'delete.validation@example.com',
      });

      const account = await FinanceProfileModel.createAccount(userId, {
        mode: 'BUSINESS',
        accountType: 'Bank',
        balance: 10000,
      });

      const expense = await TransactionModel.create({
        userId,
        type: 'DEBIT',
        accountType: 'BUSINESS',
        accountId: account.id,
        amount: 1000,
        status: 'SETTLED',
      });

      expect(account.balance).toBe(9000);

      if (scenario === 'ownership') {
        account.userId = 99999;
      } else if (scenario === 'mode') {
        account.mode = 'PERSONAL';
      } else {
        account.status = 'INACTIVE';
      }

      const res = await request(app)
        .delete(`/api/v1/expenses/${expense.id}`)
        .set('Authorization', `Bearer ${token}`);

      const saved = await TransactionModel.findById(expense.id);

      expect(res.statusCode).toBe(500);
      expect(saved).not.toBeNull();
      expect(account.balance).toBe(9000);
    }
  );
});

describe('Expense Balance Failure Protection', () => {
  const TransactionModel = require('../src/models/transaction.model');

  let accountA, accountB, token, userId;

  beforeEach(async () => {
    userId = 99996;

    token = TokenService.signAccessToken({
      id: userId,
      email: 'balance.failure@example.com',
    });

    accountA = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });

    accountB = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 20000,
    });
  });

  test('Expense creation must fail when balance deduction fails', async () => {
    const spy = jest
      .spyOn(FinanceProfileModel, 'updateAccountBalance')
      .mockRejectedValueOnce(new Error('Simulated deduction failure'));

    try {
      const res = await request(app)
        .post('/api/v1/expenses')
        .set('Authorization', `Bearer ${token}`)
        .send({
          title: 'Failed Deduction Test',
          amount: 1000,
          category: 'Office Supplies & Equipment',
          accountId: accountA.id,
          status: 'PAID',
          mode: 'BUSINESS',
        });

      expect(accountA.balance).toBe(10000);
      expect(res.statusCode).toBeGreaterThanOrEqual(400);
    } finally {
      spy.mockRestore();
    }
  });

  test('Failed account switch must preserve original expense and balances', async () => {
    const expense = await TransactionModel.create({
      userId,
      type: 'DEBIT',
      accountType: 'BUSINESS',
      accountId: accountA.id,
      amount: 1000,
      status: 'SETTLED',
    });

    const originalUpdate =
      FinanceProfileModel.updateAccountBalance.bind(FinanceProfileModel);

    const spy = jest
      .spyOn(FinanceProfileModel, 'updateAccountBalance')
      .mockImplementation(async (accountId, change) => {
        if (accountId === accountB.id && change < 0) {
          throw new Error('Simulated destination deduction failure');
        }
        return originalUpdate(accountId, change);
      });

    try {
      const res = await request(app)
        .put(`/api/v1/expenses/${expense.id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          accountId: accountB.id,
          amount: 1000,
          status: 'PAID',
        });

      const saved = await TransactionModel.findById(expense.id);

      expect({
        rejected: res.statusCode >= 400,
        accountId: saved.accountId,
        balanceA: accountA.balance,
        balanceB: accountB.balance,
      }).toEqual({
        rejected: true,
        accountId: accountA.id,
        balanceA: 9000,
        balanceB: 20000,
      });
    } finally {
      spy.mockRestore();
    }
  });
});
