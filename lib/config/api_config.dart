/// Central API configuration for Stark Group VMS.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the Spring Boot REST API.
  ///
  /// Supplied at build time so the same source deploys anywhere:
  ///
  ///   flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api
  ///
  /// The default keeps local development working with no extra flags and
  /// matches `server.port=9001` in the backend's application.properties.
  ///
  /// Two things to know when deploying:
  ///  * The value is compiled into the published JavaScript, so it is public.
  ///    That is fine for a URL - never pass a password or signing key this way.
  ///  * A site served over HTTPS cannot call an `http://` API; browsers block
  ///    it as mixed content. The deployed value must be `https://`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:9001/api',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const int defaultPageSize = 10;
}
