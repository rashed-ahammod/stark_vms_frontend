import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  const ApiError({
    this.timestamp,
    this.status,
    this.error,
    required this.message,
    this.errors,
  });

  final String? timestamp;
  final int? status;
  final String? error;
  final String message;
  final Map<String, String>? errors;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
