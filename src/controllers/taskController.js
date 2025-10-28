const { validationResult } = require('express-validator');
const odooService = require('../services/odooService');
const { ApiError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * @desc    Attach to picking
 * @route   POST /flf/api/v1/task/attach
 * @access  Private
 */
const attachToPicking = async (req, res, next) => {
  try {
    // Log the request body for debugging
    console.log('Request body:', req.body);
    
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Validation errors:', errors.array());
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { picking_barcode } = req.body;
    
    // Get user language from request user object
    const userLang = req.user?.lang || 'uk_UA';
    console.log(`Using user language: ${userLang}`);

    // Get picking by barcode with user language
    const result = await odooService.getPickingByBarcode(picking_barcode, userLang);

    // Return success response
    res.status(200).json({
      ok: true,
      ...result
    });
  } catch (error) {
    if (error.message === 'PICKING_NOT_FOUND') {
      return res.status(404).json({
        ok: false,
        error: 'НЕ ТА НАКЛАДНА. СКАНУЙ ПРАВИЛЬНУ'
      });
    }

    if (error.message === 'ORDER_LOCKED') {
      return res.status(409).json({
        ok: false,
        error: 'ORDER_LOCKED'
      });
    }

    next(error);
  }
};

/**
 * @desc    Scan item
 * @route   POST /flf/api/v1/scan/item
 * @access  Private
 */
const scanItem = async (req, res, next) => {
  console.log('=== SCAN ITEM CONTROLLER DEBUG ===');
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Validation errors:', errors.array());
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { picking_id, barcode, expected_product_id } = req.body;
    console.log(`Received scan request: picking_id=${picking_id}, barcode="${barcode}", expected_product_id=${expected_product_id}`);
    
    // Get user language from request user object
    const userLang = req.user?.lang || 'uk_UA';
    console.log(`Using user language for item scan: ${userLang}`);

    // Перш ніж валідувати сканування, знайдемо товар за штрих-кодом
    const products = await odooService.findProductByBarcode(barcode, userLang);
    
    if (!products || products.length === 0) {
      console.log(`No product found with barcode: ${barcode}`);
      return res.status(404).json({
        ok: false,
        error: 'NOT_IN_ORDER'
      });
    }
    
    const scannedProductId = products[0].id;
    console.log(`Found product: ${products[0].name} (ID: ${scannedProductId})`);
    
    // Перевіряємо, чи відсканований товар відповідає очікуваному
    if (expected_product_id && Number(scannedProductId) !== Number(expected_product_id)) {
      console.log(`Wrong product scanned: expected ${expected_product_id}, got ${scannedProductId}`);
      return res.status(409).json({
        ok: false,
        error: 'WRONG_ORDER'
      });
    }
    
    // Якщо товар відповідає очікуваному, валідуємо сканування
    console.log(`Calling odooService.validateItemScan with picking_id=${picking_id}, barcode="${barcode}", userLang=${userLang}`);
    const result = await odooService.validateItemScan(picking_id, barcode, userLang);
    console.log(`validateItemScan successful, result:`, result);

    // Return success response
    console.log('Sending success response');
    res.status(200).json({
      ok: true,
      ...result
    });
    console.log('Success response sent');
  } catch (error) {
    console.log(`Error in scanItem: ${error.message}`);
    console.log(error.stack);
    
    if (error.message === 'NOT_IN_ORDER') {
      console.log('Sending NOT_IN_ORDER error response');
      return res.status(404).json({
        ok: false,
        error: 'NOT_IN_ORDER'
      });
    }

    if (error.message === 'OVERPICK') {
      console.log('Sending OVERPICK error response');
      return res.status(409).json({
        ok: false,
        error: 'OVERPICK'
      });
    }
    
    if (error.message === 'WRONG_ORDER') {
      console.log('Sending WRONG_ORDER error response');
      return res.status(409).json({
        ok: false,
        error: 'WRONG_ORDER'
      });
    }

    next(error);
  }
};

/**
 * @desc    Validate picking
 * @route   POST /flf/api/v1/validate
 * @access  Private
 */
const validatePicking = async (req, res, next) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return next(new ApiError(400, 'Validation error', false, { errors: errors.array() }));
    }

    const { picking_id, payload } = req.body;

    // Validate picking
    const result = await odooService.validatePicking(picking_id, payload);

    // Return success response
    res.status(200).json({
      ok: true,
      ...result
    });
  } catch (error) {
    if (error.message === 'MISMATCH') {
      return res.status(409).json({
        ok: false,
        error: 'MISMATCH',
        diffs: error.data?.diffs || []
      });
    }

    if (error.message === 'ORDER_LOCKED') {
      return res.status(409).json({
        ok: false,
        error: 'ORDER_LOCKED'
      });
    }

    next(error);
  }
};

/**
 * @desc    Cancel local picking
 * @route   POST /flf/api/v1/cancel_local
 * @access  Private
 */
const cancelLocalPicking = async (req, res, next) => {
  try {
    const { picking_id } = req.body;
    
    if (!picking_id) {
      return res.status(400).json({
        ok: false,
        error: 'PICKING_ID_REQUIRED'
      });
    }
    
    // Reset progress for this picking
    await odooService.resetPickingProgress(picking_id);
    
    res.status(200).json({
      ok: true,
      message: 'Picking progress reset successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get available tasks
 * @route   GET /flf/api/v1/tasks/available
 * @access  Private
 */
const getAvailableTasks = async (req, res, next) => {
  try {
    // Get available pickings from Odoo
    const pickings = await odooService.execute('stock.picking', 'search_read', [
      [['state', '=', 'assigned']]
    ], { 
      fields: ['id', 'name', 'date', 'partner_id', 'move_line_ids'] 
    });

    // Format response
    const formattedPickings = pickings.map(picking => ({
      id: picking.id,
      name: picking.name,
      date: picking.date,
      partner_name: picking.partner_id ? picking.partner_id[1] : 'Unknown',
      products_count: picking.move_line_ids.length
    }));

    // Return success response
    res.status(200).json({
      ok: true,
      pickings: formattedPickings
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get task details
 * @route   GET /flf/api/v1/task/:pickingId
 * @access  Private
 */
const getTaskDetails = async (req, res, next) => {
  try {
    const pickingId = parseInt(req.params.pickingId);
    
    // Get user language from request user object
    const userLang = req.user?.lang || 'uk_UA';
    console.log(`Using user language for task details: ${userLang}`);
    
    // Set context with user language
    const context = { lang: userLang };

    // Get picking details
    const pickings = await odooService.execute('stock.picking', 'search_read', [
      [['id', '=', pickingId]]
    ], { 
      fields: ['id', 'name', 'date', 'partner_id', 'move_line_ids'],
      context: context // Pass the language context
    });

    if (!pickings || pickings.length === 0) {
      return next(new ApiError(404, 'PICKING_NOT_FOUND'));
    }

    const picking = pickings[0];

    // Get move lines
    const moveLines = await odooService.execute('stock.move.line', 'search_read', [
      [['id', 'in', picking.move_line_ids]]
    ], { 
      fields: [
        'id', 'product_id', 'product_uom_qty', 'qty_done', 
        'product_uom_id', 'state'
      ] 
    });

    // Get product info for each move line with user language
    const productIds = moveLines.map(line => line.product_id[0]);
    const products = await odooService.execute('product.product', 'search_read', [
      [['id', 'in', productIds]]
    ], { 
      fields: ['id', 'name', 'barcode', 'default_code', 'list_price', 'uom_id'],
      context: context // Pass the language context
    });

    // Create a map of product info
    const productMap = {};
    products.forEach(product => {
      productMap[product.id] = product;
    });

    // Format move lines with product info
    const formattedLines = moveLines.map(line => {
      const product = productMap[line.product_id[0]];
      return {
        line_id: line.id,
        product_id: line.product_id[0],
        product_name: product ? product.name : 'Unknown Product',
        product_code: product ? product.default_code : null,
        price: product ? product.list_price : 0,
        uom: product && product.uom_id ? product.uom_id[1] : 'Units',
        required: line.product_uom_qty,
        done: line.qty_done,
        remain: line.product_uom_qty - line.qty_done,
        barcode: product ? product.barcode : null
      };
    });

    // Return success response
    res.status(200).json({
      ok: true,
      picking: {
        id: picking.id,
        name: picking.name,
        date: picking.date,
        partner_name: picking.partner_id ? picking.partner_id[1] : 'Unknown'
      },
      lines: formattedLines
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  attachToPicking,
  scanItem,
  validatePicking,
  cancelLocalPicking,
  getAvailableTasks,
  getTaskDetails
};
