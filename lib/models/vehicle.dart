import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum VehicleType {
  car('Car'),
  suv('SUV'),
  van('Van'),
  microbus('Microbus'),
  bus('Bus'),
  truck('Truck'),
  pickup('Pickup'),
  motorcycle('Motorcycle');

  const VehicleType(this.label);
  final String label;
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum FuelType {
  petrol('Petrol'),
  diesel('Diesel'),
  octane('Octane'),
  cng('CNG'),
  lpg('LPG'),
  hybrid('Hybrid'),
  electric('Electric');

  const FuelType(this.label);
  final String label;
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum VehicleStatus {
  available('Available'),
  inUse('In Use'),
  maintenance('Maintenance'),
  inactive('Inactive');

  const VehicleStatus(this.label);
  final String label;
}

@JsonSerializable(includeIfNull: false)
class Vehicle {
  const Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    this.manufacturingYear,
    this.color,
    required this.fuelType,
    this.seatingCapacity,
    this.driverName,
    this.driverPhone,
    this.status = VehicleStatus.available,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String vehicleNumber;
  final VehicleType vehicleType;
  final String brand;
  final String model;
  final int? manufacturingYear;
  final String? color;
  final FuelType fuelType;
  final int? seatingCapacity;
  final String? driverName;
  final String? driverPhone;
  final VehicleStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  Vehicle copyWith({
    int? id,
    String? vehicleNumber,
    VehicleType? vehicleType,
    String? brand,
    String? model,
    int? manufacturingYear,
    String? color,
    FuelType? fuelType,
    int? seatingCapacity,
    String? driverName,
    String? driverPhone,
    VehicleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      color: color ?? this.color,
      fuelType: fuelType ?? this.fuelType,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
