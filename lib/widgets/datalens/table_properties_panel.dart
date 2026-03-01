/// Table properties panel — the main content area when a table is selected.
///
/// Provides a top-level tab bar (Properties | Data | Diagram) with the
/// Properties tab showing a [TableHeader], [PropertiesSidebar], and the
/// active sub-tab content (starting with [ColumnsTab]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';
import 'columns_tab.dart';
import 'data_browser_tab.dart';
import 'constraints_tab.dart';
import 'ddl_tab.dart';
import 'dependencies_tab.dart';
import 'foreign_keys_tab.dart';
import 'indexes_tab.dart';
import 'properties_sidebar.dart';
import 'references_tab.dart';
import 'statistics_tab.dart';
import 'table_header.dart';

/// The table detail panel with Properties / Data / Diagram tabs.
///
/// Displayed in the right panel when a table is selected in the navigator.
/// The Properties tab contains a [TableHeader] at top, then a split layout
/// with [PropertiesSidebar] on the left and sub-tab content on the right.
class TablePropertiesPanel extends ConsumerWidget {
  /// Creates a [TablePropertiesPanel].
  const TablePropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTableTabProvider);
    final tablesAsync = ref.watch(datalensTablesProvider);
    final selectedTableName = ref.watch(selectedTableProvider);

    // Find the selected table's metadata.
    final tableInfo = tablesAsync.whenOrNull(
      data: (tables) => tables.cast<TableInfo?>().firstWhere(
            (t) => t?.tableName == selectedTableName,
            orElse: () => null,
          ),
    );

    return Container(
      color: CodeOpsColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top-level tab bar
          _buildTabBar(ref, selectedTab),
          const Divider(height: 1, color: CodeOpsColors.border),
          // Tab content
          Expanded(
            child: switch (selectedTab) {
              0 => _buildPropertiesTab(tableInfo, ref),
              1 => const DataBrowserTab(),
              2 => const EmptyState(
                  icon: Icons.schema_outlined,
                  title: 'ER Diagram',
                  subtitle: 'Coming soon.',
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  /// Builds the Properties | Data | Diagram tab bar.
  Widget _buildTabBar(WidgetRef ref, int selectedTab) {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          _tab(ref, 'Properties', 0, selectedTab),
          _tab(ref, 'Data', 1, selectedTab),
          _tab(ref, 'Diagram', 2, selectedTab),
        ],
      ),
    );
  }

  /// Builds a single tab button.
  Widget _tab(WidgetRef ref, String label, int index, int selectedTab) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () {
        ref.read(selectedTableTabProvider.notifier).state = index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? CodeOpsColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? CodeOpsColors.textPrimary
                : CodeOpsColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Builds the Properties tab content with header, sidebar, and sub-tab.
  Widget _buildPropertiesTab(TableInfo? tableInfo, WidgetRef ref) {
    final selectedSubTab = ref.watch(selectedPropertiesTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table header
        if (tableInfo != null) TableHeader(table: tableInfo),
        // Sidebar + content
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sidebar
              const PropertiesSidebar(),
              const VerticalDivider(width: 1, color: CodeOpsColors.border),
              // Sub-tab content
              Expanded(
                child: _buildSubTabContent(selectedSubTab),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the content for the selected properties sub-tab.
  Widget _buildSubTabContent(int index) {
    return switch (index) {
      0 => const ColumnsTab(),
      1 => const ConstraintsTab(),
      2 => const ForeignKeysTab(),
      3 => const IndexesTab(),
      4 => const DependenciesTab(),
      5 => const ReferencesTab(),
      6 => const StatisticsTab(),
      7 => const DdlTab(),
      _ => const SizedBox.shrink(),
    };
  }
}
