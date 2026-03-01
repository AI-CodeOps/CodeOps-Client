/// DBeaver-style columns grid for the Properties panel.
///
/// Displays all columns for the selected table in a sortable data grid
/// with type icons, ordinal position, data type, identity, nullability,
/// default values, and comments.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import 'column_type_icon.dart';

/// The Columns sub-tab within the Properties panel.
///
/// Shows a scrollable grid of column metadata matching DBeaver's layout:
/// Icon | Column Name | # | Data type | Identity | Collation | Not Null |
/// Default | Comment. Column headers are clickable for sorting.
class ColumnsTab extends ConsumerStatefulWidget {
  /// Creates a [ColumnsTab].
  const ColumnsTab({super.key});

  @override
  ConsumerState<ColumnsTab> createState() => _ColumnsTabState();
}

class _ColumnsTabState extends ConsumerState<ColumnsTab> {
  int _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final columnsAsync = ref.watch(datalensColumnsProvider);

    return columnsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading columns: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (columns) {
        if (columns.isEmpty) {
          return const Center(
            child: Text(
              'No columns found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        final sorted = _sortColumns(columns);
        return _buildGrid(sorted);
      },
    );
  }

  /// Builds the column grid with header and rows.
  Widget _buildGrid(List<ColumnInfo> columns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        _buildHeaderRow(),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: columns.length,
            itemBuilder: (context, index) => _buildDataRow(columns[index]),
          ),
        ),
      ],
    );
  }

  /// Builds the sortable header row.
  Widget _buildHeaderRow() {
    return Container(
      color: CodeOpsColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _headerCell('', 0, width: 32, sortable: false),
          _headerCell('Column Name', 1, flex: 1),
          _headerCell('#', 2, width: 40),
          _headerCell('Data type', 3, width: 120),
          _headerCell('Identity', 4, width: 60),
          _headerCell('Collation', 5, width: 80),
          _headerCell('Not Null', 6, width: 60),
          _headerCell('Default', 7, width: 120),
          _headerCell('Comment', 8, flex: 1),
        ],
      ),
    );
  }

  /// Builds a single header cell.
  Widget _headerCell(
    String label,
    int index, {
    double? width,
    int? flex,
    bool sortable = true,
  }) {
    final isSorted = _sortColumnIndex == index;
    final child = InkWell(
      onTap: sortable ? () => _onHeaderTap(index) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSorted
                      ? CodeOpsColors.textPrimary
                      : CodeOpsColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSorted)
              Icon(
                _sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 10,
                color: CodeOpsColors.primary,
              ),
          ],
        ),
      ),
    );

    if (flex != null) return Expanded(flex: flex, child: child);
    return SizedBox(width: width, child: child);
  }

  /// Builds a data row for a single column.
  Widget _buildDataRow(ColumnInfo column) {
    final isPk = column.category == ColumnCategory.primaryKey;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Icon
          SizedBox(
            width: 32,
            child: Center(
              child: ColumnTypeIcon(
                udtName: column.udtName,
                category: column.category,
              ),
            ),
          ),
          // Column Name
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                column.columnName ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isPk ? FontWeight.w600 : FontWeight.w400,
                  color: CodeOpsColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Ordinal position
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${column.ordinalPosition ?? ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
          ),
          // Data type
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                column.dataType ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.secondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Identity
          SizedBox(
            width: 60,
            child: Center(
              child: column.isIdentity == true
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: CodeOpsColors.success,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Collation
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                column.collation ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Not Null
          SizedBox(
            width: 60,
            child: Center(
              child: column.isNullable == false
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: CodeOpsColors.warning,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Default
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                column.columnDefault ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Comment
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                column.comment ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sorting
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles header tap for sorting.
  void _onHeaderTap(int index) {
    setState(() {
      if (_sortColumnIndex == index) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = index;
        _sortAscending = true;
      }
    });
  }

  /// Sorts columns by the active sort column.
  List<ColumnInfo> _sortColumns(List<ColumnInfo> columns) {
    final sorted = List<ColumnInfo>.from(columns);
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        1 => (a.columnName ?? '').compareTo(b.columnName ?? ''),
        2 => (a.ordinalPosition ?? 0).compareTo(b.ordinalPosition ?? 0),
        3 => (a.dataType ?? '').compareTo(b.dataType ?? ''),
        4 => (a.isIdentity == true ? 1 : 0)
            .compareTo(b.isIdentity == true ? 1 : 0),
        5 => (a.collation ?? '').compareTo(b.collation ?? ''),
        6 => (a.isNullable == false ? 1 : 0)
            .compareTo(b.isNullable == false ? 1 : 0),
        7 => (a.columnDefault ?? '').compareTo(b.columnDefault ?? ''),
        8 => (a.comment ?? '').compareTo(b.comment ?? ''),
        _ => (a.ordinalPosition ?? 0).compareTo(b.ordinalPosition ?? 0),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}
