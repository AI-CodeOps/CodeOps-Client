/// Networks tab for the service profile detail page.
///
/// Displays a table of network configurations with network name,
/// aliases, IP address, and a remove action. Includes an
/// "Add Network" button to open the [NetworkConfigFormDialog].
library;

import 'package:flutter/material.dart';

import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// Displays network configurations and provides add/remove actions.
class ServiceProfileNetworksTab extends StatelessWidget {
  /// The list of network configurations to display.
  final List<FleetNetworkConfig> networks;

  /// Callback invoked when the user requests adding a network config.
  final VoidCallback onAdd;

  /// Callback invoked when the user requests removing a network config.
  final void Function(FleetNetworkConfig network) onRemove;

  /// Creates a [ServiceProfileNetworksTab].
  const ServiceProfileNetworksTab({
    super.key,
    required this.networks,
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
          child: networks.isEmpty
              ? const Center(
                  child: Text(
                    'No network configurations',
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

  /// Builds the toolbar with the Add Network button.
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Network'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.primary),
            ),
          ),
          const Spacer(),
          Text(
            '${networks.length} network(s)',
            style: CodeOpsTypography.bodySmall
                .copyWith(color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }

  /// Builds the network configurations table.
  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // Network Name
        1: FlexColumnWidth(2), // Aliases
        2: FlexColumnWidth(1.5), // IP Address
        3: FixedColumnWidth(60), // Actions
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          children: const [
            _HeaderCell('Network Name'),
            _HeaderCell('Aliases'),
            _HeaderCell('IP Address'),
            _HeaderCell(''),
          ],
        ),
        ...networks.map(_buildRow),
      ],
    );
  }

  /// Builds a single network config row.
  TableRow _buildRow(FleetNetworkConfig net) {
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
            net.networkName ?? '\u2014',
            style: CodeOpsTypography.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            net.aliases ?? '\u2014',
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            net.ipAddress ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: CodeOpsColors.error,
            onPressed: () => onRemove(net),
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
