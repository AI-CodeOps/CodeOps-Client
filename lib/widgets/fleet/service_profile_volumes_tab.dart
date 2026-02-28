/// Volumes tab for the service profile detail page.
///
/// Displays a table of volume mounts with container path, host path,
/// volume name, read-only status, and a remove action. Includes an
/// "Add Volume" button to open the [VolumeMountFormDialog].
library;

import 'package:flutter/material.dart';

import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// Displays volume mount configurations and provides add/remove actions.
class ServiceProfileVolumesTab extends StatelessWidget {
  /// The list of volume mounts to display.
  final List<FleetVolumeMount> volumes;

  /// Callback invoked when the user requests adding a volume mount.
  final VoidCallback onAdd;

  /// Callback invoked when the user requests removing a volume mount.
  final void Function(FleetVolumeMount volume) onRemove;

  /// Creates a [ServiceProfileVolumesTab].
  const ServiceProfileVolumesTab({
    super.key,
    required this.volumes,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: volumes.isEmpty
              ? const Center(
                  child: Text(
                    'No volume mounts configured',
                    style: TextStyle(color: CodeOpsColors.textSecondary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildTable(),
                ),
        ),
      ],
    );
  }

  /// Builds the toolbar with the Add Volume button.
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Volume'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.primary),
            ),
          ),
          const Spacer(),
          Text(
            '${volumes.length} mount(s)',
            style: CodeOpsTypography.bodySmall
                .copyWith(color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }

  /// Builds the volume mounts table.
  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // Container Path
        1: FlexColumnWidth(2), // Host Path
        2: FlexColumnWidth(1.5), // Volume Name
        3: FixedColumnWidth(80), // Read Only
        4: FixedColumnWidth(60), // Actions
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          children: const [
            _HeaderCell('Container Path'),
            _HeaderCell('Host Path'),
            _HeaderCell('Volume Name'),
            _HeaderCell('Read Only'),
            _HeaderCell(''),
          ],
        ),
        ...volumes.map(_buildRow),
      ],
    );
  }

  /// Builds a single volume mount row.
  TableRow _buildRow(FleetVolumeMount vol) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: CodeOpsColors.border.withValues(alpha: 0.5)),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            vol.containerPath ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            vol.hostPath ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            vol.volumeName ?? '\u2014',
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Icon(
            vol.isReadOnly == true ? Icons.lock : Icons.lock_open,
            size: 16,
            color: vol.isReadOnly == true
                ? CodeOpsColors.warning
                : CodeOpsColors.textTertiary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: CodeOpsColors.error,
            onPressed: () => onRemove(vol),
            tooltip: 'Remove',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(label, style: CodeOpsTypography.labelMedium),
    );
  }
}
