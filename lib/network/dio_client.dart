import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Path of the only endpoint that must not carry a Bearer token, and whose
/// 401 means "wrong credentials" rather than "session expired".
const String _loginPath = '/auth/login';

bool _isLoginRequest(RequestOptions options) =>
    options.path.contains(_loginPath);

bool _isAuthRequest(RequestOptions options) => options.path.contains('/auth/');

/// Creates and configures the shared [Dio] HTTP client.
///
/// [readToken] is consulted on every request so the newest token is always
/// used, and [onUnauthorized] is invoked when the server rejects a token with
/// a 401 so the session can be cleared and the user routed back to login.
Dio createDioClient({
  required String? Function() readToken,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Attach the token centrally; no call site adds this header itself.
        if (!_isLoginRequest(options)) {
          final token = readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // A 401 from the login call is a rejected password, not a dead
        // session, so it must not clear state or bounce the user.
        if (error.response?.statusCode == 401 &&
            !_isLoginRequest(error.requestOptions)) {
          onUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(_RedactingLogInterceptor());
  }

  return dio;
}

/// Debug logging that never prints credentials.
///
/// Dio's own [LogInterceptor] prints request headers by default and would dump
/// the `Authorization: Bearer ...` header, the login request body (the
/// password) and the login response body (the token). This logs the method,
/// path and status for every call, and bodies only for non-auth endpoints.
class _RedactingLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DIO] --> ${options.method} ${options.path}');
    if (!_isAuthRequest(options) && options.data != null) {
      debugPrint('[DIO]     body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    debugPrint(
      '[DIO] <-- ${response.statusCode} ${options.method} ${options.path}',
    );
    if (!_isAuthRequest(options) && response.data != null) {
      debugPrint('[DIO]     body: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final options = error.requestOptions;
    debugPrint(
      '[DIO] <-- ERROR ${error.response?.statusCode ?? error.type} '
      '${options.method} ${options.path}',
    );
    // Error envelopes carry no credentials, so they are safe to show and are
    // the most useful thing to see while debugging.
    if (error.response?.data != null) {
      debugPrint('[DIO]     error: ${error.response?.data}');
    }
    handler.next(error);
  }
}
