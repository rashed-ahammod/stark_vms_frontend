// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
  timestamp: json['timestamp'] as String?,
  status: (json['status'] as num?)?.toInt(),
  error: json['error'] as String?,
  message: json['message'] as String,
  errors: (json['errors'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'timestamp': instance.timestamp,
  'status': instance.status,
  'error': instance.error,
  'message': instance.message,
  'errors': instance.errors,
};
