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

    // Get stored credentials if available (from previous login)
    const storedCreds = credentialsService.getCredentials(user.id);
    if (storedCreds) {
      // Set credentials in odooService for this user
      odooService.setUserCredentials(user.id, storedCreds.login, storedCreds.password);
    }

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

    // Set credentials in odooService
    odooService.setUserCredentials(userId, storedCreds.login, storedCreds.password);

    // Get user from Odoo to validate PIN and get updated info
    const employees = await odooService.execute('hr.employee', 'search_read', [
      [['user_id', '=', userId]]
    ], { fields: ['id', 'name', 'pin', 'active', 'lang'] }, userId);

    if (!employees || employees.length === 0) {
      return res.status(401).json({
        ok: false,
        error: 'EMPLOYEE_NOT_FOUND',
        message: 'Працівник не знайдений'
      });
    }

    const employee = employees[0];

    // Validate PIN
    if (!employee.pin || employee.pin !== pin) {
      return res.status(401).json({
        ok: false,
        error: 'INVALID_PIN',
        message: 'Невірний PIN-код'
      });
    }

    // Get user info
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
    const userObject = {
      id: user.id,
      name: user.name,
      login: user.login,
      active: user.active,
      lang: user.lang || employee.lang || 'uk_UA',
      employee_id: employee.id,
      employee: {
        id: employee.id,
        name: employee.name,
        pin: employee.pin,
        active: employee.active,
        lang: employee.lang
      }
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
 * @desc    Logout
 * @route   POST /flf/api/v1/logout
 * @access  Private
 */
const logout = async (req, res, next) => {
  try {
    // Optionally remove stored credentials
    if (req.user && req.user.id) {
      credentialsService.removeCredentials(req.user.id);
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
  getDeviceStatus,
  logout
};
