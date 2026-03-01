/// DBeaver-style incoming references grid for the Properties panel.
///
/// Displays all incoming foreign key references pointing to the selected
/// table in a sortable data grid. Uses the same layout as the FK tab but
/// reads from [datalensReferencesProvider] which returns incoming references.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The References sub-tab within the Properties panel.
///
/// Shows a scrollable grid of incoming foreign key references:
/// Constraint Name | Columns | Ref Schema | Ref Table | Ref Columns |
/// On Update | On Delete.
class ReferencesTab extends ConsumerStatefulWidget {
  /// Creates a [ReferencesTab].
  const ReferencesTab({super.key});

  @override
  ConsumerState<ReferencesTab> createState() => _ReferencesTabState();
}

class _ReferencesTabState extends ConsumerState<ReferencesTab> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final refsAsync = ref.watch(datalensReferencesProvider);

    return refsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading references: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (references) {
        if (references.isEmpty) {
          return const Center(
            child: Text(
              'No incoming references found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        final sorted = _sortReferences(references);
        return _buildGrid(sorted);
      },
    );
  }

  /// Builds the references grid with header and rows.
  Widget _buildGrid(List<ForeignKeyInfo> references) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: ListView.builder(
            itemCount: references.length,
            itemBuilder: (context, index) =>
                _buildDataRow(references[index]),
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

  /// Builds a data row for a single incoming reference.
  Widget _buildDataRow(ForeignKeyInfo ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: _textCell(ref.constraintName ?? '')),
          SizedBox(
            width: 140,
            child: _textCell(ref.columns?.join(', ') ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(ref.referencedSchema ?? ''),
          ),
          SizedBox(
            width: 120,
            child: _textCell(
              ref.referencedTable ?? '',
              color: CodeOpsColors.secondary,
            ),
          ),
          SizedBox(
            width: 140,
            child: _textCell(ref.referencedColumns?.join(', ') ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(ref.onUpdate ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(ref.onDelete ?? ''),
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

  /// Sorts references by the active sort column.
  List<ForeignKeyInfo> _sortReferences(List<ForeignKeyInfo> refs) {
    final sorted = List<ForeignKeyInfo>.from(refs);
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
