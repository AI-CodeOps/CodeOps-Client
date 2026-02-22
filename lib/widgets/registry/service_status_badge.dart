/// Status and health indicator widgets for registry services.
///
/// [ServiceStatusBadge] displays the operational status (ACTIVE, INACTIVE,
/// DEPRECATED, ARCHIVED) as a colored badge. [HealthIndicator] displays
/// the health status (UP, DOWN, DEGRADED, UNKNOWN) as a colored dot.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../theme/colors.dart';

/// Colored badge displaying service operational status.
///
/// Maps [ServiceStatus] enum values to background colors and labels.
class ServiceStatusBadge extends StatelessWidget {
  /// The service status to display.
  final ServiceStatus status;

  /// Creates a [ServiceStatusBadge].
  const ServiceStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = CodeOpsColors.serviceStatusColors[status] ??
        CodeOpsColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Colored health indicator dot with optional label.
///
/// Maps [HealthStatus] to colors matching the app's severity conventions.
/// When [status] is null, displays "Never checked" with a grey dot.
class HealthIndicator extends StatelessWidget {
  /// The health status to display. Null means never checked.
  final HealthStatus? status;

  /// Whether to show the text label next to the dot.
  final bool showLabel;

  /// Creates a [HealthIndicator].
  const HealthIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = status != null
        ? (CodeOpsColors.healthStatusColors[status!] ??
            CodeOpsColors.textTertiary)
        : CodeOpsColors.textTertiary;

    final label = status?.displayName ?? 'Never checked';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
