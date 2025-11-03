const { validationResult } = require('express-validator');
const authService = require('../services/authService');
const odooService = require('../services/odooService');
const credentialsService = require('../services/credentialsService');
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

    // Store encrypted credentials for future PIN-based logins
    credentialsService.storeCredentials(user.id, login, password, 30);

    // Check if user already has PIN
    const hasPin = credentialsService.hasPin(user.id);

    // Generate long-term token (30 days)
    const token = authService.generateLongTermToken(user, deviceId);

    // Return success response
    res.status(200).json({
      ok: true,
      token,
      user,
      device_id: deviceId,
      requires_pin_setup: !hasPin // Indicate if PIN needs to be set up
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

    // First, find employee by badge to get userId
    const employees = await odooService.execute('hr.employee', 'search_read', [
      [['barcode', '=', badge_barcode]]
    ], { fields: ['id', 'name', 'user_id', 'active'] }, null);

    if (!employees || employees.length === 0) {
      return res.status(401).json({
        ok: false,
        error: 'BADGE_OR_PIN',
        message: 'Невірний бейдж або PIN-код'
      });
    }

    const employee = employees[0];
    
    if (!employee.active) {
      return res.status(403).json({
        ok: false,
        error: 'ARCHIVED',
        message: 'Працівник деактивовано'
      });
    }

    if (!employee.user_id || !employee.user_id[0]) {
      return res.status(401).json({
        ok: false,
        error: 'NO_USER_ACCOUNT',
        message: 'Працівник не має облікового запису користувача'
      });
    }

    const userId = employee.user_id[0];

    // Check if user has PIN stored on backend
    const hasBackendPin = credentialsService.hasPin(userId);
    
    if (hasBackendPin) {
      // Verify PIN from backend
      const isValidPin = await credentialsService.verifyPin(userId, pin);
      if (!isValidPin) {
        return res.status(401).json({
          ok: false,
          error: 'BADGE_OR_PIN',
          message: 'Невірний бейдж або PIN-код'
        });
      }
    } else {
      // No backend PIN - this shouldn't happen after PIN setup, but handle gracefully
      // Try to authenticate with Odoo to get user credentials, then create PIN
      // For now, return error suggesting to login first
      return res.status(401).json({
        ok: false,
        error: 'PIN_NOT_SETUP',
        message: 'PIN-код не налаштовано. Будь ласка, спочатку увійдіть через логін/пароль.'
      });
    }

    // Get stored credentials, if not found - we need to get login from Odoo
    let storedCreds = credentialsService.getCredentials(userId);
    if (!storedCreds) {
      // If no credentials stored, we can't use this flow - user must login first
      return res.status(401).json({
        ok: false,
        error: 'CREDENTIALS_NOT_FOUND',
        message: 'Будь ласка, спочатку увійдіть через логін/пароль для збереження облікових даних.'
      });
    }

    // Set credentials in odooService for this user
    odooService.setUserCredentials(userId, storedCreds.login, storedCreds.password);

    // Get user info from Odoo
    const users = await odooService.execute('res.users', 'read', [
      [userId]
    ], { fields: ['id', 'name', 'login', 'active', 'lang'] }, userId);

    if (!users || users.length === 0 || !users[0].active) {
      return res.status(403).json({
        ok: false,
        error: 'ARCHIVED',
        message: 'Обліковий запис деактивовано'
      });
    }

    const userFromOdoo = users[0];
    
    // Determine language
    let userLang = userFromOdoo.lang || employee.lang || 'uk_UA';

    const user = {
      id: userFromOdoo.id,
      name: userFromOdoo.name,
      login: userFromOdoo.login,
      active: userFromOdoo.active,
      lang: userLang,
      employee_id: employee.id,
      employee: {
        id: employee.id,
        name: employee.name,
        active: employee.active
      }
    };

    // Generate long-term token (30 days)
    const token = authService.generateLongTermToken(user, deviceId);

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
 * @desc    Login with PIN and stored token
 * @route   POST /flf/api/v1/login_pin
 * @access  Public (but requires valid token)
 */
const loginWithPin = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { pin, token } = req.body;

    if (!token) {
      return res.status(400).json({
        ok: false,
        error: 'TOKEN_REQUIRED',
        message: 'Токен обов\'язковий'
      });
    }

    // Verify token
    let decoded;
    try {
      decoded = authService.verifyToken(token);
    } catch (error) {
      return res.status(401).json({
        ok: false,
        error: 'INVALID_TOKEN',
        message: 'Невірний або прострочений токен'
      });
    }

    const userId = decoded.id;

    // Get stored credentials
    const storedCreds = credentialsService.getCredentials(userId);
    if (!storedCreds) {
      return res.status(401).json({
        ok: false,
        error: 'CREDENTIALS_NOT_FOUND',
        message: 'Збережені облікові дані не знайдено. Будь ласка, увійдіть знову через логін/пароль.'
      });
    }

    // Verify PIN from backend (not from Odoo)
    const isValidPin = await credentialsService.verifyPin(userId, pin);
    if (!isValidPin) {
      return res.status(401).json({
        ok: false,
        error: 'INVALID_PIN',
        message: 'Невірний PIN-код'
      });
    }

    // Set credentials in odooService for future Odoo requests
    odooService.setUserCredentials(userId, storedCreds.login, storedCreds.password);

    // Get user info from Odoo
    const users = await odooService.execute('res.users', 'read', [
      [userId]
    ], { fields: ['id', 'name', 'login', 'active', 'lang'] }, userId);

    if (!users || users.length === 0 || !users[0].active) {
      return res.status(403).json({
        ok: false,
        error: 'ARCHIVED',
        message: 'Обліковий запис деактивовано'
      });
    }

    const user = users[0];
    
    // Get employee info if exists
    let employee = null;
    try {
      const employees = await odooService.execute('hr.employee', 'search_read', [
        [['user_id', '=', userId]]
      ], { fields: ['id', 'name', 'active', 'lang'] }, userId);
      
      if (employees && employees.length > 0) {
        employee = employees[0];
      }
    } catch (error) {
      // Employee not found is not critical
      logger.warn(`Employee not found for user ${userId}`);
    }

    const userObject = {
      id: user.id,
      name: user.name,
      login: user.login,
      active: user.active,
      lang: user.lang || (employee ? employee.lang : null) || 'uk_UA',
      employee_id: employee ? employee.id : null,
      employee: employee ? {
        id: employee.id,
        name: employee.name,
        active: employee.active,
        lang: employee.lang
      } : null
    };

    // Generate new long-term token
    const deviceId = decoded.deviceId || authService.generateDeviceId();
    const newToken = authService.generateLongTermToken(userObject, deviceId);

    res.status(200).json({
      ok: true,
      token: newToken,
      user: userObject,
      device_id: deviceId
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create PIN for user (requires 2 PIN confirmations)
 * @route   POST /flf/api/v1/create_pin
 * @access  Public (but requires valid token)
 */
const createPin = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { pin, pin_confirm, token } = req.body;

    if (!token) {
      return res.status(400).json({
        ok: false,
        error: 'TOKEN_REQUIRED',
        message: 'Токен обов\'язковий'
      });
    }

    // Verify token
    let decoded;
    try {
      decoded = authService.verifyToken(token);
    } catch (error) {
      return res.status(401).json({
        ok: false,
        error: 'INVALID_TOKEN',
        message: 'Невірний або прострочений токен'
      });
    }

    const userId = decoded.id;

    // Check if PINs match
    if (pin !== pin_confirm) {
      return res.status(400).json({
        ok: false,
        error: 'PIN_MISMATCH',
        message: 'PIN-коди не співпадають'
      });
    }

    // Validate PIN format
    if (!pin || pin.length < 4 || pin.length > 10) {
      return res.status(400).json({
        ok: false,
        error: 'INVALID_PIN_FORMAT',
        message: 'PIN-код повинен бути від 4 до 10 символів'
      });
    }

    // Hash PIN
    const hashedPin = await authService.hashPin(pin);

    // Store PIN
    credentialsService.storePin(userId, hashedPin, 30);

    logger.info(`PIN created for user ${userId}`);

    res.status(200).json({
      ok: true,
      message: 'PIN-код успішно створено'
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
    // Optionally remove stored credentials and PIN
    if (req.user && req.user.id) {
      credentialsService.removeCredentials(req.user.id);
      credentialsService.removePin(req.user.id);
    }
    
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
  loginWithPin,
  createPin,
  getDeviceStatus,
  logout
};
