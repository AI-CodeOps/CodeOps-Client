/// Service node widget for the topology viewer.
///
/// Compact card showing service name, type icon, health indicator,
/// upstream/downstream dependency counts, and port count.
/// Supports selection highlighting and filter-based dimming.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'service_status_badge.dart';
import 'service_type_icon.dart';

/// Service node in the topology viewer.
///
/// Renders a ~140x70px card with [ServiceTypeIcon], service name,
/// [HealthIndicator], upstream count, downstream count, and port count.
/// Dimmed when [isFiltered] is true (node does not match current filter).
class TopologyNode extends StatelessWidget {
  /// The topology node data.
  final TopologyNodeResponse node;

  /// Whether this node is currently selected.
  final bool isSelected;

  /// Whether this node does NOT match the active filter (should be dimmed).
  final bool isFiltered;

  /// Callback when this node is tapped.
  final VoidCallback? onTap;

  /// Callback when this node is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Creates a [TopologyNode].
  const TopologyNode({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isFiltered = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? CodeOpsColors.primary : CodeOpsColors.border;
    final borderWidth = isSelected ? 2.0 : 1.0;
    final opacity = isFiltered ? 0.3 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: CodeOpsColors.primary.withValues(alpha: 0.2),
                  blurRadius: 6,
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: type icon + name
              Row(
                children: [
                  ServiceTypeIcon(type: node.serviceType, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row 2: health + upstream + downstream + ports
              Row(
                children: [
                  HealthIndicator(
                    status: node.healthStatus,
                    showLabel: false,
                  ),
                  const SizedBox(width: 6),
                  _CountBadge(
                    icon: Icons.arrow_upward,
                    count: node.upstreamDependencyCount ?? 0,
                    tooltip: 'Upstream',
                  ),
                  const SizedBox(width: 4),
                  _CountBadge(
                    icon: Icons.arrow_downward,
                    count: node.downstreamDependencyCount ?? 0,
                    tooltip: 'Downstream',
                  ),
                  if ((node.portCount ?? 0) > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      'P:${node.portCount}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon + count badge.
class _CountBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;

  const _CountBadge({
    required this.icon,
    required this.count,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: CodeOpsColors.textTertiary),
        const SizedBox(width: 1),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 9,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
