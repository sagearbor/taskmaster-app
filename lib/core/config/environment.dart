enum Environment { development, staging, production }

class AppConfig {
  static Environment _environment = Environment.development;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static Environment get environment => _environment;
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  // Firebase Configuration
  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.development:
        return 'taskmaster-dev';
      case Environment.staging:
        return 'taskmaster-staging';
      case Environment.production:
        return 'taskmaster-prod';
    }
  }
  
  // API Endpoints
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:5001/taskmaster-dev/us-central1';
      case Environment.staging:
        return 'https://staging-api.taskmasterapp.com';
      case Environment.production:
        return 'https://api.taskmasterapp.com';
    }
  }
  
  // Feature Flags
  static bool get enableAds => !isDevelopment;
  static bool get enablePurchases => !isDevelopment;
  static bool get enableAnalytics => isProduction;
  static bool get enableCrashReporting => !isDevelopment;
  static bool get enableDeepLinking => !isDevelopment;
  
  // Logging
  static bool get enableVerboseLogging => isDevelopment;
  static bool get enablePerformanceMonitoring => isProduction;
  
  // Cache Configuration
  static Duration get cacheExpiration {
    switch (_environment) {
      case Environment.development:
        return const Duration(minutes: 5);
      case Environment.staging:
        return const Duration(hours: 1);
      case Environment.production:
        return const Duration(days: 7);
    }
  }
  
  // Rate Limiting
  static int get maxApiCallsPerMinute {
    switch (_environment) {
      case Environment.development:
        return 1000; // No real limit in dev
      case Environment.staging:
        return 100;
      case Environment.production:
        return 60;
    }
  }
}

// Build-time configuration
class BuildConfig {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Taskmaster Party',
  );
  
  static const bool useMockServices = bool.fromEnvironment(
    'USE_MOCK_SERVICES',
    defaultValue: true,
  );
  
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
}