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

module.exports = {
  loginWithBadgeValidator,
  loginValidator
};
