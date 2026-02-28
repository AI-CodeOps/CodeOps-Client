/// Health tab for the container detail page.
///
/// Displays a table of health check history results with status,
/// output, exit code, duration, and timestamp columns. Includes
/// a "Run Check" button to manually trigger a health check.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_enums.dart';
import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';

/// Displays health check history and provides manual check trigger.
class ContainerHealthTab extends StatelessWidget {
  /// The list of health check results.
  final List<FleetContainerHealthCheck> checks;

  /// Callback to manually trigger a health check.
  final VoidCallback onRunCheck;

  /// Callback to refresh the health check history.
  final VoidCallback onRefresh;

  /// Whether a manual check is currently in progress.
  final bool isCheckRunning;

  /// Creates a [ContainerHealthTab].
  const ContainerHealthTab({
    super.key,
    required this.checks,
    required this.onRunCheck,
    required this.onRefresh,
    this.isCheckRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: checks.isEmpty
              ? const Center(
                  child: Text(
                    'No health checks recorded',
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

  /// Builds the toolbar with Run Check and Refresh buttons.
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: isCheckRunning ? null : onRunCheck,
            icon: isCheckRunning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow, size: 16),
            label: const Text('Run Check'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.success,
              side: const BorderSide(color: CodeOpsColors.success),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: onRefresh,
            tooltip: 'Refresh history',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the health check history table.
  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(120), // Status
        1: FlexColumnWidth(3), // Output
        2: FixedColumnWidth(80), // Exit Code
        3: FixedColumnWidth(80), // Duration
        4: FixedColumnWidth(160), // Timestamp
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          children: const [
            _HeaderCell('Status'),
            _HeaderCell('Output'),
            _HeaderCell('Exit Code'),
            _HeaderCell('Duration'),
            _HeaderCell('Timestamp'),
          ],
        ),
        // Data rows
        ...checks.map(_buildRow),
      ],
    );
  }

  /// Builds a single health check row.
  TableRow _buildRow(FleetContainerHealthCheck check) {
    final statusColor = _colorForHealthStatus(check.status);
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: CodeOpsColors.border.withValues(alpha: 0.5))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  check.status?.displayName ?? '\u2014',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            check.output ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            '${check.exitCode ?? "\u2014"}',
            style: CodeOpsTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            check.durationMs != null ? '${check.durationMs}ms' : '\u2014',
            style: CodeOpsTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            formatDateTime(check.createdAt),
            style: CodeOpsTypography.bodySmall,
          ),
        ),
      ],
    );
  }

  /// Maps a [HealthStatus] to a display color.
  Color _colorForHealthStatus(HealthStatus? status) => switch (status) {
        HealthStatus.healthy => CodeOpsColors.success,
        HealthStatus.unhealthy => CodeOpsColors.error,
        HealthStatus.starting => CodeOpsColors.warning,
        _ => CodeOpsColors.textTertiary,
      };
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        label,
        style: CodeOpsTypography.labelMedium,
      ),
    );
  }
}
