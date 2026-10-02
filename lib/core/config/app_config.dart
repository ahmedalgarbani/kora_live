class AppConfig {
  AppConfig._();

  static const String appName = 'Kora Live';
  static const String appVersion = '1.1.0';

  /// Server feed used on first launch. Set it at build time with:
  /// `flutter build apk --dart-define=KORA_SERVER_URL=https://example.com/streams.json`
  /// The user can still change it later from the settings screen.
  static const String defaultServerUrl = String.fromEnvironment(
    'KORA_SERVER_URL',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}
