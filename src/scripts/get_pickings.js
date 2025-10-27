require('dotenv').config();
const odooService = require('../services/odooService');
const logger = require('../utils/logger');

/**
 * Get all pickings from Odoo
 */
async function getPickings() {
  try {
    console.log('Connecting to Odoo...');
    await odooService.init();
    console.log('Connected to Odoo!');

    // Get all pickings
    console.log('Getting all pickings...');
    const pickings = await odooService.execute('stock.picking', 'search_read', [], { 
      fields: ['id', 'name', 'state', 'partner_id', 'origin', 'date', 'move_line_ids'],
      limit: 10
    });
    
    if (!pickings || pickings.length === 0) {
      console.log('No pickings found');
      return;
    }
    
    console.log(`Found ${pickings.length} pickings:`);
    pickings.forEach(picking => {
      console.log(`ID: ${picking.id}, Name: ${picking.name}, State: ${picking.state}, Origin: ${picking.origin}, Date: ${picking.date}, Move Lines: ${picking.move_line_ids.length}`);
    });
    
    // Get details of the first picking
    const firstPicking = pickings[0];
    console.log(`\nGetting details for picking ${firstPicking.name} (ID: ${firstPicking.id})...`);
    
    // Get move lines
    const moveLines = await odooService.execute('stock.move.line', 'search_read', [
      [['id', 'in', firstPicking.move_line_ids]]
    ], { 
      fields: [
        'id', 'product_id', 'product_uom_qty', 'qty_done', 
        'product_uom_id', 'state'
      ] 
    });
    
    // Get product info for each move line
    const productIds = moveLines.map(line => line.product_id[0]);
    const products = await odooService.execute('product.product', 'search_read', [
      [['id', 'in', productIds]]
    ], { 
      fields: ['id', 'name', 'barcode', 'default_code'] 
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
        required: line.product_uom_qty,
        done: line.qty_done,
        remain: line.product_uom_qty - line.qty_done,
        barcode: product ? product.barcode : null
      };
    });
    
    console.log('\nPicking details:');
    console.log(JSON.stringify({
      picking: {
        id: firstPicking.id,
        name: firstPicking.name,
        state: firstPicking.state,
        date: firstPicking.date,
        partner_name: firstPicking.partner_id ? firstPicking.partner_id[1] : 'Unknown'
      },
      lines: formattedLines
    }, null, 2));
    
  } catch (error) {
    console.error('Error getting pickings:', error);
    logger.error('Error getting pickings:', error);
  }
}

// Run the function
getPickings().then(() => {
  console.log('Script completed');
  process.exit(0);
}).catch(error => {
  console.error('Script failed:', error);
  process.exit(1);
});
