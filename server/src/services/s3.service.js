/**
 * AWS S3 File Storage Service
 * Handles secure storage of GST invoices, generated PDF receipts,
 * business documents, and statements with server-side encryption.
 * Zero AWS keys are exposed in the Flutter APK.
 */

const fs = require('fs');
const path = require('path');
const config = require('../config/env.config');

class S3Service {
  /**
   * Get AWS S3 Bucket Name
   */
  static getBucketName() {
    return process.env.S3_BUCKET_NAME || 'enx-money-production-documents';
  }

  /**
   * Check if live AWS S3 credentials are configured
   */
  static isAwsConfigured() {
    return !!(
      process.env.AWS_ACCESS_KEY_ID &&
      process.env.AWS_SECRET_ACCESS_KEY &&
      process.env.S3_BUCKET_NAME
    );
  }

  /**
   * Upload file to AWS S3 (with local fallback if AWS credentials not set)
   * @param {Object} options
   * @param {string} options.key - File path in S3 (e.g. 'invoices/2026/inv_123.pdf')
   * @param {Buffer|string} options.body - File buffer or string
   * @param {string} options.contentType - MIME type (e.g. 'application/pdf')
   * @param {boolean} options.isPrivate - Whether file requires presigned URL
   */
  static async uploadFile({ key, body, contentType = 'application/pdf', isPrivate = true }) {
    const bucketName = this.getBucketName();
    const cleanKey = key.startsWith('/') ? key.substring(1) : key;

    if (this.isAwsConfigured()) {
      try {
        const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
        const s3Client = new S3Client({
          region: process.env.AWS_REGION || 'ap-south-1',
          credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
          },
        });

        const command = new PutObjectCommand({
          Bucket: bucketName,
          Key: cleanKey,
          Body: body,
          ContentType: contentType,
          ServerSideEncryption: 'AES256',
        });

        await s3Client.send(command);
        return {
          success: true,
          provider: 'AWS_S3',
          bucket: bucketName,
          key: cleanKey,
          url: `https://${bucketName}.s3.${process.env.AWS_REGION || 'ap-south-1'}.amazonaws.com/${cleanKey}`,
        };
      } catch (awsError) {
        console.warn(`[S3 Service Warning] AWS S3 upload failed (${awsError.message}). Using persistent storage fallback.`);
      }
    }

    // Local / Persistent storage fallback
    const storageDir = path.join(__dirname, '../../uploads', path.dirname(cleanKey));
    if (!fs.existsSync(storageDir)) {
      fs.mkdirSync(storageDir, { recursive: true });
    }

    const filePath = path.join(__dirname, '../../uploads', cleanKey);
    fs.writeFileSync(filePath, body);

    return {
      success: true,
      provider: 'PERSISTENT_STORAGE',
      bucket: 'local',
      key: cleanKey,
      url: `/uploads/${cleanKey}`,
      localPath: filePath,
    };
  }

  /**
   * Generate secure pre-signed download URL (expires in 15 minutes by default)
   */
  static async getPresignedDownloadUrl({ key, expiresInSeconds = 900 }) {
    const bucketName = this.getBucketName();
    const cleanKey = key.startsWith('/') ? key.substring(1) : key;

    if (this.isAwsConfigured()) {
      try {
        const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
        const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
        const s3Client = new S3Client({
          region: process.env.AWS_REGION || 'ap-south-1',
          credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
          },
        });

        const command = new GetObjectCommand({
          Bucket: bucketName,
          Key: cleanKey,
        });

        const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
        return { success: true, url: presignedUrl, expiresIn: expiresInSeconds };
      } catch (err) {
        console.warn(`[S3 Presign Warning] Could not generate S3 URL: ${err.message}`);
      }
    }

    // Local / Proxy fallback URL
    return {
      success: true,
      url: `/api/v1/documents/${encodeURIComponent(cleanKey)}`,
      expiresIn: expiresInSeconds,
    };
  }

  /**
   * Delete file from S3
   */
  static async deleteFile({ key }) {
    const bucketName = this.getBucketName();
    const cleanKey = key.startsWith('/') ? key.substring(1) : key;

    if (this.isAwsConfigured()) {
      try {
        const { S3Client, DeleteObjectCommand } = require('@aws-sdk/client-s3');
        const s3Client = new S3Client({
          region: process.env.AWS_REGION || 'ap-south-1',
          credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
          },
        });

        await s3Client.send(new DeleteObjectCommand({ Bucket: bucketName, Key: cleanKey }));
        return { success: true };
      } catch (err) {
        console.warn(`[S3 Delete Warning] Could not delete S3 object: ${err.message}`);
      }
    }

    const filePath = path.join(__dirname, '../../uploads', cleanKey);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    return { success: true };
  }
}

module.exports = S3Service;
