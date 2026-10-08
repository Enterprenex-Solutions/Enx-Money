/**
 * ZeroCarbonix EWMS — Configuration Module
 */

module.exports = {
  PORT: process.env.PORT || 4000,
  NODE_ENV: process.env.NODE_ENV || 'development',
  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET || 'zc_jwt_access_super_secret_key_2026_x89a',
  JWT_ACCESS_EXPIRES_IN: '15m',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'zc_jwt_refresh_super_secret_key_2026_k91b',
  JWT_REFRESH_EXPIRES_IN: '30d',
  FIELD_ENCRYPTION_KEY: process.env.FIELD_ENCRYPTION_KEY || '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  DATABASE_URL: process.env.DATABASE_URL || 'postgresql://ewms_admin:ewms_secure_pass_2026@localhost:5432/zerocarbonix_ewms?schema=public',
};
