const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class RatingModel {
  /**
   * Ensure app_ratings table exists in MySQL
   */
  static async initTable() {
    if (db.isConnected()) {
      try {
        await db.query(`
          CREATE TABLE IF NOT EXISTS app_ratings (
            id VARCHAR(36) PRIMARY KEY,
            user_id VARCHAR(36) DEFAULT NULL,
            user_name VARCHAR(150) DEFAULT 'Merchant User',
            rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
            review_text TEXT DEFAULT NULL,
            version VARCHAR(20) DEFAULT '1.0.0',
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_rating (rating),
            INDEX idx_created_at (created_at)
          ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        `);
      } catch (err) {
        console.warn('[RatingModel] Could not initialize app_ratings table:', err.message);
      }
    }
  }

  /**
   * Submit an in-app rating and review
   */
  static async submitRating({ userId = null, userName = 'Merchant User', rating = 5, reviewText = null, version = '1.0.0' } = {}) {
    const id = generateUuid();
    const now = new Date();
    const cleanRating = Math.max(1, Math.min(5, Math.round(Number(rating) || 5)));
    const cleanReview = reviewText ? String(reviewText).trim().substring(0, 1000) : null;
    const cleanName = userName ? String(userName).trim().substring(0, 150) : 'Merchant User';

    if (db.isConnected()) {
      try {
        await db.query(
          `INSERT INTO app_ratings (id, user_id, user_name, rating, review_text, version, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [id, userId, cleanName, cleanRating, cleanReview, version, now]
        );
      } catch (_) {}
    }

    // In-memory resilience store
    if (!db.inMemoryStore.ratings) {
      db.inMemoryStore.ratings = [];
    }
    const item = {
      id,
      user_id: userId,
      user_name: cleanName,
      rating: cleanRating,
      review_text: cleanReview,
      version,
      created_at: now.toISOString(),
    };
    db.inMemoryStore.ratings.push(item);
    if (typeof db.saveResilienceStore === 'function') {
      try { db.saveResilienceStore(); } catch (_) {}
    }

    return item;
  }

  /**
   * Get ratings summary with average and 1-5 star distribution
   */
  static async getRatingStats() {
    // Official Play Store API check
    const hasPlayStoreApi = Boolean(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON || process.env.PLAY_STORE_API_KEY);
    const playStoreStatus = hasPlayStoreApi
      ? 'Google Play Developer API Active'
      : 'Requires Google Play Console Service Account (androidpublisher.googleapis.com)';

    let totalRatings = 0;
    let averageRating = 0;
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };

    if (db.isConnected()) {
      try {
        const rows = await db.query(`
          SELECT rating, COUNT(*) as count
          FROM app_ratings
          GROUP BY rating
        `);

        let sum = 0;
        for (const r of rows) {
          const star = Number(r.rating);
          const count = Number(r.count);
          if (distribution[star] !== undefined) {
            distribution[star] = count;
            sum += star * count;
            totalRatings += count;
          }
        }
        averageRating = totalRatings > 0 ? Number((sum / totalRatings).toFixed(2)) : 0;

        const ratingDist = {
          '5_star': distribution[5] || 0,
          '4_star': distribution[4] || 0,
          '3_star': distribution[3] || 0,
          '2_star': distribution[2] || 0,
          '1_star': distribution[1] || 0,
        };

        return {
          averageRating,
          totalRatings,
          distribution,
          ratingDistribution: ratingDist,
          googlePlayConsole: {
            packageName: 'com.enxmoney.enx_money',
            status: playStoreStatus,
            connected: hasPlayStoreApi,
          },
          source: 'ENX Money In-App Ratings Database',
          playStoreStatus,
          playStoreDataAvailable: hasPlayStoreApi,
          packageId: 'com.enxmoney.enx_money',
        };
      } catch (_) {}
    }

    // In-memory fallback
    const list = db.inMemoryStore.ratings || [];
    let sum = 0;
    for (const item of list) {
      const star = Number(item.rating);
      if (distribution[star] !== undefined) {
        distribution[star]++;
        sum += star;
        totalRatings++;
      }
    }
    averageRating = totalRatings > 0 ? Number((sum / totalRatings).toFixed(2)) : 0;

    const ratingDist = {
      '5_star': distribution[5] || 0,
      '4_star': distribution[4] || 0,
      '3_star': distribution[3] || 0,
      '2_star': distribution[2] || 0,
      '1_star': distribution[1] || 0,
    };

    return {
      averageRating,
      totalRatings,
      distribution,
      ratingDistribution: ratingDist,
      googlePlayConsole: {
        packageName: 'com.enxmoney.enx_money',
        status: playStoreStatus,
        connected: hasPlayStoreApi,
      },
      source: 'ENX Money In-App Ratings Database',
      playStoreStatus,
      playStoreDataAvailable: hasPlayStoreApi,
      packageId: 'com.enxmoney.enx_money',
    };
  }

  /**
   * Get recent reviews list
   */
  static async getRecentReviews(limit = 20) {
    if (db.isConnected()) {
      try {
        const rows = await db.query(`
          SELECT id, user_id, user_name, rating, review_text, version, created_at
          FROM app_ratings
          WHERE review_text IS NOT NULL AND review_text != ''
          ORDER BY created_at DESC
          LIMIT ?
        `, [limit]);
        return rows;
      } catch (_) {}
    }

    const list = (db.inMemoryStore.ratings || []).filter(r => Boolean(r.review_text));
    return list.slice(-limit).reverse();
  }
}

// Auto-initialize table on module load
RatingModel.initTable();

module.exports = RatingModel;
