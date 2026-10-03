class AppConfig {
  AppConfig._();

  /// Override at launch time:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000`
  ///
  /// Default `10.0.2.2` is the host machine as seen from the Android Emulator.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
