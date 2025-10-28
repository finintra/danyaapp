const { body } = require('express-validator');

const attachToPickingValidator = [
  body('picking_barcode')
    .notEmpty()
    .withMessage('Picking barcode is required')
];

const scanItemValidator = [
  body('picking_id')
    .notEmpty()
    .withMessage('Picking ID is required')
    .isNumeric()
    .withMessage('Picking ID must be a number'),
  body('barcode')
    .notEmpty()
    .withMessage('Barcode is required'),
  body('expected_product_id')
    .optional()
    .isNumeric()
    .withMessage('Expected product ID must be a number')
];

const validatePickingValidator = [
  body('picking_id')
    .notEmpty()
    .withMessage('Picking ID is required')
    .isNumeric()
    .withMessage('Picking ID must be a number'),
  body('payload')
    .isArray()
    .withMessage('Payload must be an array'),
  body('payload.*.line_id')
    .notEmpty()
    .withMessage('Line ID is required')
    .isNumeric()
    .withMessage('Line ID must be a number'),
  body('payload.*.product_id')
    .notEmpty()
    .withMessage('Product ID is required')
    .isNumeric()
    .withMessage('Product ID must be a number'),
  body('payload.*.qty')
    .notEmpty()
    .withMessage('Quantity is required')
    .isNumeric()
    .withMessage('Quantity must be a number')
];

module.exports = {
  attachToPickingValidator,
  scanItemValidator,
  validatePickingValidator
};
