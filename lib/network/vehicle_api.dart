import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/page_response.dart';
import '../models/vehicle.dart';

part 'vehicle_api.g.dart';

@RestApi()
abstract class VehicleApi {
  factory VehicleApi(Dio dio, {String? baseUrl}) = _VehicleApi;

  @GET('/vehicles')
  Future<PageResponse<Vehicle>> getVehicles({
    @Query('page') int page = 0,
    @Query('size') int size = 10,
  });

  @GET('/vehicles/{id}')
  Future<Vehicle> getVehicleById(@Path('id') int id);

  @POST('/vehicles')
  Future<Vehicle> createVehicle(@Body() Vehicle vehicle);

  @PUT('/vehicles/{id}')
  Future<Vehicle> updateVehicle(
    @Path('id') int id,
    @Body() Vehicle vehicle,
  );

  @DELETE('/vehicles/{id}')
  Future<void> deleteVehicle(@Path('id') int id);
}
