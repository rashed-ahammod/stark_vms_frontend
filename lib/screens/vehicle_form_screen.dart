import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../config/app_colors.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/state_message_card.dart';

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

  /// Cached result of [_hasUnsavedChanges], refreshed by the controller
  /// listeners. Typing into a controller rebuilds nothing by itself, so this
  /// is what makes the sticky bar and the back guard react live.
  bool _isDirty = false;

  /// The form as it was when last loaded or saved; `null` until prefilled.
  String? _originalSnapshot;

  /// Set while the authoritative record is being re-fetched via GET /vehicles/{id}.
  bool _isLoadingVehicle = false;

  /// Non-null when the edited vehicle could not be re-fetched (e.g. deleted -> 404).
  VehicleApiException? _loadError;

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

    _originalSnapshot = _snapshot();

    for (final c in [
      _vehicleNumberController,
      _brandController,
      _modelController,
      _yearController,
      _colorController,
      _seatingCapacityController,
      _driverNameController,
      _driverPhoneController,
    ]) {
      c.addListener(_recomputeDirty);
    }

    final editingId = v?.id;
    if (editingId != null) {
      _isLoadingVehicle = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVehicle(editingId);
      });
    }
  }

  /// Re-fetches the vehicle so the form always edits the authoritative record.
  /// This matters because PUT /vehicles/{id} is a full replace: every field in
  /// the body overwrites the row, so the form must start from complete data.
  Future<void> _loadVehicle(int id) async {
    try {
      final fresh = await ref
          .read(vehicleRepositoryProvider)
          .getVehicleById(id);
      if (!mounted) return;
      setState(() {
        _isLoadingVehicle = false;
        _loadError = null;
        _prefillFrom(fresh);
      });
    } on VehicleApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingVehicle = false;
        _loadError = e;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingVehicle = false;
        _loadError = const VehicleApiException(
          message: 'An unexpected error occurred while loading this vehicle.',
        );
      });
    }
  }

  /// Writes [v] into every control. Call inside [setState].
  void _prefillFrom(Vehicle v) {
    _vehicleNumberController.text = v.vehicleNumber;
    _brandController.text = v.brand;
    _modelController.text = v.model;
    _yearController.text = v.manufacturingYear?.toString() ?? '';
    _colorController.text = v.color ?? '';
    _seatingCapacityController.text = v.seatingCapacity?.toString() ?? '';
    _driverNameController.text = v.driverName ?? '';
    _driverPhoneController.text = v.driverPhone ?? '';
    _vehicleType = v.vehicleType;
    _fuelType = v.fuelType;
    _status = v.status;
    // The freshly loaded record becomes the new baseline.
    _originalSnapshot = _snapshot();
    _isDirty = false;
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

  /// Builds the record from the current field values.
  ///
  /// Shared by submit and by the unsaved-changes check, so the two can never
  /// disagree about what counts as a change.
  Vehicle _buildPayload(VehicleType type) {
    final yearText = _yearController.text.trim();
    final seatsText = _seatingCapacityController.text.trim();
    final colorText = _colorController.text.trim();
    final driverNameText = _driverNameController.text.trim();
    final driverPhoneText = _driverPhoneController.text.trim();

    return Vehicle(
      vehicleNumber: _vehicleNumberController.text.trim(),
      vehicleType: type,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      manufacturingYear: yearText.isEmpty ? null : int.tryParse(yearText),
      color: colorText.isEmpty ? null : colorText,
      fuelType: _fuelType,
      seatingCapacity: seatsText.isEmpty ? null : int.tryParse(seatsText),
      driverName: driverNameText.isEmpty ? null : driverNameText,
      driverPhone: driverPhoneText.isEmpty ? null : driverPhoneText,
      status: _status,
    );
  }

  /// A comparable snapshot of every field.
  ///
  /// Taken straight from the controls rather than from [_buildPayload], which
  /// needs a non-null vehicle type - routing through it would have hidden all
  /// the other fields on a new form until a type was picked.
  String _snapshot() => jsonEncode([
    _vehicleNumberController.text.trim(),
    _vehicleType?.name,
    _brandController.text.trim(),
    _modelController.text.trim(),
    _yearController.text.trim(),
    _colorController.text.trim(),
    _fuelType?.name,
    _seatingCapacityController.text.trim(),
    _driverNameController.text.trim(),
    _driverPhoneController.text.trim(),
    _status.name,
  ]);

  /// Rebuilds only when the dirty state actually flips, not on every keystroke.
  void _recomputeDirty() {
    final dirty = _hasUnsavedChanges;
    if (dirty != _isDirty && mounted) {
      setState(() => _isDirty = dirty);
    }
  }

  bool get _hasUnsavedChanges =>
      _originalSnapshot != null && _snapshot() != _originalSnapshot;

  /// Guards leaving the screen with edits that were never saved.
  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;

    final discard = await showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Discard changes?'),
        description: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'You have unsaved changes on this form. Leaving now will lose them.',
          ),
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _close() async {
    if (!await _confirmDiscard()) return;
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _submit() async {
    ref.read(vehicleFormProvider.notifier).clearErrors();

    final isValid = _formKey.currentState?.saveAndValidate() ?? false;
    if (!isValid || _vehicleType == null) {
      return;
    }

    final payload = _buildPayload(_vehicleType!);

    final saved = await ref
        .read(vehicleFormProvider.notifier)
        .submit(existingId: widget.vehicle?.id, vehicle: payload);

    if (saved != null && mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          title: Text(_isEditing ? 'Vehicle updated' : 'Vehicle added'),
          description: Text(
            '${saved.vehicleNumber} (${saved.brand} ${saved.model}) saved successfully.',
          ),
        ),
      );
      _originalSnapshot = _snapshot();
      _isDirty = false;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final formState = ref.watch(vehicleFormProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final maxYear = DateTime.now().year + 1;

    return PopScope(
      // A system/browser back with unsaved edits asks first.
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          if (context.mounted) Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
      backgroundColor: AppSurface.of(context).page,
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
                        onPressed: formState.isSubmitting ? null : _close,
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
                              style: theme.textTheme.muted.copyWith(
                                fontSize: 13,
                              ),
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
            child: _loadError != null
                ? StateMessageCard(
                    icon: _loadError!.isNotFound
                        ? LucideIcons.fileX
                        : LucideIcons.wifiOff,
                    tone: StateTone.destructive,
                    title: _loadError!.isNotFound
                        ? 'Vehicle no longer exists'
                        : 'Could not load vehicle',
                    message: _loadError!.isNotFound
                        ? '${widget.vehicle?.vehicleNumber ?? 'This vehicle'} was not found. It may have been deleted by someone else.'
                        : _loadError!.message,
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(context).pop(false),
                        leading: const Icon(LucideIcons.arrowLeft, size: 15),
                        child: const Text('Back to list'),
                      ),
                      if (!_loadError!.isNotFound)
                        ShadButton(
                          onPressed: () {
                            final id = widget.vehicle?.id;
                            if (id == null) return;
                            setState(() {
                              _isLoadingVehicle = true;
                              _loadError = null;
                            });
                            _loadVehicle(id);
                          },
                          leading: const Icon(LucideIcons.refreshCw, size: 15),
                          child: const Text('Retry'),
                        ),
                    ],
                  )
                : _isLoadingVehicle
                ? const StateMessageCard(
                    icon: LucideIcons.loader,
                    tone: StateTone.progress,
                    title: 'Loading vehicle details',
                    message: 'Fetching the latest record from the server.',
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
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
                                  title:
                                      'Vehicle Identification & Specifications',
                                  subtitle: 'Required fields are marked with an asterisk (*).',
                                ),
                                const SizedBox(height: 18),
                                _FormPair(
                                  isWide: isWide,
                                  left: ShadInputFormField(
                                    id: 'vehicleNumber',
                                    controller: _vehicleNumberController,
                                    label: const Text('Vehicle Number *'),
                                    placeholder: const Text(
                                      'e.g. DHA-METRO-GA-11-9001',
                                    ),
                                    leading: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        LucideIcons.hash,
                                        size: 15,
                                        color:
                                            theme.colorScheme.mutedForeground,
                                      ),
                                    ),
                                    forceErrorText:
                                        formState.vehicleNumberError,
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
                                  right: SizedBox(
                                    width: double.infinity,
                                    child: ShadSelectFormField<VehicleType>(
                                    id: 'vehicleType',
                                    forceErrorText:
                                        formState.fieldErrors['vehicleType'],
                                    label: const Text('Vehicle Type *'),
                                    initialValue: _vehicleType,
                                    placeholder: const Text(
                                      'Select vehicle type',
                                    ),
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
                                    onChanged: (value) {
                                      setState(() => _vehicleType = value);
                                      _recomputeDirty();
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Vehicle type is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _FormPair(
                                  isWide: isWide,
                                  left: ShadInputFormField(
                                    id: 'brand',
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('brand'),
                                    forceErrorText:
                                        formState.fieldErrors['brand'],
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
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('model'),
                                    forceErrorText:
                                        formState.fieldErrors['model'],
                                    controller: _modelController,
                                    label: const Text('Model *'),
                                    placeholder: const Text(
                                      'e.g. Corolla Cross',
                                    ),
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
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('manufacturingYear'),
                                    forceErrorText: formState
                                        .fieldErrors['manufacturingYear'],
                                    controller: _yearController,
                                    label: const Text('Manufacturing Year'),
                                    placeholder: const Text('e.g. 2023'),
                                    leading: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        LucideIcons.calendar,
                                        size: 15,
                                        color:
                                            theme.colorScheme.mutedForeground,
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
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('color'),
                                    forceErrorText:
                                        formState.fieldErrors['color'],
                                    controller: _colorController,
                                    label: const Text('Color'),
                                    placeholder: const Text('e.g. Pearl White'),
                                    leading: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        LucideIcons.palette,
                                        size: 15,
                                        color:
                                            theme.colorScheme.mutedForeground,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _FormPair(
                                  isWide: isWide,
                                  left: SizedBox(
                                    width: double.infinity,
                                    child: ShadSelectFormField<FuelType>(
                                    id: 'fuelType',
                                    forceErrorText:
                                        formState.fieldErrors['fuelType'],
                                    label: const Text('Fuel Type'),
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
                                    onChanged: (value) {
                                      setState(() => _fuelType = value);
                                      _recomputeDirty();
                                    },
                                  ),
                                  ),
                                  right: ShadInputFormField(
                                    id: 'seatingCapacity',
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('seatingCapacity'),
                                    forceErrorText: formState
                                        .fieldErrors['seatingCapacity'],
                                    controller: _seatingCapacityController,
                                    label: const Text('Seating Capacity'),
                                    placeholder: const Text('e.g. 5'),
                                    leading: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        LucideIcons.users,
                                        size: 15,
                                        color:
                                            theme.colorScheme.mutedForeground,
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
                                  subtitle: 'Assign a driver and set current fleet availability.',
                                ),
                                const SizedBox(height: 18),
                                _FormPair(
                                  isWide: isWide,
                                  left: ShadInputFormField(
                                    id: 'driverName',
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('driverName'),
                                    forceErrorText:
                                        formState.fieldErrors['driverName'],
                                    controller: _driverNameController,
                                    label: const Text('Driver Name'),
                                    placeholder: const Text(
                                      'e.g. Kamrul Hasan',
                                    ),
                                    leading: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        LucideIcons.user,
                                        size: 15,
                                        color:
                                            theme.colorScheme.mutedForeground,
                                      ),
                                    ),
                                  ),
                                  right: ShadInputFormField(
                                    id: 'driverPhone',
                                    onChanged: (_) => ref
                                        .read(vehicleFormProvider.notifier)
                                        .clearFieldError('driverPhone'),
                                    forceErrorText:
                                        formState.fieldErrors['driverPhone'],
                                    controller: _driverPhoneController,
                                    label: const Text('Driver Phone'),
                                    placeholder: const Text(
                                      'e.g. +8801711000000',
                                    ),
                                    leading: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        LucideIcons.phone,
                                        size: 15,
                                        color:
                                            theme.colorScheme.mutedForeground,
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _StatusSelector(
                                  value: _status,
                                  onChanged: (value) {
                                    setState(() => _status = value);
                                    _recomputeDirty();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          // Sticky action bar: on a form this long the save control must stay
          // reachable without scrolling to the bottom.
          _FormActionBar(
            isEditing: _isEditing,
            isSubmitting: formState.isSubmitting,
            hasUnsavedChanges: _isDirty,
            onCancel: _close,
            onSubmit: _submit,
          ),
        ],
      ),
      ),
    );
  }
}

/// Sticky bar holding Cancel and Save.
///
/// It sits outside the scroll view so the primary action is always on screen,
/// and it doubles as the place that tells the user there is unsaved work.
class _FormActionBar extends StatelessWidget {
  const _FormActionBar({
    required this.isEditing,
    required this.isSubmitting,
    required this.hasUnsavedChanges,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isEditing;
  final bool isSubmitting;
  final bool hasUnsavedChanges;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Widget? hint = hasUnsavedChanges && !isSubmitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.circleDot,
                              size: 14,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Unsaved changes',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      : null;

                  final cancel = ShadButton.outline(
                    onPressed: isSubmitting ? null : onCancel,
                    child: const Text('Cancel'),
                  );

                  final compact = constraints.maxWidth < 520;
                  final save = ShadButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    leading: isSubmitting
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isEditing ? LucideIcons.check : LucideIcons.plus,
                            size: 15,
                          ),
                    child: Text(
                      isSubmitting
                          ? 'Saving...'
                          : compact
                          ? (isEditing ? 'Save' : 'Create')
                          : (isEditing ? 'Save Changes' : 'Create Vehicle'),
                    ),
                  );

                  // Narrow: the buttons share a full-width row with the hint
                  // above them, instead of overflowing sideways.
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hint != null) ...[hint, const SizedBox(height: 10)],
                        Row(
                          children: [
                            Expanded(child: cancel),
                            const SizedBox(width: 12),
                            Expanded(child: save),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      if (hint != null) Flexible(child: hint),
                      const Spacer(),
                      cancel,
                      const SizedBox(width: 12),
                      save,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width status picker.
///
/// Status previously sat in a half-width dropdown paired with an empty slot,
/// which left a visible gap at the end of the form. Four options fit inline, so
/// they are shown as segments: one tap, and the current value is always visible
/// without opening anything.
class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.value, required this.onChanged});

  final VehicleStatus value;
  final ValueChanged<VehicleStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status *',
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in VehicleStatus.values)
              _StatusSegment(
                status: status,
                selected: status == value,
                onTap: () => onChanged(status),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Sets the vehicle's current operational availability.",
          style: theme.textTheme.muted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final VehicleStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = StatusPalette.of(context, status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.background : theme.colorScheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? palette.border : theme.colorScheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? palette.accent
                      : theme.colorScheme.mutedForeground.withValues(
                          alpha: 0.4,
                        ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status.label,
                style: theme.textTheme.small.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? palette.foreground
                      : theme.colorScheme.foreground,
                ),
              ),
            ],
          ),
        ),
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
          if (right is! SizedBox) ...[const SizedBox(height: 16), right],
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
