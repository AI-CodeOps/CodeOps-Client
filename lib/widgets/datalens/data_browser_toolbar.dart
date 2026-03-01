/// DBeaver-style toolbar for the data browser tab.
///
/// Displays pagination controls (prev/next/page number), page size selector,
/// refresh button, filter toggle, sort indicator, export button, and total
/// row count.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Toolbar above the data grid in the Data browser tab.
///
/// Provides pagination navigation, page size selection, refresh, filter toggle,
/// export, and row count display.
class DataBrowserToolbar extends StatelessWidget {
  /// Current zero-based page index.
  final int currentPage;

  /// Total number of rows.
  final int totalRows;

  /// Rows per page.
  final int pageSize;

  /// Whether the filter panel is visible.
  final bool filterVisible;

  /// Currently sorted column name, or `null`.
  final String? sortColumn;

  /// Whether the sort is ascending.
  final bool sortAscending;

  /// Called when the previous page button is tapped.
  final VoidCallback? onPrevious;

  /// Called when the next page button is tapped.
  final VoidCallback? onNext;

  /// Called when the page size changes.
  final ValueChanged<int> onPageSizeChanged;

  /// Called when the refresh button is tapped.
  final VoidCallback onRefresh;

  /// Called when the filter toggle button is tapped.
  final VoidCallback onFilterToggle;

  /// Called when the export button is tapped.
  final VoidCallback onExport;

  /// Creates a [DataBrowserToolbar].
  const DataBrowserToolbar({
    super.key,
    required this.currentPage,
    required this.totalRows,
    required this.pageSize,
    required this.filterVisible,
    this.sortColumn,
    this.sortAscending = true,
    this.onPrevious,
    this.onNext,
    required this.onPageSizeChanged,
    required this.onRefresh,
    required this.onFilterToggle,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = totalRows > 0 ? (totalRows / pageSize).ceil() : 1;
    final displayPage = currentPage + 1;

    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Previous
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Previous page',
            onPressed: onPrevious,
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Page display
          Text(
            'Page $displayPage of $totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          // Next
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Next page',
            onPressed: onNext,
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          const SizedBox(width: 8),
          const VerticalDivider(
            width: 1,
            indent: 6,
            endIndent: 6,
            color: CodeOpsColors.border,
          ),
          const SizedBox(width: 8),

          // Page size dropdown
          const Text(
            'Rows:',
            style: TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          _PageSizeDropdown(
            pageSize: pageSize,
            onChanged: onPageSizeChanged,
          ),

          const SizedBox(width: 8),
          const VerticalDivider(
            width: 1,
            indent: 6,
            endIndent: 6,
            color: CodeOpsColors.border,
          ),
          const SizedBox(width: 8),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: onRefresh,
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Filter toggle
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              size: 16,
              color: filterVisible
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textSecondary,
            ),
            tooltip: 'Toggle filter',
            onPressed: onFilterToggle,
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Sort indicator
          if (sortColumn != null) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: CodeOpsColors.primary,
            ),
            Text(
              sortColumn!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.primary,
              ),
            ),
          ],

          const Spacer(),

          // Export
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 16),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Export data',
            onPressed: onExport,
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          const SizedBox(width: 8),

          // Row count
          Text(
            _formatRowCount(totalRows),
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the row count with commas.
  String _formatRowCount(int count) {
    if (count < 1000) return '$count rows';
    final str = count.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return '${buf.toString()} rows';
  }
}

/// Page size dropdown widget.
class _PageSizeDropdown extends StatelessWidget {
  /// Current page size.
  final int pageSize;

  /// Called when selection changes.
  final ValueChanged<int> onChanged;

  const _PageSizeDropdown({
    required this.pageSize,
    required this.onChanged,
  });

  static const _sizes = [25, 50, 100, 250, 500];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: pageSize,
      items: _sizes
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(
                  '$s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      isDense: true,
      underline: const SizedBox.shrink(),
      dropdownColor: CodeOpsColors.surface,
      iconSize: 16,
      icon: const Icon(Icons.arrow_drop_down,
          color: CodeOpsColors.textSecondary),
    );
  }
}
