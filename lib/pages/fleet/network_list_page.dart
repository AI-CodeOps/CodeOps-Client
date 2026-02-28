/// Docker network list page for the Fleet module.
///
/// Displays all Docker networks at `/fleet/networks`. Features include
/// create network, per-row remove, and connect/disconnect container actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/fleet/connect_container_dialog.dart';
import '../../widgets/fleet/create_network_dialog.dart';
import '../../widgets/shared/confirm_dialog.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The Docker network list page at `/fleet/networks`.
class NetworkListPage extends ConsumerStatefulWidget {
  /// Creates a [NetworkListPage].
  const NetworkListPage({super.key});

  @override
  ConsumerState<NetworkListPage> createState() => _NetworkListPageState();
}

class _NetworkListPageState extends ConsumerState<NetworkListPage> {
  bool _isBusy = false;

  /// Returns the currently selected team ID, or null.
  String? get _teamId => ref.read(selectedTeamIdProvider);

  /// Refreshes the network list.
  void _refresh() {
    final teamId = _teamId;
    if (teamId != null) {
      ref.invalidate(fleetNetworksProvider);
    }
  }

  /// Opens the create network dialog.
  Future<void> _createNetwork() async {
    final teamId = _teamId;
    if (teamId == null) return;

    final result = await CreateNetworkDialog.show(context);
    if (result == null) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.createNetwork(
        teamId,
        result.name,
        driver: result.driver,
        subnet: result.subnet,
        gateway: result.gateway,
      );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network "${result.name}" created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create network: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Removes a Docker network after confirmation.
  Future<void> _removeNetwork(FleetDockerNetwork network) async {
    final teamId = _teamId;
    if (teamId == null || network.id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Network',
      message: 'Remove network "${network.name}"?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.removeNetwork(teamId, network.id!);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove network: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Opens the connect container dialog and connects.
  Future<void> _connectContainer(FleetDockerNetwork network) async {
    final teamId = _teamId;
    if (teamId == null || network.id == null) return;

    // Fetch available containers for the picker.
    final containers =
        await ref.read(fleetContainersProvider(teamId).future);

    final connectedIds =
        (network.connectedContainers ?? []).toSet();

    if (!mounted) return;

    final containerId = await ConnectContainerDialog.show(
      context,
      containers: containers,
      connectedIds: connectedIds,
    );
    if (containerId == null) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.connectContainerToNetwork(
          teamId, network.id!, containerId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container connected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect container: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Disconnects a container from a network after confirmation.
  Future<void> _disconnectContainer(
    FleetDockerNetwork network,
    String containerId,
  ) async {
    final teamId = _teamId;
    if (teamId == null || network.id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Disconnect Container',
      message: 'Disconnect container "$containerId" from "${network.name}"?',
      confirmLabel: 'Disconnect',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.disconnectContainerFromNetwork(
          teamId, network.id!, containerId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container disconnected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect container: $e')),
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
        subtitle: 'Select a team to view Docker networks.',
      );
    }

    final networksAsync = ref.watch(fleetNetworksProvider(teamId));

    return networksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (networks) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Docker Networks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${networks.length})',
                    style: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toolbar
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _createNetwork,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Network'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    color: CodeOpsColors.textSecondary,
                    onPressed: _isBusy ? null : _refresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Table or empty state
              if (networks.isEmpty)
                const EmptyState(
                  icon: Icons.hub_outlined,
                  title: 'No Docker networks found',
                  subtitle: 'Create a network to get started.',
                )
              else
                _buildTable(networks),
            ],
          ),
        );
      },
    );
  }

  /// Builds the networks data table.
  Widget _buildTable(List<FleetDockerNetwork> networks) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2), // Name
          1: FixedColumnWidth(100), // Driver
          2: FlexColumnWidth(1.5), // Subnet
          3: FlexColumnWidth(1.5), // Gateway
          4: FixedColumnWidth(100), // Containers
          5: FixedColumnWidth(100), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: const [
              _HeaderCell('Name'),
              _HeaderCell('Driver'),
              _HeaderCell('Subnet'),
              _HeaderCell('Gateway'),
              _HeaderCell('Containers'),
              _HeaderCell('Actions'),
            ],
          ),
          ...networks.map(_buildRow),
        ],
      ),
    );
  }

  /// Builds a single network row.
  TableRow _buildRow(FleetDockerNetwork network) {
    final containerCount = network.connectedContainers?.length ?? 0;

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: CodeOpsColors.border.withValues(alpha: 0.5)),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            network.name ?? '\u2014',
            style: CodeOpsTypography.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            network.driver ?? '\u2014',
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            network.subnet ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            network.gateway ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            '$containerCount',
            style: CodeOpsTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.link, size: 16),
                color: CodeOpsColors.primary,
                onPressed:
                    _isBusy ? null : () => _connectContainer(network),
                tooltip: 'Connect Container',
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: CodeOpsColors.error,
                onPressed:
                    _isBusy ? null : () => _removeNetwork(network),
                tooltip: 'Remove',
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(label, style: CodeOpsTypography.labelMedium),
    );
  }
}
