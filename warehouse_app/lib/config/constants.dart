class AppConstants {
  // API URLs
  static const String baseUrl = 'http://192.168.31.252:3000';
  static const String apiPrefix = '/flf/api/v1';
  
  // API Endpoints
  static const String loginEndpoint = '$apiPrefix/login';
  static const String loginBadgeEndpoint = '$apiPrefix/login_badge';
  static const String deviceStatusEndpoint = '$apiPrefix/device/status';
  static const String logoutEndpoint = '$apiPrefix/logout';
  static const String taskAttachEndpoint = '$apiPrefix/task/attach';
  static const String scanItemEndpoint = '$apiPrefix/scan/item';
  static const String validateEndpoint = '$apiPrefix/validate';
  static const String cancelLocalEndpoint = '$apiPrefix/cancel_local';
  static const String tasksAvailableEndpoint = '$apiPrefix/tasks/available';
  static const String taskDetailsEndpoint = '$apiPrefix/task'; // + /:pickingId
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String tokenExpiryKey = 'token_expiry';
  static const String pinKey = 'user_pin';
  
  // Colors
  static const String successColor = '#4CAF50';
  static const String errorColor = '#F44336';
  static const String warningColor = '#FF9800';
  static const String textColor = '#757575';
  static const String primaryColor = '#000000';
  static const String backgroundColor = '#FFFFFF';
}
