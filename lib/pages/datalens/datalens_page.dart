/// DataLens shell page — the main database browser layout.
///
/// Provides a DBeaver-style interface with a resizable split view:
/// left panel for the [DatabaseNavigatorTree] (schemas, tables, views),
/// right panel for the content area (table detail, SQL editor, data browser).
/// A [DatalensToolbar] sits above the content and a [DatalensStatusBar]
/// sits at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_view/split_view.dart';

import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/datalens/database_navigator_tree.dart';
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
                    // Left panel — Navigator tree
                    const DatabaseNavigatorTree(),
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
