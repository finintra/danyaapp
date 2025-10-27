require('dotenv').config();
const odooService = require('../services/odooService');
const logger = require('../utils/logger');

/**
 * Create test data in Odoo
 */
async function createTestData() {
  try {
    console.log('Connecting to Odoo...');
    await odooService.init();
    console.log('Connected to Odoo!');

    // Create a test picking with OUT/00007
    console.log('Creating test picking OUT/00007...');
    
    // Check if picking already exists
    const existingPickings = await odooService.execute('stock.picking', 'search_read', [
      [['name', '=', 'OUT/00007']]
    ], { fields: ['id'] });
    
    if (existingPickings && existingPickings.length > 0) {
      console.log('Picking OUT/00007 already exists with ID:', existingPickings[0].id);
      
      // Delete existing picking
      console.log('Deleting existing picking...');
      await odooService.execute('stock.picking', 'unlink', [existingPickings[0].id]);
      console.log('Existing picking deleted.');
    }
    
    // Get warehouse
    const warehouses = await odooService.execute('stock.warehouse', 'search_read', [], { limit: 1 });
    if (!warehouses || warehouses.length === 0) {
      throw new Error('No warehouses found');
    }
    const warehouseId = warehouses[0].id;
    
    // Get picking type for outgoing transfers
    const pickingTypes = await odooService.execute('stock.picking.type', 'search_read', [
      [
        ['warehouse_id', '=', warehouseId],
        ['code', '=', 'outgoing']
      ]
    ], { limit: 1 });
    
    if (!pickingTypes || pickingTypes.length === 0) {
      throw new Error('No outgoing picking type found');
    }
    const pickingTypeId = pickingTypes[0].id;
    
    // Get a customer
    const partners = await odooService.execute('res.partner', 'search_read', [
      [['is_company', '=', true]]
    ], { limit: 1 });
    
    if (!partners || partners.length === 0) {
      throw new Error('No customers found');
    }
    const partnerId = partners[0].id;
    
    // Get stock locations
    const stockLocations = await odooService.execute('stock.location', 'search_read', [
      [['usage', '=', 'internal']]
    ], { limit: 1 });
    
    if (!stockLocations || stockLocations.length === 0) {
      throw new Error('No stock locations found');
    }
    const stockLocationId = stockLocations[0].id;
    
    const customerLocations = await odooService.execute('stock.location', 'search_read', [
      [['usage', '=', 'customer']]
    ], { limit: 1 });
    
    if (!customerLocations || customerLocations.length === 0) {
      throw new Error('No customer locations found');
    }
    const customerLocationId = customerLocations[0].id;
    
    // Get products with barcodes
    const products = await odooService.execute('product.product', 'search_read', [
      [
        ['type', '=', 'product'],
        ['barcode', '!=', false]
      ]
    ], { fields: ['id', 'name', 'barcode'], limit: 5 });
    
    if (!products || products.length === 0) {
      throw new Error('No products with barcodes found');
    }
    
    console.log('Found products:', products.map(p => `${p.name} (${p.barcode})`).join(', '));
    
    // Create picking
    const pickingId = await odooService.execute('stock.picking', 'create', [{
      name: 'OUT/00007',
      partner_id: partnerId,
      picking_type_id: pickingTypeId,
      location_id: stockLocationId,
      location_dest_id: customerLocationId,
      state: 'assigned',
      origin: 'Test Order'
    }]);
    
    console.log('Created picking with ID:', pickingId);
    
    // Create stock moves
    for (const product of products) {
      const moveId = await odooService.execute('stock.move', 'create', [{
        name: product.name,
        product_id: product.id,
        product_uom_qty: Math.floor(Math.random() * 5) + 1, // Random quantity between 1 and 5
        product_uom: 1, // Default UoM (usually 'Units')
        picking_id: pickingId,
        location_id: stockLocationId,
        location_dest_id: customerLocationId
      }]);
      
      console.log(`Created move for product ${product.name} with ID: ${moveId}`);
    }
    
    // Confirm picking to create move lines
    await odooService.execute('stock.picking', 'action_confirm', [pickingId]);
    console.log('Picking confirmed');
    
    // Check availability to set state to 'assigned'
    await odooService.execute('stock.picking', 'action_assign', [pickingId]);
    console.log('Picking availability checked');
    
    console.log('Test data created successfully!');
    
  } catch (error) {
    console.error('Error creating test data:', error);
    logger.error('Error creating test data:', error);
  }
}

// Run the function
createTestData().then(() => {
  console.log('Script completed');
  process.exit(0);
}).catch(error => {
  console.error('Script failed:', error);
  process.exit(1);
});
