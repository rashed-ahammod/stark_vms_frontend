import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stark_vms/main.dart';
import 'package:stark_vms/models/page_response.dart';
import 'package:stark_vms/models/vehicle.dart';
import 'package:stark_vms/providers/vehicle_providers.dart';
import 'package:stark_vms/repositories/vehicle_repository.dart';

class _StubVehicleRepository implements VehicleRepository {
  @override
  Future<PageResponse<Vehicle>> getVehicles({
    int page = 0,
    int size = 10,
  }) async {
    return const PageResponse<Vehicle>(
      content: [],
      hasNext: false,
      totalElements: 0,
    );
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) => throw UnimplementedError();

  @override
  Future<void> deleteVehicle(int id) => throw UnimplementedError();

  @override
  Future<Vehicle> getVehicleById(int id) => throw UnimplementedError();

  @override
  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('StarkVmsApp renders title and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(_StubVehicleRepository()),
        ],
        child: const StarkVmsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stark Group VMS'), findsOneWidget);
    expect(find.text('No vehicles registered yet'), findsOneWidget);
  });
}
