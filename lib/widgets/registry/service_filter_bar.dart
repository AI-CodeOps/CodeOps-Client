/// Search and filter controls for the service list.
///
/// Provides text search, status filter, type filter, and health filter
/// dropdowns. All filter state is stored in Riverpod providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../shared/search_bar.dart';

/// Search and filter controls for the service list.
///
/// Row containing a search field, status/type/health dropdowns, and
/// a clear-all button visible when any filter is active.
class ServiceFilterBar extends ConsumerWidget {
  /// Creates a [ServiceFilterBar].
  const ServiceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(registryServiceStatusFilterProvider);
    final typeFilter = ref.watch(registryServiceTypeFilterProvider);
    final healthFilter = ref.watch(registryServiceHealthFilterProvider);
    final search = ref.watch(registryServiceSearchProvider);

    final hasActiveFilter =
        statusFilter != null ||
        typeFilter != null ||
        healthFilter != null ||
        search.isNotEmpty;

    return Row(
      children: [
        // Search
        SizedBox(
          width: 240,
          child: CodeOpsSearchBar(
            hint: 'Search services...',
            onChanged: (value) {
              ref.read(registryServiceSearchProvider.notifier).state = value;
              ref.read(registryServicePageProvider.notifier).state = 0;
            },
          ),
        ),
        const SizedBox(width: 12),

        // Status filter
        _FilterDropdown<ServiceStatus>(
          label: 'Status',
          value: statusFilter,
          items: ServiceStatus.values,
          displayName: (v) => v.displayName,
          onChanged: (v) {
            ref.read(registryServiceStatusFilterProvider.notifier).state = v;
            ref.read(registryServicePageProvider.notifier).state = 0;
          },
        ),
        const SizedBox(width: 8),

        // Type filter
        _FilterDropdown<ServiceType>(
          label: 'Type',
          value: typeFilter,
          items: ServiceType.values,
          displayName: (v) => v.displayName,
          onChanged: (v) {
            ref.read(registryServiceTypeFilterProvider.notifier).state = v;
            ref.read(registryServicePageProvider.notifier).state = 0;
          },
        ),
        const SizedBox(width: 8),

        // Health filter
        _FilterDropdown<HealthStatus>(
          label: 'Health',
          value: healthFilter,
          items: HealthStatus.values,
          displayName: (v) => v.displayName,
          onChanged: (v) {
            ref.read(registryServiceHealthFilterProvider.notifier).state = v;
            ref.read(registryServicePageProvider.notifier).state = 0;
          },
        ),

        // Clear button
        if (hasActiveFilter) ...[
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(registryServiceSearchProvider.notifier).state = '';
              ref.read(registryServiceStatusFilterProvider.notifier).state =
                  null;
              ref.read(registryServiceTypeFilterProvider.notifier).state = null;
              ref.read(registryServiceHealthFilterProvider.notifier).state =
                  null;
              ref.read(registryServicePageProvider.notifier).state = 0;
            },
            icon:
                const Icon(Icons.clear_all, size: 18, color: CodeOpsColors.textSecondary),
            label: const Text(
              'Clear',
              style: TextStyle(fontSize: 13, color: CodeOpsColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// A generic dropdown filter button with "All" option.
class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayName;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.displayName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: value != null
            ? Border.all(color: CodeOpsColors.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isDense: true,
          hint: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: CodeOpsColors.textTertiary,
            size: 20,
          ),
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textPrimary,
          ),
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text('All $label'),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T?>(
                value: item,
                child: Text(displayName(item)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
