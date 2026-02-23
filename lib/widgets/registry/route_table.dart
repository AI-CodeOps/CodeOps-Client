/// Sortable data table displaying registered API routes.
///
/// Shows route prefix, HTTP methods, owning service, gateway service,
/// environment, description, and a delete action. Rows with colliding
/// prefixes display a warning indicator.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Data table widget for API routes.
///
/// Renders sortable columns for prefix, HTTP methods, service, gateway,
/// environment, and description. Collision prefixes are highlighted with
/// a warning icon.
class RouteTable extends StatelessWidget {
  /// Routes to display.
  final List<ApiRouteResponse> routes;

  /// Set of route prefixes that have known collisions.
  final Set<String>? collisionPrefixes;

  /// Currently sorted column name.
  final String sortField;

  /// Sort direction.
  final bool sortAscending;

  /// Called when a column header is tapped for sorting.
  final void Function(String field) onSort;

  /// Called when the Delete action is selected.
  final ValueChanged<ApiRouteResponse>? onDelete;

  /// Called when a service name is tapped.
  final void Function(String serviceId)? onServiceTap;

  /// Creates a [RouteTable].
  const RouteTable({
    super.key,
    required this.routes,
    this.collisionPrefixes,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    this.onDelete,
    this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: CodeOpsColors.surface,
          border: Border.all(color: CodeOpsColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: sortAscending,
            headingRowColor:
                WidgetStateProperty.all(CodeOpsColors.surfaceVariant),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return CodeOpsColors.surfaceVariant.withValues(alpha: 0.5);
              }
              return null;
            }),
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textPrimary,
            ),
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: [
              DataColumn(
                label: const Text('Prefix'),
                onSort: (_, __) => onSort('prefix'),
              ),
              const DataColumn(label: Text('Methods')),
              DataColumn(
                label: const Text('Service'),
                onSort: (_, __) => onSort('service'),
              ),
              const DataColumn(label: Text('Gateway')),
              DataColumn(
                label: const Text('Env'),
                onSort: (_, __) => onSort('environment'),
              ),
              const DataColumn(label: Text('Description')),
              const DataColumn(label: Text('')),
            ],
            rows: routes.map((r) => _buildRow(r)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(ApiRouteResponse r) {
    final hasCollision =
        collisionPrefixes != null && collisionPrefixes!.contains(r.routePrefix);

    return DataRow(
      color: hasCollision
          ? WidgetStateProperty.all(
              CodeOpsColors.warning.withValues(alpha: 0.05))
          : null,
      cells: [
        // Prefix
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCollision) ...[
              const Icon(Icons.warning_amber,
                  size: 14, color: CodeOpsColors.warning),
              const SizedBox(width: 4),
            ],
            Text(
              r.routePrefix,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                fontSize: 12,
                color: hasCollision
                    ? CodeOpsColors.warning
                    : CodeOpsColors.textPrimary,
              ),
            ),
          ],
        )),
        // Methods
        DataCell(Text(
          r.httpMethods ?? '*',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: CodeOpsColors.textSecondary,
          ),
        )),
        // Service
        DataCell(
          GestureDetector(
            onTap: onServiceTap != null
                ? () => onServiceTap!(r.serviceId)
                : null,
            child: Text(
              r.serviceName ?? r.serviceId,
              style: TextStyle(
                fontSize: 12,
                color: onServiceTap != null
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textPrimary,
                decoration:
                    onServiceTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
        // Gateway
        DataCell(Text(
          r.gatewayServiceName ?? r.gatewayServiceId ?? '\u2014',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        )),
        // Environment
        DataCell(Text(
          r.environment ?? '\u2014',
          style: const TextStyle(fontSize: 12),
        )),
        // Description
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              r.description ?? '\u2014',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Delete
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: CodeOpsColors.textTertiary),
            tooltip: 'Delete route',
            onPressed: onDelete != null ? () => onDelete!(r) : null,
          ),
        ),
      ],
    );
  }

  int? get _sortColumnIndex => switch (sortField) {
        'prefix' => 0,
        'service' => 2,
        'environment' => 4,
        _ => null,
      };
}
