/// Dropdown panel for log query execution history.
///
/// Shows recent query executions with their timestamp, result count,
/// and execution time. Click to re-execute a historical query.
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// A dropdown button showing query execution history.
///
/// Clicking a history entry invokes [onReExecute] with the
/// query details so it can be re-run.
class QueryHistoryDropdown extends StatelessWidget {
  /// The list of history entries to display.
  final List<QueryHistoryResponse> history;

  /// Called when a history entry is selected for re-execution.
  final ValueChanged<QueryHistoryResponse> onReExecute;

  /// Creates a [QueryHistoryDropdown].
  const QueryHistoryDropdown({
    super.key,
    required this.history,
    required this.onReExecute,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<QueryHistoryResponse>(
      tooltip: 'Query History',
      color: CodeOpsColors.surface,
      enabled: history.isNotEmpty,
      onSelected: onReExecute,
      offset: const Offset(0, 36),
      constraints: const BoxConstraints(maxWidth: 450, maxHeight: 320),
      itemBuilder: (_) => [
        // Header item.
        const PopupMenuItem(
          enabled: false,
          height: 28,
          child: Text(
            'Query History',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        // History items.
        ...history.map((h) => PopupMenuItem(
              value: h,
              height: 44,
              child: Row(
                children: [
                  const Icon(
                    Icons.history,
                    size: 14,
                    color: CodeOpsColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          h.queryDsl ?? _summarizeQuery(h.queryJson),
                          style: const TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            if (h.createdAt != null)
                              Text(
                                _formatTime(h.createdAt!),
                                style: const TextStyle(
                                  color: CodeOpsColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              '${h.resultCount} results',
                              style: const TextStyle(
                                color: CodeOpsColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${h.executionTimeMs}ms',
                              style: const TextStyle(
                                color: CodeOpsColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: CodeOpsColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'History (${history.length})',
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// Summarizes a JSON query string for display.
  String _summarizeQuery(String queryJson) {
    if (queryJson.length <= 60) return queryJson;
    return '${queryJson.substring(0, 57)}...';
  }

  /// Formats a [DateTime] for compact display.
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $h:$m';
  }
}
