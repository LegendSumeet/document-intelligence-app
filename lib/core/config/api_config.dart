import 'package:flutter/foundation.dart';

/// Runtime configuration for the backend API.
///
/// Values are supplied at build time via `--dart-define`, e.g.
/// `flutter run --dart-define=API_TOKEN=... --dart-define=API_BASE_URL=...`.
class ApiConfig {
  ApiConfig._();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const apiToken = String.fromEnvironment('API_TOKEN');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  /// Throws a [StateError] when required configuration is missing.
  static void validate() {
    if (apiToken.isEmpty) {
      throw StateError(
        'Missing API_TOKEN. Start Flutter with --dart-define=API_TOKEN=...',
      );
    }
  }
}
