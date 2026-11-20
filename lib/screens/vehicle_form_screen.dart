import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});

  /// When `null`, creates a new vehicle; otherwise edits the given vehicle.
  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<ShadFormState>();

  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late final TextEditingController _seatingCapacityController;
  late final TextEditingController _driverNameController;
  late final TextEditingController _driverPhoneController;

  VehicleType? _vehicleType;
  FuelType? _fuelType;
  VehicleStatus _status = VehicleStatus.available;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _vehicleNumberController = TextEditingController(
      text: v?.vehicleNumber ?? '',
    );
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(
      text: v?.manufacturingYear?.toString() ?? '',
    );
    _colorController = TextEditingController(text: v?.color ?? '');
    _seatingCapacityController = TextEditingController(
      text: v?.seatingCapacity?.toString() ?? '',
    );
    _driverNameController = TextEditingController(text: v?.driverName ?? '');
    _driverPhoneController = TextEditingController(text: v?.driverPhone ?? '');
    _vehicleType = v?.vehicleType;
    _fuelType = v?.fuelType;
    _status = v?.status ?? VehicleStatus.available;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _seatingCapacityController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(vehicleFormProvider.notifier).clearErrors();

    final isValid = _formKey.currentState?.saveAndValidate() ?? false;
    if (!isValid || _vehicleType == null || _fuelType == null) {
      return;
    }

    final yearText = _yearController.text.trim();
    final seatsText = _seatingCapacityController.text.trim();
    final colorText = _colorController.text.trim();
    final driverNameText = _driverNameController.text.trim();
    final driverPhoneText = _driverPhoneController.text.trim();

    final payload = Vehicle(
      vehicleNumber: _vehicleNumberController.text.trim(),
      vehicleType: _vehicleType!,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      manufacturingYear: yearText.isEmpty ? null : int.parse(yearText),
      color: colorText.isEmpty ? null : colorText,
      fuelType: _fuelType!,
      seatingCapacity: seatsText.isEmpty ? null : int.parse(seatsText),
      driverName: driverNameText.isEmpty ? null : driverNameText,
      driverPhone: driverPhoneText.isEmpty ? null : driverPhoneText,
      status: _status,
    );

    final saved = await ref.read(vehicleFormProvider.notifier).submit(
          existingId: widget.vehicle?.id,
          vehicle: payload,
        );

    if (saved != null && mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          title: Text(_isEditing ? 'Vehicle updated' : 'Vehicle added'),
          description: Text(
            '${saved.vehicleNumber} (${saved.brand} ${saved.model}) saved successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final formState = ref.watch(vehicleFormProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final maxYear = DateTime.now().year + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      ShadButton.outline(
                        size: ShadButtonSize.sm,
                        onPressed: formState.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        leading: const Icon(LucideIcons.arrowLeft, size: 15),
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Edit Vehicle' : 'Add New Vehicle',
                              style: theme.textTheme.h4.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Update registration, specs, and assignment for ${widget.vehicle!.vehicleNumber}'
                                  : 'Register a new vehicle in the Stark Group fleet',
                              style:
                                  theme.textTheme.muted.copyWith(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: ShadCard(
                    padding: const EdgeInsets.all(28),
                    child: ShadForm(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (formState.generalError != null) ...[
                            ShadAlert.destructive(
                              icon: const Icon(LucideIcons.circleAlert),
                              title: const Text('Could not save vehicle'),
                              description: Text(formState.generalError!),
                            ),
                            const SizedBox(height: 24),
                          ],
                          const _SectionHeader(
                            icon: LucideIcons.car,
                            title: 'Vehicle Identification & Specifications',
                            subtitle:
                                'Required fields are marked with an asterisk (*).',
                          ),
                          const SizedBox(height: 18),
                          _FormPair(
                            isWide: isWide,
                            left: ShadInputFormField(
                              id: 'vehicleNumber',
                              controller: _vehicleNumberController,
                              label: const Text('Vehicle Number *'),
                              placeholder:
                                  const Text('e.g. DHA-METRO-GA-11-9001'),
                              leading: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.hash,
                                  size: 15,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              forceErrorText: formState.vehicleNumberError,
                              onChanged: (_) => ref
                                  .read(vehicleFormProvider.notifier)
                                  .clearVehicleNumberError(),
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return 'Vehicle number is required';
                                }
                                return null;
                              },
                            ),
                            right: ShadSelectFormField<VehicleType>(
                              id: 'vehicleType',
                              label: const Text('Vehicle Type *'),
                              initialValue: _vehicleType,
                              placeholder: const Text('Select vehicle type'),
                              options: VehicleType.values
                                  .map(
                                    (type) => ShadOption(
                                      value: type,
                                      child: Text(type.label),
                                    ),
                                  )
                                  .toList(),
                              selectedOptionBuilder: (_, value) =>
                                  Text(value.label),
                              onChanged: (value) =>
                                  setState(() => _vehicleType = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'Vehicle type is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FormPair(
                            isWide: isWide,
                            left: ShadInputFormField(
                              id: 'brand',
                              controller: _brandController,
                              label: const Text('Brand *'),
                              placeholder: const Text('e.g. Toyota'),
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return 'Brand is required';
                                }
                                return null;
                              },
                            ),
                            right: ShadInputFormField(
                              id: 'model',
                              controller: _modelController,
                              label: const Text('Model *'),
                              placeholder: const Text('e.g. Corolla Cross'),
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return 'Model is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FormPair(
                            isWide: isWide,
                            left: ShadInputFormField(
                              id: 'manufacturingYear',
                              controller: _yearController,
                              label: const Text('Manufacturing Year'),
                              placeholder: const Text('e.g. 2023'),
                              leading: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.calendar,
                                  size: 15,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final trimmed = v.trim();
                                if (trimmed.isEmpty) return null;
                                final year = int.tryParse(trimmed);
                                if (year == null ||
                                    year < 1900 ||
                                    year > maxYear) {
                                  return 'Enter a valid year between 1900 and $maxYear';
                                }
                                return null;
                              },
                            ),
                            right: ShadInputFormField(
                              id: 'color',
                              controller: _colorController,
                              label: const Text('Color'),
                              placeholder: const Text('e.g. Pearl White'),
                              leading: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.palette,
                                  size: 15,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FormPair(
                            isWide: isWide,
                            left: ShadSelectFormField<FuelType>(
                              id: 'fuelType',
                              label: const Text('Fuel Type *'),
                              initialValue: _fuelType,
                              placeholder: const Text('Select fuel type'),
                              options: FuelType.values
                                  .map(
                                    (fuel) => ShadOption(
                                      value: fuel,
                                      child: Text(fuel.label),
                                    ),
                                  )
                                  .toList(),
                              selectedOptionBuilder: (_, value) =>
                                  Text(value.label),
                              onChanged: (value) =>
                                  setState(() => _fuelType = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'Fuel type is required';
                                }
                                return null;
                              },
                            ),
                            right: ShadInputFormField(
                              id: 'seatingCapacity',
                              controller: _seatingCapacityController,
                              label: const Text('Seating Capacity'),
                              placeholder: const Text('e.g. 5'),
                              leading: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.users,
                                  size: 15,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final trimmed = v.trim();
                                if (trimmed.isEmpty) return null;
                                final seats = int.tryParse(trimmed);
                                if (seats == null || seats <= 0) {
                                  return 'Seating capacity must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: ShadSeparator.horizontal(),
                          ),
                          const _SectionHeader(
                            icon: LucideIcons.userCheck,
                            title: 'Assignment & Operational Status',
                            subtitle:
                                'Assign a driver and set current fleet availability.',
                          ),
                          const SizedBox(height: 18),
                          _FormPair(
                            isWide: isWide,
                            left: ShadInputFormField(
                              id: 'driverName',
                              controller: _driverNameController,
                              label: const Text('Driver Name'),
                              placeholder: const Text('e.g. Kamrul Hasan'),
                              leading: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.user,
                                  size: 15,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ),
                            right: ShadInputFormField(
                              id: 'driverPhone',
                              controller: _driverPhoneController,
                              label: const Text('Driver Phone'),
                              placeholder: const Text('e.g. +8801711000000'),
                              leading: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.phone,
                                  size: 15,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FormPair(
                            isWide: isWide,
                            left: ShadSelectFormField<VehicleStatus>(
                              id: 'status',
                              label: const Text('Status *'),
                              initialValue: _status,
                              options: VehicleStatus.values
                                  .map(
                                    (status) => ShadOption(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  )
                                  .toList(),
                              selectedOptionBuilder: (_, value) =>
                                  Text(value.label),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                            ),
                            right: const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 28),
                          const ShadSeparator.horizontal(),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ShadButton.outline(
                                onPressed: formState.isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              ShadButton(
                                onPressed:
                                    formState.isSubmitting ? null : _submit,
                                leading: Icon(
                                  _isEditing
                                      ? LucideIcons.check
                                      : LucideIcons.plus,
                                  size: 15,
                                ),
                                child: Text(
                                  formState.isSubmitting
                                      ? 'Saving...'
                                      : (_isEditing
                                          ? 'Save Changes'
                                          : 'Create Vehicle'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.foreground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormPair extends StatelessWidget {
  const _FormPair({
    required this.isWide,
    required this.left,
    required this.right,
  });

  final bool isWide;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          if (right is! SizedBox) ...[
            const SizedBox(height: 16),
            right,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}
