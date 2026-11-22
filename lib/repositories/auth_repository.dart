import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/api_error.dart';
import '../models/auth_models.dart';
import '../network/auth_api.dart';

/// Domain-level exception thrown when an authentication call fails.
class AuthApiException implements Exception {
  const AuthApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;
  final bool isNetworkError;

  /// Rejected credentials, or an expired/invalid token.
  bool get isUnauthorized => statusCode == 401;
  bool get isValidationError => statusCode == 400;

  @override
  String toString() => message;
}

/// Repository wrapping [AuthApi] and translating [DioException]s into
/// user-friendly [AuthApiException]s.
class AuthRepository {
  const AuthRepository(this._api, this._dio);

  final AuthApi _api;
  final Dio _dio;

  /// Nudges a sleeping backend awake.
  ///
  /// Free hosting tiers spin an idle instance down, and the first request then
  /// waits the better part of a minute. Firing this when the login screen
  /// opens means the instance is already warming while the user types.
  /// Failures are deliberately swallowed: this is an optimisation, and the
  /// endpoint may not exist on every deployment.
  Future<void> warmUp() async {
    try {
      await _dio.getUri<void>(
        Uri.parse(ApiConfig.healthUrl),
        options: Options(
          // No auth, and a failure here must never surface to the user.
          validateStatus: (_) => true,
          receiveTimeout: ApiConfig.receiveTimeout,
        ),
      );
    } catch (_) {
      // Ignored on purpose.
    }
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      return await _api.login(
        LoginRequest(username: username, password: password),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<AuthUser> me() async {
    try {
      return await _api.me();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AuthApiException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AuthApiException(
          message:
              'Request timed out. Please verify the VMS backend server is running and try again.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return const AuthApiException(
          message:
              'Unable to reach the VMS backend server. Please check that the server is running at ${ApiConfig.baseUrl}.',
          isNetworkError: true,
        );
      case DioExceptionType.cancel:
        return const AuthApiException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const AuthApiException(
          message:
              'A network error occurred while communicating with the VMS server.',
          isNetworkError: true,
        );
      case DioExceptionType.badResponse:
        return _mapResponseError(error.response);
    }
  }

  AuthApiException _mapResponseError(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    // The API always uses the same error envelope, so prefer its `message`
    // and map `errors` straight onto the login form's fields.
    if (data is Map<String, dynamic>) {
      try {
        final apiError = ApiError.fromJson(data);
        return AuthApiException(
          message: apiError.message,
          statusCode: apiError.status ?? statusCode,
          fieldErrors: apiError.errors,
        );
      } catch (_) {
        final rawMessage = data['message'];
        if (rawMessage is String && rawMessage.isNotEmpty) {
          return AuthApiException(
            message: rawMessage,
            statusCode: statusCode,
          );
        }
      }
    }

    return switch (statusCode) {
      400 => const AuthApiException(
        message: 'Please enter your username and password.',
        statusCode: 400,
      ),
      401 => const AuthApiException(
        message: 'Invalid username or password',
        statusCode: 401,
      ),
      _ => AuthApiException(
        message: 'Server returned an error (HTTP ${statusCode ?? 'unknown'}).',
        statusCode: statusCode,
      ),
    };
  }
}
