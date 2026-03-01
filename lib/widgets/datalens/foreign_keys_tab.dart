/// DBeaver-style foreign keys grid for the Properties panel.
///
/// Displays all foreign key relationships for the selected table in a
/// sortable data grid with constraint name, source columns, referenced
/// schema/table/columns, and ON UPDATE/DELETE actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The Foreign Keys sub-tab within the Properties panel.
///
/// Shows a scrollable grid of outgoing foreign key relationships:
/// Constraint Name | Columns | Ref Schema | Ref Table | Ref Columns |
/// On Update | On Delete.
class ForeignKeysTab extends ConsumerStatefulWidget {
  /// Creates a [ForeignKeysTab].
  const ForeignKeysTab({super.key});

  @override
  ConsumerState<ForeignKeysTab> createState() => _ForeignKeysTabState();
}

class _ForeignKeysTabState extends ConsumerState<ForeignKeysTab> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final fkAsync = ref.watch(datalensForeignKeysProvider);

    return fkAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading foreign keys: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (foreignKeys) {
        if (foreignKeys.isEmpty) {
          return const Center(
            child: Text(
              'No foreign keys found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        final sorted = _sortForeignKeys(foreignKeys);
        return _buildGrid(sorted);
      },
    );
  }

  /// Builds the FK grid with header and rows.
  Widget _buildGrid(List<ForeignKeyInfo> foreignKeys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: ListView.builder(
            itemCount: foreignKeys.length,
            itemBuilder: (context, index) =>
                _buildDataRow(foreignKeys[index]),
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
          _headerCell('Constraint Name', 0, flex: 1),
          _headerCell('Columns', 1, width: 140),
          _headerCell('Ref Schema', 2, width: 100),
          _headerCell('Ref Table', 3, width: 120),
          _headerCell('Ref Columns', 4, width: 140),
          _headerCell('On Update', 5, width: 100),
          _headerCell('On Delete', 6, width: 100),
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
  }) {
    final isSorted = _sortColumnIndex == index;
    final child = InkWell(
      onTap: () => _onHeaderTap(index),
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

  /// Builds a data row for a single foreign key.
  Widget _buildDataRow(ForeignKeyInfo fk) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: _textCell(fk.constraintName ?? '')),
          SizedBox(
            width: 140,
            child: _textCell(fk.columns?.join(', ') ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(fk.referencedSchema ?? ''),
          ),
          SizedBox(
            width: 120,
            child: _textCell(
              fk.referencedTable ?? '',
              color: CodeOpsColors.secondary,
            ),
          ),
          SizedBox(
            width: 140,
            child: _textCell(fk.referencedColumns?.join(', ') ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(fk.onUpdate ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(fk.onDelete ?? ''),
          ),
        ],
      ),
    );
  }

  /// Builds a padded text cell.
  Widget _textCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? CodeOpsColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
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

  /// Sorts foreign keys by the active sort column.
  List<ForeignKeyInfo> _sortForeignKeys(List<ForeignKeyInfo> foreignKeys) {
    final sorted = List<ForeignKeyInfo>.from(foreignKeys);
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => (a.constraintName ?? '').compareTo(b.constraintName ?? ''),
        1 => (a.columns?.join(', ') ?? '')
            .compareTo(b.columns?.join(', ') ?? ''),
        2 => (a.referencedSchema ?? '')
            .compareTo(b.referencedSchema ?? ''),
        3 => (a.referencedTable ?? '').compareTo(b.referencedTable ?? ''),
        4 => (a.referencedColumns?.join(', ') ?? '')
            .compareTo(b.referencedColumns?.join(', ') ?? ''),
        5 => (a.onUpdate ?? '').compareTo(b.onUpdate ?? ''),
        6 => (a.onDelete ?? '').compareTo(b.onDelete ?? ''),
        _ => (a.constraintName ?? '').compareTo(b.constraintName ?? ''),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}
