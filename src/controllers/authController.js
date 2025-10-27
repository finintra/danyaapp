const { validationResult } = require('express-validator');
const authService = require('../services/authService');
const odooService = require('../services/odooService');
const { ApiError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * @desc    Login with username and password
 * @route   POST /flf/api/v1/login
 * @access  Public
 */
const login = async (req, res, next) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { login, password, device_id } = req.body;

    // Generate device ID if not provided
    const deviceId = device_id || authService.generateDeviceId();

    // Authenticate user with Odoo
    const user = await odooService.authenticateUser(login, password);

    // Generate token
    const token = authService.generateToken(user, deviceId);

    // Return success response
    res.status(200).json({
      ok: true,
      token,
      user,
      device_id: deviceId
    });
  } catch (error) {
    if (error.message === 'INVALID_CREDENTIALS') {
      return res.status(401).json({
        ok: false,
        error: 'INVALID_CREDENTIALS',
        message: 'Невірний логін або пароль'
      });
    }

    if (error.message === 'ARCHIVED') {
      return res.status(403).json({
        ok: false,
        error: 'ARCHIVED',
        message: 'Обліковий запис деактивовано'
      });
    }

    next(error);
  }
};

/**
 * @desc    Login with badge and PIN
 * @route   POST /flf/api/v1/login_badge
 * @access  Public
 */
const loginWithBadge = async (req, res, next) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { badge_barcode, device_id, pin } = req.body;

    // Generate device ID if not provided
    const deviceId = device_id || authService.generateDeviceId();

    // Validate badge and PIN with Odoo
    const user = await odooService.validateBadgeAndPin(badge_barcode, pin);

    // Generate token
    const token = authService.generateToken(user, deviceId);

    // Return success response
    res.status(200).json({
      ok: true,
      token,
      user,
      device_id: deviceId
    });
  } catch (error) {
    if (error.message === 'BADGE_OR_PIN') {
      return res.status(401).json({
        ok: false,
        error: 'BADGE_OR_PIN'
      });
    }

    if (error.message === 'ARCHIVED') {
      return res.status(403).json({
        ok: false,
        error: 'ARCHIVED'
      });
    }

    if (error.message === 'NO_USER_ACCOUNT') {
      return res.status(401).json({
        ok: false,
        error: 'NO_USER_ACCOUNT',
        message: 'Працівник не має облікового запису користувача'
      });
    }

    next(error);
  }
};

/**
 * @desc    Get device status
 * @route   GET /flf/api/v1/device/status
 * @access  Private
 */
const getDeviceStatus = async (req, res, next) => {
  try {
    // User is already attached to req by auth middleware
    res.status(200).json({
      ok: true,
      device_id: req.user.deviceId,
      user: {
        id: req.user.id,
        name: req.user.name
      },
      active: true
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Logout
 * @route   POST /flf/api/v1/logout
 * @access  Private
 */
const logout = async (req, res, next) => {
  try {
    // In a stateless JWT system, we don't need to do anything server-side
    // The client should discard the token
    res.status(200).json({
      ok: true
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  login,
  loginWithBadge,
  getDeviceStatus,
  logout
};
