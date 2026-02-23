/// Filter controls for the topology viewer.
///
/// Provides dropdowns for service type, health status, and solution
/// filtering, plus a text search field and reset button.
/// Filters control which nodes are visible/highlighted via
/// [topologyFilterProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';

/// Filter bar for the topology viewer.
///
/// Reads the current [TopologyFilter] from [topologyFilterProvider] and
/// provides controls to modify each filter dimension. Filtered-out nodes
/// are dimmed in the topology canvas, not hidden.
class TopologyFilterBar extends ConsumerWidget {
  /// Solution groups available for filtering.
  final List<TopologySolutionGroup> solutionGroups;

  /// Creates a [TopologyFilterBar].
  const TopologyFilterBar({super.key, this.solutionGroups = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(topologyFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Type filter
          const Text(
            'Type:',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          _FilterDropdown<ServiceType?>(
            value: filter.typeFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...ServiceType.values.map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.displayName),
                ),
              ),
            ],
            onChanged: (v) {
              ref.read(topologyFilterProvider.notifier).state =
                  filter.copyWith(typeFilter: () => v);
            },
          ),
          const SizedBox(width: 16),
          // Health filter
          const Text(
            'Health:',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          _FilterDropdown<HealthStatus?>(
            value: filter.healthFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...HealthStatus.values.map(
                (h) => DropdownMenuItem(
                  value: h,
                  child: Text(h.displayName),
                ),
              ),
            ],
            onChanged: (v) {
              ref.read(topologyFilterProvider.notifier).state =
                  filter.copyWith(healthFilter: () => v);
            },
          ),
          const SizedBox(width: 16),
          // Solution filter
          const Text(
            'Solution:',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          _FilterDropdown<String?>(
            value: filter.solutionIdFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...solutionGroups.map(
                (s) => DropdownMenuItem(
                  value: s.solutionId,
                  child: Text(s.name),
                ),
              ),
            ],
            onChanged: (v) {
              ref.read(topologyFilterProvider.notifier).state =
                  filter.copyWith(solutionIdFilter: () => v);
            },
          ),
          const SizedBox(width: 16),
          // Search field
          SizedBox(
            width: 180,
            height: 30,
            child: TextField(
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
                prefixIcon: const Icon(Icons.search, size: 16),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 0),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: CodeOpsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: CodeOpsColors.border),
                ),
              ),
              onChanged: (v) {
                ref.read(topologyFilterProvider.notifier).state =
                    filter.copyWith(searchQuery: v);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Reset button
          IconButton(
            onPressed: () {
              ref.read(topologyFilterProvider.notifier).state =
                  const TopologyFilter();
            },
            icon: const Icon(Icons.refresh, size: 16),
            tooltip: 'Reset filters',
            style: IconButton.styleFrom(
              foregroundColor: CodeOpsColors.textTertiary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(28, 28),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact filter dropdown.
class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
          ),
          icon: const Icon(
            Icons.expand_more,
            size: 14,
            color: CodeOpsColors.textTertiary,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
