class Config {
  /// Base URL for the backend API.
  /// This value can be overridden at build time via `--dart-define`
  /// (e.g. `flutter run --dart-define=API_BASE_URL=https://api.myserver.com`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
