/// Compliance matrix widget.
///
/// Displays compliance items in a DataTable with status badges and filtering.
library;

import 'package:flutter/material.dart';

import '../../models/compliance_item.dart';
import '../../models/enums.dart';
import '../../theme/colors.dart';

/// Displays compliance check results in a filterable table.
class ComplianceMatrix extends StatefulWidget {
  /// Compliance items to display.
  final List<ComplianceItem> items;

  /// Called when a compliance item is tapped.
  final ValueChanged<ComplianceItem>? onItemTap;

  /// Creates a [ComplianceMatrix].
  const ComplianceMatrix({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  State<ComplianceMatrix> createState() => _ComplianceMatrixState();
}

class _ComplianceMatrixState extends State<ComplianceMatrix> {
  ComplianceStatus? _statusFilter;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  List<ComplianceItem> get _filteredItems {
    var items = widget.items;
    if (_statusFilter != null) {
      items = items.where((i) => i.status == _statusFilter).toList();
    }
    items = List.of(items)..sort((a, b) {
      final result = switch (_sortColumnIndex) {
        0 => a.requirement.compareTo(b.requirement),
        1 => (a.specName ?? '').compareTo(b.specName ?? ''),
        2 => a.status.index.compareTo(b.status.index),
        3 => (a.agentType?.displayName ?? '')
            .compareTo(b.agentType?.displayName ?? ''),
        _ => 0,
      };
      return _sortAscending ? result : -result;
    });
    return items;
  }

  Map<ComplianceStatus, int> get _statusCounts {
    final counts = <ComplianceStatus, int>{};
    for (final item in widget.items) {
      counts.update(item.status, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = _statusCounts;
    final filtered = _filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _FilterChip(
              label: 'All (${widget.items.length})',
              selected: _statusFilter == null,
              onTap: () => setState(() => _statusFilter = null),
            ),
            ...ComplianceStatus.values.map((status) {
              final count = statusCounts[status] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return _FilterChip(
                label: '${status.displayName} ($count)',
                selected: _statusFilter == status,
                color: _statusColor(status),
                onTap: () => setState(() {
                  _statusFilter =
                      _statusFilter == status ? null : status;
                }),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),

        // Data table
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStateProperty.all(
                CodeOpsColors.surfaceVariant,
              ),
              dataRowColor: WidgetStateProperty.all(
                CodeOpsColors.surface,
              ),
              columns: [
                DataColumn(
                  label: const Text('Requirement',
                      style: TextStyle(color: CodeOpsColors.textPrimary)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Spec',
                      style: TextStyle(color: CodeOpsColors.textPrimary)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Status',
                      style: TextStyle(color: CodeOpsColors.textPrimary)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Agent',
                      style: TextStyle(color: CodeOpsColors.textPrimary)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
              ],
              rows: filtered.map((item) {
                return DataRow(
                  onSelectChanged: widget.onItemTap != null
                      ? (_) => widget.onItemTap!(item)
                      : null,
                  cells: [
                    DataCell(
                      Text(
                        item.requirement,
                        style: const TextStyle(
                          color: CodeOpsColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        item.specName ?? 'N/A',
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(_StatusBadge(status: item.status)),
                    DataCell(
                      Text(
                        item.agentType?.displayName ?? 'N/A',
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(ComplianceStatus status) {
    return switch (status) {
      ComplianceStatus.met => CodeOpsColors.success,
      ComplianceStatus.partial => CodeOpsColors.warning,
      ComplianceStatus.missing => CodeOpsColors.error,
      ComplianceStatus.notApplicable => CodeOpsColors.textTertiary,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final ComplianceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ComplianceStatus.met => CodeOpsColors.success,
      ComplianceStatus.partial => CodeOpsColors.warning,
      ComplianceStatus.missing => CodeOpsColors.error,
      ComplianceStatus.notApplicable => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? CodeOpsColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? chipColor.withValues(alpha: 0.4)
                : CodeOpsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : CodeOpsColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
