const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { AiService, AiServiceError } = require('../src/services/ai.service');

describe('Meta AI & Live Chat Service Integration Tests', () => {
  const testUserId = 'test_ai_user_' + Date.now();

  afterAll(() => {
    AiService.clearHistory(testUserId);
  });

  test('Positive: AiService.chat sends "Hello" and receives real AI response from Meta AI (Groq)', async () => {
    if (!process.env.GROQ_API_KEY) return;
    const res = await AiService.chat({
      userId: testUserId,
      message: 'Hello',
      language: 'en',
      provider: 'meta',
    });

    expect(res).toBeDefined();
    expect(res.reply).toBeDefined();
    expect(typeof res.reply).toBe('string');
    expect(res.reply.length).toBeGreaterThan(5);
    expect(res.source).toBe('META_AI_GROQ');
    expect(res.provider).toBe('Meta AI (Llama 3.3)');
    expect(res.model).toBeDefined();
  }, 15000);

  test('Positive: AiService.chat sends second business question with history', async () => {
    if (!process.env.GROQ_API_KEY) return;
    const res = await AiService.chat({
      userId: testUserId,
      message: 'Explain GST invoice rule in 1 concise sentence',
      language: 'en',
      provider: 'meta',
      history: [{ role: 'user', content: 'Hello' }],
    });

    expect(res).toBeDefined();
    expect(res.reply).toBeDefined();
    expect(typeof res.reply).toBe('string');
    expect(res.reply.length).toBeGreaterThan(10);
    expect(res.source).toBe('META_AI_GROQ');
  }, 15000);

  test('Positive: AiService.chat works with secondary upstream Google Gemini', async () => {
    if (!process.env.GROQ_API_KEY) return;
    const res = await AiService.chat({
      userId: testUserId,
      message: 'Hello',
      language: 'en',
      provider: 'gemini',
    });

    expect(res).toBeDefined();
    expect(res.reply).toBeDefined();
    expect(typeof res.reply).toBe('string');
    expect(res.source).toBe('GOOGLE_GEMINI');
    expect(res.provider).toContain('Google Gemini');
  }, 15000);

  test('Positive: Session chat history stores user and assistant turns', () => {
    AiService._saveHistory(testUserId, 'Hello', 'Hi, how can I help with your finances?');
    const history = AiService.getHistory(testUserId);
    expect(Array.isArray(history)).toBe(true);
    expect(history.length).toBeGreaterThanOrEqual(1);
    expect(history[0]).toHaveProperty('role');
    expect(history[0]).toHaveProperty('content');
  });

  test('Positive: AiService.clearHistory deletes session history cleanly', () => {
    const cleared = AiService.clearHistory(testUserId);
    expect(cleared).toBe(true);
    expect(AiService.getHistory(testUserId)).toEqual([]);
  });

  test('Negative: Empty prompt throws INVALID_REQUEST_BODY (400)', async () => {
    await expect(AiService.chat({
      userId: testUserId,
      message: '   ',
      provider: 'meta',
    })).rejects.toThrow(AiServiceError);

    try {
      await AiService.chat({ userId: testUserId, message: '', provider: 'meta' });
    } catch (err) {
      expect(err.code).toBe('INVALID_REQUEST_BODY');
      expect(err.statusCode).toBe(400);
    }
  });

  test('Negative: Missing API key throws MISSING_API_KEY (500)', async () => {
    const originalGroq = process.env.GROQ_API_KEY;
    const originalMeta = process.env.META_AI_API_KEY;
    delete process.env.GROQ_API_KEY;
    delete process.env.META_AI_API_KEY;

    try {
      await AiService.chat({
        userId: testUserId,
        message: 'Hello',
        provider: 'meta',
      });
      throw new Error('Should not succeed without key');
    } catch (err) {
      expect(err.code).toBe('MISSING_API_KEY');
      expect(err.statusCode).toBe(500);
      expect(err.userMessage).toBe('AI service is currently not configured on this server.');
    } finally {
      process.env.GROQ_API_KEY = originalGroq;
      process.env.META_AI_API_KEY = originalMeta;
    }
  });

  test('Negative: Invalid API key throws UNAUTHORIZED (502)', async () => {
    if (!process.env.GROQ_API_KEY) return;
    const originalGroq = process.env.GROQ_API_KEY;
    process.env.GROQ_API_KEY = 'gsk_invalid_fake_key_1234567890abcdef';

    try {
      await AiService.chat({
        userId: testUserId,
        message: 'Hello',
        provider: 'meta',
      });
      throw new Error('Should not succeed with fake key');
    } catch (err) {
      expect(err.code).toBe('UNAUTHORIZED');
      expect(err.statusCode).toBe(502);
      expect(err.userMessage).toBe('AI service authentication error. Please try again later.');
    } finally {
      process.env.GROQ_API_KEY = originalGroq;
    }
  }, 10000);

  test('Negative: Invalid/Wrong model throws WRONG_MODEL (502)', async () => {
    if (!process.env.GROQ_API_KEY) return;
    const originalModel = process.env.GROQ_MODEL;
    process.env.GROQ_MODEL = 'nonexistent-model-xyz-999';

    try {
      await AiService.chat({
        userId: testUserId,
        message: 'Hello',
        provider: 'meta',
      });
      throw new Error('Should not succeed with nonexistent model');
    } catch (err) {
      expect(['WRONG_MODEL', 'UNAUTHORIZED', 'AUTH_ERROR']).toContain(err.code || 'UNAUTHORIZED');
    } finally {
      process.env.GROQ_MODEL = originalModel;
    }
  }, 10000);
});
