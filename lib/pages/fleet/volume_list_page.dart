/// Docker volume list page for the Fleet module.
///
/// Displays all Docker volumes at `/fleet/volumes`. Features include
/// create volume, prune unused volumes, and per-row remove actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import '../../widgets/fleet/create_volume_dialog.dart';
import '../../widgets/shared/confirm_dialog.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The Docker volume list page at `/fleet/volumes`.
class VolumeListPage extends ConsumerStatefulWidget {
  /// Creates a [VolumeListPage].
  const VolumeListPage({super.key});

  @override
  ConsumerState<VolumeListPage> createState() => _VolumeListPageState();
}

class _VolumeListPageState extends ConsumerState<VolumeListPage> {
  bool _isBusy = false;

  /// Returns the currently selected team ID, or null.
  String? get _teamId => ref.read(selectedTeamIdProvider);

  /// Refreshes the volume list.
  void _refresh() {
    final teamId = _teamId;
    if (teamId != null) {
      ref.invalidate(fleetVolumesProvider);
    }
  }

  /// Opens the create volume dialog.
  Future<void> _createVolume() async {
    final teamId = _teamId;
    if (teamId == null) return;

    final result = await CreateVolumeDialog.show(context);
    if (result == null) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.createVolume(teamId, result.name, driver: result.driver);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Volume "${result.name}" created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create volume: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Prunes unused volumes after confirmation.
  Future<void> _pruneVolumes() async {
    final teamId = _teamId;
    if (teamId == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Prune Volumes',
      message: 'Remove all unused Docker volumes? This cannot be undone.',
      confirmLabel: 'Prune',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.pruneVolumes(teamId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unused volumes pruned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to prune volumes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Removes a Docker volume after confirmation.
  Future<void> _removeVolume(FleetDockerVolume volume) async {
    final teamId = _teamId;
    if (teamId == null || volume.name == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Volume',
      message: 'Remove volume "${volume.name}"?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.removeVolume(teamId, volume.name!, force: true);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volume removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove volume: $e')),
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
        subtitle: 'Select a team to view Docker volumes.',
      );
    }

    final volumesAsync = ref.watch(fleetVolumesProvider(teamId));

    return volumesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (volumes) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Docker Volumes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${volumes.length})',
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
                    onPressed: _isBusy ? null : _createVolume,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Volume'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _pruneVolumes,
                    icon: const Icon(Icons.cleaning_services, size: 18),
                    label: const Text('Prune'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CodeOpsColors.warning,
                      side: const BorderSide(color: CodeOpsColors.warning),
                    ),
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
              if (volumes.isEmpty)
                const EmptyState(
                  icon: Icons.storage_outlined,
                  title: 'No Docker volumes found',
                  subtitle: 'Create a volume to get started.',
                )
              else
                _buildTable(volumes),
            ],
          ),
        );
      },
    );
  }

  /// Builds the volumes data table.
  Widget _buildTable(List<FleetDockerVolume> volumes) {
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
          2: FlexColumnWidth(2.5), // Mountpoint
          3: FixedColumnWidth(130), // Created
          4: FixedColumnWidth(60), // Actions
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
              _HeaderCell('Mountpoint'),
              _HeaderCell('Created'),
              _HeaderCell(''),
            ],
          ),
          ...volumes.map(_buildRow),
        ],
      ),
    );
  }

  /// Builds a single volume row.
  TableRow _buildRow(FleetDockerVolume volume) {
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
            volume.name ?? '\u2014',
            style: CodeOpsTypography.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            volume.driver ?? '\u2014',
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            volume.mountpoint ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            formatDateTime(volume.createdAt),
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: CodeOpsColors.error,
            onPressed: _isBusy ? null : () => _removeVolume(volume),
            tooltip: 'Remove',
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
