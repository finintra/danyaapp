const crypto = require('crypto');
const logger = require('../utils/logger');

/**
 * Service for storing and retrieving encrypted user credentials
 * Credentials are stored in memory with encryption
 */
class CredentialsService {
  constructor() {
    // In-memory storage: userId -> encrypted credentials
    this.credentials = new Map();
    // Encryption key from environment or generate a default (should be set in production!)
    this.encryptionKey = process.env.CREDENTIALS_ENCRYPTION_KEY || 'default-key-change-in-production-32chars!!';
    this.algorithm = 'aes-256-cbc';
  }

  /**
   * Encrypt text
   * @param {string} text - Text to encrypt
   * @returns {string} - Encrypted text (iv:encryptedData)
   */
  encrypt(text) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(
      this.algorithm,
      Buffer.from(this.encryptionKey.padEnd(32, '0').slice(0, 32)),
      iv
    );
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return `${iv.toString('hex')}:${encrypted}`;
  }

  /**
   * Decrypt text
   * @param {string} encryptedText - Encrypted text (iv:encryptedData)
   * @returns {string} - Decrypted text
   */
  decrypt(encryptedText) {
    const parts = encryptedText.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = parts[1];
    const decipher = crypto.createDecipheriv(
      this.algorithm,
      Buffer.from(this.encryptionKey.padEnd(32, '0').slice(0, 32)),
      iv
    );
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  }

  /**
   * Store encrypted credentials for a user
   * @param {number} userId - User ID
   * @param {string} login - User login
   * @param {string} password - User password
   * @param {number} expiresInDays - Expiration in days (default 30)
   */
  storeCredentials(userId, login, password, expiresInDays = 30) {
    const credentials = {
      login,
      password,
      storedAt: new Date(),
      expiresAt: new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000)
    };

    const encrypted = this.encrypt(JSON.stringify(credentials));
    this.credentials.set(userId, encrypted);

    logger.info(`Stored encrypted credentials for user ${userId}, expires at ${credentials.expiresAt}`);
  }

  /**
   * Get decrypted credentials for a user
   * @param {number} userId - User ID
   * @returns {Object|null} - Decrypted credentials {login, password} or null if not found/expired
   */
  getCredentials(userId) {
    const encrypted = this.credentials.get(userId);
    if (!encrypted) {
      logger.warn(`No credentials found for user ${userId}`);
      return null;
    }

    try {
      const decrypted = JSON.parse(this.decrypt(encrypted));
      
      // Check if expired
      if (new Date() > new Date(decrypted.expiresAt)) {
        logger.warn(`Credentials expired for user ${userId}`);
        this.credentials.delete(userId);
        return null;
      }

      return {
        login: decrypted.login,
        password: decrypted.password
      };
    } catch (error) {
      logger.error(`Error decrypting credentials for user ${userId}:`, error);
      return null;
    }
  }

  /**
   * Remove credentials for a user
   * @param {number} userId - User ID
   */
  removeCredentials(userId) {
    this.credentials.delete(userId);
    logger.info(`Removed credentials for user ${userId}`);
  }

  /**
   * Clean up expired credentials (should be called periodically)
   */
  cleanupExpired() {
    const now = new Date();
    let cleaned = 0;

    for (const [userId, encrypted] of this.credentials.entries()) {
      try {
        const decrypted = JSON.parse(this.decrypt(encrypted));
        if (now > new Date(decrypted.expiresAt)) {
          this.credentials.delete(userId);
          cleaned++;
        }
      } catch (error) {
        // If decryption fails, remove it
        this.credentials.delete(userId);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      logger.info(`Cleaned up ${cleaned} expired credential entries`);
    }
  }
}

module.exports = new CredentialsService();

