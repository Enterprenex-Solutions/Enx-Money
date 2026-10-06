const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class LoanReminderModel {
  static _format(row) {
    if (!row) return null;
    return {
      id: row.id,
      loanId: row.loan_id || row.loanId,
      scheduleId: row.schedule_id || row.scheduleId,
      userId: row.user_id || row.userId,
      reminderType: row.reminder_type || row.reminderType,
      channel: row.channel,
      emiAmount: parseFloat(row.emi_amount || row.emiAmount),
      dueDate: row.due_date || row.dueDate,
      sentDate: row.sent_date || row.sentDate,
      status: row.status,
      message: row.message,
      createdAt: row.created_at || row.createdAt,
    };
  }

  /**
   * Create a new reminder record
   */
  static async create({
    loanId,
    scheduleId,
    userId,
    reminderType,
    channel = 'EMAIL',
    emiAmount,
    dueDate,
    sentDate,
    status = 'SENT',
    message = null,
  }) {
    const id = generateUuid();
    const now = new Date();
    const formattedSentDate = sentDate || now.toISOString().split('T')[0];

    if (db.isConnected()) {
      const sql = `
        INSERT INTO loan_reminders (
          id, loan_id, schedule_id, user_id, reminder_type, channel,
          emi_amount, due_date, sent_date, status, message, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      await db.query(sql, [
        id,
        loanId,
        scheduleId,
        userId,
        reminderType,
        channel,
        parseFloat(emiAmount),
        dueDate,
        formattedSentDate,
        status,
        message,
        now,
      ]);
      return this.findById(id);
    }

    // In-memory fallback
    const record = {
      id,
      loanId,
      scheduleId,
      userId,
      reminderType,
      channel,
      emiAmount: parseFloat(emiAmount),
      dueDate,
      sentDate: formattedSentDate,
      status,
      message,
      createdAt: now,
    };
    db.inMemoryStore.loanReminders.set(id, record);
    return this._format(record);
  }

  /**
   * Find reminder by ID
   */
  static async findById(id) {
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM loan_reminders WHERE id = ? LIMIT 1', [id]);
      return rows[0] ? this._format(rows[0]) : null;
    }
    const record = db.inMemoryStore.loanReminders.get(id);
    return record ? this._format(record) : null;
  }

  /**
   * Check if a reminder of the given type was already sent for this installment on this sentDate
   */
  static async findExisting({ scheduleId, reminderType, sentDate }) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM loan_reminders WHERE schedule_id = ? AND reminder_type = ? AND sent_date = ? LIMIT 1',
        [scheduleId, reminderType, sentDate]
      );
      return rows[0] ? this._format(rows[0]) : null;
    }

    for (const record of db.inMemoryStore.loanReminders.values()) {
      if (
        record.scheduleId === scheduleId &&
        record.reminderType === reminderType &&
        record.sentDate === sentDate
      ) {
        return this._format(record);
      }
    }
    return null;
  }

  /**
   * Find all reminders for a user
   */
  static async findByUserId(userId, limit = 50) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM loan_reminders WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
        [userId, limit]
      );
      return rows.map((r) => this._format(r));
    }

    const list = Array.from(db.inMemoryStore.loanReminders.values()).filter(
      (r) => r.userId === userId
    );
    list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return list.slice(0, limit).map((r) => this._format(r));
  }
}

module.exports = LoanReminderModel;
