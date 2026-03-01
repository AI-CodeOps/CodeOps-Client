/// DataLens shell page — the main database browser layout.
///
/// Provides a DBeaver-style interface with a resizable split view:
/// left panel for the database object navigator (schemas, tables),
/// right panel for the content area (table detail, SQL editor, data browser).
/// A [DatalensToolbar] sits above the content and a [DatalensStatusBar]
/// sits at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_view/split_view.dart';

import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';
import 'datalens_status_bar.dart';
import 'datalens_toolbar.dart';

/// The main DataLens page with toolbar, split-view content, and status bar.
class DatalensPage extends ConsumerStatefulWidget {
  /// Creates a [DatalensPage].
  const DatalensPage({super.key});

  @override
  ConsumerState<DatalensPage> createState() => _DatalensPageState();
}

class _DatalensPageState extends ConsumerState<DatalensPage> {
  @override
  Widget build(BuildContext context) {
    final selectedConnectionId = ref.watch(selectedConnectionIdProvider);

    return Column(
      children: [
        // Toolbar
        const DatalensToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Main content
        Expanded(
          child: selectedConnectionId == null
              ? const EmptyState(
                  icon: Icons.storage_outlined,
                  title: 'No connection selected',
                  subtitle:
                      'Select or create a connection to start browsing your database.',
                  actionLabel: 'Connection Manager',
                )
              : SplitView(
                  viewMode: SplitViewMode.Horizontal,
                  gripColor: CodeOpsColors.border,
                  gripSize: 4,
                  controller: SplitViewController(weights: [0.25, 0.75]),
                  children: [
                    // Left panel — Navigator
                    _NavigatorPanel(connectionId: selectedConnectionId),
                    // Right panel — Content area
                    const _ContentPanel(),
                  ],
                ),
        ),

        // Status bar
        const Divider(height: 1, color: CodeOpsColors.border),
        const DatalensStatusBar(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Navigator Panel (left side)
// ---------------------------------------------------------------------------

class _NavigatorPanel extends ConsumerWidget {
  final String connectionId;

  const _NavigatorPanel({required this.connectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemasAsync = ref.watch(datalensSchemasProvider);
    final selectedSchema = ref.watch(selectedSchemaProvider);
    final selectedTable = ref.watch(selectedTableProvider);

    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Schema selector header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.border),
              ),
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
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    ref.invalidate(datalensSchemasProvider);
                    ref.invalidate(datalensTablesProvider);
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Schema list + table tree
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

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final schema in schemas)
                      _SchemaNode(
                        schema: schema.name ?? '',
                        isSelected: selectedSchema == schema.name,
                        selectedTable: selectedTable,
                        onSelectSchema: () {
                          ref
                              .read(selectedSchemaProvider.notifier)
                              .state = schema.name;
                          ref.read(selectedTableProvider.notifier).state =
                              null;
                        },
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
}

// ---------------------------------------------------------------------------
// Schema Node (expandable)
// ---------------------------------------------------------------------------

class _SchemaNode extends ConsumerWidget {
  final String schema;
  final bool isSelected;
  final String? selectedTable;
  final VoidCallback onSelectSchema;

  const _SchemaNode({
    required this.schema,
    required this.isSelected,
    required this.selectedTable,
    required this.onSelectSchema,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Schema header
        InkWell(
          onTap: onSelectSchema,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isSelected
                ? CodeOpsColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.folder_open_outlined
                      : Icons.folder_outlined,
                  size: 16,
                  color: isSelected
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schema,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isSelected
                          ? CodeOpsColors.textPrimary
                          : CodeOpsColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tables list when schema is selected
        if (isSelected) _TableList(selectedTable: selectedTable),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Table List (under a schema)
// ---------------------------------------------------------------------------

class _TableList extends ConsumerWidget {
  final String? selectedTable;

  const _TableList({required this.selectedTable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(datalensTablesProvider);

    return tablesAsync.when(
      loading: () => const Padding(
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
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 11),
        ),
      ),
      data: (tables) {
        if (tables.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 36, top: 4, bottom: 4),
            child: Text(
              'No tables found',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final table in tables)
              InkWell(
                onTap: () {
                  ref.read(selectedTableProvider.notifier).state =
                      table.tableName;
                  ref.read(selectedTableTabProvider.notifier).state = 0;
                },
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 36,
                    right: 12,
                    top: 4,
                    bottom: 4,
                  ),
                  color: selectedTable == table.tableName
                      ? CodeOpsColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 14,
                        color: selectedTable == table.tableName
                            ? CodeOpsColors.primary
                            : CodeOpsColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          table.tableName ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedTable == table.tableName
                                ? CodeOpsColors.textPrimary
                                : CodeOpsColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Content Panel (right side)
// ---------------------------------------------------------------------------

class _ContentPanel extends ConsumerWidget {
  const _ContentPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTable = ref.watch(selectedTableProvider);
    final selectedSchema = ref.watch(selectedSchemaProvider);

    if (selectedSchema == null) {
      return const EmptyState(
        icon: Icons.account_tree_outlined,
        title: 'Select a schema',
        subtitle: 'Choose a schema from the navigator to view its tables.',
      );
    }

    if (selectedTable == null) {
      return const EmptyState(
        icon: Icons.table_chart_outlined,
        title: 'Select a table',
        subtitle: 'Choose a table from the navigator to view its details.',
      );
    }

    // Placeholder content — table detail tabs will be added in a later task.
    return Container(
      color: CodeOpsColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.table_chart_outlined,
              size: 48,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              '$selectedSchema.$selectedTable',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Table detail view coming soon.',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
