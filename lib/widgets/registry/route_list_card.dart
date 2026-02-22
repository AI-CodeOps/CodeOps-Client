/// Card displaying API routes registered for a service.
///
/// Shows HTTP method badges, route prefixes, environments,
/// and descriptions in a compact list layout.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Card displaying API routes registered for a service.
///
/// Each row shows an HTTP method badge (color-coded), the route prefix,
/// environment, and description.
class RouteListCard extends StatelessWidget {
  /// The API routes to display.
  final List<ApiRouteResponse> routes;

  /// Creates a [RouteListCard].
  const RouteListCard({super.key, required this.routes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.route_outlined, size: 18,
                    color: CodeOpsColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'API Routes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${routes.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (routes.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'No routes registered',
                style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
              ),
            )
          else
            ...routes.map((route) => _RouteRow(route: route)),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final ApiRouteResponse route;

  const _RouteRow({required this.route});

  @override
  Widget build(BuildContext context) {
    final methods = route.httpMethods ?? 'ANY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // HTTP method badges
          SizedBox(
            width: 120,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: methods
                  .split(',')
                  .map((m) => m.trim())
                  .where((m) => m.isNotEmpty)
                  .map((m) => _MethodBadge(method: m))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          // Route prefix
          Expanded(
            flex: 3,
            child: Text(
              route.routePrefix,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          // Environment
          if (route.environment != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                route.environment!,
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ),
          ],
          // Description
          if (route.description != null) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                route.description!,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Color-coded HTTP method badge.
class _MethodBadge extends StatelessWidget {
  final String method;

  const _MethodBadge({required this.method});

  Color get _color => switch (method.toUpperCase()) {
        'GET' => CodeOpsColors.success,
        'POST' => const Color(0xFF3B82F6),
        'PUT' => CodeOpsColors.warning,
        'PATCH' => const Color(0xFFA855F7),
        'DELETE' => CodeOpsColors.error,
        _ => CodeOpsColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: _color,
        ),
      ),
    );
  }
}
