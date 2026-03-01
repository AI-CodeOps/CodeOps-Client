/// DBeaver-style indexes grid for the Properties panel.
///
/// Displays all indexes for the selected table in a sortable data grid
/// with index name, type, columns, unique/primary flags, size, condition,
/// tablespace, and validity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The Indexes sub-tab within the Properties panel.
///
/// Shows a scrollable grid of index metadata:
/// Index Name | Type | Columns | Unique | Primary | Size | Condition |
/// Tablespace | Valid.
class IndexesTab extends ConsumerStatefulWidget {
  /// Creates an [IndexesTab].
  const IndexesTab({super.key});

  @override
  ConsumerState<IndexesTab> createState() => _IndexesTabState();
}

class _IndexesTabState extends ConsumerState<IndexesTab> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final indexesAsync = ref.watch(datalensIndexesProvider);

    return indexesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading indexes: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (indexes) {
        if (indexes.isEmpty) {
          return const Center(
            child: Text(
              'No indexes found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        final sorted = _sortIndexes(indexes);
        return _buildGrid(sorted);
      },
    );
  }

  /// Builds the index grid with header and rows.
  Widget _buildGrid(List<IndexInfo> indexes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: ListView.builder(
            itemCount: indexes.length,
            itemBuilder: (context, index) => _buildDataRow(indexes[index]),
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
          _headerCell('Index Name', 0, flex: 1),
          _headerCell('Type', 1, width: 80),
          _headerCell('Columns', 2, width: 140),
          _headerCell('Unique', 3, width: 60),
          _headerCell('Primary', 4, width: 60),
          _headerCell('Size', 5, width: 80),
          _headerCell('Condition', 6, flex: 1),
          _headerCell('Tablespace', 7, width: 100),
          _headerCell('Valid', 8, width: 50),
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

  /// Builds a data row for a single index.
  Widget _buildDataRow(IndexInfo idx) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: _textCell(idx.indexName ?? '')),
          SizedBox(
            width: 80,
            child: _textCell(
              idx.indexType?.displayName ?? '',
              color: CodeOpsColors.secondary,
            ),
          ),
          SizedBox(
            width: 140,
            child: _textCell(idx.columns?.join(', ') ?? ''),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: idx.isUnique == true
                  ? const Icon(Icons.check, size: 14,
                      color: CodeOpsColors.warning)
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: idx.isPrimary == true
                  ? const Icon(Icons.check, size: 14,
                      color: CodeOpsColors.warning)
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 80,
            child: _textCell(idx.indexSize ?? ''),
          ),
          Expanded(
            child: _textCell(idx.condition ?? ''),
          ),
          SizedBox(
            width: 100,
            child: _textCell(idx.tablespace ?? ''),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: idx.isValid == true
                  ? const Icon(Icons.check, size: 14,
                      color: CodeOpsColors.success)
                  : idx.isValid == false
                      ? const Icon(Icons.close, size: 14,
                          color: CodeOpsColors.error)
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

  /// Sorts indexes by the active sort column.
  List<IndexInfo> _sortIndexes(List<IndexInfo> indexes) {
    final sorted = List<IndexInfo>.from(indexes);
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => (a.indexName ?? '').compareTo(b.indexName ?? ''),
        1 => (a.indexType?.displayName ?? '')
            .compareTo(b.indexType?.displayName ?? ''),
        2 => (a.columns?.join(', ') ?? '')
            .compareTo(b.columns?.join(', ') ?? ''),
        3 => (a.isUnique == true ? 1 : 0)
            .compareTo(b.isUnique == true ? 1 : 0),
        4 => (a.isPrimary == true ? 1 : 0)
            .compareTo(b.isPrimary == true ? 1 : 0),
        5 => (a.indexSize ?? '').compareTo(b.indexSize ?? ''),
        6 => (a.condition ?? '').compareTo(b.condition ?? ''),
        7 => (a.tablespace ?? '').compareTo(b.tablespace ?? ''),
        8 => (a.isValid == true ? 1 : 0)
            .compareTo(b.isValid == true ? 1 : 0),
        _ => (a.indexName ?? '').compareTo(b.indexName ?? ''),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}
