const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class UserModel {
  /**
   * Find user by email
   */
  static async findByEmail(email) {
    if (!email) return null;
    const normalizedEmail = email.toLowerCase().trim();
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM users WHERE LOWER(email) = ? LIMIT 1', [normalizedEmail]);
      return rows[0] || null;
    }
    // In-memory fallback: direct get first, then case-insensitive scan
    const direct = db.inMemoryStore.users.get(normalizedEmail);
    if (direct) return direct;
    for (const [key, user] of db.inMemoryStore.users.entries()) {
      if (key.toLowerCase().trim() === normalizedEmail || (user.email && user.email.toLowerCase().trim() === normalizedEmail)) {
        return user;
      }
    }
    return null;
  }

  /**
   * Find user by phone number
   */
  static async findByPhone(phone) {
    if (!phone) return null;
    return this.findByIdentifier(phone);
  }

  /**
   * Find user by email or phone
   */
  static async findByIdentifier(identifier) {
    if (!identifier) return null;
    const input = identifier.toLowerCase().trim();
    const cleanDigits = identifier.replace(/\D/g, '');

    if (db.isConnected()) {
      // 1. Direct match on email or phone
      let rows = await db.query(
        'SELECT * FROM users WHERE LOWER(email) = ? OR phone = ? LIMIT 1',
        [input, input]
      );
      if (rows[0]) return rows[0];

      // 2. Match last 10 digits of phone number if numeric input
      if (cleanDigits.length >= 10) {
        const last10 = cleanDigits.slice(-10);
        rows = await db.query(
          `SELECT * FROM users 
           WHERE REPLACE(REPLACE(REPLACE(REPLACE(phone, ' ', ''), '+', ''), '-', ''), '(', '') LIKE ?
           LIMIT 1`,
          [`%${last10}`]
        );
        if (rows[0]) return rows[0];
      }
      return null;
    }

    // In-memory fallback
    for (const user of db.inMemoryStore.users.values()) {
      const userPhoneDigits = (user.phone || '').replace(/\D/g, '');
      if (user.email.toLowerCase() === input || user.phone === input) return user;
      if (cleanDigits.length >= 10 && userPhoneDigits.endsWith(cleanDigits.slice(-10))) return user;
    }
    return null;
  }

  /**
   * Find user by ID
   */
  static async findById(id) {
    if (id === null || id === undefined) return null;
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
      return rows[0] || null;
    }
    // In-memory fallback
    for (const user of db.inMemoryStore.users.values()) {
      if (String(user.id) === String(id)) return user;
    }
    return null;
  }

  /**
   * Create a new user (or reuse existing account if already present)
   */
  static async create({ email, name = null, phone = null, passwordHash = null, isBiometricEnabled = false, isEmailVerified = false }) {
    const normalizedEmail = email.toLowerCase().trim();
    const normalizedPhone = phone ? phone.trim() : null;
    const now = new Date();
    const verified = Boolean(isEmailVerified);

    // Check if account already exists to guarantee user_id is never duplicated
    const existing = await this.findByEmail(normalizedEmail);
    if (existing) {
      await this.updateUserDetails(existing.id, {
        name: name || existing.name,
        phone: normalizedPhone || existing.phone,
        passwordHash: passwordHash || existing.password_hash || existing.passwordHash,
        isBiometricEnabled: isBiometricEnabled !== undefined ? isBiometricEnabled : existing.is_biometric_enabled,
      });
      if (verified) {
        await this.setEmailVerified(existing.id);
      }
      return this.findById(existing.id);
    }

    const id = generateUuid();

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO users (id, email, name, phone, password_hash, is_biometric_enabled, status, is_email_verified, last_login_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?)`,
        [id, normalizedEmail, name, normalizedPhone, passwordHash, Boolean(isBiometricEnabled), verified, now, now, now]
      );
      const createdUser = await this.findById(id);
      if (createdUser) {
        db.inMemoryStore.users.set(normalizedEmail, createdUser);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
      }
      return createdUser;
    }

    // In-memory fallback
    const user = {
      id,
      email: normalizedEmail,
      name,
      phone: normalizedPhone,
      password_hash: passwordHash,
      passwordHash,
      role: (process.env.ADMIN_EMAIL && normalizedEmail === process.env.ADMIN_EMAIL.toLowerCase().trim()) ? 'admin' : 'user',
      is_biometric_enabled: Boolean(isBiometricEnabled),
      isBiometricEnabled: Boolean(isBiometricEnabled),
      status: 'ACTIVE',
      is_email_verified: verified,
      isEmailVerified: verified,
      kyc_tier: verified ? 'VERIFIED' : 'NOT VERIFIED',
      last_login_at: now,
      created_at: now,
      updated_at: now,
    };
    db.inMemoryStore.users.set(normalizedEmail, user);
    if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
    return user;
  }

  /**
   * Set user role (e.g. 'admin' or 'user')
   */
  static async setUserRole(id, role = 'user') {
    const now = new Date();
    const cleanRole = role === 'admin' ? 'admin' : 'user';
    if (db.isConnected()) {
      await db.query('UPDATE users SET role = ?, updated_at = ? WHERE id = ?', [cleanRole, now, id]);
      return this.findById(id);
    }
    for (const [email, user] of db.inMemoryStore.users.entries()) {
      if (String(user.id) === String(id)) {
        user.role = cleanRole;
        user.updated_at = now;
        db.inMemoryStore.users.set(email, user);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
        return user;
      }
    }
    return null;
  }

  /**
   * Update email verification status in database and in-memory store
   */
  static async setEmailVerified(id, isVerified = true) {
    const now = new Date();
    const verified = Boolean(isVerified);

    if (db.isConnected()) {
      await db.query('UPDATE users SET is_email_verified = ?, updated_at = ? WHERE id = ?', [verified, now, id]);
      const updated = await this.findById(id);
      if (updated && updated.email) {
        db.inMemoryStore.users.set(updated.email.toLowerCase().trim(), updated);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
      }
      return updated;
    }

    // In-memory fallback
    for (const [email, user] of db.inMemoryStore.users.entries()) {
      if (String(user.id) === String(id)) {
        user.is_email_verified = verified;
        user.isEmailVerified = verified;
        user.kyc_tier = verified ? 'VERIFIED' : 'NOT VERIFIED';
        user.updated_at = now;
        db.inMemoryStore.users.set(email, user);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
        return user;
      }
    }
    return null;
  }

  /**
   * Update full user details (e.g. completing registration after OTP)
   */
  static async updateUserDetails(id, { name, phone, passwordHash, isBiometricEnabled, securityQuestions }) {
    const now = new Date();
    if (db.isConnected()) {
      const fields = [];
      const values = [];

      if (name !== undefined) { fields.push('name = ?'); values.push(name); }
      if (phone !== undefined) { fields.push('phone = ?'); values.push(phone); }
      if (passwordHash !== undefined) { fields.push('password_hash = ?'); values.push(passwordHash); }
      if (isBiometricEnabled !== undefined) { fields.push('is_biometric_enabled = ?'); values.push(Boolean(isBiometricEnabled)); }
      if (securityQuestions !== undefined) {
        fields.push('security_questions = ?');
        values.push(JSON.stringify(securityQuestions));
      }

      fields.push('updated_at = ?');
      values.push(now);
      values.push(id);

      try {
        await db.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);
      } catch (_) {}
      const updated = await this.findById(id);
      if (updated && updated.email) {
        if (securityQuestions !== undefined) updated.securityQuestions = securityQuestions;
        db.inMemoryStore.users.set(updated.email.toLowerCase().trim(), updated);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
      }
      return updated;
    }

    // In-memory fallback
    for (const [email, user] of db.inMemoryStore.users.entries()) {
      if (String(user.id) === String(id)) {
        if (name !== undefined) user.name = name;
        if (phone !== undefined) user.phone = phone;
        if (passwordHash !== undefined) { user.password_hash = passwordHash; user.passwordHash = passwordHash; }
        if (isBiometricEnabled !== undefined) { user.is_biometric_enabled = Boolean(isBiometricEnabled); user.isBiometricEnabled = Boolean(isBiometricEnabled); }
        if (securityQuestions !== undefined) {
          user.security_questions = securityQuestions;
          user.securityQuestions = securityQuestions;
        }
        user.updated_at = now;
        db.inMemoryStore.users.set(email, user);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
        return user;
      }
    }
    return null;
  }

  /**
   * Update user last login timestamp
   */
  static async updateLastLogin(id) {
    const now = new Date();
    if (db.isConnected()) {
      await db.query('UPDATE users SET last_login_at = ?, updated_at = ? WHERE id = ?', [now, now, id]);
      return this.findById(id);
    }

    // In-memory fallback
    for (const [email, user] of db.inMemoryStore.users.entries()) {
      if (String(user.id) === String(id)) {
        user.last_login_at = now;
        user.updated_at = now;
        db.inMemoryStore.users.set(email, user);
        return user;
      }
    }
    return null;
  }

  /**
   * Update user phone number
   */
  static async updatePhone(id, phone) {
    const now = new Date();
    if (db.isConnected()) {
      await db.query('UPDATE users SET phone = ?, updated_at = ? WHERE id = ?', [phone, now, id]);
      const updated = await this.findById(id);
      if (updated && updated.email) {
        db.inMemoryStore.users.set(updated.email.toLowerCase().trim(), updated);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
      }
      return updated;
    }

    // In-memory fallback
    for (const [email, user] of db.inMemoryStore.users.entries()) {
      if (String(user.id) === String(id)) {
        user.phone = phone;
        user.updated_at = now;
        db.inMemoryStore.users.set(email, user);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
        return user;
      }
    }
    return null;
  }

  /**
   * Delete or anonymize user account and personal data (Google Play Policy Compliance)
   */
  static async deleteUser(id) {
    const now = new Date();
    const strId = String(id);

    // Purge associated business data from in-memory resilience stores
    for (const [key, cust] of db.inMemoryStore.customers.entries()) {
      if (String(cust.userId) === strId) db.inMemoryStore.customers.delete(key);
    }
    for (const [key, supp] of db.inMemoryStore.suppliers.entries()) {
      if (String(supp.userId) === strId) db.inMemoryStore.suppliers.delete(key);
    }
    for (const [key, prod] of db.inMemoryStore.products.entries()) {
      if (String(prod.userId) === strId) db.inMemoryStore.products.delete(key);
    }
    for (const [key, inv] of db.inMemoryStore.invoices.entries()) {
      if (String(inv.userId) === strId) db.inMemoryStore.invoices.delete(key);
    }
    for (const [key, tx] of db.inMemoryStore.transactions.entries()) {
      if (String(tx.userId) === strId) db.inMemoryStore.transactions.delete(key);
    }
    for (const [key, entry] of db.inMemoryStore.khataEntries.entries()) {
      if (String(entry.userId) === strId) db.inMemoryStore.khataEntries.delete(key);
    }
    for (const [key, po] of db.inMemoryStore.purchaseOrders.entries()) {
      if (String(po.userId) === strId) db.inMemoryStore.purchaseOrders.delete(key);
    }
    for (const [key, dev] of db.inMemoryStore.devices.entries()) {
      if (String(dev.user_id || dev.userId) === strId) db.inMemoryStore.devices.delete(key);
    }

    if (db.isConnected()) {
      try {
        await db.query(`DELETE FROM customers WHERE user_id = ?`, [id]);
        await db.query(`DELETE FROM suppliers WHERE user_id = ?`, [id]);
        await db.query(`DELETE FROM transactions WHERE user_id = ?`, [id]);
        await db.query(`DELETE FROM devices WHERE user_id = ?`, [id]);
        await db.query(
          `UPDATE users SET status = 'DELETED', name = 'Deleted User', email = CONCAT('deleted_', id, '@deleted.enxmoney.local'), phone = NULL, password_hash = 'DELETED', updated_at = ? WHERE id = ?`,
          [now, id]
        );
      } catch (err) {
        console.warn('[UserModel] Error during MySQL account deletion purge:', err.message);
      }
      for (const [email, user] of db.inMemoryStore.users.entries()) {
        if (String(user.id) === strId) {
          db.inMemoryStore.users.delete(email);
          break;
        }
      }
      if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
      return true;
    }

    // In-memory fallback
    for (const [email, user] of db.inMemoryStore.users.entries()) {
      if (String(user.id) === strId) {
        db.inMemoryStore.users.delete(email);
        user.status = 'DELETED';
        user.name = 'Deleted User';
        user.phone = null;
        user.password_hash = 'DELETED';
        user.passwordHash = 'DELETED';
        user.updated_at = now;
        db.inMemoryStore.users.set(`deleted_${id}@deleted.enxmoney.local`, user);
        if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
        return true;
      }
    }
    if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
    return false;
  }
}

module.exports = UserModel;
