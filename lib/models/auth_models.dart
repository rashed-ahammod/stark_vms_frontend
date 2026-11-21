import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

/// Body of `POST /api/auth/login`. Never persisted — the password is used for
/// the request only and is never written to storage or logs.
@JsonSerializable(createFactory: false)
class LoginRequest {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/// The signed-in administrator, as returned by `/api/auth/login` and
/// `/api/auth/me`.
@JsonSerializable()
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    this.fullName,
  });

  final int id;
  final String username;
  final String? fullName;

  /// Name to show in the UI, falling back to the username.
  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : username;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}

/// Successful `POST /api/auth/login` response.
@JsonSerializable(createToJson: false)
class LoginResponse {
  const LoginResponse({
    required this.token,
    this.tokenType,
    this.expiresIn,
    required this.user,
  });

  final String token;
  final String? tokenType;

  /// Token lifetime in **seconds** (the API sends 86400 for 24 hours).
  final int? expiresIn;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}
