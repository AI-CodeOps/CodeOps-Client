/// Sortable, paginated results table for log search.
///
/// Displays search results in a tabular layout with columns for
/// Timestamp, Level, Source, Logger, Message, and Correlation ID.
/// Supports click-to-expand detail rows (reusing [LogEntryDetail]),
/// server-side pagination, column sorting, and CSV/JSON export.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';
import 'log_entry_detail.dart';
import 'log_level_badge.dart';

/// A sortable, paginated table of log search results.
///
/// Reuses [LogEntryDetail] for expandable row details and
/// [LogLevelBadge] for level indicators.
class SearchResultsTable extends StatefulWidget {
  /// The paginated log entries to display.
  final PageResponse<LogEntryResponse> results;

  /// Currently sorted column name, or `null` for unsorted.
  final String? sortColumn;

  /// Whether the sort is ascending.
  final bool sortAscending;

  /// Called when a column header is tapped.
  final ValueChanged<String>? onSort;

  /// Called when the next page is requested.
  final VoidCallback? onNextPage;

  /// Called when the previous page is requested.
  final VoidCallback? onPreviousPage;

  /// Creates a [SearchResultsTable].
  const SearchResultsTable({
    super.key,
    required this.results,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.onNextPage,
    this.onPreviousPage,
  });

  @override
  State<SearchResultsTable> createState() => _SearchResultsTableState();
}

class _SearchResultsTableState extends State<SearchResultsTable> {
  String? _expandedEntryId;

  @override
  Widget build(BuildContext context) {
    final entries = widget.results.content;

    return Column(
      children: [
        // Results header with count and export.
        _buildResultsHeader(entries.length),

        // Column headers.
        _buildColumnHeaders(),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Results rows.
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isExpanded = _expandedEntryId == entry.id;

                    return Column(
                      children: [
                        _buildResultRow(entry, index, isExpanded),
                        if (isExpanded) LogEntryDetail(entry: entry),
                      ],
                    );
                  },
                ),
        ),

        // Pagination footer.
        _buildPaginationFooter(),
      ],
    );
  }

  /// Builds the results header with match count and export buttons.
  Widget _buildResultsHeader(int visibleCount) {
    final total = widget.results.totalElements;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Results ($total matches)',
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),

          // CSV export.
          _ExportButton(
            label: 'CSV',
            icon: Icons.table_chart_outlined,
            onTap: () => _exportCsv(widget.results.content),
          ),
          const SizedBox(width: 4),

          // JSON export.
          _ExportButton(
            label: 'JSON',
            icon: Icons.data_object,
            onTap: () => _exportJson(widget.results.content),
          ),
        ],
      ),
    );
  }

  /// Builds the sortable column header row.
  Widget _buildColumnHeaders() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: CodeOpsColors.surfaceVariant,
      child: Row(
        children: [
          _ColumnHeader(
            label: 'Timestamp',
            width: 160,
            columnKey: 'timestamp',
            sortColumn: widget.sortColumn,
            sortAscending: widget.sortAscending,
            onSort: widget.onSort,
          ),
          _ColumnHeader(
            label: 'Level',
            width: 70,
            columnKey: 'level',
            sortColumn: widget.sortColumn,
            sortAscending: widget.sortAscending,
            onSort: widget.onSort,
          ),
          _ColumnHeader(
            label: 'Source',
            width: 120,
            columnKey: 'sourceName',
            sortColumn: widget.sortColumn,
            sortAscending: widget.sortAscending,
            onSort: widget.onSort,
          ),
          _ColumnHeader(
            label: 'Logger',
            width: 140,
            columnKey: 'loggerName',
            sortColumn: widget.sortColumn,
            sortAscending: widget.sortAscending,
            onSort: widget.onSort,
          ),
          const Expanded(
            child: Text(
              'Message',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ColumnHeader(
            label: 'Correlation',
            width: 100,
            columnKey: 'correlationId',
            sortColumn: widget.sortColumn,
            sortAscending: widget.sortAscending,
            onSort: widget.onSort,
          ),
        ],
      ),
    );
  }

  /// Builds a single result row.
  Widget _buildResultRow(
    LogEntryResponse entry,
    int index,
    bool isExpanded,
  ) {
    return Material(
      color: isExpanded
          ? CodeOpsColors.surfaceVariant
          : index.isEven
              ? CodeOpsColors.background
              : CodeOpsColors.surface.withValues(alpha: 0.5),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedEntryId = isExpanded ? null : entry.id;
          });
        },
        hoverColor: CodeOpsColors.surfaceVariant.withValues(alpha: 0.5),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Timestamp.
              SizedBox(
                width: 160,
                child: Text(
                  _formatTimestamp(entry.timestamp),
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              // Level badge.
              SizedBox(
                width: 70,
                child: LogLevelBadge(level: entry.level),
              ),

              // Source.
              SizedBox(
                width: 120,
                child: Text(
                  entry.sourceName,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Logger.
              SizedBox(
                width: 140,
                child: Text(
                  entry.loggerName ?? '',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Message (truncated).
              Expanded(
                child: Text(
                  entry.message,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Correlation ID.
              SizedBox(
                width: 100,
                child: Text(
                  entry.correlationId != null
                      ? entry.correlationId!.length > 8
                          ? '${entry.correlationId!.substring(0, 8)}...'
                          : entry.correlationId!
                      : '',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the pagination footer.
  Widget _buildPaginationFooter() {
    final r = widget.results;
    final start = r.page * r.size + 1;
    final end = start + r.content.length - 1;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          Text(
            r.content.isEmpty
                ? '0 results'
                : 'Showing $start–$end of ${r.totalElements}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          if (r.page > 0)
            TextButton(
              onPressed: widget.onPreviousPage,
              style: TextButton.styleFrom(
                foregroundColor: CodeOpsColors.primary,
                textStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 24),
              ),
              child: const Text('Previous'),
            ),
          if (r.page > 0 && !r.isLast) const SizedBox(width: 4),
          if (!r.isLast)
            TextButton(
              onPressed: widget.onNextPage,
              style: TextButton.styleFrom(
                foregroundColor: CodeOpsColors.primary,
                textStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 24),
              ),
              child: const Text('Next'),
            ),
          const SizedBox(width: 8),
          Text(
            'Page ${r.page + 1} of ${r.totalPages == 0 ? 1 : r.totalPages}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a [DateTime] for table display.
  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m:$s.$ms';
  }

  /// Copies CSV-formatted results to the clipboard.
  void _exportCsv(List<LogEntryResponse> entries) {
    final buffer = StringBuffer()
      ..writeln('Timestamp,Level,Source,Logger,Message,CorrelationId');
    for (final e in entries) {
      final msg = e.message.replaceAll('"', '""');
      buffer.writeln(
        '"${e.timestamp.toIso8601String()}","${e.level.toJson()}",'
        '"${e.sourceName}","${e.loggerName ?? ""}","$msg",'
        '"${e.correlationId ?? ""}"',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Copies JSON-formatted results to the clipboard.
  void _exportJson(List<LogEntryResponse> entries) {
    final json = const JsonEncoder.withIndent('  ')
        .convert(entries.map((e) => e.toJson()).toList());
    Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// A clickable, sortable column header cell.
class _ColumnHeader extends StatelessWidget {
  final String label;
  final double width;
  final String columnKey;
  final String? sortColumn;
  final bool sortAscending;
  final ValueChanged<String>? onSort;

  const _ColumnHeader({
    required this.label,
    required this.width,
    required this.columnKey,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortColumn == columnKey;

    return InkWell(
      onTap: onSort != null ? () => onSort!(columnKey) : null,
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 12,
                color: CodeOpsColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small export button for the results header.
class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: CodeOpsColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
