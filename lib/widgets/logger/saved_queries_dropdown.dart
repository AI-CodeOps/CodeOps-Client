/// Dropdown panel for managing saved log queries.
///
/// Shows a list of saved queries for the team. Click to load a query
/// into the query builder. Supports rename and delete operations.
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// A dropdown button that shows saved queries in a popup overlay.
///
/// Clicking a query invokes [onLoad] with the selected query.
/// The delete icon invokes [onDelete] for removal.
class SavedQueriesDropdown extends StatelessWidget {
  /// The list of saved queries to display.
  final List<SavedQueryResponse> queries;

  /// Called when a saved query is selected for loading.
  final ValueChanged<SavedQueryResponse> onLoad;

  /// Called when a query should be deleted.
  final ValueChanged<SavedQueryResponse> onDelete;

  /// Creates a [SavedQueriesDropdown].
  const SavedQueriesDropdown({
    super.key,
    required this.queries,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SavedQueryResponse>(
      tooltip: 'Saved Queries',
      color: CodeOpsColors.surface,
      enabled: queries.isNotEmpty,
      onSelected: onLoad,
      offset: const Offset(0, 36),
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 320),
      itemBuilder: (_) => [
        // Header item.
        const PopupMenuItem(
          enabled: false,
          height: 28,
          child: Text(
            'Saved Queries',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Query items.
        ...queries.map((q) => PopupMenuItem(
              value: q,
              height: 44,
              child: Row(
                children: [
                  const Icon(
                    Icons.bookmark,
                    size: 14,
                    color: CodeOpsColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          q.name,
                          style: const TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (q.description != null &&
                            q.description!.isNotEmpty)
                          Text(
                            q.description!,
                            style: const TextStyle(
                              color: CodeOpsColors.textTertiary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${q.executionCount}x',
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete(q);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: CodeOpsColors.textTertiary,
                      ),
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
              Icons.bookmark_outline,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'Saved Queries (${queries.length})',
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
}
