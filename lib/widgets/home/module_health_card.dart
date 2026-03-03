// Module health card for the unified dashboard.
//
// Displays a module's name, icon, health status, and key metric.
// Tapping navigates to the module's dashboard.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_providers.dart';
import '../../theme/colors.dart';

/// A clickable card showing a module's health status and key metric.
class ModuleHealthCard extends StatefulWidget {
  /// The module health data to display.
  final ModuleHealth health;

  /// Creates a [ModuleHealthCard].
  const ModuleHealthCard({super.key, required this.health});

  @override
  State<ModuleHealthCard> createState() => _ModuleHealthCardState();
}

class _ModuleHealthCardState extends State<ModuleHealthCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.health;
    final statusColor = _statusColor(h.status);
    final statusLabel = _statusLabel(h.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(h.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? CodeOpsColors.surfaceVariant : CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? statusColor : CodeOpsColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(h.icon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.name,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                h.metric,
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(ModuleHealthStatus status) {
    return switch (status) {
      ModuleHealthStatus.healthy => CodeOpsColors.success,
      ModuleHealthStatus.degraded => CodeOpsColors.warning,
      ModuleHealthStatus.down => CodeOpsColors.error,
      ModuleHealthStatus.unknown => CodeOpsColors.textTertiary,
    };
  }

  static String _statusLabel(ModuleHealthStatus status) {
    return switch (status) {
      ModuleHealthStatus.healthy => 'Healthy',
      ModuleHealthStatus.degraded => 'Degraded',
      ModuleHealthStatus.down => 'Down',
      ModuleHealthStatus.unknown => 'Unknown',
    };
  }
}
