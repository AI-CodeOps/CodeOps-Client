/// Overview tab for the container detail page.
///
/// Displays container metadata (name, image, status, restart policy,
/// started/finished timestamps, exit code, service profile) in a
/// card layout, plus action buttons for stop, restart, and remove.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_enums.dart';
import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import 'container_status_badge.dart';

/// Callbacks for container actions on the overview tab.
typedef OverviewActionCallbacks = ({
  VoidCallback onStop,
  VoidCallback onRestart,
  VoidCallback onRemove,
});

/// Displays container detail information and action buttons.
class ContainerOverviewTab extends StatelessWidget {
  /// The container detail to display.
  final FleetContainerDetail detail;

  /// Action callbacks for stop, restart, and remove.
  final OverviewActionCallbacks callbacks;

  /// Creates a [ContainerOverviewTab].
  const ContainerOverviewTab({
    super.key,
    required this.detail,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  /// Builds the container information card.
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Container Info', style: CodeOpsTypography.titleMedium),
          const SizedBox(height: 16),
          _InfoRow(label: 'Name', value: detail.containerName ?? '\u2014'),
          _InfoRow(
            label: 'Image',
            value: '${detail.imageName ?? ""}:${detail.imageTag ?? "latest"}',
          ),
          _InfoRow(label: 'Service', value: detail.serviceName ?? '\u2014'),
          _InfoRow(
            label: 'Container ID',
            value: detail.containerId ?? '\u2014',
          ),
          _InfoRow(
            label: 'Status',
            child: detail.status != null
                ? ContainerStatusBadge(status: detail.status!)
                : const Text('\u2014',
                    style: TextStyle(color: CodeOpsColors.textSecondary)),
          ),
          _InfoRow(
            label: 'Health',
            value: detail.healthStatus?.displayName ?? 'None',
          ),
          _InfoRow(
            label: 'Restart Policy',
            value: detail.restartPolicy?.displayName ?? '\u2014',
          ),
          _InfoRow(
            label: 'Restart Count',
            value: '${detail.restartCount ?? 0}',
          ),
          if (detail.exitCode != null)
            _InfoRow(label: 'Exit Code', value: '${detail.exitCode}'),
          if (detail.pid != null)
            _InfoRow(label: 'PID', value: '${detail.pid}'),
          _InfoRow(label: 'Started', value: formatDateTime(detail.startedAt)),
          if (detail.finishedAt != null)
            _InfoRow(
                label: 'Finished', value: formatDateTime(detail.finishedAt)),
          if (detail.serviceProfileName != null)
            _InfoRow(
                label: 'Service Profile',
                value: detail.serviceProfileName!),
          _InfoRow(label: 'Created', value: formatDateTime(detail.createdAt)),
          if (detail.updatedAt != null)
            _InfoRow(
                label: 'Updated', value: formatDateTime(detail.updatedAt)),
        ],
      ),
    );
  }

  /// Builds the action buttons row.
  Widget _buildActions() {
    final isRunning = detail.status == ContainerStatus.running;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (isRunning)
          OutlinedButton.icon(
            onPressed: callbacks.onStop,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.warning,
              side: const BorderSide(color: CodeOpsColors.warning),
            ),
          ),
        OutlinedButton.icon(
          onPressed: callbacks.onRestart,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Restart'),
          style: OutlinedButton.styleFrom(
            foregroundColor: CodeOpsColors.secondary,
            side: const BorderSide(color: CodeOpsColors.secondary),
          ),
        ),
        OutlinedButton.icon(
          onPressed: callbacks.onRemove,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Remove'),
          style: OutlinedButton.styleFrom(
            foregroundColor: CodeOpsColors.error,
            side: const BorderSide(color: CodeOpsColors.error),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _InfoRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: CodeOpsTypography.bodySmall
                  .copyWith(color: CodeOpsColors.textTertiary),
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value ?? '\u2014',
                  style: CodeOpsTypography.bodyMedium,
                ),
          ),
        ],
      ),
    );
  }
}
