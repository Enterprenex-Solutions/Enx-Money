const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class DownloadModel {
  /**
   * Ensure downloads table exists in MySQL if connected
   */
  static async initTable() {
    if (db.isConnected()) {
      try {
        await db.query(`
          CREATE TABLE IF NOT EXISTS app_downloads (
            id VARCHAR(36) PRIMARY KEY,
            ip_address VARCHAR(45) DEFAULT NULL,
            user_agent TEXT DEFAULT NULL,
            platform VARCHAR(50) NOT NULL DEFAULT 'Android APK',
            version VARCHAR(20) DEFAULT '1.0.0',
            channel VARCHAR(50) DEFAULT 'Direct APK Download',
            downloaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_downloaded_at (downloaded_at),
            INDEX idx_platform (platform)
          ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        `);
      } catch (err) {
        console.warn('[DownloadModel] Could not initialize app_downloads table:', err.message);
      }
    }
  }

  /**
   * Record a download event
   */
  static async recordDownload({ ipAddress = null, userAgent = null, platform = 'Android APK', version = '1.0.0', channel = 'Direct APK' } = {}) {
    const id = generateUuid();
    const now = new Date();

    // Mask IPv4/IPv6 address for privacy compliance
    const sanitizedIp = ipAddress ? ipAddress.replace(/(\d+)\.(\d+)\.(\d+)\.(\d+)/, '$1.$2.xxx.xxx') : 'Anonymous';

    if (db.isConnected()) {
      try {
        await db.query(
          `INSERT INTO app_downloads (id, ip_address, user_agent, platform, version, channel, downloaded_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [id, sanitizedIp, userAgent ? userAgent.substring(0, 500) : null, platform, version, channel, now]
        );
      } catch (err) {
        // Silently fallback to in-memory store
      }
    }

    // In-memory resilience store
    if (!db.inMemoryStore.downloads) {
      db.inMemoryStore.downloads = [];
    }
    const event = {
      id,
      ip_address: sanitizedIp,
      user_agent: userAgent ? userAgent.substring(0, 200) : null,
      platform,
      version,
      channel,
      downloaded_at: now.toISOString(),
    };
    db.inMemoryStore.downloads.push(event);
    if (db.inMemoryStore.downloads.length > 5000) {
      db.inMemoryStore.downloads.shift();
    }
    if (typeof db.saveResilienceStore === 'function') {
      try { db.saveResilienceStore(); } catch (_) {}
    }

    return event;
  }

  /**
   * Get total downloads and periodic breakdown
   */
  static async getDownloadStats() {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const monthStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    if (db.isConnected()) {
      try {
        const [totalRow] = await db.query('SELECT COUNT(*) as count FROM app_downloads');
        const [todayRow] = await db.query('SELECT COUNT(*) as count FROM app_downloads WHERE downloaded_at >= ?', [todayStart]);
        const [weekRow] = await db.query('SELECT COUNT(*) as count FROM app_downloads WHERE downloaded_at >= ?', [weekStart]);
        const [monthRow] = await db.query('SELECT COUNT(*) as count FROM app_downloads WHERE downloaded_at >= ?', [monthStart]);

        const recent = await this.getRecentDownloads(10);
        return {
          totalDownloads: Number(totalRow?.count || 0),
          downloadsToday: Number(todayRow?.count || 0),
          downloadsThisWeek: Number(weekRow?.count || 0),
          downloadsThisMonth: Number(monthRow?.count || 0),
          recentDownloads: recent,
          googlePlayConsole: {
            packageName: 'com.enxmoney.enx_money',
            status: 'Requires Google Play Console Service Account (androidpublisher.googleapis.com)',
            connected: false,
          },
          source: 'ENX Money Download Tracker (Direct Server Distribution)',
          playStoreStatus: 'Requires Google Play Console Service Account (androidpublisher.googleapis.com)',
        };
      } catch (err) {
        // Fall back to in-memory store
      }
    }

    // In-memory fallback
    const list = db.inMemoryStore.downloads || [];
    let today = 0, week = 0, month = 0;
    for (const d of list) {
      const dt = new Date(d.downloaded_at);
      if (dt >= todayStart) today++;
      if (dt >= weekStart) week++;
      if (dt >= monthStart) month++;
    }

    const recent = await this.getRecentDownloads(10);
    return {
      totalDownloads: list.length,
      downloadsToday: today,
      downloadsThisWeek: week,
      downloadsThisMonth: month,
      recentDownloads: recent,
      googlePlayConsole: {
        packageName: 'com.enxmoney.enx_money',
        status: 'Requires Google Play Console Service Account (androidpublisher.googleapis.com)',
        connected: false,
      },
      source: 'ENX Money Download Tracker (Direct Server Distribution)',
      playStoreStatus: 'Requires Google Play Console Service Account (androidpublisher.googleapis.com)',
    };
  }

  /**
   * Get download timeline grouped by date for charts
   */
  static async getDownloadsByDate(days = 14) {
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    if (db.isConnected()) {
      try {
        const rows = await db.query(`
          SELECT DATE_FORMAT(downloaded_at, '%Y-%m-%d') as date, COUNT(*) as count
          FROM app_downloads
          WHERE downloaded_at >= ?
          GROUP BY DATE_FORMAT(downloaded_at, '%Y-%m-%d')
          ORDER BY date ASC
        `, [cutoff]);

        return rows.map(r => ({ date: r.date, count: Number(r.count) }));
      } catch (_) {}
    }

    // In-memory fallback
    const list = db.inMemoryStore.downloads || [];
    const countsByDate = {};
    for (const d of list) {
      const dt = new Date(d.downloaded_at);
      if (dt >= cutoff) {
        const key = dt.toISOString().split('T')[0];
        countsByDate[key] = (countsByDate[key] || 0) + 1;
      }
    }

    return Object.keys(countsByDate)
      .sort()
      .map(date => ({ date, count: countsByDate[date] }));
  }

  /**
   * Get recent download events
   */
  static async getRecentDownloads(limit = 20) {
    if (db.isConnected()) {
      try {
        const rows = await db.query(`
          SELECT id, ip_address, platform, version, channel, downloaded_at
          FROM app_downloads
          ORDER BY downloaded_at DESC
          LIMIT ?
        `, [limit]);
        return rows.map(r => ({
          ...r,
          ipAddress: r.ip_address || r.ipAddress,
          downloadedAt: r.downloaded_at || r.downloadedAt,
        }));
      } catch (_) {}
    }

    const list = db.inMemoryStore.downloads || [];
    return list.slice(-limit).reverse().map(d => ({
      ...d,
      ipAddress: d.ip_address || d.ipAddress,
      ip_address: d.ip_address || d.ipAddress,
      downloadedAt: d.downloaded_at || d.downloadedAt,
      downloaded_at: d.downloaded_at || d.downloadedAt,
    }));
  }
}

// Auto-initialize table on module load
DownloadModel.initTable();

module.exports = DownloadModel;
