/// DBeaver-style data grid for displaying SQL query results.
///
/// Renders a scrollable 2D table with sortable column headers, type-appropriate
/// cell formatting, zebra striping, row selection, and both horizontal and
/// vertical scrolling.
library;

import 'package:flutter/material.dart';

import '../../models/datalens_models.dart';
import '../../theme/colors.dart';

/// A scrollable data grid for displaying [QueryResult] data.
///
/// Features:
/// - Column headers with click-to-sort
/// - Type-appropriate cell formatting (null, bool, datetime, uuid, json)
/// - Alternating row colors (zebra striping)
/// - Row selection with highlight
/// - Horizontal + vertical scrolling
class DataGrid extends StatefulWidget {
  /// The query result to display.
  final QueryResult result;

  /// Currently sorted column name, or `null` for unsorted.
  final String? sortColumn;

  /// Whether the sort is ascending.
  final bool sortAscending;

  /// Called when a column header is tapped for sorting.
  final ValueChanged<String>? onSort;

  /// Creates a [DataGrid].
  const DataGrid({
    super.key,
    required this.result,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  int? _selectedRow;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.result.columns ?? [];
    final rows = widget.result.rows ?? [];

    if (columns.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _calculateTotalWidth(columns),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderRow(columns),
              const Divider(height: 1, color: CodeOpsColors.border),
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _verticalController,
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        _buildDataRow(columns, rows[index], index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculates total width for all columns.
  double _calculateTotalWidth(List<QueryColumn> columns) {
    // 40px row number + 150px per column minimum.
    final computed = 40.0 + columns.length * 150.0;
    return computed < 800 ? 800 : computed;
  }

  /// Builds the column header row.
  Widget _buildHeaderRow(List<QueryColumn> columns) {
    return Container(
      color: CodeOpsColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Row number header
          const SizedBox(
            width: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ),
          ),
          ...columns.map((col) => _buildHeaderCell(col)),
        ],
      ),
    );
  }

  /// Builds a single column header cell.
  Widget _buildHeaderCell(QueryColumn column) {
    final name = column.name ?? '';
    final isSorted = widget.sortColumn == name;

    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: widget.onSort != null ? () => widget.onSort!(name) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
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
                  widget.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 10,
                  color: CodeOpsColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a data row with zebra striping.
  Widget _buildDataRow(
    List<QueryColumn> columns,
    List<dynamic> row,
    int index,
  ) {
    final isSelected = _selectedRow == index;
    final isEven = index % 2 == 0;

    Color bgColor;
    if (isSelected) {
      bgColor = CodeOpsColors.primary.withValues(alpha: 0.15);
    } else if (isEven) {
      bgColor = Colors.transparent;
    } else {
      bgColor = CodeOpsColors.surfaceVariant.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedRow = index),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Row number
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ),
            ...List.generate(columns.length, (colIdx) {
              final value = colIdx < row.length ? row[colIdx] : null;
              final typeName = columns[colIdx].typeName ?? '';
              return SizedBox(
                width: 150,
                child: _buildCell(value, typeName),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds a single cell with type-appropriate formatting.
  Widget _buildCell(dynamic value, String typeName) {
    if (value == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '(null)',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      );
    }

    if (value is bool) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 12,
            color: value ? CodeOpsColors.success : CodeOpsColors.error,
          ),
        ),
      );
    }

    if (value is DateTime) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          _formatDateTime(value),
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (value is num) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    final str = value.toString();

    // UUID detection.
    if (_isUuid(str)) {
      return Tooltip(
        message: str,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            str.substring(0, 8),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ),
      );
    }

    // JSON detection.
    if (_isJson(str)) {
      final preview = str.length > 20 ? '${str.substring(0, 20)}...' : str;
      return Tooltip(
        message: str,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            preview,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: CodeOpsColors.secondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Default string.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        str.length > 200 ? '${str.substring(0, 200)}...' : str,
        style: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Formats a DateTime value.
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  /// Pads a number with a leading zero.
  String _pad(int n) => n.toString().padLeft(2, '0');

  /// Returns `true` if the string looks like a UUID.
  bool _isUuid(String s) {
    return s.length == 36 &&
        s[8] == '-' &&
        s[13] == '-' &&
        s[18] == '-' &&
        s[23] == '-';
  }

  /// Returns `true` if the string looks like JSON.
  bool _isJson(String s) {
    final trimmed = s.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}
