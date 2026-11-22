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

  /// Host root of the API, i.e. [baseUrl] without its `/api` suffix.
  static String get _origin =>
      baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;

  /// Unauthenticated health endpoint, used to wake a sleeping instance.
  static String get healthUrl => '$_origin/actuator/health';

  /// Connecting should fail fast - a wrong host or a dead server is not worth
  /// a long wait, and the TCP/TLS handshake is answered promptly even by a
  /// sleeping free-tier instance.
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Generous, because a free-tier host that has spun down can take the better
  /// part of a minute to answer the first request. The UI explains the wait
  /// rather than leaving the user staring at a spinner.
  static const Duration receiveTimeout = Duration(seconds: 90);
  static const Duration sendTimeout = Duration(seconds: 90);

  /// How long a request may run before the UI starts explaining the delay.
  static const Duration slowRequestHint = Duration(seconds: 4);

  static const int defaultPageSize = 10;
}
