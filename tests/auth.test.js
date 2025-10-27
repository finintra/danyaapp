const request = require('supertest');
const app = require('../src/index');
const authService = require('../src/services/authService');
const odooService = require('../src/services/odooService');

// Mock services
jest.mock('../src/services/odooService');
jest.mock('../src/services/authService');

describe('Auth Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /flf/api/v1/login_badge', () => {
    it('should login with valid badge and PIN', async () => {
      // Mock services
      odooService.validateBadgeAndPin.mockResolvedValue({
        id: 1,
        name: 'Test User',
        active: true
      });
      authService.generateToken.mockReturnValue('test-token');
      authService.generateDeviceId.mockReturnValue('test-device-id');

      // Make request
      const res = await request(app)
        .post('/flf/api/v1/login_badge')
        .send({
          badge_barcode: '123456',
          pin: '1234',
          device_id: 'test-device-id'
        });

      // Assertions
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('ok', true);
      expect(res.body).toHaveProperty('token', 'test-token');
      expect(res.body.user).toHaveProperty('id', 1);
      expect(res.body.user).toHaveProperty('name', 'Test User');
      expect(res.body).toHaveProperty('device_id', 'test-device-id');
    });

    it('should return 401 with invalid badge or PIN', async () => {
      // Mock services
      odooService.validateBadgeAndPin.mockRejectedValue({
        message: 'BADGE_OR_PIN'
      });

      // Make request
      const res = await request(app)
        .post('/flf/api/v1/login_badge')
        .send({
          badge_barcode: '123456',
          pin: '1234',
          device_id: 'test-device-id'
        });

      // Assertions
      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('ok', false);
      expect(res.body).toHaveProperty('error', 'BADGE_OR_PIN');
    });

    it('should return 403 with archived account', async () => {
      // Mock services
      odooService.validateBadgeAndPin.mockRejectedValue({
        message: 'ARCHIVED'
      });

      // Make request
      const res = await request(app)
        .post('/flf/api/v1/login_badge')
        .send({
          badge_barcode: '123456',
          pin: '1234',
          device_id: 'test-device-id'
        });

      // Assertions
      expect(res.statusCode).toEqual(403);
      expect(res.body).toHaveProperty('ok', false);
      expect(res.body).toHaveProperty('error', 'ARCHIVED');
    });
  });
});
