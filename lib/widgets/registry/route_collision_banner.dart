/// Warning banner displaying detected route prefix collisions.
///
/// Shows a collapsible list of conflicting route prefixes, the
/// environment, and the services that claim each prefix.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Warning banner for detected route collisions.
///
/// Collapsed state shows collision count. Expanded state lists each
/// collision with prefix, environment, and conflicting service names.
class RouteCollisionBanner extends StatefulWidget {
  /// Route check responses with collisions (available == false).
  final List<RouteCheckResponse> collisions;

  /// Creates a [RouteCollisionBanner].
  const RouteCollisionBanner({super.key, required this.collisions});

  @override
  State<RouteCollisionBanner> createState() => _RouteCollisionBannerState();
}

class _RouteCollisionBannerState extends State<RouteCollisionBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.collisions.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: CodeOpsColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.collisions.length} route collision${widget.collisions.length == 1 ? '' : 's'} detected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CodeOpsColors.warning,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: CodeOpsColors.warning,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: widget.collisions.map((c) {
                  final services = c.conflictingRoutes
                      .map((r) => r.serviceName ?? r.serviceId)
                      .toSet()
                      .join(', ');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Text(
                          c.routePrefix,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                            color: CodeOpsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${c.environment})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'claimed by $services',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CodeOpsColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
