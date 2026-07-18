/// Base URL for the backend API.
/// Change to your server's IP/hostname when running on a real device.
/// For iOS simulator connecting to localhost: use http://localhost:3000
/// For physical iPhone: use your Mac's local IP, e.g. http://192.168.1.x:3000
class AppConfig {
  AppConfig._();

  static const String baseUrl = 'http://192.168.1.4:3000/api';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
