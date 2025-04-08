class AppConstants {
  // App Information
  static const String appName = 'Iqbal Literature';
  static const String appVersion = '1.5.0';

  // Database
  static const String databaseName = 'iqbal_literature.db';
  static const int databaseVersion = 1;

  // Cache
  static const int maxCacheSize = 100;
  static const Duration cacheDuration = Duration(days: 7);

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 50;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Feature Flags
  static const bool enableDevicePreview = false;
  static const bool enableDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableAnalytics = true;
}
