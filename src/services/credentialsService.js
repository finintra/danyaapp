const fs = require('fs');
const path = require('path');
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
    this.pinStoragePath = path.resolve(__dirname, '../../data/pins.json');

    this.loadPinsFromDisk();
  }

  ensurePinStorageDir() {
    const dir = path.dirname(this.pinStoragePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  loadPinsFromDisk() {
    try {
      this.ensurePinStorageDir();
      if (!fs.existsSync(this.pinStoragePath)) {
        logger.info('No persisted PIN storage found, starting fresh');
        return;
      }

      const raw = fs.readFileSync(this.pinStoragePath, 'utf8');
      if (!raw) {
        return;
      }

      const parsed = JSON.parse(raw);
      this.userPins = new Map(
        Object.entries(parsed).map(([userId, data]) => [
          Number(userId),
          {
            hashedPin: data.hashedPin,
            createdAt: data.createdAt ? new Date(data.createdAt) : new Date(),
            expiresAt: data.expiresAt ? new Date(data.expiresAt) : new Date(Date.now() - 1)
          }
        ])
      );

      logger.info(`Loaded ${this.userPins.size} persisted PIN entries from disk`);
      this.cleanupExpired();
    } catch (error) {
      logger.error('Failed to load persisted PINs from disk:', error);
    }
  }

  persistPinsToDisk() {
    try {
      this.ensurePinStorageDir();
      const serializable = {};
      for (const [userId, data] of this.userPins.entries()) {
        serializable[userId] = {
          hashedPin: data.hashedPin,
          createdAt: data.createdAt ? new Date(data.createdAt).toISOString() : new Date().toISOString(),
          expiresAt: data.expiresAt ? new Date(data.expiresAt).toISOString() : new Date().toISOString()
        };
      }

      fs.writeFileSync(this.pinStoragePath, JSON.stringify(serializable, null, 2), 'utf8');
      logger.info(`Persisted ${this.userPins.size} PIN entries to disk`);
    } catch (error) {
      logger.error('Failed to persist PINs to disk:', error);
    }
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
    logger.info(`Storing credentials for user ${userId}, login: ${login}, expiresInDays: ${expiresInDays}`);

    const credentials = {
      login,
      password,
      storedAt: new Date(),
      expiresAt: new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000)
    };

    const encrypted = this.encrypt(JSON.stringify(credentials));
    this.credentials.set(userId, encrypted);

    logger.info(`Stored encrypted credentials for user ${userId}, expires at ${credentials.expiresAt}`);
    logger.info(`Total credentials now stored: ${this.credentials.size}`);
    logger.info(`Stored user IDs: ${Array.from(this.credentials.keys()).join(', ')}`);
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
    this.persistPinsToDisk();
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
      this.persistPinsToDisk();
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
      this.persistPinsToDisk();
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
    this.persistPinsToDisk();
    logger.info(`Removed PIN for user ${userId}`);
  }

  /**
   * Get decrypted credentials for a user
   * @param {number} userId - User ID
   * @returns {Object|null} - Decrypted credentials {login, password} or null if not found/expired
   */
  getCredentials(userId) {
    logger.info(`Getting credentials for user ${userId}`);
    logger.info(`Total credentials stored: ${this.credentials.size}`);
    logger.info(`Stored user IDs: ${Array.from(this.credentials.keys()).join(', ')}`);

    const encrypted = this.credentials.get(userId);
    if (!encrypted) {
      logger.warn(`No credentials found for user ${userId}`);
      return null;
    }

    try {
      const decrypted = JSON.parse(this.decrypt(encrypted));

      // Check if expired
      if (new Date() > new Date(decrypted.expiresAt)) {
        logger.warn(`Credentials expired for user ${userId}. Expired at: ${decrypted.expiresAt}, now: ${new Date()}`);
        this.credentials.delete(userId);
        return null;
      }

      logger.info(`Successfully retrieved credentials for user ${userId}`);
      return {
        login: decrypted.login,
        password: decrypted.password
      };
    } catch (error) {
      logger.error(`Error decrypting credentials for user ${userId}:`, error);
      this.credentials.delete(userId);
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
      this.persistPinsToDisk();
    }
  }
}

module.exports = new CredentialsService();

