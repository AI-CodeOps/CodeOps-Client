/// Visual startup order display showing services in boot sequence.
///
/// Each service shows its position number, name, type icon, health dot,
/// and service type. Connected by a vertical line showing sequence flow.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'service_status_badge.dart';
import 'service_type_icon.dart';

/// Visual startup order display with timeline-style rendering.
///
/// Orders services by [startupOrder] (service ID list). Falls back to the
/// order of [services] if [startupOrder] is empty, with a message to
/// refresh ordering.
class StartupOrderDisplay extends StatelessWidget {
  /// Service entries with metadata.
  final List<WorkstationServiceEntry> services;

  /// Ordered service IDs defining the boot sequence.
  final List<String> startupOrder;

  /// Called when a service name is tapped.
  final ValueChanged<String>? onServiceTap;

  /// Creates a [StartupOrderDisplay].
  const StartupOrderDisplay({
    super.key,
    required this.services,
    required this.startupOrder,
    this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No services in this profile',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final ordered = _orderedServices();
    final hasOrder = startupOrder.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CodeOpsColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: CodeOpsColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16,
                      color: CodeOpsColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'No dependency-based ordering available. '
                    'Click Refresh Order.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CodeOpsColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (int i = 0; i < ordered.length; i++)
          _StepRow(
            index: i,
            entry: ordered[i],
            isLast: i == ordered.length - 1,
            onTap: onServiceTap != null
                ? () => onServiceTap!(ordered[i].serviceId)
                : null,
          ),
      ],
    );
  }

  List<WorkstationServiceEntry> _orderedServices() {
    if (startupOrder.isEmpty) return services;

    final byId = {for (final s in services) s.serviceId: s};
    final result = <WorkstationServiceEntry>[];

    for (final id in startupOrder) {
      final entry = byId.remove(id);
      if (entry != null) result.add(entry);
    }
    // Add any remaining services not in startupOrder.
    result.addAll(byId.values);
    return result;
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final WorkstationServiceEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  const _StepRow({
    required this.index,
    required this.entry,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = CodeOpsColors.healthStatusColors[entry.healthStatus] ??
        CodeOpsColors.textTertiary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circled number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CodeOpsColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CodeOpsColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: CodeOpsColors.primary,
                      ),
                    ),
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: CodeOpsColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CodeOpsColors.border),
                  ),
                  child: Row(
                    children: [
                      // Service name
                      Expanded(
                        child: Text(
                          entry.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CodeOpsColors.textPrimary,
                            decoration: onTap != null
                                ? TextDecoration.underline
                                : null,
                            decorationColor:
                                CodeOpsColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      // Type icon
                      ServiceTypeIcon(type: entry.serviceType, size: 16),
                      const SizedBox(width: 12),
                      // Health dot
                      HealthIndicator(
                        status: entry.healthStatus,
                        showLabel: false,
                      ),
                      const SizedBox(width: 8),
                      // Health label
                      Text(
                        entry.healthStatus.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: healthColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
