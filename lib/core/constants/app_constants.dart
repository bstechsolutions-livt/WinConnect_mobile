class AppConstants {
  // App Info
  static const String appName = 'WinConnect Mobile';
  static const String appVersion = '1.0.0';
  
  // API Configuration - URL agora vem de ClientConfig
  // Use: ClientConfig.current.apiBaseUrl
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Routes
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}