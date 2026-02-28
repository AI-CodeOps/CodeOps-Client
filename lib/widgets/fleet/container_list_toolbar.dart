/// Toolbar for the container list page.
///
/// Provides a status filter dropdown, search text field, and refresh button.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../widgets/shared/search_bar.dart';

/// Possible status filters for the container list.
enum ContainerStatusFilter {
  /// Show all containers regardless of status.
  all,

  /// Show only running containers.
  running,

  /// Show only stopped or exited containers.
  stopped,

  /// Show only containers with unhealthy health status.
  unhealthy;

  /// Human-readable label for the filter.
  String get label => switch (this) {
        ContainerStatusFilter.all => 'All',
        ContainerStatusFilter.running => 'Running',
        ContainerStatusFilter.stopped => 'Stopped',
        ContainerStatusFilter.unhealthy => 'Unhealthy',
      };
}

/// Toolbar with filter dropdown, search, and refresh.
class ContainerListToolbar extends StatelessWidget {
  /// The currently selected status filter.
  final ContainerStatusFilter filter;

  /// Called when the filter selection changes.
  final ValueChanged<ContainerStatusFilter> onFilterChanged;

  /// Called when the search query changes (debounced).
  final ValueChanged<String> onSearchChanged;

  /// Called when the refresh button is tapped.
  final VoidCallback onRefresh;

  /// Creates a [ContainerListToolbar].
  const ContainerListToolbar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Status filter dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ContainerStatusFilter>(
              value: filter,
              dropdownColor: CodeOpsColors.surface,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: CodeOpsColors.textSecondary,
              ),
              items: ContainerStatusFilter.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onFilterChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Search bar
        SizedBox(
          width: 240,
          child: CodeOpsSearchBar(
            hint: 'Search containers...',
            onChanged: onSearchChanged,
          ),
        ),
        const Spacer(),

        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          color: CodeOpsColors.textSecondary,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
