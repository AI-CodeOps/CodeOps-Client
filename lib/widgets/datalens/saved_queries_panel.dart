/// Saved queries panel for the DataLens module.
///
/// Displays user-saved SQL queries grouped by folder in expandable sections.
/// Supports search filtering, folder filter dropdown, creating new queries,
/// click-to-load into the SQL editor, and context menu actions (edit, delete,
/// copy SQL).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import 'save_query_dialog.dart';

/// Panel showing user-saved queries organized by folder.
///
/// Features:
/// - Search bar with filtering by query name and SQL content
/// - Folder filter dropdown
/// - Expandable folder sections with query entries
/// - New Query button (opens [SaveQueryDialog])
/// - Click to load SQL into the editor
/// - Context menu: Edit, Delete, Copy SQL
class SavedQueriesPanel extends ConsumerStatefulWidget {
  /// Called when a saved query entry is tapped (load SQL into editor).
  final ValueChanged<String>? onLoadSql;

  /// Creates a [SavedQueriesPanel].
  const SavedQueriesPanel({super.key, this.onLoadSql});

  @override
  ConsumerState<SavedQueriesPanel> createState() => _SavedQueriesPanelState();
}

class _SavedQueriesPanelState extends ConsumerState<SavedQueriesPanel> {
  String _searchQuery = '';
  String? _folderFilter;
  final Set<String> _expandedFolders = {};

  @override
  Widget build(BuildContext context) {
    final queriesAsync = ref.watch(datalensSavedQueriesProvider);

    return Container(
      color: CodeOpsColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar: search + new button
          _buildToolbar(),
          const Divider(height: 1, color: CodeOpsColors.border),

          // Saved queries list
          Expanded(
            child: queriesAsync.when(
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
              data: (queries) {
                final filtered = _filterQueries(queries);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No saved queries',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return _buildFolderGroupedList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar, folder filter, and new query button.
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
                  hintText: 'Search saved queries...',
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
          // New query button
          TextButton.icon(
            icon: const Icon(Icons.add, size: 14),
            label: const Text(
              'New',
              style: TextStyle(fontSize: 11),
            ),
            style: TextButton.styleFrom(
              foregroundColor: CodeOpsColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(50, 28),
            ),
            onPressed: _openSaveDialog,
          ),
        ],
      ),
    );
  }

  /// Builds the folder-grouped list of saved queries.
  Widget _buildFolderGroupedList(List<SavedQuery> queries) {
    // Group queries by folder (null folder → 'Ungrouped').
    final groups = <String, List<SavedQuery>>{};
    for (final query in queries) {
      final folder = query.folder ?? 'Ungrouped';
      groups.putIfAbsent(folder, () => []).add(query);
    }

    // Sort folder names (Ungrouped last).
    final folderNames = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'Ungrouped') return 1;
        if (b == 'Ungrouped') return -1;
        return a.compareTo(b);
      });

    // Apply folder filter.
    final visibleFolders = _folderFilter != null
        ? folderNames.where((f) => f == _folderFilter).toList()
        : folderNames;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // Folder filter dropdown
        if (folderNames.length > 1) _buildFolderFilter(folderNames),
        // Folder sections
        for (final folder in visibleFolders)
          _buildFolderSection(folder, groups[folder]!),
      ],
    );
  }

  /// Builds the folder filter dropdown.
  Widget _buildFolderFilter(List<String> folderNames) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _folderFilter,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: CodeOpsColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: CodeOpsColors.border),
          ),
          filled: true,
          fillColor: CodeOpsColors.surface,
        ),
        dropdownColor: CodeOpsColors.surface,
        style: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textPrimary,
        ),
        hint: const Text(
          'All folders',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
        items: [
          const DropdownMenuItem<String>(
            child: Text(
              'All folders',
              style: TextStyle(fontSize: 12),
            ),
          ),
          for (final folder in folderNames)
            DropdownMenuItem(
              value: folder,
              child: Text(folder, style: const TextStyle(fontSize: 12)),
            ),
        ],
        onChanged: (value) => setState(() => _folderFilter = value),
      ),
    );
  }

  /// Builds an expandable folder section with its queries.
  Widget _buildFolderSection(String folder, List<SavedQuery> queries) {
    final isExpanded = _expandedFolders.contains(folder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Folder header
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedFolders.remove(folder);
            } else {
              _expandedFolders.add(folder);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.folder_open_outlined
                      : Icons.folder_outlined,
                  size: 16,
                  color: CodeOpsColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    folder,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${queries.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: CodeOpsColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        // Query entries
        if (isExpanded)
          for (final query in queries) _buildQueryEntry(query),
      ],
    );
  }

  /// Builds a single saved query entry row.
  Widget _buildQueryEntry(SavedQuery query) {
    return InkWell(
      onTap: () {
        if (query.sql != null) {
          widget.onLoadSql?.call(query.sql!);
        }
      },
      onSecondaryTapUp: (details) =>
          _showContextMenu(details.globalPosition, query),
      child: Padding(
        padding: const EdgeInsets.only(left: 36, right: 12, top: 4, bottom: 4),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 14,
              color: CodeOpsColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    query.name ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (query.description != null &&
                      query.description!.isNotEmpty)
                    Text(
                      query.description!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: CodeOpsColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a context menu for a saved query entry.
  void _showContextMenu(Offset position, SavedQuery query) {
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
          value: 'edit',
          child: Text(
            'Edit',
            style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 13),
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Text(
            'Copy SQL',
            style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 13),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: CodeOpsColors.error, fontSize: 13),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'copy' && query.sql != null) {
        Clipboard.setData(ClipboardData(text: query.sql!));
      } else if (value == 'edit') {
        _openEditDialog(query);
      } else if (value == 'delete') {
        _confirmDelete(query);
      }
    });
  }

  /// Opens the save query dialog to create a new saved query.
  void _openSaveDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => const SaveQueryDialog(),
    ).then((saved) {
      if (saved == true) {
        ref.invalidate(datalensSavedQueriesProvider);
      }
    });
  }

  /// Opens the save query dialog to edit an existing saved query.
  void _openEditDialog(SavedQuery query) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => SaveQueryDialog(existingQuery: query),
    ).then((saved) {
      if (saved == true) {
        ref.invalidate(datalensSavedQueriesProvider);
      }
    });
  }

  /// Shows a confirmation dialog to delete a saved query.
  void _confirmDelete(SavedQuery query) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Delete Query',
          style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Delete "${query.name ?? 'Untitled'}"?',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CodeOpsColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) _deleteQuery(query);
    });
  }

  /// Deletes a saved query.
  Future<void> _deleteQuery(SavedQuery query) async {
    if (query.id == null) return;

    try {
      final service = ref.read(datalensHistoryServiceProvider);
      await service.deleteSavedQuery(query.id!);
      ref.invalidate(datalensSavedQueriesProvider);
    } on Object catch (_) {
      // Best-effort deletion.
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Filters queries by search query (matches name or SQL content).
  List<SavedQuery> _filterQueries(List<SavedQuery> queries) {
    if (_searchQuery.isEmpty) return queries;
    final query = _searchQuery.toLowerCase();
    return queries.where((q) {
      final name = (q.name ?? '').toLowerCase();
      final sql = (q.sql ?? '').toLowerCase();
      return name.contains(query) || sql.contains(query);
    }).toList();
  }
}
