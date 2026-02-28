/// Container list page for the Fleet module.
///
/// Displays all containers for the current team in a sortable, filterable
/// data table at `/fleet/containers`. Features include status filtering,
/// fuzzy search, column sorting, checkbox bulk selection, per-row actions,
/// and auto-refresh polling every 5 seconds.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/fleet_enums.dart';
import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../../utils/fuzzy_matcher.dart';
import '../../widgets/fleet/container_bulk_actions.dart';
import '../../widgets/fleet/container_list_table.dart';
import '../../widgets/fleet/container_list_toolbar.dart';
import '../../widgets/shared/confirm_dialog.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The container list page at `/fleet/containers`.
class ContainerListPage extends ConsumerStatefulWidget {
  /// Creates a [ContainerListPage].
  const ContainerListPage({super.key});

  @override
  ConsumerState<ContainerListPage> createState() => _ContainerListPageState();
}

class _ContainerListPageState extends ConsumerState<ContainerListPage> {
  ContainerStatusFilter _filter = ContainerStatusFilter.all;
  String _searchQuery = '';
  ContainerSortColumn _sortColumn = ContainerSortColumn.name;
  bool _sortAscending = true;
  final Set<String> _selectedIds = {};
  bool _isBusy = false;
  Timer? _pollTimer;

  /// Returns the currently selected team ID, or null.
  String? get _teamId => ref.read(selectedTeamIdProvider);

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Starts the auto-refresh polling timer.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: AppConstants.fleetContainerPollIntervalSeconds),
      (_) => _refresh(),
    );
  }

  /// Refreshes the container list data.
  void _refresh() {
    ref.invalidate(fleetContainersProvider);
  }

  /// Applies the status filter to a container.
  bool _matchesFilter(FleetContainerInstance c) {
    return switch (_filter) {
      ContainerStatusFilter.all => true,
      ContainerStatusFilter.running =>
        c.status == ContainerStatus.running,
      ContainerStatusFilter.stopped =>
        c.status == ContainerStatus.stopped ||
        c.status == ContainerStatus.exited,
      ContainerStatusFilter.unhealthy =>
        c.healthStatus == HealthStatus.unhealthy,
    };
  }

  /// Applies fuzzy search to a container by name.
  bool _matchesSearch(FleetContainerInstance c) {
    if (_searchQuery.isEmpty) return true;
    final name = c.containerName ?? '';
    return FuzzyMatcher.match(_searchQuery, name).score > 0;
  }

  /// Sorts containers by the active column and direction.
  List<FleetContainerInstance> _sortContainers(
    List<FleetContainerInstance> list,
  ) {
    final sorted = List<FleetContainerInstance>.from(list);
    sorted.sort((a, b) {
      final cmp = _compareByColumn(a, b);
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  /// Compares two containers by the active sort column.
  int _compareByColumn(FleetContainerInstance a, FleetContainerInstance b) {
    return switch (_sortColumn) {
      ContainerSortColumn.name =>
        (a.containerName ?? '').compareTo(b.containerName ?? ''),
      ContainerSortColumn.image =>
        _formatImage(a).compareTo(_formatImage(b)),
      ContainerSortColumn.status =>
        (a.status?.displayName ?? '').compareTo(b.status?.displayName ?? ''),
      ContainerSortColumn.cpu =>
        (a.cpuPercent ?? 0).compareTo(b.cpuPercent ?? 0),
      ContainerSortColumn.memory =>
        (a.memoryBytes ?? 0).compareTo(b.memoryBytes ?? 0),
      ContainerSortColumn.age =>
        (a.startedAt ?? DateTime(1970)).compareTo(
          b.startedAt ?? DateTime(1970),
        ),
    };
  }

  /// Formats image name:tag for sort comparison.
  String _formatImage(FleetContainerInstance c) {
    final name = c.imageName ?? '';
    final tag = c.imageTag;
    if (tag != null && tag.isNotEmpty) return '$name:$tag';
    return name;
  }

  /// Handles sort column tap — toggles direction or switches column.
  void _onSort(ContainerSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  /// Selects or deselects all visible containers.
  void _onSelectAll(bool selected, List<FleetContainerInstance> visible) {
    setState(() {
      if (selected) {
        for (final c in visible) {
          if (c.id != null) _selectedIds.add(c.id!);
        }
      } else {
        _selectedIds.clear();
      }
    });
  }

  /// Toggles selection of a single container.
  void _onSelectRow(String containerId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(containerId);
      } else {
        _selectedIds.remove(containerId);
      }
    });
  }

  /// Stops a single container.
  Future<void> _stopContainer(FleetContainerInstance container) async {
    final teamId = _teamId;
    if (teamId == null || container.id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Stop Container',
      message: 'Stop "${container.containerName ?? container.id}"?',
      confirmLabel: 'Stop',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.stopContainer(teamId, container.id!);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container stopped')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop container: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Starts a stopped container by restarting it.
  Future<void> _startContainer(FleetContainerInstance container) async {
    final teamId = _teamId;
    if (teamId == null || container.id == null) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.restartContainer(teamId, container.id!);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start container: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Restarts a single container.
  Future<void> _restartContainer(FleetContainerInstance container) async {
    final teamId = _teamId;
    if (teamId == null || container.id == null) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.restartContainer(teamId, container.id!);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container restarted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restart container: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Removes a single container after confirmation.
  Future<void> _removeContainer(FleetContainerInstance container) async {
    final teamId = _teamId;
    if (teamId == null || container.id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Container',
      message:
          'Remove "${container.containerName ?? container.id}"? This cannot be undone.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.removeContainer(teamId, container.id!, force: true);
      _selectedIds.remove(container.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove container: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Navigates to the container logs page.
  void _viewLogs(FleetContainerInstance container) {
    if (container.id != null) {
      context.go('/fleet/containers/${container.id}');
    }
  }

  /// Starts all selected containers.
  Future<void> _bulkStart() async {
    final teamId = _teamId;
    if (teamId == null || _selectedIds.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      for (final id in _selectedIds) {
        await api.restartContainer(teamId, id);
      }
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} container(s) started'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start containers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Stops all selected containers after confirmation.
  Future<void> _bulkStop() async {
    final teamId = _teamId;
    if (teamId == null || _selectedIds.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Stop Containers',
      message: 'Stop ${_selectedIds.length} selected container(s)?',
      confirmLabel: 'Stop All',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      for (final id in _selectedIds) {
        await api.stopContainer(teamId, id);
      }
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} container(s) stopped'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop containers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Removes all selected containers after confirmation.
  Future<void> _bulkRemove() async {
    final teamId = _teamId;
    if (teamId == null || _selectedIds.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Containers',
      message:
          'Remove ${_selectedIds.length} selected container(s)? This cannot be undone.',
      confirmLabel: 'Remove All',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      for (final id in Set<String>.from(_selectedIds)) {
        await api.removeContainer(teamId, id, force: true);
        _selectedIds.remove(id);
      }
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected containers removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove containers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view containers.',
      );
    }

    final containersAsync = ref.watch(fleetContainersProvider(teamId));

    return containersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (containers) {
        // Apply filter + search
        final filtered = containers
            .where(_matchesFilter)
            .where(_matchesSearch)
            .toList();

        // Apply sort
        final sorted = _sortContainers(filtered);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Containers',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${filtered.length})',
                    style: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toolbar
              ContainerListToolbar(
                filter: _filter,
                onFilterChanged: (f) => setState(() {
                  _filter = f;
                  _selectedIds.clear();
                }),
                onSearchChanged: (q) => setState(() {
                  _searchQuery = q;
                  _selectedIds.clear();
                }),
                onRefresh: _isBusy ? () {} : _refresh,
              ),
              const SizedBox(height: 12),

              // Bulk actions (shown when items are selected)
              if (_selectedIds.isNotEmpty) ...[
                ContainerBulkActions(
                  selectedCount: _selectedIds.length,
                  onStart: _isBusy ? () {} : _bulkStart,
                  onStop: _isBusy ? () {} : _bulkStop,
                  onRemove: _isBusy ? () {} : _bulkRemove,
                ),
                const SizedBox(height: 12),
              ],

              // Table or empty state
              if (sorted.isEmpty)
                const EmptyState(
                  icon: Icons.dns_outlined,
                  title: 'No containers found',
                  subtitle:
                      'No containers match the current filter and search.',
                )
              else
                ContainerListTable(
                  containers: sorted,
                  sortColumn: _sortColumn,
                  sortAscending: _sortAscending,
                  onSort: _onSort,
                  selectedIds: _selectedIds,
                  onSelectAll: (v) => _onSelectAll(v, sorted),
                  onSelectRow: _onSelectRow,
                  onRowTap: (c) {
                    if (c.id != null) {
                      context.go('/fleet/containers/${c.id}');
                    }
                  },
                  onStop: _stopContainer,
                  onStart: _startContainer,
                  onRestart: _restartContainer,
                  onRemove: _removeContainer,
                  onViewLogs: _viewLogs,
                ),
            ],
          ),
        );
      },
    );
  }
}
