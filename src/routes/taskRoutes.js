const express = require('express');
const {
  attachToPicking,
  scanItem,
  validatePicking,
  cancelLocalPicking,
  getAvailableTasks,
  getTaskDetails
} = require('../controllers/taskController');
const {
  attachToPickingValidator,
  scanItemValidator,
  validatePickingValidator
} = require('../validators/taskValidators');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protected routes
router.post('/task/attach', protect, attachToPickingValidator, attachToPicking);
router.post('/scan/item', protect, scanItemValidator, scanItem);
router.post('/validate', protect, validatePickingValidator, validatePicking);
router.post('/cancel_local', protect, cancelLocalPicking);
router.get('/tasks/available', protect, getAvailableTasks);
router.get('/task/:pickingId', protect, getTaskDetails);

module.exports = router;
