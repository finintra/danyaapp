const axios = require('axios');
const logger = require('../utils/logger');
const { ApiError } = require('../middleware/errorHandler');

class OdooService {
  constructor() {
    this.url = process.env.ODOO_URL;
    this.db = process.env.ODOO_DB;
    // Default credentials from env (for backward compatibility)
    this.defaultUsername = process.env.ODOO_USERNAME;
    this.defaultPassword = process.env.ODOO_PASSWORD;
    // Per-user credentials (userId -> {username, password, uid})
    this.userCredentials = new Map();
    this.apiKey = process.env.ODOO_API_KEY;
  }

  /**
   * Set credentials for a specific user
   * @param {number} userId - User ID
   * @param {string} username - Username
   * @param {string} password - Password
   */
  setUserCredentials(userId, username, password) {
    this.userCredentials.set(userId, {
      username,
      password,
      uid: null
    });
  }

  /**
   * Get credentials for a user or use defaults
   * @param {number|null} userId - User ID (null for default)
   * @returns {Object} - {username, password, uid}
   */
  getCredentials(userId = null) {
    if (userId && this.userCredentials.has(userId)) {
      return this.userCredentials.get(userId);
    }
    return {
      username: this.defaultUsername,
      password: this.defaultPassword,
      uid: null
    };
  }

  /**
   * Initialize connection to Odoo for a specific user
   * @param {number|null} userId - User ID (null for default credentials)
   */
  async init(userId = null) {
    try {
      const creds = this.getCredentials(userId);
      
      // Debug connection parameters
      console.log('Connecting to Odoo with URL:', this.url);
      console.log('Database:', this.db);
      console.log('Username:', creds.username);
      
      const requestUrl = `${this.url}/jsonrpc`;
      console.log('Request URL:', requestUrl);
      
      // Authenticate with Odoo
      const response = await axios.post(requestUrl, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          service: 'common',
          method: 'authenticate',
          args: [this.db, creds.username, creds.password, {}]
        },
        id: Math.floor(Math.random() * 1000000)
      }, {
        headers: {
          'X-db-name': this.db
        }
      });

      console.log('Odoo response status:', response.status);
      console.log('Odoo response data:', JSON.stringify(response.data));

      if (response.data.error) {
        console.error('Odoo authentication error:', response.data.error);
        throw new ApiError(500, `Odoo authentication error: ${response.data.error.message}`);
      }

      const uid = response.data.result;
      
      // Check if authentication failed (Odoo returns false on auth failure)
      if (uid === false || uid === null || uid === undefined) {
        console.error('Odoo authentication returned false/null/undefined');
        console.error('Username used:', creds.username);
        console.error('Database:', this.db);
        throw new ApiError(500, 'Odoo authentication failed: Invalid credentials');
      }
      
      // Ensure uid is a number
      const numericUid = typeof uid === 'number' ? uid : parseInt(uid, 10);
      if (isNaN(numericUid) || numericUid <= 0) {
        console.error('Invalid UID received from Odoo:', uid);
        throw new ApiError(500, 'Odoo authentication failed: Invalid UID received');
      }
      
      if (userId && this.userCredentials.has(userId)) {
        this.userCredentials.get(userId).uid = numericUid;
      } else {
        // For backward compatibility, store in old location
        this.defaultUid = numericUid;
      }
      
      logger.info(`Connected to Odoo with UID: ${numericUid} for user ${userId || 'default'}`);
      return numericUid;
    } catch (error) {
      console.error('Failed to connect to Odoo:', error.message);
      if (error.response) {
        console.error('Response data:', error.response.data);
        console.error('Response status:', error.response.status);
      }
      logger.error('Failed to connect to Odoo:', error);
      throw new ApiError(500, 'Failed to connect to Odoo');
    }
  }

  /**
   * Execute RPC call to Odoo
   * @param {string} model - Odoo model name
   * @param {string} method - Method to call
   * @param {Array} args - Arguments for the method
   * @param {Object} kwargs - Keyword arguments
   * @param {number|null} userId - User ID (null for default credentials)
   * @returns {Promise<any>} - Response from Odoo
   */
  async execute(model, method, args = [], kwargs = {}, userId = null) {
    try {
      const creds = this.getCredentials(userId);
      
      // Check if credentials exist
      if (!creds || !creds.username || !creds.password) {
        logger.error(`Missing credentials for user ${userId || 'default'}`);
        logger.error(`Credentials object:`, creds ? JSON.stringify({ hasUsername: !!creds.username, hasPassword: !!creds.password }) : 'null');
        throw new ApiError(500, 'Odoo credentials not configured');
      }
      
      // Initialize connection if needed
      let uid = creds.uid;
      if (!uid || uid === false) {
        uid = await this.init(userId);
      }
      
      // Validate UID after initialization
      if (!uid || uid === false || typeof uid !== 'number' || uid <= 0) {
        logger.error(`Invalid UID after initialization: ${uid} for user ${userId || 'default'}`);
        throw new ApiError(500, 'Failed to authenticate with Odoo: Invalid UID');
      }

      const requestPayload = {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          service: 'object',
          method: 'execute_kw',
          args: [this.db, uid, creds.password, model, method, args, kwargs]
        },
        id: Math.floor(Math.random() * 1000000)
      };
      
      // Log request details for debugging
      console.log(`Executing ${model}.${method}:`, {
        db: this.db,
        uid: uid,
        args: args,
        kwargs: kwargs
      });
      
      const response = await axios.post(`${this.url}/jsonrpc`, requestPayload, {
        headers: {
          'X-db-name': this.db
        }
      });

      // Log full response for debugging
      console.log(`Odoo response for ${model}.${method}:`, {
        status: response.status,
        data: JSON.stringify(response.data, null, 2)
      });

      if (response.data.error) {
        const errorDetails = response.data.error;
        const errorInfo = {
          message: errorDetails.message,
          code: errorDetails.code,
          data: errorDetails.data,
          name: errorDetails.name,
          debug: errorDetails.debug,
          fullError: JSON.stringify(errorDetails, null, 2)
        };
        console.error(`Odoo execution error for ${model}.${method}:`, errorInfo);
        logger.error(`Odoo execution error for ${model}.${method}:`, errorInfo);
        throw new ApiError(500, `Odoo execution error: ${errorDetails.message || JSON.stringify(errorDetails)}`);
      }

      return response.data.result;
    } catch (error) {
      logger.error(`Error executing ${model}.${method}:`, error);
      if (error.response) {
        logger.error(`Response status: ${error.response.status}`);
        logger.error(`Response data: ${JSON.stringify(error.response.data, null, 2)}`);
      }
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, `Error executing ${model}.${method}: ${error.message}`);
    }
  }

  /**
   * Validate user badge and PIN
   * @param {string} badgeBarcode - Badge barcode
   * @param {string} pin - User PIN
   * @returns {Promise<Object>} - User info
   */
  /**
   * Authenticate user with login and password
   * @param {string} login - User login
   * @param {string} password - User password
   * @returns {Promise<Object>} - User info
   */
  async authenticateUser(login, password) {
    try {
      console.log(`Authenticating user with login: ${login}`);
      
      // Authenticate directly with Odoo session
      const response = await axios.post(`${this.url}/web/session/authenticate`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          db: this.db,
          login: login,
          password: password
        },
        id: Math.floor(Math.random() * 1000000)
      }, {
        headers: {
          'X-db-name': this.db
        }
      });

      console.log('Authentication response status:', response.status);
      
      if (response.data.error) {
        console.error('Authentication error:', response.data.error);
        throw new ApiError(401, 'INVALID_CREDENTIALS');
      }

      const result = response.data.result;
      console.log('Authentication result:', JSON.stringify(result));
      
      if (!result || !result.uid) {
        throw new ApiError(401, 'INVALID_CREDENTIALS');
      }

      // Set credentials for this user for future requests
      this.setUserCredentials(result.uid, login, password);

      // Get user details with employee_id and language
      const users = await this.execute('res.users', 'read', [
        [result.uid]
      ], { fields: ['id', 'name', 'login', 'active', 'employee_id', 'lang'] }, result.uid);

      if (!users || users.length === 0) {
        throw new ApiError(401, 'INVALID_CREDENTIALS');
      }

      const user = users[0];
      
      if (!user.active) {
        throw new ApiError(403, 'ARCHIVED');
      }
      
      // Create the user object to return
      const userObject = {
        id: user.id,
        name: user.name,
        login: user.login,
        active: user.active,
        lang: user.lang || 'uk_UA' // Default to Ukrainian if not set
      };
      
      // If user has an employee_id, get the employee details including PIN
      if (user.employee_id && user.employee_id[0]) {
        console.log(`User ${user.login} has employee_id: ${user.employee_id[0]}`);
        
        try {
          const employees = await this.execute('hr.employee', 'read', [
            [user.employee_id[0]]
          ], { fields: ['id', 'name', 'pin', 'active', 'lang'] }, result.uid);
          
          if (employees && employees.length > 0) {
            const employee = employees[0];
            console.log(`Found employee for user ${user.login}:`, employee);
            
            // Add employee information to the user object
            userObject.employee_id = employee.id;
            userObject.employee = {
              id: employee.id,
              name: employee.name,
              pin: employee.pin,
              active: employee.active,
              lang: employee.lang || userObject.lang // Use employee language if available
            };
            
            // Update user language if employee has a language set
            if (employee.lang) {
              userObject.lang = employee.lang;
            }
            
            console.log(`Added employee data with PIN: ${employee.pin} to user object`);
          }
        } catch (empError) {
          console.error(`Error fetching employee data for user ${user.login}:`, empError);
          // Don't fail if we can't get employee data, just continue without it
        }
      } else {
        console.log(`User ${user.login} does not have an associated employee - this is OK, PIN will be stored on backend`);
        // Ensure employee is null/undefined, not missing
        userObject.employee_id = null;
        userObject.employee = null;
      }

      return userObject;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('Error authenticating user:', error.message);
      if (error.response) {
        console.error('Response data:', error.response.data);
        console.error('Response status:', error.response.status);
      }
      logger.error('Error authenticating user:', error);
      throw new ApiError(401, 'INVALID_CREDENTIALS');
    }
  }

  async validateBadgeAndPin(badgeBarcode, pin) {
    try {
      // Find employee by badge barcode (using default credentials as we don't have user yet)
      const employees = await this.execute('hr.employee', 'search_read', [
        [['barcode', '=', badgeBarcode]]
      ], { fields: ['id', 'name', 'user_id', 'active', 'pin', 'lang'] }, null);

      if (!employees || employees.length === 0) {
        throw new ApiError(401, 'BADGE_OR_PIN');
      }

      const employee = employees[0];
      
      if (!employee.active) {
        throw new ApiError(403, 'ARCHIVED');
      }

      // Validate PIN directly from employee record
      if (!employee.pin || employee.pin !== pin) {
        throw new ApiError(401, 'BADGE_OR_PIN');
      }

      // Check if employee has a user account
      if (!employee.user_id || !employee.user_id[0]) {
        throw new ApiError(401, 'NO_USER_ACCOUNT');
      }

      const userId = employee.user_id[0];
      
      // Get user info to check if user is active and get language
      const users = await this.execute('res.users', 'read', [
        [userId]
      ], { fields: ['active', 'lang'] }, null);
      
      if (!users || users.length === 0 || !users[0].active) {
        throw new ApiError(403, 'ARCHIVED');
      }

      // Determine language - prefer employee language, fallback to user language, then default
      let userLang = employee.lang;
      if (!userLang && users[0].lang) {
        userLang = users[0].lang;
      }
      if (!userLang) {
        userLang = 'uk_UA'; // Default to Ukrainian
      }
      
      return {
        id: userId,
        name: employee.name,
        active: true,
        employee_id: employee.id,
        lang: userLang,
        employee: {
          id: employee.id,
          name: employee.name,
          pin: employee.pin,
          active: employee.active,
          lang: employee.lang
        }
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      logger.error('Error validating badge and PIN:', error);
      throw new ApiError(500, 'Error validating badge and PIN');
    }
  }

  /**
   * Get picking by barcode and reset progress
   * @param {string} pickingBarcode - Picking barcode
   * @param {string} [userLang='uk_UA'] - User language code
   * @param {number|null} [userId=null] - User ID for credentials
   * @returns {Promise<Object>} - Picking info
   */
  async getPickingByBarcode(pickingBarcode, userLang = 'uk_UA', userId = null) {
    try {
      // Find picking by barcode
      const pickings = await this.execute('stock.picking', 'search_read', [
        [['name', '=', pickingBarcode]]
      ], { fields: ['id', 'name', 'state', 'move_line_ids'] }, userId);

      if (!pickings || pickings.length === 0) {
        throw new ApiError(404, 'PICKING_NOT_FOUND');
      }

      const picking = pickings[0];
      
      if (picking.state === 'done' || picking.state === 'cancel') {
        throw new ApiError(409, 'ORDER_LOCKED');
      }

      // Reset progress for all move lines
      for (const moveLineId of picking.move_line_ids) {
        await this.execute('stock.move.line', 'write', [
          [moveLineId],
          { qty_done: 0 }
        ], {}, userId);
      }
      
      // Get move lines with reset progress and location information
      const moveLines = await this.execute('stock.move.line', 'search_read', [
        [['id', 'in', picking.move_line_ids]]
      ], { 
        fields: [
          'id', 'product_id', 'product_uom_qty', 'qty_done', 
          'product_uom_id', 'state', 'location_id'
        ] 
      }, userId);
      
      console.log('Reset progress for picking:', pickingBarcode);

      // Get product info for each move line with translations based on user language
      const productIds = moveLines.map(line => line.product_id[0]);
      
      // Set the language context for product names
      const context = { lang: userLang };
      console.log(`Using language context for products: ${userLang}`);
      
      const products = await this.execute('product.product', 'search_read', [
        [['id', 'in', productIds]]
      ], { 
        fields: ['id', 'name', 'barcode', 'default_code', 'list_price', 'uom_id'],
        context: context // Pass the language context
      }, userId);

      // Create a map of product info
      const productMap = {};
      products.forEach(product => {
        productMap[product.id] = product;
      });

      // Get location information
      const locationIds = moveLines.map(line => line.location_id[0]);
      const locations = await this.execute('stock.location', 'search_read', [
        [['id', 'in', locationIds]]
      ], { 
        fields: ['id', 'name', 'complete_name'] 
      }, userId);
      
      // Create a map of location info
      const locationMap = {};
      locations.forEach(location => {
        locationMap[location.id] = location;
      });
      
      // Format move lines with product info and location
      const formattedLines = moveLines.map(line => {
        const product = productMap[line.product_id[0]];
        const location = line.location_id ? locationMap[line.location_id[0]] : null;
        const required = line.product_uom_qty;
        const done = line.qty_done;
        const remain = required - done;
        
        // Debugging information
        console.log('Line data:', {
          line_id: line.id,
          product_id: line.product_id[0],
          product_name: product ? product.name : 'Unknown Product',
          location: location ? location.name : 'Unknown Location',
          product_uom_qty: line.product_uom_qty,
          qty_done: line.qty_done,
          calculated_remain: remain
        });
        
        return {
          line_id: line.id,
          product_id: line.product_id[0],
          product_name: product ? product.name : 'Unknown Product',
          product_code: product ? product.default_code : null,
          price: product ? product.list_price : 0,
          uom: product && product.uom_id ? product.uom_id[1] : 'Units',
          required: required,
          done: done,
          remain: remain,
          barcode: product ? product.barcode : null,
          location: location ? location.name : null,
          location_complete: location ? location.complete_name : null
        };
      });

      // Get first line that needs work
      const firstLine = formattedLines.find(line => line.remain > 0) || formattedLines[0];

      return {
        picking: {
          id: picking.id,
          name: picking.name
        },
        line: firstLine,
        order_summary: {
          total_lines: formattedLines.length,
          completed_lines: formattedLines.filter(line => line.remain === 0).length
        }
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      logger.error('Error getting picking by barcode:', error);
      throw new ApiError(500, 'Error getting picking by barcode');
    }
  }

  /**
   * Find product by barcode or default_code
   * @param {string} code - Scanned code (default_code or barcode)
   * @param {string} [userLang='uk_UA'] - User language code
   * @param {number|null} [userId=null] - User ID for credentials
   * @returns {Promise<Array>} - Array of products
   */
  async findProductByBarcode(code, userLang = 'uk_UA', userId = null) {
    try {
      console.log(`Finding product with code: ${code}, userLang=${userLang}`);
      
      // Find product by default_code or barcode with user language
      const context = { lang: userLang };
      
      const products = await this.execute('product.product', 'search_read', [
        ['|', ['default_code', '=', code], ['barcode', '=', code]]
      ], { 
        fields: ['id', 'name', 'default_code', 'barcode'],
        context: context // Pass the language context
      }, userId);
      
      console.log(`Found ${products.length} products with code ${code}`);
      return products;
    } catch (error) {
      console.error(`Error finding product by barcode: ${error.message}`);
      throw error;
    }
  }
  
  /**
   * Validate item scan
   * @param {number} pickingId - Picking ID
   * @param {string} code - Scanned code (default_code or barcode)
   * @param {string} [userLang='uk_UA'] - User language code
   * @param {number|null} [userId=null] - User ID for credentials
   * @returns {Promise<Object>} - Scan result
   */
  async validateItemScan(pickingId, code, userLang = 'uk_UA', userId = null) {
    try {
      console.log(`Validating item scan: pickingId=${pickingId}, code=${code}, userLang=${userLang}`);
      
      // Find product by default_code or barcode with user language
      const context = { lang: userLang };
      console.log(`Using language context for product scan: ${userLang}`);
      
      const products = await this.execute('product.product', 'search_read', [
        ['|', ['default_code', '=', code], ['barcode', '=', code]]
      ], { 
        fields: ['id', 'name', 'default_code'],
        context: context // Pass the language context
      }, userId);

      if (!products || products.length === 0) {
        console.log(`No product found with code: ${code}`);
        throw new ApiError(404, 'NOT_IN_ORDER');
      }

      const productId = products[0].id;
      console.log(`Found product: ${products[0].name} (ID: ${productId})`);

      // Find move line for this product in the picking
      const moveLines = await this.execute('stock.move.line', 'search_read', [
        [
          ['picking_id', '=', pickingId],
          ['product_id', '=', productId]
        ]
      ], { 
        fields: ['id', 'product_uom_qty', 'qty_done', 'location_id', 'state', 'picking_id'] 
      }, userId);

      if (!moveLines || moveLines.length === 0) {
        console.log(`Product ${productId} is not in picking ${pickingId}`);
        throw new ApiError(404, 'NOT_IN_ORDER');
      }
      
      // Get all move lines for this picking to check order
      const allMoveLines = await this.execute('stock.move.line', 'search_read', [
        [['picking_id', '=', pickingId]]
      ], { 
        fields: ['id', 'product_id', 'product_uom_qty', 'qty_done'] 
      }, userId);
      
      console.log(`All move lines for picking ${pickingId}: ${JSON.stringify(allMoveLines)}`);
      
      // Сортуємо рядки за ID, щоб забезпечити послідовність
      allMoveLines.sort((a, b) => a.id - b.id);
      
      // Логуємо всі рядки для аналізу
      console.log('All move lines details (sorted by ID):');
      allMoveLines.forEach((ml, index) => {
        console.log(`Line ${index}: id=${ml.id}, product_id=${ml.product_id[0]}, qty_done=${ml.qty_done}, product_uom_qty=${ml.product_uom_qty}, remaining=${ml.product_uom_qty - ml.qty_done}`);
      });
      
      // Знаходимо перший незавершений рядок
      const incompleteLines = allMoveLines.filter(ml => ml.product_uom_qty > ml.qty_done && ml.product_uom_qty > 0);
      
      // Якщо немає незавершених рядків, дозволяємо сканувати будь-який товар
      if (incompleteLines.length === 0) {
        console.log('No incomplete lines found, allowing any product to be scanned');
        return;
      }
      
      // Сортуємо незавершені рядки за ID
      incompleteLines.sort((a, b) => a.id - b.id);
      
      // Перший незавершений рядок - це той, який повинен бути відсканований наступним
      const firstIncompleteLine = incompleteLines[0];
      
      console.log('First incomplete line:', firstIncompleteLine ? 
        `id=${firstIncompleteLine.id}, product_id=${firstIncompleteLine.product_id[0]}, qty_done=${firstIncompleteLine.qty_done}, product_uom_qty=${firstIncompleteLine.product_uom_qty}` : 
        'No incomplete lines found');
      console.log(`Scanned product ID: ${productId}`);
      
      // Перетворюємо ID товарів на числа для коректного порівняння
      const expectedProductId = firstIncompleteLine ? Number(firstIncompleteLine.product_id[0]) : null;
      const scannedProductId = Number(productId);
      
      console.log(`Comparing product IDs: expected=${expectedProductId}, scanned=${scannedProductId}, equal=${expectedProductId === scannedProductId}`);
      
      // Якщо відсканований товар не відповідає очікуваному, визначаємо причину
      if (expectedProductId !== scannedProductId) {
        // Перевіряємо, чи вже відскановано весь обсяг для цього товару
        try {
          const scannedProductLines = await this.execute('stock.move.line', 'search_read', [
            [
              ['picking_id', '=', pickingId],
              ['product_id', '=', scannedProductId]
            ]
          ], { 
            fields: ['id', 'product_uom_qty', 'qty_done'] 
          }, userId);

          const totalRequired = scannedProductLines.reduce((sum, l) => sum + (l.product_uom_qty || 0), 0);
          const totalDone = scannedProductLines.reduce((sum, l) => sum + (l.qty_done || 0), 0);
          const hasAnyRemain = scannedProductLines.some(l => (l.product_uom_qty || 0) > (l.qty_done || 0));

          if (scannedProductLines.length > 0 && (!hasAnyRemain || totalDone >= totalRequired)) {
            // Товар присутній у замовленні, але вже повністю відсканований
            throw new ApiError(409, 'ALREADY_SCANNED');
          }
        } catch (probeErr) {
          // Ігноруємо помилки перевірки, продовжимо як WRONG_ORDER
        }
        // Get product info for better logging
        const firstIncompleteProduct = await this.execute('product.product', 'search_read', [
          [['id', '=', firstIncompleteLine.product_id[0]]]
        ], { 
          fields: ['id', 'name', 'default_code'],
          context: context
        }, userId);
        
        const expectedProductName = firstIncompleteProduct.length > 0 ? firstIncompleteProduct[0].name : 'Unknown';
        const scannedProductName = products[0].name;
        
        console.log(`Wrong order: Expected product ${expectedProductName} (ID: ${expectedProductId}) but scanned ${scannedProductName} (ID: ${scannedProductId})`);
        throw new ApiError(409, 'WRONG_ORDER');
      }

      const line = moveLines[0];
      
      // Extract line ID - it might be a number or an array [id, name]
      const lineId = Array.isArray(line.id) ? line.id[0] : line.id;
      
      const required = line.product_uom_qty;
      const done = line.qty_done + 1; // Increment by 1 for this scan
      const remain = required - done;

      // Check if we're trying to pick more than required
      if (done > required) {
        throw new ApiError(409, 'OVERPICK');
      }
      
      // Log the write operation details
      console.log(`Updating stock.move.line with ID: ${lineId}, setting qty_done to: ${done}`);
      console.log(`Line details:`, {
        id: line.id,
        lineId: lineId,
        required: required,
        current_qty_done: line.qty_done,
        new_qty_done: done,
        state: line.state,
        picking_id: line.picking_id
      });
      
      // Check if line is in a state that allows writing
      if (line.state && line.state !== 'assigned' && line.state !== 'partially_available') {
        console.warn(`Warning: Move line state is ${line.state}, might not allow writing`);
      }
      
      // Update the quantity in Odoo
      try {
        await this.execute('stock.move.line', 'write', [
          [lineId],
          { qty_done: done }
        ], {}, userId);
        console.log(`Successfully updated stock.move.line ${lineId} with qty_done=${done}`);
      } catch (writeError) {
        console.error(`Failed to write to stock.move.line ${lineId}:`, writeError);
        console.error(`Line state: ${line.state}, picking_id: ${line.picking_id}`);
        throw writeError;
      }
      
      // Get updated line data
      const updatedLines = await this.execute('stock.move.line', 'search_read', [
        [['id', '=', lineId]]
      ], { fields: ['id', 'product_uom_qty', 'qty_done', 'location_id'] }, userId);
      
      const updatedLine = updatedLines[0];
      const updatedDone = updatedLine.qty_done;
      const updatedRemain = updatedLine.product_uom_qty - updatedDone;
      
      // Debugging information
      console.log('Updated line data:', {
        id: updatedLine.id,
        product_uom_qty: updatedLine.product_uom_qty,
        qty_done: updatedLine.qty_done,
        calculated_remain: updatedRemain
      });

      // Get location information
      let locationInfo = null;
      if (updatedLine.location_id) {
        const locations = await this.execute('stock.location', 'search_read', [
          [['id', '=', updatedLine.location_id[0]]]
        ], { 
          fields: ['id', 'name', 'complete_name'] 
        }, userId);
        
        if (locations && locations.length > 0) {
          locationInfo = {
            id: locations[0].id,
            name: locations[0].name,
            complete_name: locations[0].complete_name
          };
        }
      }
      
      // Now we update Odoo and return the updated values
      const result = {
        line: {
          required: updatedLine.product_uom_qty,
          done: updatedDone,
          remain: updatedRemain,
          location: locationInfo ? locationInfo.name : null,
          location_complete: locationInfo ? locationInfo.complete_name : null
        },
        row_completed: updatedRemain === 0,
        order_completed: false // We'll check this below
      };
      
      // If this row is completed, find the next line that needs work
      if (updatedRemain === 0) {
        try {
          // Get all move lines for this picking
          const allMoveLines = await this.execute('stock.move.line', 'search_read', [
            [['picking_id', '=', pickingId]]
          ], { 
            fields: ['id', 'product_id', 'product_uom_qty', 'qty_done', 'location_id'] 
          }, userId);
          
          // Find a line that still has work to do
          const nextLine = allMoveLines.find(ml => ml.product_uom_qty > ml.qty_done && ml.id !== line.id);
          
          if (nextLine) {
            // Get product info
            const nextProduct = await this.execute('product.product', 'search_read', [
              [['id', '=', nextLine.product_id[0]]]
            ], { 
              fields: ['id', 'name', 'barcode', 'default_code', 'list_price', 'uom_id'] 
            }, userId);
            
            if (nextProduct && nextProduct.length > 0) {
              // Get location information for next line
              let nextLocationInfo = null;
              if (nextLine.location_id) {
                const nextLocations = await this.execute('stock.location', 'search_read', [
                  [['id', '=', nextLine.location_id[0]]]
                ], { 
                  fields: ['id', 'name', 'complete_name'] 
                }, userId);
                
                if (nextLocations && nextLocations.length > 0) {
                  nextLocationInfo = {
                    id: nextLocations[0].id,
                    name: nextLocations[0].name,
                    complete_name: nextLocations[0].complete_name
                  };
                }
              }
              
              result.next_line = {
                line_id: nextLine.id,
                product_id: nextLine.product_id[0],
                product_name: nextProduct[0].name,
                product_code: nextProduct[0].default_code,
                price: nextProduct[0].list_price || 0,
                uom: nextProduct[0].uom_id ? nextProduct[0].uom_id[1] : 'Units',
                required: nextLine.product_uom_qty,
                done: nextLine.qty_done,
                remain: nextLine.product_uom_qty - nextLine.qty_done,
                barcode: nextProduct[0].barcode,
                location: nextLocationInfo ? nextLocationInfo.name : null,
                location_complete: nextLocationInfo ? nextLocationInfo.complete_name : null
              };
            }
          } else {
            // Check if all lines are completed
            const incompleteLines = allMoveLines.filter(ml => ml.product_uom_qty > ml.qty_done);
            if (incompleteLines.length === 0) {
              // If no more lines need work, the order is completed
              result.order_completed = true;
              try {
                const totalItems = allMoveLines.reduce((sum, ml) => sum + (ml.product_uom_qty || 0), 0);
                result.order_summary = Object.assign({}, result.order_summary, { total_items: totalItems });
              } catch (e) {
                // ignore
              }
            }
          }
        } catch (err) {
          // If there's an error finding the next line, just continue without it
          console.error('Error finding next line:', err);
        }
      }
      
      return result;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      logger.error('Error validating item scan:', error);
      throw new ApiError(500, 'Error validating item scan');
    }
  }

  /**
   * Reset picking progress
   * @param {number} pickingId - Picking ID
   * @param {number|null} [userId=null] - User ID for credentials
   * @returns {Promise<Object>} - Reset result
   */
  async resetPickingProgress(pickingId, userId = null) {
    try {
      // Find all move lines for this picking
      const moveLines = await this.execute('stock.move.line', 'search_read', [
        [['picking_id', '=', pickingId]]
      ], { fields: ['id', 'qty_done'] }, userId);
      
      // Reset qty_done to 0 for all lines
      for (const line of moveLines) {
        await this.execute('stock.move.line', 'write', [
          [line.id],
          { qty_done: 0 }
        ], {}, userId);
      }
      
      return { success: true };
    } catch (error) {
      logger.error('Error resetting picking progress:', error);
      throw new ApiError(500, 'Error resetting picking progress');
    }
  }

  /**
   * Validate picking
   * @param {number} pickingId - Picking ID
   * @param {Array} payload - Array of line items with quantities
   * @param {number|null} [userId=null] - User ID for credentials
   * @returns {Promise<Object>} - Validation result
   */
  async validatePicking(pickingId, payload, userId = null) {
    try {
      // Get current state of the picking
      const pickings = await this.execute('stock.picking', 'search_read', [
        [['id', '=', pickingId]]
      ], { fields: ['id', 'name', 'state', 'move_line_ids'] }, userId);

      if (!pickings || pickings.length === 0) {
        throw new ApiError(404, 'PICKING_NOT_FOUND');
      }

      const picking = pickings[0];
      
      if (picking.state === 'done' || picking.state === 'cancel') {
        throw new ApiError(409, 'ORDER_LOCKED');
      }

      // Get current move lines
      const moveLines = await this.execute('stock.move.line', 'search_read', [
        [['id', 'in', picking.move_line_ids]]
      ], { 
        fields: ['id', 'product_id', 'product_uom_qty', 'qty_done'] 
      }, userId);

      // Check for mismatches
      const diffs = [];
      for (const item of payload) {
        const moveLine = moveLines.find(line => line.id === item.line_id);
        if (!moveLine) {
          diffs.push({
            line_id: item.line_id,
            product_id: item.product_id,
            new_required: 0 // Line doesn't exist anymore
          });
          continue;
        }

        if (moveLine.product_uom_qty !== item.qty) {
          diffs.push({
            line_id: item.line_id,
            product_id: item.product_id,
            new_required: moveLine.product_uom_qty
          });
        }
      }

      // If there are mismatches, return them
      if (diffs.length > 0) {
        throw new ApiError(409, 'MISMATCH', false, { diffs });
      }

      // Update quantities in Odoo
      for (const item of payload) {
        await this.execute('stock.move.line', 'write', [
          [item.line_id],
          { qty_done: item.qty }
        ], {}, userId);
      }

      // Count how many labels are needed (one per line)
      const labelsCount = payload.length;

      return {
        labels_count: labelsCount
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      logger.error('Error validating picking:', error);
      throw new ApiError(500, 'Error validating picking');
    }
  }
}

module.exports = new OdooService();
