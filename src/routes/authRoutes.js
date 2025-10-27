const express = require('express');
const { login, loginWithBadge, getDeviceStatus, logout } = require('../controllers/authController');
const { loginValidator, loginWithBadgeValidator } = require('../validators/authValidators');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Public routes
router.post('/login', loginValidator, login);
router.post('/login_badge', loginWithBadgeValidator, loginWithBadge);

// Protected routes
router.get('/device/status', protect, getDeviceStatus);
router.post('/logout', protect, logout);

module.exports = router;
