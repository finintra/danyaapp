require('dotenv').config();

// Debug: Print environment variables
console.log('ODOO_URL:', process.env.ODOO_URL);
console.log('ODOO_DB:', process.env.ODOO_DB);
console.log('ODOO_USERNAME:', process.env.ODOO_USERNAME);
// Don't log the password for security reasons
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { errorHandler } = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const routes = require('./routes');

// Initialize express app
const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Parse JSON bodies
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } })); // HTTP request logging

// Routes
app.use('/flf/api/v1', routes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use(errorHandler);

// Start the server
app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  // Close server & exit process
  process.exit(1);
});

module.exports = app; // For testing purposes
