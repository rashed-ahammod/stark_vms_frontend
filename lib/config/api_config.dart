/// Central API configuration for Stark Group VMS.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the Spring Boot REST API.
  /// Matches `server.port=9001` in stark-vms-backend/src/main/resources/application.properties.
  /// Change this if your backend runs on a different host or port (e.g. http://localhost:8080/api).
  static const String baseUrl = 'http://localhost:9001/api';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const int defaultPageSize = 10;
}
