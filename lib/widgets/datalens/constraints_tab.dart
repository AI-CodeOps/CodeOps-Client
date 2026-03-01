/// DBeaver-style constraints grid for the Properties panel.
///
/// Displays all constraints for the selected table in a sortable data grid
/// with constraint name, type, columns, check expression, referenced table,
/// ON UPDATE/DELETE actions, and deferrable/deferred flags.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The Constraints sub-tab within the Properties panel.
///
/// Shows a scrollable grid of constraint metadata matching DBeaver's layout:
/// Constraint Name | Type | Columns | Expression | Ref Table | On Update |
/// On Delete | Deferrable | Deferred.
class ConstraintsTab extends ConsumerStatefulWidget {
  /// Creates a [ConstraintsTab].
  const ConstraintsTab({super.key});

  @override
  ConsumerState<ConstraintsTab> createState() => _ConstraintsTabState();
}

class _ConstraintsTabState extends ConsumerState<ConstraintsTab> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final constraintsAsync = ref.watch(datalensConstraintsProvider);

    return constraintsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading constraints: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (constraints) {
        if (constraints.isEmpty) {
          return const Center(
            child: Text(
              'No constraints found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        final sorted = _sortConstraints(constraints);
        return _buildGrid(sorted);
      },
    );
  }

  /// Builds the constraint grid with header and rows.
  Widget _buildGrid(List<ConstraintInfo> constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: ListView.builder(
            itemCount: constraints.length,
            itemBuilder: (context, index) =>
                _buildDataRow(constraints[index]),
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
          _headerCell('Type', 1, width: 100),
          _headerCell('Columns', 2, width: 140),
          _headerCell('Expression', 3, width: 140),
          _headerCell('Ref Table', 4, width: 120),
          _headerCell('On Update', 5, width: 90),
          _headerCell('On Delete', 6, width: 90),
          _headerCell('Deferrable', 7, width: 70),
          _headerCell('Deferred', 8, width: 70),
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

  /// Builds a data row for a single constraint.
  Widget _buildDataRow(ConstraintInfo constraint) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _textCell(constraint.constraintName ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(
              constraint.constraintType?.displayName ?? '',
              color: _typeColor(constraint.constraintType),
            ),
          ),
          SizedBox(
            width: 140,
            child: _textCell(constraint.columns?.join(', ') ?? ''),
          ),
          SizedBox(
            width: 140,
            child: _textCell(constraint.checkExpression ?? ''),
          ),
          SizedBox(
            width: 120,
            child: _textCell(constraint.referencedTable ?? ''),
          ),
          SizedBox(
            width: 90,
            child: _textCell(constraint.onUpdate ?? ''),
          ),
          SizedBox(
            width: 90,
            child: _textCell(constraint.onDelete ?? ''),
          ),
          SizedBox(
            width: 70,
            child: Center(
              child: constraint.isDeferrable == true
                  ? const Icon(Icons.check, size: 14,
                      color: CodeOpsColors.success)
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 70,
            child: Center(
              child: constraint.isDeferred == true
                  ? const Icon(Icons.check, size: 14,
                      color: CodeOpsColors.success)
                  : const SizedBox.shrink(),
            ),
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

  /// Returns a color for the constraint type badge.
  Color _typeColor(dynamic type) {
    if (type == null) return CodeOpsColors.textPrimary;
    return switch (type.toString()) {
      'ConstraintType.primaryKey' => CodeOpsColors.warning,
      'ConstraintType.foreignKey' => CodeOpsColors.secondary,
      'ConstraintType.unique' => CodeOpsColors.primary,
      'ConstraintType.check' => CodeOpsColors.success,
      _ => CodeOpsColors.textPrimary,
    };
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

  /// Sorts constraints by the active sort column.
  List<ConstraintInfo> _sortConstraints(List<ConstraintInfo> constraints) {
    final sorted = List<ConstraintInfo>.from(constraints);
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => (a.constraintName ?? '').compareTo(b.constraintName ?? ''),
        1 => (a.constraintType?.displayName ?? '')
            .compareTo(b.constraintType?.displayName ?? ''),
        2 => (a.columns?.join(', ') ?? '')
            .compareTo(b.columns?.join(', ') ?? ''),
        3 => (a.checkExpression ?? '').compareTo(b.checkExpression ?? ''),
        4 => (a.referencedTable ?? '').compareTo(b.referencedTable ?? ''),
        5 => (a.onUpdate ?? '').compareTo(b.onUpdate ?? ''),
        6 => (a.onDelete ?? '').compareTo(b.onDelete ?? ''),
        7 => (a.isDeferrable == true ? 1 : 0)
            .compareTo(b.isDeferrable == true ? 1 : 0),
        8 => (a.isDeferred == true ? 1 : 0)
            .compareTo(b.isDeferred == true ? 1 : 0),
        _ => (a.constraintName ?? '').compareTo(b.constraintName ?? ''),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}
