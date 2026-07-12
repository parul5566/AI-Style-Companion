/// Centralized configuration for the Flutter app.
///
/// The BASE_URL must point to the deployed backend. When running in
/// development, set it to your local dev server IP.
class AppConfig {
  /// Base API URL — update for your deployment.
  static const String baseUrl = 'https://ai-style-companion-b1wduf.drytis.dev/api';

  /// JWT storage keys.
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';

  /// Default city for weather.
  static const String defaultCity = 'London';

  /// Subscription tiers.
  static const List<String> tierNames = ['free', 'basic', 'plus', 'premium'];
}
