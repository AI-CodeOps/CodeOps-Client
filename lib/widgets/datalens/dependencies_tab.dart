/// DBeaver-style dependencies grid for the Properties panel.
///
/// Displays table dependency relationships (both outgoing and incoming)
/// in a sortable data grid with source/target table/column, constraint name,
/// and direction indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The Dependencies sub-tab within the Properties panel.
///
/// Shows a scrollable grid of dependency relationships:
/// Direction | Source Table | Source Column | Target Table | Target Column |
/// Constraint Name.
class DependenciesTab extends ConsumerStatefulWidget {
  /// Creates a [DependenciesTab].
  const DependenciesTab({super.key});

  @override
  ConsumerState<DependenciesTab> createState() => _DependenciesTabState();
}

class _DependenciesTabState extends ConsumerState<DependenciesTab> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final depsAsync = ref.watch(datalensDependenciesProvider);

    return depsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading dependencies: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (dependencies) {
        if (dependencies.isEmpty) {
          return const Center(
            child: Text(
              'No dependencies found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        final sorted = _sortDependencies(dependencies);
        return _buildGrid(sorted);
      },
    );
  }

  /// Builds the dependencies grid with header and rows.
  Widget _buildGrid(List<TableDependency> dependencies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: ListView.builder(
            itemCount: dependencies.length,
            itemBuilder: (context, index) =>
                _buildDataRow(dependencies[index]),
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
          _headerCell('Direction', 0, width: 90),
          _headerCell('Source Table', 1, flex: 1),
          _headerCell('Source Column', 2, width: 140),
          _headerCell('Target Table', 3, flex: 1),
          _headerCell('Target Column', 4, width: 140),
          _headerCell('Constraint', 5, flex: 1),
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

  /// Builds a data row for a single dependency.
  Widget _buildDataRow(TableDependency dep) {
    final isOutgoing = dep.direction == 'outgoing';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOutgoing
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    size: 14,
                    color: isOutgoing
                        ? CodeOpsColors.secondary
                        : CodeOpsColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOutgoing ? 'Out' : 'In',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOutgoing
                          ? CodeOpsColors.secondary
                          : CodeOpsColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _textCell(dep.sourceTable ?? ''),
          ),
          SizedBox(
            width: 140,
            child: _textCell(dep.sourceColumn ?? ''),
          ),
          Expanded(
            child: _textCell(
              dep.targetTable ?? '',
              color: CodeOpsColors.secondary,
            ),
          ),
          SizedBox(
            width: 140,
            child: _textCell(dep.targetColumn ?? ''),
          ),
          Expanded(
            child: _textCell(dep.constraintName ?? ''),
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

  /// Sorts dependencies by the active sort column.
  List<TableDependency> _sortDependencies(List<TableDependency> deps) {
    final sorted = List<TableDependency>.from(deps);
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => (a.direction ?? '').compareTo(b.direction ?? ''),
        1 => (a.sourceTable ?? '').compareTo(b.sourceTable ?? ''),
        2 => (a.sourceColumn ?? '').compareTo(b.sourceColumn ?? ''),
        3 => (a.targetTable ?? '').compareTo(b.targetTable ?? ''),
        4 => (a.targetColumn ?? '').compareTo(b.targetColumn ?? ''),
        5 => (a.constraintName ?? '').compareTo(b.constraintName ?? ''),
        _ => (a.direction ?? '').compareTo(b.direction ?? ''),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}
