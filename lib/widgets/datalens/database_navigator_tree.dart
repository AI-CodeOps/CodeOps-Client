/// DBeaver-style database navigator tree widget.
///
/// Shows a hierarchical tree: Schemas → Object Type Folders → Objects.
/// Supports expand/collapse, selection, search filtering, and lazy loading
/// via Riverpod providers. Object type folders group database objects by
/// category: Tables, Views, Materialized Views, and Sequences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import 'navigator_search_bar.dart';
import 'navigator_tree_node.dart';

/// The database navigator tree for the DataLens left panel.
///
/// Renders a tree of schemas for the active connection. Each schema
/// expands to show categorized folders (Tables, Views, Materialized Views,
/// Sequences), each of which expands to show the individual database objects.
/// A search bar filters objects by name across all visible levels.
class DatabaseNavigatorTree extends ConsumerStatefulWidget {
  /// Creates a [DatabaseNavigatorTree].
  const DatabaseNavigatorTree({super.key});

  @override
  ConsumerState<DatabaseNavigatorTree> createState() =>
      _DatabaseNavigatorTreeState();
}

class _DatabaseNavigatorTreeState extends ConsumerState<DatabaseNavigatorTree> {
  String _searchQuery = '';
  final Set<String> _expandedFolders = {
    'Tables',
    'Views',
    'Materialized Views',
    'Sequences',
  };

  @override
  Widget build(BuildContext context) {
    final schemasAsync = ref.watch(datalensSchemasProvider);
    final selectedSchema = ref.watch(selectedSchemaProvider);
    final selectedTable = ref.watch(selectedTableProvider);

    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          // Search bar
          NavigatorSearchBar(
            onChanged: (query) => setState(() => _searchQuery = query),
          ),
          // Tree content
          Expanded(
            child: schemasAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: CodeOpsColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $error',
                  style: const TextStyle(
                    color: CodeOpsColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
              data: (schemas) {
                if (schemas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No schemas found',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final filteredSchemas = _filterSchemas(schemas);
                if (filteredSchemas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching objects',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final schema in filteredSchemas)
                      _buildSchemaNode(
                        schema,
                        selectedSchema == schema.name,
                        selectedTable,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header bar with title and refresh button.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 16,
            color: CodeOpsColors.textSecondary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Database Navigator',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 14),
            color: CodeOpsColors.textTertiary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  /// Builds a schema node with its child object folders when expanded.
  Widget _buildSchemaNode(
    SchemaInfo schema,
    bool isExpanded,
    String? selectedTable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigatorTreeNode(
          depth: 0,
          isExpanded: isExpanded,
          isExpandable: true,
          isSelected: isExpanded,
          icon: isExpanded
              ? Icons.folder_open_outlined
              : Icons.folder_outlined,
          iconColor: isExpanded
              ? CodeOpsColors.primary
              : CodeOpsColors.textSecondary,
          label: schema.name ?? '',
          onTap: () => _toggleSchema(schema),
        ),
        if (isExpanded) ..._buildObjectFolders(schema, selectedTable),
      ],
    );
  }

  /// Builds the object type folders (Tables, Views, MVs, Sequences) under
  /// the expanded schema.
  List<Widget> _buildObjectFolders(
    SchemaInfo schema,
    String? selectedTable,
  ) {
    final tablesAsync = ref.watch(datalensTablesProvider);
    final sequencesAsync = ref.watch(datalensSequencesProvider);

    return [
      // Tables folder
      _buildTableTypeFolder(
        folderName: 'Tables',
        icon: Icons.table_chart_outlined,
        badgeCount: schema.tableCount,
        tablesAsync: tablesAsync,
        objectType: ObjectType.table,
        selectedTable: selectedTable,
      ),
      // Views folder
      _buildTableTypeFolder(
        folderName: 'Views',
        icon: Icons.visibility_outlined,
        badgeCount: schema.viewCount,
        tablesAsync: tablesAsync,
        objectType: ObjectType.view,
        selectedTable: selectedTable,
      ),
      // Materialized Views folder
      _buildTableTypeFolder(
        folderName: 'Materialized Views',
        icon: Icons.view_in_ar_outlined,
        badgeCount: null,
        tablesAsync: tablesAsync,
        objectType: ObjectType.materializedView,
        selectedTable: selectedTable,
      ),
      // Sequences folder
      _buildSequencesFolder(sequencesAsync, schema.sequenceCount),
    ];
  }

  /// Builds a folder node for a specific [ObjectType] (Tables, Views, MVs).
  ///
  /// When expanded, shows filtered objects matching the [objectType] from
  /// the tables provider.
  Widget _buildTableTypeFolder({
    required String folderName,
    required IconData icon,
    required int? badgeCount,
    required AsyncValue<List<TableInfo>> tablesAsync,
    required ObjectType objectType,
    required String? selectedTable,
  }) {
    final isExpanded = _expandedFolders.contains(folderName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigatorTreeNode(
          depth: 1,
          isExpanded: isExpanded,
          isExpandable: true,
          icon: icon,
          iconColor: CodeOpsColors.textSecondary,
          label: folderName,
          badgeCount: badgeCount,
          onTap: () => _toggleFolder(folderName),
        ),
        if (isExpanded)
          tablesAsync.when(
            loading: () => _buildLoadingIndicator(),
            error: (error, _) => _buildErrorText('$error'),
            data: (tables) {
              final filtered = tables
                  .where((t) => t.objectType == objectType)
                  .where((t) => _matchesSearch(t.tableName))
                  .toList();

              if (filtered.isEmpty) {
                return _buildEmptyText('No ${folderName.toLowerCase()}');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final table in filtered)
                    NavigatorTreeNode(
                      depth: 2,
                      isSelected: selectedTable == table.tableName,
                      icon: _iconForObjectType(objectType),
                      iconColor: selectedTable == table.tableName
                          ? CodeOpsColors.primary
                          : null,
                      label: table.tableName ?? '',
                      trailingText: table.rowEstimate != null
                          ? '~${_formatCount(table.rowEstimate!)}'
                          : null,
                      onTap: () => _selectTable(table.tableName),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// Builds the Sequences folder node.
  ///
  /// When expanded, shows sequences from the sequences provider.
  Widget _buildSequencesFolder(
    AsyncValue<List<SequenceInfo>> sequencesAsync,
    int? badgeCount,
  ) {
    const folderName = 'Sequences';
    final isExpanded = _expandedFolders.contains(folderName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigatorTreeNode(
          depth: 1,
          isExpanded: isExpanded,
          isExpandable: true,
          icon: Icons.format_list_numbered_outlined,
          iconColor: CodeOpsColors.textSecondary,
          label: folderName,
          badgeCount: badgeCount,
          onTap: () => _toggleFolder(folderName),
        ),
        if (isExpanded)
          sequencesAsync.when(
            loading: () => _buildLoadingIndicator(),
            error: (error, _) => _buildErrorText('$error'),
            data: (sequences) {
              final filtered = sequences
                  .where((s) => _matchesSearch(s.sequenceName))
                  .toList();

              if (filtered.isEmpty) {
                return _buildEmptyText('No sequences');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final seq in filtered)
                    NavigatorTreeNode(
                      depth: 2,
                      icon: Icons.format_list_numbered_outlined,
                      label: seq.sequenceName ?? '',
                      trailingText: seq.dataType,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggles a schema node expand/collapse and updates selection.
  void _toggleSchema(SchemaInfo schema) {
    final current = ref.read(selectedSchemaProvider);
    if (current == schema.name) {
      // Collapse: clear schema selection.
      ref.read(selectedSchemaProvider.notifier).state = null;
      ref.read(selectedTableProvider.notifier).state = null;
    } else {
      // Expand: select this schema.
      ref.read(selectedSchemaProvider.notifier).state = schema.name;
      ref.read(selectedTableProvider.notifier).state = null;
    }
  }

  /// Toggles a folder's expanded state.
  void _toggleFolder(String folderName) {
    setState(() {
      if (_expandedFolders.contains(folderName)) {
        _expandedFolders.remove(folderName);
      } else {
        _expandedFolders.add(folderName);
      }
    });
  }

  /// Selects a table/view/MV and resets the table tab.
  void _selectTable(String? tableName) {
    ref.read(selectedTableProvider.notifier).state = tableName;
    ref.read(selectedTableTabProvider.notifier).state = 0;
  }

  /// Refreshes schemas and tables data.
  void _onRefresh() {
    ref.invalidate(datalensSchemasProvider);
    ref.invalidate(datalensTablesProvider);
    ref.invalidate(datalensSequencesProvider);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Filters schemas by search query (matches schema name or is currently
  /// expanded with matching objects).
  List<SchemaInfo> _filterSchemas(List<SchemaInfo> schemas) {
    if (_searchQuery.isEmpty) return schemas;
    final query = _searchQuery.toLowerCase();
    return schemas
        .where((s) => (s.name ?? '').toLowerCase().contains(query))
        .toList();
  }

  /// Returns whether a name matches the current search query.
  bool _matchesSearch(String? name) {
    if (_searchQuery.isEmpty) return true;
    return (name ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
  }

  /// Returns the appropriate icon for a given [ObjectType].
  IconData _iconForObjectType(ObjectType type) {
    return switch (type) {
      ObjectType.table => Icons.table_chart_outlined,
      ObjectType.view => Icons.visibility_outlined,
      ObjectType.materializedView => Icons.view_in_ar_outlined,
      ObjectType.sequence => Icons.format_list_numbered_outlined,
      ObjectType.enumType => Icons.list_outlined,
      ObjectType.function => Icons.functions_outlined,
    };
  }

  /// Formats a large count with k/M suffixes.
  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  /// Builds a compact loading indicator for folder content.
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: CodeOpsColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// Builds an error text for folder content.
  Widget _buildErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, top: 4, bottom: 4),
      child: Text(
        'Error: $message',
        style: const TextStyle(color: CodeOpsColors.error, fontSize: 11),
      ),
    );
  }

  /// Builds an empty text label for an empty folder.
  Widget _buildEmptyText(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, top: 4, bottom: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: CodeOpsColors.textTertiary,
          fontSize: 11,
        ),
      ),
    );
  }
}
