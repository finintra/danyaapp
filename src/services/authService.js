const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const { ApiError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

class AuthService {
  /**
   * Generate JWT token
   * @param {Object} user - User object
   * @param {string} deviceId - Device ID
   * @returns {string} - JWT token
   */
  generateToken(user, deviceId) {
    return jwt.sign(
      { 
        id: user.id, 
        name: user.name,
        deviceId 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );
  }

  /**
   * Verify JWT token
   * @param {string} token - JWT token
   * @returns {Object} - Decoded token
   */
  verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new ApiError(401, 'Token expired');
      }
      throw new ApiError(401, 'Invalid token');
    }
  }

  /**
   * Generate device ID
   * @returns {string} - Device ID
   */
  generateDeviceId() {
    return uuidv4();
  }

  /**
   * Hash PIN
   * @param {string} pin - PIN to hash
   * @returns {Promise<string>} - Hashed PIN
   */
  async hashPin(pin) {
    const salt = await bcrypt.genSalt(10);
    return bcrypt.hash(pin, salt);
  }

  /**
   * Compare PIN with hash
   * @param {string} pin - PIN to compare
   * @param {string} hashedPin - Hashed PIN
   * @returns {Promise<boolean>} - True if PIN matches
   */
  async comparePin(pin, hashedPin) {
    return bcrypt.compare(pin, hashedPin);
  }
}

module.exports = new AuthService();
