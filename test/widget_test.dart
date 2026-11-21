import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:stark_vms/main.dart';
import 'package:stark_vms/models/auth_models.dart';
import 'package:stark_vms/models/page_response.dart';
import 'package:stark_vms/models/vehicle.dart';
import 'package:stark_vms/providers/auth_providers.dart';
import 'package:stark_vms/providers/vehicle_providers.dart';
import 'package:stark_vms/repositories/auth_repository.dart';
import 'package:stark_vms/repositories/vehicle_repository.dart';
import 'package:stark_vms/widgets/user_menu.dart';

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

class _StubAuthRepository implements AuthRepository {
  const _StubAuthRepository();

  static const AuthUser user = AuthUser(
    id: 1,
    username: 'admin',
    fullName: 'Administrator',
  );

  @override
  Future<AuthUser> me() async => user;

  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    return const LoginResponse(token: 'stub-token', user: user);
  }
}

void main() {
  late Directory tempDir;
  late Box<dynamic> sessionBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('stark_vms_test');
    Hive.init(tempDir.path);
    sessionBox = await Hive.openBox<dynamic>('test_session');
  });

  tearDown(() async {
    await sessionBox.clear();
  });

  tearDownAll(() async {
    await sessionBox.close();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        sessionBoxProvider.overrideWithValue(sessionBox),
        vehicleRepositoryProvider.overrideWithValue(_StubVehicleRepository()),
        authRepositoryProvider.overrideWithValue(const _StubAuthRepository()),
      ],
      child: const StarkVmsApp(),
    );
  }

  testWidgets('shows the login screen when there is no stored session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Use your administrator account to manage the fleet.'),
      findsOneWidget,
    );
    expect(find.text('Sign In'), findsOneWidget);
    // The fleet screens must not be reachable without a session.
    expect(find.text('No vehicles registered yet'), findsNothing);
  });

  testWidgets('restores a stored session and renders the empty fleet state', (
    WidgetTester tester,
  ) async {
    // runAsync, because testWidgets bodies run in a fake-async zone where a
    // real Hive file write would never complete. The cached user is seeded as
    // well so the /auth/me refresh finds it unchanged and writes nothing.
    await tester.runAsync(() async {
      await sessionBox.put('auth_token', 'stored-token');
      await sessionBox.put(
        'auth_user',
        jsonEncode(_StubAuthRepository.user.toJson()),
      );
    });

    await tester.pumpWidget(buildApp());
    // Bounded pumps rather than pumpAndSettle: the session-check spinner and
    // the list's skeleton shimmer both animate indefinitely, so there is never
    // a frame-free moment for pumpAndSettle to return on. A few pumps are
    // enough for /auth/me and the first page fetch to resolve.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Stark Group VMS'), findsOneWidget);
    expect(find.text('No vehicles registered yet'), findsOneWidget);
    // The signed-in user now lives behind the account menu in the top bar
    // rather than as inline text.
    expect(find.byType(UserMenu), findsOneWidget);
  });
}
