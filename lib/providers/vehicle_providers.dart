import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import '../network/dio_client.dart';
import '../network/vehicle_api.dart';
import '../repositories/vehicle_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = createDioClient();
  ref.onDispose(dio.close);
  return dio;
});

final vehicleApiProvider = Provider<VehicleApi>((ref) {
  return VehicleApi(ref.watch(dioProvider));
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.watch(vehicleApiProvider));
});

class TotalVehiclesCountNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setCount(int count) {
    state = count;
  }
}

final totalVehiclesCountProvider =
    NotifierProvider<TotalVehiclesCountNotifier, int?>(
  TotalVehiclesCountNotifier.new,
);

class VehicleFormState {
  const VehicleFormState({
    this.isSubmitting = false,
    this.vehicleNumberError,
    this.generalError,
    this.fieldErrors = const {},
  });

  final bool isSubmitting;
  final String? vehicleNumberError;
  final String? generalError;
  final Map<String, String> fieldErrors;

  VehicleFormState copyWith({
    bool? isSubmitting,
    String? vehicleNumberError,
    bool clearVehicleNumberError = false,
    String? generalError,
    bool clearGeneralError = false,
    Map<String, String>? fieldErrors,
  }) {
    return VehicleFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      vehicleNumberError: clearVehicleNumberError
          ? null
          : (vehicleNumberError ?? this.vehicleNumberError),
      generalError:
          clearGeneralError ? null : (generalError ?? this.generalError),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class VehicleFormNotifier extends Notifier<VehicleFormState> {
  @override
  VehicleFormState build() => const VehicleFormState();

  void clearVehicleNumberError() {
    if (state.vehicleNumberError != null) {
      state = state.copyWith(clearVehicleNumberError: true);
    }
  }

  void clearErrors() {
    state = const VehicleFormState();
  }

  Future<Vehicle?> submit({
    int? existingId,
    required Vehicle vehicle,
  }) async {
    state = const VehicleFormState(isSubmitting: true);

    final repo = ref.read(vehicleRepositoryProvider);
    try {
      final result = existingId == null
          ? await repo.createVehicle(vehicle)
          : await repo.updateVehicle(existingId, vehicle);
      state = const VehicleFormState(isSubmitting: false);
      return result;
    } on VehicleApiException catch (e) {
      final fieldErrors = e.fieldErrors ?? const {};
      if (e.isConflict) {
        state = VehicleFormState(
          isSubmitting: false,
          vehicleNumberError: e.message,
          fieldErrors: fieldErrors,
        );
      } else if (fieldErrors.containsKey('vehicleNumber')) {
        state = VehicleFormState(
          isSubmitting: false,
          vehicleNumberError: fieldErrors['vehicleNumber'],
          generalError: e.message,
          fieldErrors: fieldErrors,
        );
      } else {
        state = VehicleFormState(
          isSubmitting: false,
          generalError: e.message,
          fieldErrors: fieldErrors,
        );
      }
      return null;
    } catch (_) {
      state = const VehicleFormState(
        isSubmitting: false,
        generalError: 'An unexpected error occurred while saving the vehicle.',
      );
      return null;
    }
  }
}

final vehicleFormProvider =
    NotifierProvider.autoDispose<VehicleFormNotifier, VehicleFormState>(
  VehicleFormNotifier.new,
);
