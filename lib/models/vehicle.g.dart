// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  id: (json['id'] as num?)?.toInt(),
  vehicleNumber: json['vehicleNumber'] as String,
  vehicleType: $enumDecode(_$VehicleTypeEnumMap, json['vehicleType']),
  brand: json['brand'] as String,
  model: json['model'] as String,
  manufacturingYear: (json['manufacturingYear'] as num?)?.toInt(),
  color: json['color'] as String?,
  fuelType: $enumDecode(_$FuelTypeEnumMap, json['fuelType']),
  seatingCapacity: (json['seatingCapacity'] as num?)?.toInt(),
  driverName: json['driverName'] as String?,
  driverPhone: json['driverPhone'] as String?,
  status:
      $enumDecodeNullable(_$VehicleStatusEnumMap, json['status']) ??
      VehicleStatus.available,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
  'id': ?instance.id,
  'vehicleNumber': instance.vehicleNumber,
  'vehicleType': _$VehicleTypeEnumMap[instance.vehicleType]!,
  'brand': instance.brand,
  'model': instance.model,
  'manufacturingYear': ?instance.manufacturingYear,
  'color': ?instance.color,
  'fuelType': _$FuelTypeEnumMap[instance.fuelType]!,
  'seatingCapacity': ?instance.seatingCapacity,
  'driverName': ?instance.driverName,
  'driverPhone': ?instance.driverPhone,
  'status': _$VehicleStatusEnumMap[instance.status]!,
  'createdAt': ?instance.createdAt?.toIso8601String(),
  'updatedAt': ?instance.updatedAt?.toIso8601String(),
};

const _$VehicleTypeEnumMap = {
  VehicleType.car: 'CAR',
  VehicleType.suv: 'SUV',
  VehicleType.van: 'VAN',
  VehicleType.microbus: 'MICROBUS',
  VehicleType.bus: 'BUS',
  VehicleType.truck: 'TRUCK',
  VehicleType.pickup: 'PICKUP',
  VehicleType.motorcycle: 'MOTORCYCLE',
};

const _$FuelTypeEnumMap = {
  FuelType.petrol: 'PETROL',
  FuelType.diesel: 'DIESEL',
  FuelType.octane: 'OCTANE',
  FuelType.cng: 'CNG',
  FuelType.lpg: 'LPG',
  FuelType.hybrid: 'HYBRID',
  FuelType.electric: 'ELECTRIC',
};

const _$VehicleStatusEnumMap = {
  VehicleStatus.available: 'AVAILABLE',
  VehicleStatus.inUse: 'IN_USE',
  VehicleStatus.maintenance: 'MAINTENANCE',
  VehicleStatus.inactive: 'INACTIVE',
};
