/// Sortable data table for displaying registered services.
///
/// Shows service name, type, status, health, dependency count, and
/// last health check time. Supports column sorting and row tap navigation.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'service_status_badge.dart';
import 'service_type_icon.dart';

/// Callback signature for service row taps.
typedef ServiceTapCallback = void Function(ServiceRegistrationResponse service);

/// Sortable data table widget for registered services.
///
/// Displays paginated rows with columns for name, type, status, health,
/// dependency count, and last health check. Click column headers to sort.
class ServiceTable extends StatelessWidget {
  /// The services to display in the table.
  final List<ServiceRegistrationResponse> services;

  /// Currently sorted column name.
  final String sortField;

  /// Sort direction.
  final bool sortAscending;

  /// Called when a column header is tapped for sorting.
  final void Function(String field) onSort;

  /// Called when a service row is tapped.
  final ServiceTapCallback? onTap;

  /// Creates a [ServiceTable].
  const ServiceTable({
    super.key,
    required this.services,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    this.onTap,
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
          headingRowColor: WidgetStateProperty.all(CodeOpsColors.surfaceVariant),
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
          columnSpacing: 24,
          horizontalMargin: 16,
          columns: [
            DataColumn(
              label: const Text('Name'),
              onSort: (_, __) => onSort('name'),
            ),
            DataColumn(
              label: const Text('Type'),
              onSort: (_, __) => onSort('type'),
            ),
            DataColumn(
              label: const Text('Status'),
              onSort: (_, __) => onSort('status'),
            ),
            DataColumn(
              label: const Text('Health'),
              onSort: (_, __) => onSort('health'),
            ),
            const DataColumn(
              label: Text('Deps'),
              numeric: true,
            ),
            DataColumn(
              label: const Text('Last Check'),
              onSort: (_, __) => onSort('lastCheck'),
            ),
          ],
          rows: services
              .map(
                (s) => DataRow(
                  onSelectChanged: onTap != null ? (_) => onTap!(s) : null,
                  cells: [
                    // Name + slug
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            s.slug,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CodeOpsColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Type
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ServiceTypeIcon(type: s.serviceType, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            s.serviceType.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    DataCell(ServiceStatusBadge(status: s.status)),
                    // Health
                    DataCell(HealthIndicator(status: s.lastHealthStatus)),
                    // Dependency count
                    DataCell(
                      Text(
                        '${s.dependencyCount ?? 0}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CodeOpsColors.textSecondary,
                        ),
                      ),
                    ),
                    // Last check
                    DataCell(
                      Text(
                        s.lastHealthCheckAt != null
                            ? formatTimeAgo(s.lastHealthCheckAt)
                            : 'never',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        ),
      ),
    );
  }

  int? get _sortColumnIndex => switch (sortField) {
        'name' => 0,
        'type' => 1,
        'status' => 2,
        'health' => 3,
        'lastCheck' => 5,
        _ => null,
      };
}
