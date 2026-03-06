const express = require('express');
const { login, loginWithBadge, loginWithPin, createPin, getDeviceStatus, logout } = require('../controllers/authController');
const { loginValidator, loginWithBadgeValidator, loginWithPinValidator, createPinValidator } = require('../validators/authValidators');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Public routes
router.post('/login', loginValidator, login);
router.post('/login_badge', loginWithBadgeValidator, loginWithBadge);
router.post('/login_pin', loginWithPinValidator, loginWithPin);
router.post('/create_pin', createPinValidator, createPin);

// Protected routes
router.get('/device/status', protect, getDeviceStatus);
router.post('/logout', protect, logout);

module.exports = router;
