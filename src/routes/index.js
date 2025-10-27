const express = require('express');
const authRoutes = require('./authRoutes');
const taskRoutes = require('./taskRoutes');

const router = express.Router();

// Mount routes
router.use('/', authRoutes);
router.use('/', taskRoutes);

module.exports = router;
