/// DBeaver-style data browser tab for the table properties panel.
///
/// Composes a toolbar, optional filter bar, data grid, and status bar.
/// Manages pagination, sorting, and filtering state locally, delegating
/// data fetching to [QueryExecutionService.browseTable].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import 'data_browser_filter.dart';
import 'data_browser_toolbar.dart';
import 'data_export_dialog.dart';
import 'data_grid.dart';

/// The Data tab within the table properties panel.
///
/// Displays table data in a paginated, sortable, filterable grid. On initial
/// display, fetches the first page of rows using [QueryExecutionService.browseTable].
class DataBrowserTab extends ConsumerStatefulWidget {
  /// Creates a [DataBrowserTab].
  const DataBrowserTab({super.key});

  @override
  ConsumerState<DataBrowserTab> createState() => _DataBrowserTabState();
}

class _DataBrowserTabState extends ConsumerState<DataBrowserTab> {
  QueryResult? _result;
  bool _loading = false;
  String? _error;

  int _page = 0;
  int _pageSize = 100;
  String? _sortColumn;
  SortDirection? _sortDirection;
  String _filterText = '';
  bool _filterVisible = false;

  @override
  void initState() {
    super.initState();
    // Load data on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final selectedTable = ref.watch(selectedTableProvider);

    if (selectedTable == null) {
      return const Center(
        child: Text(
          'No table selected',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        DataBrowserToolbar(
          currentPage: _page,
          totalRows: _result?.totalRows ?? 0,
          pageSize: _pageSize,
          filterVisible: _filterVisible,
          sortColumn: _sortColumn,
          sortAscending: _sortDirection != SortDirection.desc,
          onPrevious: _page > 0 ? _previousPage : null,
          onNext: _hasNextPage() ? _nextPage : null,
          onPageSizeChanged: _onPageSizeChanged,
          onRefresh: _loadData,
          onFilterToggle: () =>
              setState(() => _filterVisible = !_filterVisible),
          onExport: _showExportDialog,
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Filter (collapsible)
        if (_filterVisible) ...[
          DataBrowserFilter(
            filterText: _filterText,
            onApply: _onFilterApply,
            onClear: _onFilterClear,
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
        ],

        // Data grid or loading/error state
        Expanded(child: _buildContent()),

        // Status bar
        const Divider(height: 1, color: CodeOpsColors.border),
        _buildStatusBar(),
      ],
    );
  }

  /// Builds the main content area — grid, loading, or error.
  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_result == null) {
      return const Center(
        child: Text(
          'No data loaded',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return DataGrid(
      result: _result!,
      sortColumn: _sortColumn,
      sortAscending: _sortDirection != SortDirection.desc,
      onSort: _onSort,
    );
  }

  /// Builds the bottom status bar.
  Widget _buildStatusBar() {
    final totalRows = _result?.totalRows ?? 0;
    final rowCount = _result?.rowCount ?? 0;
    final executionTime = _result?.executionTimeMs ?? 0;

    final startRow = totalRows > 0 ? _page * _pageSize + 1 : 0;
    final endRow = startRow > 0 ? startRow + rowCount - 1 : 0;

    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            '${_formatInt(totalRows)} rows',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          if (totalRows > 0)
            Text(
              'Showing $startRow-$endRow',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          const Spacer(),
          if (executionTime > 0)
            Text(
              'Query time: ${executionTime}ms',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data Loading
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads data from the database using browseTable.
  Future<void> _loadData() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    final schema = ref.read(selectedSchemaProvider);
    final table = ref.read(selectedTableProvider);

    if (connectionId == null || schema == null || table == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(datalensQueryServiceProvider);
      final result = await service.browseTable(
        connectionId,
        schema,
        table,
        limit: _pageSize,
        offset: _page * _pageSize,
        orderBy: _sortColumn,
        sortDirection: _sortDirection,
        whereClause: _filterText.isNotEmpty ? _filterText : null,
      );

      if (!mounted) return;

      if (result.status == QueryStatus.failed) {
        setState(() {
          _error = result.error ?? 'Query failed';
          _loading = false;
        });
      } else {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pagination
  // ─────────────────────────────────────────────────────────────────────────

  /// Goes to the previous page.
  void _previousPage() {
    setState(() => _page--);
    _loadData();
  }

  /// Goes to the next page.
  void _nextPage() {
    setState(() => _page++);
    _loadData();
  }

  /// Returns true if there is a next page.
  bool _hasNextPage() {
    final totalRows = _result?.totalRows ?? 0;
    return (_page + 1) * _pageSize < totalRows;
  }

  /// Changes the page size and resets to page 0.
  void _onPageSizeChanged(int newSize) {
    setState(() {
      _pageSize = newSize;
      _page = 0;
    });
    _loadData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sorting
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles column header sort tap.
  void _onSort(String columnName) {
    setState(() {
      if (_sortColumn == columnName) {
        if (_sortDirection == SortDirection.asc) {
          _sortDirection = SortDirection.desc;
        } else {
          _sortColumn = null;
          _sortDirection = null;
        }
      } else {
        _sortColumn = columnName;
        _sortDirection = SortDirection.asc;
      }
      _page = 0;
    });
    _loadData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter
  // ─────────────────────────────────────────────────────────────────────────

  /// Applies a WHERE clause filter.
  void _onFilterApply(String text) {
    setState(() {
      _filterText = text;
      _page = 0;
    });
    _loadData();
  }

  /// Clears the filter.
  void _onFilterClear() {
    setState(() {
      _filterText = '';
      _page = 0;
    });
    _loadData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Export
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows the export dialog.
  void _showExportDialog() {
    if (_result == null) return;
    final table = ref.read(selectedTableProvider);
    showDialog<bool>(
      context: context,
      builder: (_) => DataExportDialog(
        result: _result!,
        tableName: table,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats an integer with commas.
  String _formatInt(int value) {
    if (value < 1000) return '$value';
    final str = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}
