/// Properties sub-tab sidebar for the DataLens Properties panel.
///
/// Provides a vertical list of selectable sub-sections (Columns, Constraints,
/// Foreign Keys, Indexes, Dependencies, References, Statistics, DDL) that
/// switch the main content area via [selectedPropertiesTabProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The sub-section labels in display order.
const propertiesSidebarItems = [
  'Columns',
  'Constraints',
  'Foreign Keys',
  'Indexes',
  'Dependencies',
  'References',
  'Statistics',
  'DDL',
];

/// Vertical sidebar within the Properties tab.
///
/// Lists all property sub-sections. The active section is highlighted
/// and controlled by [selectedPropertiesTabProvider].
class PropertiesSidebar extends ConsumerWidget {
  /// Creates a [PropertiesSidebar].
  const PropertiesSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedPropertiesTabProvider);

    return Container(
      width: 130,
      color: CodeOpsColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: propertiesSidebarItems.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return InkWell(
            onTap: () {
              ref.read(selectedPropertiesTabProvider.notifier).state = index;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isSelected
                  ? CodeOpsColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              child: Text(
                propertiesSidebarItems[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? CodeOpsColors.textPrimary
                      : CodeOpsColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
