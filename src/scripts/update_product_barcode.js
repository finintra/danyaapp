require('dotenv').config();
const odooService = require('../services/odooService');
const logger = require('../utils/logger');

/**
 * Update product barcode
 */
async function updateProductBarcode() {
  try {
    console.log('Connecting to Odoo...');
    await odooService.init();
    console.log('Connected to Odoo!');

    // Product ID to update
    const productId = 17; // Large Cabinet
    const barcode = '7777777777777'; // New barcode
    
    // Update product barcode
    console.log(`Updating barcode for product ID ${productId}...`);
    await odooService.execute('product.product', 'write', [
      [productId],
      { barcode: barcode }
    ]);
    
    console.log(`Barcode updated successfully to ${barcode}`);
    
    // Verify the update
    const products = await odooService.execute('product.product', 'search_read', [
      [['id', '=', productId]]
    ], { fields: ['id', 'name', 'barcode', 'default_code'] });
    
    if (products && products.length > 0) {
      console.log('Updated product:', products[0]);
    } else {
      console.log('Product not found');
    }
    
  } catch (error) {
    console.error('Error updating product barcode:', error);
    logger.error('Error updating product barcode:', error);
  }
}

// Run the function
updateProductBarcode().then(() => {
  console.log('Script completed');
  process.exit(0);
}).catch(error => {
  console.error('Script failed:', error);
  process.exit(1);
});
