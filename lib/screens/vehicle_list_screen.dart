import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../config/api_config.dart';
import '../config/app_colors.dart';
import '../models/auth_models.dart';
import '../models/vehicle.dart';
import '../providers/auth_providers.dart';
import '../providers/vehicle_providers.dart';
import '../repositories/vehicle_repository.dart';
import '../widgets/state_message_card.dart';
import '../widgets/user_menu.dart';
import '../widgets/vehicle_delete_dialog.dart';
import '../widgets/vehicle_detail_sheet.dart';
import '../widgets/vehicle_row_card.dart';
import 'vehicle_form_screen.dart';

/// Width at or above which the list renders as an aligned table.
const double _kTableBreakpoint = 960;

/// Shared horizontal rhythm: the content column and every row use this.
const double _kContentMaxWidth = 1200;
const double _kGutter = 24;

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  late final PagingController<int, Vehicle> _pagingController;
  final TextEditingController _searchController = TextEditingController();

  bool _hasNextPage = true;

  /// The rows most recently rendered.
  ///
  /// `PagingController.refresh()` clears the state, so without this every save
  /// or delete would blank the list and flash skeletons. Holding the previous
  /// rows and dimming them keeps the page still while it refetches.
  List<Vehicle> _previousItems = const [];
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
    ref
        .read(totalVehiclesCountProvider.notifier)
        .setCount(response.totalElements);
    return response.content;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter => _searchQuery.isNotEmpty || _statusFilter != null;

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

    final toaster = ShadToaster.of(context);
    String? failureMessage;

    // The dialog drives the request so it can show progress and block a
    // second confirm; it stays open until the call settles.
    final deleted = await showVehicleDeleteDialog(
      context,
      vehicle,
      onConfirm: () async {
        try {
          await ref.read(vehicleRepositoryProvider).deleteVehicle(id);
          return true;
        } on VehicleApiException catch (e) {
          failureMessage = e.message;
          return false;
        } catch (_) {
          failureMessage = 'An unexpected error occurred.';
          return false;
        }
      },
    );

    if (!mounted) return;

    if (deleted == true) {
      toaster.show(
        ShadToast(
          title: const Text('Vehicle deleted'),
          description: Text(
            '${vehicle.vehicleNumber} (${vehicle.brand} ${vehicle.model}) has been removed.',
          ),
        ),
      );
      _pagingController.refresh();
    } else if (failureMessage != null) {
      toaster.show(
        ShadToast.destructive(
          title: const Text('Failed to delete vehicle'),
          description: Text(failureMessage!),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    // AuthGate watches the session, so clearing it returns to the login
    // screen without navigating from here.
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
    final totalCount = ref.watch(totalVehiclesCountProvider);
    final isTable = MediaQuery.sizeOf(context).width >= _kTableBreakpoint;
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppSurface.of(context).page,
      body: Column(
        children: [
          _TopAdminBar(
            user: currentUser,
            onRefresh: _pagingController.refresh,
            onAddVehicle: () => _openForm(),
            onLogout: _logout,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _kGutter,
                    20,
                    _kGutter,
                    16,
                  ),
                  child: PagingListener<int, Vehicle>(
                    controller: _pagingController,
                    builder: (context, state, fetchNextPage) {
                      final loaded = state.items ?? const <Vehicle>[];
                      if (loaded.isNotEmpty) {
                        _previousItems = loaded;
                      }
                      final isRefreshing =
                          state.isLoading && _previousItems.isNotEmpty;

                      // Filtering the paging state itself, rather than hiding
                      // rows in the item builder, so no separators are drawn
                      // for invisible items.
                      final visibleState = _hasActiveFilter
                          ? state.copyWith(
                              pages: state.pages
                                  ?.map((p) => p.where(_matchesFilter).toList())
                                  .toList(),
                            )
                          : state;
                      final visibleCount = visibleState.items?.length ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (totalCount != null) ...[
                            _FleetKpiRow(
                              totalCount: totalCount,
                              loadedVehicles: loaded,
                            ),
                            const SizedBox(height: 18),
                          ],
                          _FilterToolbar(
                            searchController: _searchController,
                            searchQuery: _searchQuery,
                            statusFilter: _statusFilter,
                            resultLabel: _buildResultLabel(
                              visibleCount: visibleCount,
                              loadedCount: loaded.length,
                              totalCount: totalCount,
                            ),
                            onSearchChanged: (value) =>
                                setState(() => _searchQuery = value.trim()),
                            onStatusChanged: (status) =>
                                setState(() => _statusFilter = status),
                            onClear: _clearFilters,
                          ),
                          const SizedBox(height: 14),
                          if (isTable) ...[
                            const _TableHeaderRow(),
                            const SizedBox(height: 6),
                          ],
                          // Refetch shows a thin bar over the held rows rather
                          // than replacing them, so nothing jumps.
                          SizedBox(
                            height: 3,
                            child: isRefreshing
                                ? const ShadProgress(minHeight: 3)
                                : null,
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: PagedListView<int, Vehicle>.separated(
                              state: visibleState,
                              fetchNextPage: fetchNextPage,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              builderDelegate:
                                  PagedChildBuilderDelegate<Vehicle>(
                                    itemBuilder: (context, vehicle, index) {
                                      return VehicleRowCard(
                                        vehicle: vehicle,
                                        onTap: () => showVehicleDetailSheet(
                                          context: context,
                                          vehicle: vehicle,
                                          onEdit: () =>
                                              _openForm(vehicle: vehicle),
                                          onDelete: () =>
                                              _confirmAndDelete(vehicle),
                                        ),
                                        onEdit: () =>
                                            _openForm(vehicle: vehicle),
                                        onDelete: () =>
                                            _confirmAndDelete(vehicle),
                                      );
                                    },
                                    firstPageProgressIndicatorBuilder: (_) =>
                                        _previousItems.isEmpty
                                        ? const _FirstPageSkeletonList()
                                        : _HeldRowsPlaceholder(
                                            items: _previousItems,
                                          ),
                                    newPageProgressIndicatorBuilder: (_) =>
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Skeletonizer(
                                            child: VehicleRowCard(
                                              vehicle: VehicleRowCard
                                                  .placeholderVehicle,
                                              onEdit: _noop,
                                              onDelete: _noop,
                                            ),
                                          ),
                                        ),
                                    firstPageErrorIndicatorBuilder: (_) =>
                                        StateMessageCard(
                                          icon: LucideIcons.wifiOff,
                                          tone: StateTone.destructive,
                                          title: 'Could not load vehicles',
                                          message: _errorMessage(state.error),
                                          actions: [
                                            ShadButton(
                                              onPressed:
                                                  _pagingController.refresh,
                                              leading: const Icon(
                                                LucideIcons.refreshCw,
                                                size: 15,
                                              ),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                    newPageErrorIndicatorBuilder: (_) =>
                                        _NewPageErrorBanner(
                                          error: state.error,
                                          onRetry: fetchNextPage,
                                        ),
                                    noItemsFoundIndicatorBuilder: (_) =>
                                        _hasActiveFilter
                                        ? StateMessageCard(
                                            icon: LucideIcons.searchX,
                                            title: 'No matching vehicles',
                                            message:
                                                'No loaded vehicle matches your search or status filter.',
                                            actions: [
                                              ShadButton.outline(
                                                onPressed: _clearFilters,
                                                child: const Text(
                                                  'Clear filters',
                                                ),
                                              ),
                                            ],
                                          )
                                        : StateMessageCard(
                                            icon: LucideIcons.car,
                                            title: 'No vehicles registered yet',
                                            message:
                                                'Get started by adding the first vehicle to the Stark Group fleet.',
                                            actions: [
                                              ShadButton(
                                                onPressed: () => _openForm(),
                                                leading: const Icon(
                                                  LucideIcons.plus,
                                                  size: 16,
                                                ),
                                                child: const Text(
                                                  'Add Vehicle',
                                                ),
                                              ),
                                            ],
                                          ),
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

  static void _noop() {}

  static String _errorMessage(Object? error) {
    if (error is VehicleApiException) return error.message;
    return 'Unable to load vehicles. Please check that the backend server is running.';
  }

  /// One line describing what the list is currently showing, so the filter row
  /// explains its own effect instead of leaving the user to count rows.
  String _buildResultLabel({
    required int visibleCount,
    required int loadedCount,
    required int? totalCount,
  }) {
    if (totalCount == null) return '';
    if (_hasActiveFilter) {
      return 'Showing $visibleCount of $loadedCount loaded';
    }
    if (loadedCount >= totalCount) {
      return '$totalCount ${totalCount == 1 ? 'vehicle' : 'vehicles'}';
    }
    return 'Showing $loadedCount of $totalCount';
  }
}

class _TopAdminBar extends StatelessWidget {
  const _TopAdminBar({
    required this.user,
    required this.onRefresh,
    required this.onAddVehicle,
    required this.onLogout,
  });

  final AuthUser? user;
  final VoidCallback onRefresh;
  final VoidCallback onAddVehicle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 640;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kGutter,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.truck,
                    size: 19,
                    color: theme.colorScheme.primaryForeground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stark Group VMS',
                        style: theme.textTheme.large.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isCompact)
                        Text(
                          'Fleet registry, driver assignment and operational status',
                          style: theme.textTheme.muted.copyWith(fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Actions, in increasing order of prominence.
                if (isCompact)
                  ShadTooltip(
                    builder: (_) => const Text('Refresh'),
                    child: ShadIconButton.outline(
                      onPressed: onRefresh,
                      icon: const Icon(LucideIcons.refreshCw, size: 15),
                    ),
                  )
                else
                  ShadButton.outline(
                    onPressed: onRefresh,
                    leading: const Icon(LucideIcons.refreshCw, size: 15),
                    child: const Text('Refresh'),
                  ),
                const SizedBox(width: 10),
                if (isCompact)
                  ShadTooltip(
                    builder: (_) => const Text('Add vehicle'),
                    child: ShadIconButton(
                      onPressed: onAddVehicle,
                      icon: const Icon(LucideIcons.plus, size: 16),
                    ),
                  )
                else
                  ShadButton(
                    onPressed: onAddVehicle,
                    leading: const Icon(LucideIcons.plus, size: 16),
                    child: const Text('Add Vehicle'),
                  ),
                if (user != null) ...[
                  const SizedBox(width: 10),
                  UserMenu(user: user!, onLogout: onLogout),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of stat tiles summarising the fleet.
///
/// `totalCount` is authoritative (the server reports it); the per-status counts
/// can only describe the pages loaded so far, because the API exposes no
/// aggregate or filter endpoint. Each tile says which it is showing rather than
/// implying a fleet-wide number.
class _FleetKpiRow extends StatelessWidget {
  const _FleetKpiRow({required this.totalCount, required this.loadedVehicles});

  final int totalCount;
  final List<Vehicle> loadedVehicles;

  int _countOf(VehicleStatus status) =>
      loadedVehicles.where((v) => v.status == status).length;

  @override
  Widget build(BuildContext context) {
    final loaded = loadedVehicles.length;
    final surface = AppSurface.of(context);

    final tiles = <Widget>[
      _StatTile(
        label: 'Total fleet',
        value: totalCount,
        icon: LucideIcons.layers,
        // Neutral slate: the total is not a status.
        track: surface.neutralTrack,
        fill: surface.ink,
        iconTint: surface.neutralTint,
        share: totalCount == 0 ? 0 : loaded / totalCount,
        caption: loaded >= totalCount
            ? 'All records loaded'
            : '$loaded loaded so far',
      ),
      for (final status in const [
        VehicleStatus.available,
        VehicleStatus.inUse,
        VehicleStatus.maintenance,
      ])
        _StatTile(
          label: switch (status) {
            VehicleStatus.available => 'Available',
            VehicleStatus.inUse => 'In use',
            VehicleStatus.maintenance => 'Maintenance',
            VehicleStatus.inactive => 'Inactive',
          },
          value: _countOf(status),
          icon: switch (status) {
            VehicleStatus.available => LucideIcons.circleCheck,
            VehicleStatus.inUse => LucideIcons.navigation,
            VehicleStatus.maintenance => LucideIcons.wrench,
            VehicleStatus.inactive => LucideIcons.circleMinus,
          },
          // Meter track is a lighter step of the fill's own hue.
          track: StatusPalette.of(context, status).background,
          fill: StatusPalette.of(context, status).accent,
          iconTint: StatusPalette.of(context, status).background,
          iconColor: StatusPalette.of(context, status).foreground,
          share: loaded == 0 ? 0 : _countOf(status) / loaded,
          caption: loaded == 0
              ? 'No rows loaded'
              : 'of $loaded loaded',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two per row once four across would squeeze the numbers.
        if (constraints.maxWidth < 760) {
          const gap = 10.0;
          final cardWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final tile in tiles)
                SizedBox(width: cardWidth, child: tile),
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              Expanded(child: tiles[i]),
              if (i < tiles.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

/// A single stat tile: label, value, thin share meter, caption.
///
/// All four tiles share this structure so the row lines up on one grid and the
/// cards are the same height whatever the numbers are.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.track,
    required this.fill,
    required this.iconTint,
    required this.share,
    required this.caption,
    this.iconColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color track;
  final Color fill;
  final Color iconTint;
  final Color? iconColor;

  /// 0..1 portion of the meter that is filled.
  final double share;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor ?? fill),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value stays in the text token - the colour lives on the icon and
          // the meter, never on the number.
          Text(
            '$value',
            style: theme.textTheme.h3.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ShadProgress(
            value: share.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: track,
            color: fill,
            borderRadius: BorderRadius.circular(999),
            innerBorderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 7),
          Text(
            caption,
            style: theme.textTheme.muted.copyWith(fontSize: 11.5),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The single filter row. It scopes the list beneath it; the stat tiles above
/// describe the whole loaded set and deliberately stay outside its scope.
class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.searchController,
    required this.searchQuery,
    required this.statusFilter,
    required this.resultLabel,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final VehicleStatus? statusFilter;
  final String resultLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VehicleStatus?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasFilter = searchQuery.isNotEmpty || statusFilter != null;

    final search = ShadInput(
      controller: searchController,
      placeholder: const Text('Search plate, brand, model, or driver'),
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
    );

    final pills = Wrap(
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
            onTap: () =>
                onStatusChanged(statusFilter == status ? null : status),
          ),
      ],
    );

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resultLabel.isNotEmpty)
          Flexible(
            child: Text(
              resultLabel,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.muted.copyWith(fontSize: 12.5),
            ),
          ),
        if (hasFilter) ...[
          const SizedBox(width: 8),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: onClear,
            leading: const Icon(LucideIcons.x, size: 14),
            child: const Text('Reset'),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          // Stacked: the pills can wrap to several lines here, and a result
          // label floating beside that block reads as detached, so it gets its
          // own line underneath.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              pills,
              if (resultLabel.isNotEmpty || hasFilter) ...[
                const SizedBox(height: 10),
                Row(children: [trailing]),
              ],
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 320, child: search),
            const SizedBox(width: 14),
            Expanded(child: pills),
            const SizedBox(width: 14),
            trailing,
          ],
        );
      },
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

/// Column headings for the table layout.
///
/// The flex values and the trailing fixed width must stay in step with
/// [VehicleRowCard]'s desktop row, or the columns drift apart.
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
          Expanded(flex: 2, child: Text('FUEL & CAPACITY', style: headerStyle)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: Text('ASSIGNED DRIVER', style: headerStyle)),
          const SizedBox(width: 12),
          SizedBox(
            width: kVehicleActionsColumnWidth,
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
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
            child: VehicleRowCard(
              vehicle: VehicleRowCard.placeholderVehicle,
              onEdit: _VehicleListScreenState._noop,
              onDelete: _VehicleListScreenState._noop,
            ),
          ),
        ),
      ),
    );
  }
}

/// The previous rows, dimmed and inert, shown while a refetch is in flight.
///
/// This is what replaces a skeleton flash: the same content stays in place, so
/// the list does not collapse and reflow after every save or delete.
class _HeldRowsPlaceholder extends StatelessWidget {
  const _HeldRowsPlaceholder({required this.items});

  final List<Vehicle> items;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.45,
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8),
                child: VehicleRowCard(
                  vehicle: items[i],
                  onEdit: _VehicleListScreenState._noop,
                  onDelete: _VehicleListScreenState._noop,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewPageErrorBanner extends StatelessWidget {
  const _NewPageErrorBanner({required this.error, required this.onRetry});

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
