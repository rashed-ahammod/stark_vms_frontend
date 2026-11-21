import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_models.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  /// The only endpoint that needs no Bearer token.
  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest request);

  /// Validates a stored token. Returns 401 when it is expired or invalid.
  @GET('/auth/me')
  Future<AuthUser> me();
}
