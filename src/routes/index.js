const express = require('express');
const authRoutes = require('./authRoutes');
const taskRoutes = require('./taskRoutes');
const analyticsRoutes = require('./analyticsRoutes');

const router = express.Router();

// Mount routes
router.use('/', authRoutes);
router.use('/', taskRoutes);
router.use('/analytics', analyticsRoutes);

module.exports = router;
