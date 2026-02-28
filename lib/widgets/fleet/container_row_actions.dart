/// Per-row action buttons for a container in the list table.
///
/// Shows contextual actions based on the container's current status:
/// Stop (if running), Start (if stopped/exited), Restart, Remove, View Logs.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_enums.dart';
import '../../theme/colors.dart';

/// Callbacks for per-row container actions.
typedef ContainerActionCallbacks = ({
  VoidCallback? onStop,
  VoidCallback? onStart,
  VoidCallback onRestart,
  VoidCallback onRemove,
  VoidCallback onViewLogs,
});

/// Action buttons displayed at the end of each container row.
class ContainerRowActions extends StatelessWidget {
  /// The current status of the container.
  final ContainerStatus status;

  /// Callbacks for each action.
  final ContainerActionCallbacks callbacks;

  /// Creates [ContainerRowActions].
  const ContainerRowActions({
    super.key,
    required this.status,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = status == ContainerStatus.running;
    final isStopped = status == ContainerStatus.stopped ||
        status == ContainerStatus.exited ||
        status == ContainerStatus.created;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRunning)
          _ActionIcon(
            icon: Icons.stop,
            tooltip: 'Stop',
            color: CodeOpsColors.warning,
            onTap: callbacks.onStop,
          ),
        if (isStopped)
          _ActionIcon(
            icon: Icons.play_arrow,
            tooltip: 'Start',
            color: CodeOpsColors.success,
            onTap: callbacks.onStart,
          ),
        _ActionIcon(
          icon: Icons.restart_alt,
          tooltip: 'Restart',
          color: CodeOpsColors.secondary,
          onTap: callbacks.onRestart,
        ),
        _ActionIcon(
          icon: Icons.delete_outline,
          tooltip: 'Remove',
          color: CodeOpsColors.error,
          onTap: callbacks.onRemove,
        ),
        _ActionIcon(
          icon: Icons.article_outlined,
          tooltip: 'View Logs',
          color: CodeOpsColors.textSecondary,
          onTap: callbacks.onViewLogs,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      color: color,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      splashRadius: 16,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
