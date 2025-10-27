const authService = require('../services/authService');
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
        deviceId: decoded.deviceId
      };

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
