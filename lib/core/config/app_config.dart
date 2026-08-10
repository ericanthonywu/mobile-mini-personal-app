import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration constants loaded from the .env file.
class AppConfig {
  AppConfig._();

  /// Base URL for the API — read from .env file with fallback to localhost.
  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://localhost:3000/api';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
