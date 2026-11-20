import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../config/api_config.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/vehicle_delete_dialog.dart';
import '../widgets/vehicle_detail_sheet.dart';
import '../widgets/vehicle_row_card.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  late final PagingController<int, Vehicle> _pagingController;
  final TextEditingController _searchController = TextEditingController();

  bool _hasNextPage = true;
  String _searchQuery = '';
  VehicleStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, Vehicle>(
      getNextPageKey: (state) {
        if (state.keys == null || state.keys!.isEmpty) {
          return 0;
        }
        if (!_hasNextPage) {
          return null;
        }
        return state.keys!.last + 1;
      },
      fetchPage: _fetchPage,
    );
  }

  Future<List<Vehicle>> _fetchPage(int pageKey) async {
    if (pageKey == 0) {
      _hasNextPage = true;
    }
    final repository = ref.read(vehicleRepositoryProvider);
    final response = await repository.getVehicles(
      page: pageKey,
      size: ApiConfig.defaultPageSize,
    );
    _hasNextPage = response.hasNext;
    ref.read(totalVehiclesCountProvider.notifier).setCount(response.totalElements);
    return response.content;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Vehicle vehicle) {
    if (_statusFilter != null && vehicle.status != _statusFilter) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    final q = _searchQuery.toLowerCase();
    return vehicle.vehicleNumber.toLowerCase().contains(q) ||
        vehicle.brand.toLowerCase().contains(q) ||
        vehicle.model.toLowerCase().contains(q) ||
        (vehicle.driverName?.toLowerCase().contains(q) ?? false) ||
        (vehicle.driverPhone?.toLowerCase().contains(q) ?? false);
  }

  Future<void> _openForm({Vehicle? vehicle}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleFormScreen(vehicle: vehicle),
      ),
    );
    if (changed == true) {
      _pagingController.refresh();
    }
  }

  Future<void> _confirmAndDelete(Vehicle vehicle) async {
    final id = vehicle.id;
    if (id == null) return;

    final confirmed = await showVehicleDeleteDialog(context, vehicle);
    if (confirmed != true || !mounted) return;

    final toaster = ShadToaster.of(context);
    try {
      await ref.read(vehicleRepositoryProvider).deleteVehicle(id);
      if (!mounted) return;
      toaster.show(
        ShadToast(
          title: const Text('Vehicle deleted'),
          description: Text(
            '${vehicle.vehicleNumber} (${vehicle.brand} ${vehicle.model}) has been removed.',
          ),
        ),
      );
      _pagingController.refresh();
    } on VehicleApiException catch (e) {
      if (!mounted) return;
      toaster.show(
        ShadToast.destructive(
          title: const Text('Failed to delete vehicle'),
          description: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      toaster.show(
        const ShadToast.destructive(
          title: Text('Failed to delete vehicle'),
          description: Text('An unexpected error occurred.'),
        ),
      );
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final totalCount = ref.watch(totalVehiclesCountProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _TopAdminBar(
            totalCount: totalCount,
            onRefresh: _pagingController.refresh,
            onAddVehicle: () => _openForm(),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: PagingListener<int, Vehicle>(
                    controller: _pagingController,
                    builder: (context, state, fetchNextPage) {
                      final loadedItems = state.items ?? const <Vehicle>[];
                      final hasActiveFilter =
                          _searchQuery.isNotEmpty || _statusFilter != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (totalCount != null) ...[
                            _FleetSummaryStrip(
                              totalCount: totalCount,
                              loadedVehicles: loadedItems,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _FilterToolbar(
                            searchController: _searchController,
                            searchQuery: _searchQuery,
                            statusFilter: _statusFilter,
                            onSearchChanged: (value) =>
                                setState(() => _searchQuery = value.trim()),
                            onStatusChanged: (status) =>
                                setState(() => _statusFilter = status),
                            onClear: _clearFilters,
                          ),
                          const SizedBox(height: 16),
                          if (isWide) const _TableHeaderRow(),
                          if (isWide) const SizedBox(height: 8),
                          Expanded(
                            child: PagedListView<int, Vehicle>.separated(
                              state: state,
                              fetchNextPage: fetchNextPage,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              builderDelegate:
                                  PagedChildBuilderDelegate<Vehicle>(
                                itemBuilder: (context, vehicle, index) {
                                  if (!_matchesFilter(vehicle)) {
                                    return const SizedBox.shrink();
                                  }
                                  return VehicleRowCard(
                                    vehicle: vehicle,
                                    onTap: () => showVehicleDetailSheet(
                                      context: context,
                                      vehicle: vehicle,
                                      onEdit: () => _openForm(vehicle: vehicle),
                                      onDelete: () =>
                                          _confirmAndDelete(vehicle),
                                    ),
                                    onEdit: () => _openForm(vehicle: vehicle),
                                    onDelete: () => _confirmAndDelete(vehicle),
                                  );
                                },
                                firstPageProgressIndicatorBuilder: (_) =>
                                    const _FirstPageSkeletonList(),
                                newPageProgressIndicatorBuilder: (_) =>
                                    Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Skeletonizer(
                                    enabled: true,
                                    child: VehicleRowCard(
                                      vehicle:
                                          VehicleRowCard.placeholderVehicle,
                                      onEdit: () {},
                                      onDelete: () {},
                                    ),
                                  ),
                                ),
                                firstPageErrorIndicatorBuilder: (_) =>
                                    _ErrorStateCard(
                                  error: state.error,
                                  onRetry: _pagingController.refresh,
                                ),
                                newPageErrorIndicatorBuilder: (_) =>
                                    _NewPageErrorBanner(
                                  error: state.error,
                                  onRetry: fetchNextPage,
                                ),
                                noItemsFoundIndicatorBuilder: (_) =>
                                    _EmptyStateCard(
                                  onAddVehicle: () => _openForm(),
                                ),
                                noMoreItemsIndicatorBuilder: (_) {
                                  final visibleCount = loadedItems
                                      .where(_matchesFilter)
                                      .length;
                                  if (hasActiveFilter && visibleCount == 0) {
                                    return _FilteredEmptyCard(
                                      onClear: _clearFilters,
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        hasActiveFilter
                                            ? 'Showing $visibleCount matching vehicles (from ${loadedItems.length} loaded)'
                                            : 'All ${loadedItems.length} vehicles loaded',
                                        style: theme.textTheme.muted
                                            .copyWith(fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _TopAdminBar extends StatelessWidget {
  const _TopAdminBar({
    required this.totalCount,
    required this.onRefresh,
    required this.onAddVehicle,
  });

  final int? totalCount;
  final VoidCallback onRefresh;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 640;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.truck,
                        size: 20,
                        color: theme.colorScheme.primaryForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Stark Group VMS',
                                style: theme.textTheme.h4.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (totalCount != null)
                                ShadBadge.secondary(
                                  child: Text('$totalCount total'),
                                ),
                            ],
                          ),
                          if (!isCompact)
                            Text(
                              'Fleet registry, driver assignment, and operational status',
                              style:
                                  theme.textTheme.muted.copyWith(fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadButton.outline(
                      onPressed: onRefresh,
                      leading: const Icon(LucideIcons.refreshCw, size: 15),
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 10),
                    ShadButton(
                      onPressed: onAddVehicle,
                      leading: const Icon(LucideIcons.plus, size: 16),
                      child: const Text('Add Vehicle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FleetSummaryStrip extends StatelessWidget {
  const _FleetSummaryStrip({
    required this.totalCount,
    required this.loadedVehicles,
  });

  final int totalCount;
  final List<Vehicle> loadedVehicles;

  @override
  Widget build(BuildContext context) {
    final availableCount = loadedVehicles
        .where((v) => v.status == VehicleStatus.available)
        .length;
    final inUseCount =
        loadedVehicles.where((v) => v.status == VehicleStatus.inUse).length;
    final maintenanceCount = loadedVehicles
        .where((v) => v.status == VehicleStatus.maintenance)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final cards = [
          _KpiCard(
            label: 'Total Fleet',
            value: '$totalCount',
            subtitle: '${loadedVehicles.length} loaded',
            icon: LucideIcons.layers,
            accentColor: const Color(0xFF0F172A),
          ),
          _KpiCard(
            label: 'Available',
            value: '$availableCount',
            subtitle: 'In loaded pages',
            icon: LucideIcons.circleCheck,
            accentColor: const Color(0xFF027A48),
          ),
          _KpiCard(
            label: 'In Use',
            value: '$inUseCount',
            subtitle: 'Active assignments',
            icon: LucideIcons.navigation,
            accentColor: const Color(0xFF175CD3),
          ),
          _KpiCard(
            label: 'Maintenance',
            value: '$maintenanceCount',
            subtitle: 'In service bay',
            icon: LucideIcons.wrench,
            accentColor: const Color(0xFFB54708),
          ),
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards
                .map(
                  (c) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: c,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: theme.textTheme.muted.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.searchController,
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final VehicleStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VehicleStatus?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasFilter = searchQuery.isNotEmpty || statusFilter != null;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: ShadInput(
            controller: searchController,
            placeholder: const Text(
              'Search plate, brand, model, or driver...',
            ),
            leading: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                LucideIcons.search,
                size: 15,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            trailing: searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    child: Icon(
                      LucideIcons.x,
                      size: 15,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  )
                : null,
            onChanged: onSearchChanged,
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusFilterPill(
              label: 'All',
              selected: statusFilter == null,
              onTap: () => onStatusChanged(null),
            ),
            for (final status in VehicleStatus.values)
              _StatusFilterPill(
                label: status.label,
                selected: statusFilter == status,
                onTap: () => onStatusChanged(
                  statusFilter == status ? null : status,
                ),
              ),
            if (hasFilter)
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: onClear,
                child: const Text('Reset'),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusFilterPill extends StatelessWidget {
  const _StatusFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return ShadButton(
        size: ShadButtonSize.sm,
        onPressed: onTap,
        child: Text(label),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final headerStyle = theme.textTheme.muted.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('VEHICLE & STATUS', style: headerStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text('MAKE / MODEL / SPECS', style: headerStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text('FUEL & CAPACITY', style: headerStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text('ASSIGNED DRIVER', style: headerStyle),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(
              'ACTIONS',
              style: headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstPageSkeletonList extends StatelessWidget {
  const _FirstPageSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
            child: VehicleRowCard(
              vehicle: VehicleRowCard.placeholderVehicle,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ShadCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.car,
                  size: 28,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No vehicles registered yet',
                style: theme.textTheme.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get started by adding the first vehicle to the Stark Group fleet.',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ShadButton(
                onPressed: onAddVehicle,
                leading: const Icon(LucideIcons.plus, size: 16),
                child: const Text('Add Vehicle'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _FilteredEmptyCard extends StatelessWidget {
  const _FilteredEmptyCard({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ShadCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.searchX,
                size: 28,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text('No matching vehicles', style: theme.textTheme.h4),
              const SizedBox(height: 6),
              Text(
                'Try clearing your search or status filter.',
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final message = error is VehicleApiException
        ? (error as VehicleApiException).message
        : 'Unable to load vehicles. Please check that the backend server is running.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ShadCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.destructive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.wifiOff,
                  size: 28,
                  color: theme.colorScheme.destructive,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load vehicles',
                style: theme.textTheme.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ShadButton(
                onPressed: onRetry,
                leading: const Icon(LucideIcons.refreshCw, size: 15),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _NewPageErrorBanner extends StatelessWidget {
  const _NewPageErrorBanner({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is VehicleApiException
        ? (error as VehicleApiException).message
        : 'Failed to load more vehicles.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ShadAlert.destructive(
        icon: const Icon(LucideIcons.circleAlert),
        title: const Text('Pagination error'),
        description: Row(
          children: [
            Expanded(child: Text(message)),
            const SizedBox(width: 12),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
