/// Query history panel for the DataLens module.
///
/// Displays past SQL query executions in a searchable, scrollable list.
/// Each entry shows status icon, truncated SQL, execution time, row count,
/// and timestamp. Supports click-to-load into the SQL editor, context menu
/// actions, and clearing all history.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// Panel showing past query executions for the active connection.
///
/// Features:
/// - Search bar with debounced filtering by SQL content
/// - History list with status icon, SQL preview, timing, row count
/// - Click to load SQL into the editor
/// - Clear all history with confirmation dialog
class QueryHistoryPanel extends ConsumerStatefulWidget {
  /// Called when a history entry is tapped (load SQL into editor).
  final ValueChanged<String>? onLoadSql;

  /// Creates a [QueryHistoryPanel].
  const QueryHistoryPanel({super.key, this.onLoadSql});

  @override
  ConsumerState<QueryHistoryPanel> createState() => _QueryHistoryPanelState();
}

class _QueryHistoryPanelState extends ConsumerState<QueryHistoryPanel> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(datalensQueryHistoryProvider);

    return Container(
      color: CodeOpsColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar + clear button
          _buildToolbar(),
          const Divider(height: 1, color: CodeOpsColors.border),

          // History list
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: CodeOpsColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(
                    color: CodeOpsColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
              data: (entries) {
                final filtered = _filterEntries(entries);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No query history',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: CodeOpsColors.border,
                  ),
                  itemBuilder: (context, index) =>
                      _buildHistoryEntry(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar and clear history button.
  Widget _buildToolbar() {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: SizedBox(
              height: 28,
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search queries...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: CodeOpsColors.textTertiary,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 28,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.primary),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                  filled: true,
                  fillColor: CodeOpsColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear history button
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text(
              'Clear',
              style: TextStyle(fontSize: 11),
            ),
            style: TextButton.styleFrom(
              foregroundColor: CodeOpsColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(60, 28),
            ),
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
    );
  }

  /// Builds a single history entry row.
  Widget _buildHistoryEntry(QueryHistoryEntry entry) {
    return InkWell(
      onTap: () {
        if (entry.sql != null) {
          widget.onLoadSql?.call(entry.sql!);
        }
      },
      onSecondaryTapUp: (details) =>
          _showContextMenu(details.globalPosition, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: status + SQL + timing
            Row(
              children: [
                _statusIcon(entry.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _truncateSql(entry.sql ?? ''),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (entry.executionTimeMs != null)
                  Text(
                    '${entry.executionTimeMs}ms',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _rowLabel(entry),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
            // Second row: timestamp
            if (entry.executedAt != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  _formatTimestamp(entry.executedAt!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Shows a context menu for a history entry.
  void _showContextMenu(Offset position, QueryHistoryEntry entry) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: CodeOpsColors.surface,
      items: const [
        PopupMenuItem(
          value: 'copy',
          child: Text(
            'Copy SQL',
            style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 13),
          ),
        ),
        PopupMenuItem(
          value: 'save',
          child: Text(
            'Save as Query',
            style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'copy' && entry.sql != null) {
        Clipboard.setData(ClipboardData(text: entry.sql!));
      }
    });
  }

  /// Shows a confirmation dialog to clear all history.
  void _confirmClearHistory() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Clear History',
          style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: const Text(
          'Delete all query history for this connection?',
          style: TextStyle(color: CodeOpsColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CodeOpsColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) _clearHistory();
    });
  }

  /// Clears all history for the active connection.
  Future<void> _clearHistory() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    try {
      final service = ref.read(datalensHistoryServiceProvider);
      await service.clearHistory(connectionId);
      ref.invalidate(datalensQueryHistoryProvider);
    } on Object catch (_) {
      // Best-effort cleanup.
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Filters entries by search query.
  List<QueryHistoryEntry> _filterEntries(List<QueryHistoryEntry> entries) {
    if (_searchQuery.isEmpty) return entries;
    final query = _searchQuery.toLowerCase();
    return entries
        .where((e) => (e.sql ?? '').toLowerCase().contains(query))
        .toList();
  }

  /// Truncates SQL for single-line display.
  String _truncateSql(String sql) {
    final oneLine = sql.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length > 80 ? '${oneLine.substring(0, 80)}...' : oneLine;
  }

  /// Returns a row count label for a history entry.
  String _rowLabel(QueryHistoryEntry entry) {
    if (entry.status == QueryStatus.failed) return 'Error';
    if (entry.status == QueryStatus.cancelled) return 'Cancelled';
    final count = entry.rowCount ?? 0;
    return '$count row${count == 1 ? '' : 's'}';
  }

  /// Returns a status icon widget.
  Widget _statusIcon(QueryStatus? status) {
    final (IconData icon, Color color) = switch (status) {
      QueryStatus.completed => (Icons.check_circle, CodeOpsColors.success),
      QueryStatus.failed => (Icons.cancel, CodeOpsColors.error),
      QueryStatus.cancelled => (Icons.stop_circle, CodeOpsColors.warning),
      QueryStatus.running => (Icons.hourglass_empty, CodeOpsColors.primary),
      null => (Icons.circle_outlined, CodeOpsColors.textTertiary),
    };

    return Icon(icon, size: 14, color: color);
  }

  /// Formats a timestamp for display.
  String _formatTimestamp(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, ${dt.year} $hour:$minute $amPm';
  }
}
