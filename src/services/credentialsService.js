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
    // In-memory storage: userId -> hashed PIN
    this.userPins = new Map(); // userId -> { hashedPin, createdAt, expiresAt }
    // Encryption key from environment or generate a default (should be set in production!)
    this.encryptionKey = process.env.CREDENTIALS_ENCRYPTION_KEY || 'default-key-change-in-production-32chars!!';
    this.algorithm = 'aes-256-cbc';
  }

  /**
   * Get encryption key as 32-byte buffer
   * Supports hex (64 chars), base64 (44 chars), or raw string (32 chars)
   * @returns {Buffer} - 32-byte key buffer
   */
  getKeyBuffer() {
    let keyBuffer;
    
    // Try hex format (64 characters = 32 bytes)
    if (this.encryptionKey.length === 64 && /^[0-9a-fA-F]+$/.test(this.encryptionKey)) {
      keyBuffer = Buffer.from(this.encryptionKey, 'hex');
    }
    // Try base64 format
    else if (this.encryptionKey.length >= 32) {
      try {
        keyBuffer = Buffer.from(this.encryptionKey, 'base64').slice(0, 32);
      } catch (e) {
        // Fallback to raw string
        keyBuffer = Buffer.from(this.encryptionKey.padEnd(32, '0').slice(0, 32));
      }
    }
    // Raw string (pad to 32 bytes)
    else {
      keyBuffer = Buffer.from(this.encryptionKey.padEnd(32, '0').slice(0, 32));
    }
    
    // Ensure exactly 32 bytes
    if (keyBuffer.length !== 32) {
      const finalKey = Buffer.alloc(32);
      keyBuffer.copy(finalKey, 0, 0, Math.min(32, keyBuffer.length));
      return finalKey;
    }
    
    return keyBuffer;
  }

  /**
   * Encrypt text
   * @param {string} text - Text to encrypt
   * @returns {string} - Encrypted text (iv:encryptedData)
   */
  encrypt(text) {
    const iv = crypto.randomBytes(16);
    const keyBuffer = this.getKeyBuffer();
    const cipher = crypto.createCipheriv(
      this.algorithm,
      keyBuffer,
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
    const keyBuffer = this.getKeyBuffer();
    const decipher = crypto.createDecipheriv(
      this.algorithm,
      keyBuffer,
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
   * Store PIN for a user (hashed)
   * @param {number} userId - User ID
   * @param {string} hashedPin - Hashed PIN
   * @param {number} expiresInDays - Expiration in days (default 30)
   */
  storePin(userId, hashedPin, expiresInDays = 30) {
    this.userPins.set(userId, {
      hashedPin,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000)
    });

    logger.info(`Stored PIN for user ${userId}, expires at ${new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000)}`);
  }

  /**
   * Check if user has PIN
   * @param {number} userId - User ID
   * @returns {boolean} - True if PIN exists and not expired
   */
  hasPin(userId) {
    const pinData = this.userPins.get(userId);
    if (!pinData) {
      return false;
    }

    if (new Date() > new Date(pinData.expiresAt)) {
      this.userPins.delete(userId);
      return false;
    }

    return true;
  }

  /**
   * Verify PIN for a user
   * @param {number} userId - User ID
   * @param {string} pin - PIN to verify
   * @returns {Promise<boolean>} - True if PIN matches
   */
  async verifyPin(userId, pin) {
    const pinData = this.userPins.get(userId);
    if (!pinData) {
      return false;
    }

    if (new Date() > new Date(pinData.expiresAt)) {
      this.userPins.delete(userId);
      return false;
    }

    // Use bcrypt to compare
    const bcrypt = require('bcrypt');
    return bcrypt.compare(pin, pinData.hashedPin);
  }

  /**
   * Remove PIN for a user
   * @param {number} userId - User ID
   */
  removePin(userId) {
    this.userPins.delete(userId);
    logger.info(`Removed PIN for user ${userId}`);
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
   * Clean up expired credentials and PINs (should be called periodically)
   */
  cleanupExpired() {
    const now = new Date();
    let cleaned = 0;

    // Clean expired credentials
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

    // Clean expired PINs
    for (const [userId, pinData] of this.userPins.entries()) {
      if (now > new Date(pinData.expiresAt)) {
        this.userPins.delete(userId);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      logger.info(`Cleaned up ${cleaned} expired credential/PIN entries`);
    }
  }
}

module.exports = new CredentialsService();

