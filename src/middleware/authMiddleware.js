const authService = require('../services/authService');
const credentialsService = require('../services/credentialsService');
const odooService = require('../services/odooService');
const { ApiError } = require('./errorHandler');
const logger = require('../utils/logger');

/**
 * Middleware to protect routes
 */
const protect = async (req, res, next) => {
  try {
    let token;

    // Check if token exists in headers
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    // Check if token exists
    if (!token) {
      return next(new ApiError(401, 'Not authorized, no token'));
    }

    try {
      // Verify token
      const decoded = authService.verifyToken(token);

      // Add user info to request
      req.user = {
        id: decoded.id,
        name: decoded.name,
        deviceId: decoded.deviceId,
        lang: decoded.lang || 'uk_UA' // Add language with default fallback
      };

      // Load and set stored credentials for Odoo requests
      const storedCreds = credentialsService.getCredentials(decoded.id);
      if (storedCreds) {
        logger.info(`Loading stored credentials for user ${decoded.id}`);
        odooService.setUserCredentials(decoded.id, storedCreds.login, storedCreds.password);
      } else {
        logger.warn(`No stored credentials found for user ${decoded.id}`);
      }

      next();
    } catch (error) {
      return next(new ApiError(401, 'Not authorized, token failed'));
    }
  } catch (error) {
    logger.error('Auth middleware error:', error);
    return next(new ApiError(500, 'Server Error'));
  }
};

module.exports = {
  protect
};
