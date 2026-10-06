const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class DeviceModel {
  static _formatDevice(d) {
    if (!d) return null;
    return {
      id: d.id,
      userId: d.user_id || d.userId,
      user_id: d.user_id || d.userId,
      deviceId: d.device_id || d.deviceId,
      device_id: d.device_id || d.deviceId,
      deviceName: d.device_name || d.deviceName,
      device_name: d.device_name || d.deviceName,
      platform: d.platform,
      status: d.status,
      ipAddress: d.ip_address || d.ipAddress,
      ip_address: d.ip_address || d.ipAddress,
      lastActiveAt: d.last_active_at || d.lastActiveAt,
      last_active_at: d.last_active_at || d.lastActiveAt,
      createdAt: d.created_at || d.createdAt,
      created_at: d.created_at || d.createdAt,
    };
  }

  static _formatRequest(r) {
    if (!r) return null;
    return {
      id: r.id,
      userId: r.user_id || r.userId,
      user_id: r.user_id || r.userId,
      deviceId: r.device_id || r.deviceId,
      device_id: r.device_id || r.deviceId,
      deviceName: r.device_name || r.deviceName,
      device_name: r.device_name || r.deviceName,
      platform: r.platform,
      ipAddress: r.ip_address || r.ipAddress,
      ip_address: r.ip_address || r.ipAddress,
      verificationCode: r.verification_code || r.verificationCode,
      verification_code: r.verification_code || r.verificationCode,
      status: r.status,
      expiresAt: r.expires_at || r.expiresAt,
      expires_at: r.expires_at || r.expiresAt,
      createdAt: r.created_at || r.createdAt,
      created_at: r.created_at || r.createdAt,
    };
  }

  /**
   * Get all registered devices for a user
   */
  static async getDevicesByUser(userId) {
    if (!userId) return [];

    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM user_devices WHERE user_id = ? ORDER BY created_at ASC',
        [userId]
      );
      return rows.map((r) => this._formatDevice(r));
    }

    // In-memory fallback
    const list = [];
    for (const d of db.inMemoryStore.devices.values()) {
      if ((d.user_id || d.userId) === userId) {
        list.push(this._formatDevice(d));
      }
    }
    return list.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  }

  /**
   * Get specific device for a user
   */
  static async getDevice(userId, deviceId) {
    if (!userId || !deviceId) return null;

    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM user_devices WHERE user_id = ? AND device_id = ? LIMIT 1',
        [userId, deviceId]
      );
      return rows[0] ? this._formatDevice(rows[0]) : null;
    }

    const key = `${userId}_${deviceId}`;
    const dev = db.inMemoryStore.devices.get(key);
    return dev ? this._formatDevice(dev) : null;
  }

  /**
   * Register or update a device
   */
  static async registerDevice({ userId, deviceId, deviceName, platform, ipAddress, status = 'APPROVED' }) {
    const existing = await this.getDevice(userId, deviceId);
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

    if (existing) {
      if (db.isConnected()) {
        await db.query(
          `UPDATE user_devices 
           SET device_name = ?, platform = ?, status = ?, ip_address = ?, last_active_at = ?
           WHERE user_id = ? AND device_id = ?`,
          [deviceName || existing.device_name, platform || existing.platform, status, ipAddress || existing.ip_address, now, userId, deviceId]
        );
      }
      existing.device_name = deviceName || existing.device_name;
      existing.deviceName = existing.device_name;
      existing.platform = platform || existing.platform;
      existing.status = status;
      existing.ip_address = ipAddress || existing.ip_address;
      existing.ipAddress = existing.ip_address;
      existing.last_active_at = now;
      existing.lastActiveAt = now;
      db.inMemoryStore.devices.set(`${userId}_${deviceId}`, existing);
      if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
      return this._formatDevice(existing);
    }

    const id = generateUuid();
    const newDevice = {
      id,
      user_id: userId,
      userId,
      device_id: deviceId,
      deviceId,
      device_name: deviceName || 'Mobile Device',
      deviceName: deviceName || 'Mobile Device',
      platform: platform || 'Android',
      status,
      ip_address: ipAddress || '127.0.0.1',
      ipAddress: ipAddress || '127.0.0.1',
      last_active_at: now,
      lastActiveAt: now,
      created_at: now,
      createdAt: now,
    };

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO user_devices (id, user_id, device_id, device_name, platform, status, ip_address, last_active_at, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, userId, deviceId, newDevice.device_name, newDevice.platform, status, newDevice.ip_address, now, now]
      );
    }

    const key = `${userId}_${deviceId}`;
    db.inMemoryStore.devices.set(key, newDevice);
    if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
    return this._formatDevice(newDevice);
  }

  /**
   * Update device status
   */
  static async updateDeviceStatus(userId, deviceId, status) {
    if (db.isConnected()) {
      await db.query(
        'UPDATE user_devices SET status = ? WHERE user_id = ? AND device_id = ?',
        [status, userId, deviceId]
      );
    }
    const key = `${userId}_${deviceId}`;
    const dev = db.inMemoryStore.devices.get(key);
    if (dev) {
      dev.status = status;
    }
    if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
    return true;
  }

  /**
   * Remove/revoke a device
   */
  static async removeDevice(userId, deviceId) {
    if (db.isConnected()) {
      await db.query(
        'DELETE FROM user_devices WHERE user_id = ? AND device_id = ?',
        [userId, deviceId]
      );
    }
    const key = `${userId}_${deviceId}`;
    db.inMemoryStore.devices.delete(key);
    if (typeof db.saveResilienceStore === 'function') db.saveResilienceStore();
    return true;
  }

  /**
   * Create an approval request for a new device attempt
   */
  static async createApprovalRequest({ userId, deviceId, deviceName, platform, ipAddress, verificationCode, expiresMinutes = 10 }) {
    const id = `req_${generateUuid()}`;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + expiresMinutes * 60 * 1000);

    const record = {
      id,
      user_id: userId,
      userId,
      device_id: deviceId,
      deviceId,
      device_name: deviceName || 'New Device',
      deviceName: deviceName || 'New Device',
      platform: platform || 'Android',
      ip_address: ipAddress || '127.0.0.1',
      ipAddress: ipAddress || '127.0.0.1',
      verification_code: verificationCode || Math.floor(1000 + Math.random() * 9000).toString(),
      verificationCode: verificationCode || Math.floor(1000 + Math.random() * 9000).toString(),
      status: 'PENDING',
      expires_at: expiresAt.toISOString(),
      expiresAt: expiresAt.toISOString(),
      created_at: now.toISOString(),
      createdAt: now.toISOString(),
    };

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO device_approval_requests (id, user_id, device_id, device_name, platform, ip_address, verification_code, status, expires_at, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          id,
          userId,
          deviceId,
          record.device_name,
          record.platform,
          record.ip_address,
          record.verification_code,
          'PENDING',
          record.expires_at.slice(0, 19).replace('T', ' '),
          record.created_at.slice(0, 19).replace('T', ' '),
        ]
      );
    }

    db.inMemoryStore.deviceApprovalRequests.set(id, record);
    return this._formatRequest(record);
  }

  /**
   * Get approval request by id
   */
  static async getApprovalRequest(requestId) {
    if (!requestId) return null;

    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM device_approval_requests WHERE id = ? LIMIT 1',
        [requestId]
      );
      if (rows[0]) {
        const req = rows[0];
        // Check expiry
        if (new Date(req.expires_at) < new Date() && req.status === 'PENDING') {
          req.status = 'EXPIRED';
        }
        return this._formatRequest(req);
      }
    }

    const req = db.inMemoryStore.deviceApprovalRequests.get(requestId);
    if (req) {
      if (new Date(req.expires_at) < new Date() && req.status === 'PENDING') {
        req.status = 'EXPIRED';
      }
      return this._formatRequest(req);
    }
    return null;
  }

  /**
   * Get pending approval requests for a user
   */
  static async getPendingRequestsForUser(userId) {
    if (!userId) return [];

    const now = new Date();
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM device_approval_requests WHERE user_id = ? AND status = "PENDING" AND expires_at > ? ORDER BY created_at DESC',
        [userId, now.toISOString().slice(0, 19).replace('T', ' ')]
      );
      return rows.map((r) => this._formatRequest(r));
    }

    const pending = [];
    for (const req of db.inMemoryStore.deviceApprovalRequests.values()) {
      if ((req.user_id || req.userId) === userId && req.status === 'PENDING' && new Date(req.expires_at) > now) {
        pending.push(this._formatRequest(req));
      }
    }
    return pending.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  }

  /**
   * Resolve approval request (APPROVED or REJECTED)
   */
  static async resolveApprovalRequest(requestId, status) {
    const validStatuses = ['APPROVED', 'REJECTED'];
    if (!validStatuses.includes(status)) {
      throw new Error(`Invalid status ${status}`);
    }

    const req = await this.getApprovalRequest(requestId);
    if (!req) return null;

    if (db.isConnected()) {
      await db.query(
        'UPDATE device_approval_requests SET status = ? WHERE id = ?',
        [status, requestId]
      );
    }

    req.status = status;
    db.inMemoryStore.deviceApprovalRequests.set(requestId, req);

    if (status === 'APPROVED') {
      // Register device as approved
      await this.registerDevice({
        userId: req.user_id || req.userId,
        deviceId: req.device_id || req.deviceId,
        deviceName: req.device_name || req.deviceName,
        platform: req.platform,
        ipAddress: req.ip_address || req.ipAddress,
        status: 'APPROVED',
      });
    }

    return this._formatRequest(req);
  }
}

module.exports = DeviceModel;
