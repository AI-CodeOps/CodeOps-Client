/// Sortable data table displaying infrastructure resources.
///
/// Shows resource name, type icon, owning service, environment, region,
/// ARN/URL (truncated), and an actions menu. Orphan resources are
/// highlighted with a warning background and icon.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'infra_resource_type_icon.dart';

/// Data table widget for infrastructure resources.
///
/// Displays sortable columns for name, type, service, environment, region,
/// and ARN/URL. Orphaned resources (serviceId == null) show a warning icon
/// in the Service column with a subtle warning background.
class InfraResourceTable extends StatelessWidget {
  /// Resources to display.
  final List<InfraResourceResponse> resources;

  /// Currently sorted column name.
  final String sortField;

  /// Sort direction.
  final bool sortAscending;

  /// Called when a column header is tapped for sorting.
  final void Function(String field) onSort;

  /// Called when the Edit action is selected.
  final ValueChanged<InfraResourceResponse>? onEdit;

  /// Called when the Reassign action is selected.
  final ValueChanged<InfraResourceResponse>? onReassign;

  /// Called when the Mark as Orphan action is selected.
  final ValueChanged<InfraResourceResponse>? onOrphan;

  /// Called when the Delete action is selected.
  final ValueChanged<InfraResourceResponse>? onDelete;

  /// Called when a service name is tapped.
  final void Function(String serviceId)? onServiceTap;

  /// Creates an [InfraResourceTable].
  const InfraResourceTable({
    super.key,
    required this.resources,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    this.onEdit,
    this.onReassign,
    this.onOrphan,
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
                label: const Text('Name'),
                onSort: (_, __) => onSort('name'),
              ),
              DataColumn(
                label: const Text('Type'),
                onSort: (_, __) => onSort('type'),
              ),
              DataColumn(
                label: const Text('Service'),
                onSort: (_, __) => onSort('service'),
              ),
              DataColumn(
                label: const Text('Env'),
                onSort: (_, __) => onSort('environment'),
              ),
              DataColumn(
                label: const Text('Region'),
                onSort: (_, __) => onSort('region'),
              ),
              const DataColumn(label: Text('ARN / URL')),
              const DataColumn(label: Text('')),
            ],
            rows: resources.map((r) => _buildRow(r)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(InfraResourceResponse r) {
    final isOrphan = r.serviceId == null;
    return DataRow(
      color: isOrphan
          ? WidgetStateProperty.all(
              CodeOpsColors.warning.withValues(alpha: 0.05))
          : null,
      cells: [
        // Name
        DataCell(Text(
          r.resourceName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        // Type
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfraResourceTypeIcon(type: r.resourceType, size: 16),
            const SizedBox(width: 6),
            Text(
              r.resourceType.displayName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        )),
        // Service
        DataCell(
          isOrphan
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 14,
                        color: CodeOpsColors.warning),
                    SizedBox(width: 4),
                    Text(
                      'None',
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: onServiceTap != null && r.serviceId != null
                      ? () => onServiceTap!(r.serviceId!)
                      : null,
                  child: Text(
                    r.serviceName ?? r.serviceId ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: onServiceTap != null
                          ? CodeOpsColors.primary
                          : CodeOpsColors.textPrimary,
                      decoration: onServiceTap != null
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
                ),
        ),
        // Environment
        DataCell(Text(
          r.environment,
          style: const TextStyle(fontSize: 12),
        )),
        // Region
        DataCell(Text(
          r.region ?? '\u2014',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        )),
        // ARN / URL
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              r.arnOrUrl ?? '\u2014',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Actions
        DataCell(_ActionsMenu(
          resource: r,
          onEdit: onEdit,
          onReassign: onReassign,
          onOrphan: onOrphan,
          onDelete: onDelete,
        )),
      ],
    );
  }

  int? get _sortColumnIndex => switch (sortField) {
        'name' => 0,
        'type' => 1,
        'service' => 2,
        'environment' => 3,
        'region' => 4,
        _ => null,
      };
}

/// Three-dot actions menu for a resource row.
class _ActionsMenu extends StatelessWidget {
  final InfraResourceResponse resource;
  final ValueChanged<InfraResourceResponse>? onEdit;
  final ValueChanged<InfraResourceResponse>? onReassign;
  final ValueChanged<InfraResourceResponse>? onOrphan;
  final ValueChanged<InfraResourceResponse>? onDelete;

  const _ActionsMenu({
    required this.resource,
    this.onEdit,
    this.onReassign,
    this.onOrphan,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: CodeOpsColors.textSecondary,
      ),
      tooltip: 'Actions',
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'reassign', child: Text('Reassign')),
        if (resource.serviceId != null)
          const PopupMenuItem(
              value: 'orphan', child: Text('Mark as Orphan')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: CodeOpsColors.error)),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call(resource);
          case 'reassign':
            onReassign?.call(resource);
          case 'orphan':
            onOrphan?.call(resource);
          case 'delete':
            onDelete?.call(resource);
        }
      },
    );
  }
}
