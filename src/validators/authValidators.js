const { body } = require('express-validator');

const loginWithBadgeValidator = [
  body('badge_barcode')
    .notEmpty()
    .withMessage('Badge barcode is required'),
  body('pin')
    .notEmpty()
    .withMessage('PIN is required')
    .isLength({ min: 4, max: 6 })
    .withMessage('PIN must be between 4 and 6 digits')
    .isNumeric()
    .withMessage('PIN must contain only digits')
];

const loginValidator = [
  body('login')
    .notEmpty()
    .withMessage('Login is required'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

const loginWithPinValidator = [
  body('pin')
    .notEmpty()
    .withMessage('PIN is required')
    .isLength({ min: 4, max: 10 })
    .withMessage('PIN must be between 4 and 10 characters'),
  body('token')
    .notEmpty()
    .withMessage('Token is required')
    .isString()
    .withMessage('Token must be a string')
];

const createPinValidator = [
  body('pin')
    .notEmpty()
    .withMessage('PIN is required')
    .isLength({ min: 4, max: 10 })
    .withMessage('PIN must be between 4 and 10 characters'),
  body('pin_confirm')
    .notEmpty()
    .withMessage('PIN confirmation is required')
    .isLength({ min: 4, max: 10 })
    .withMessage('PIN confirmation must be between 4 and 10 characters'),
  body('token')
    .notEmpty()
    .withMessage('Token is required')
    .isString()
    .withMessage('Token must be a string')
];

module.exports = {
  loginWithBadgeValidator,
  loginValidator,
  loginWithPinValidator,
  createPinValidator
};
