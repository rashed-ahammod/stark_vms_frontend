import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/api_error.dart';
import '../models/page_response.dart';
import '../models/vehicle.dart';
import '../network/vehicle_api.dart';

/// Domain-level exception thrown when an API call fails.
class VehicleApiException implements Exception {
  const VehicleApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;
  final bool isNetworkError;

  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 400;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Repository wrapping [VehicleApi] and translating [DioException]s
/// into user-friendly [VehicleApiException]s.
class VehicleRepository {
  const VehicleRepository(this._api);

  final VehicleApi _api;

  Future<PageResponse<Vehicle>> getVehicles({
    int page = 0,
    int size = ApiConfig.defaultPageSize,
  }) async {
    try {
      return await _api.getVehicles(page: page, size: size);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Vehicle> getVehicleById(int id) async {
    try {
      return await _api.getVehicleById(id);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      return await _api.createVehicle(vehicle);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) async {
    try {
      return await _api.updateVehicle(id, vehicle);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _api.deleteVehicle(id);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  VehicleApiException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const VehicleApiException(
          message:
              'Request timed out. Please verify the VMS backend server is running and try again.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return const VehicleApiException(
          message:
              'Unable to reach the VMS backend server. Please check that the server is running at ${ApiConfig.baseUrl}.',
          isNetworkError: true,
        );
      case DioExceptionType.cancel:
        return const VehicleApiException(
          message: 'Request was cancelled.',
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const VehicleApiException(
          message:
              'A network error occurred while communicating with the VMS server.',
          isNetworkError: true,
        );
      case DioExceptionType.badResponse:
        return _mapResponseError(error.response);
    }
  }

  VehicleApiException _mapResponseError(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      try {
        final apiError = ApiError.fromJson(data);
        return VehicleApiException(
          message: apiError.message,
          statusCode: apiError.status ?? statusCode,
          fieldErrors: apiError.errors,
        );
      } catch (_) {
        final rawMessage = data['message'];
        if (rawMessage is String && rawMessage.isNotEmpty) {
          return VehicleApiException(
            message: rawMessage,
            statusCode: statusCode,
          );
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return VehicleApiException(
        message: data.trim(),
        statusCode: statusCode,
      );
    }

    return switch (statusCode) {
      400 => const VehicleApiException(
          message: 'Please check the submitted fields and try again.',
          statusCode: 400,
        ),
      404 => const VehicleApiException(
          message: 'The requested vehicle could not be found.',
          statusCode: 404,
        ),
      409 => const VehicleApiException(
          message: 'A vehicle with this vehicle number already exists.',
          statusCode: 409,
        ),
      500 => const VehicleApiException(
          message: 'An unexpected server error occurred. Please try again.',
          statusCode: 500,
        ),
      _ => VehicleApiException(
          message: 'Server returned an error (HTTP ${statusCode ?? 'unknown'}).',
          statusCode: statusCode,
        ),
    };
  }
}
