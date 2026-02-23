/// Infrastructure resources management page.
///
/// Displays a filterable, sortable table of infrastructure resources with
/// orphan detection banner, search, type/env/service filter controls,
/// pagination, and create/edit dialogs.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/team_providers.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/infra_resource_form_dialog.dart';
import '../../widgets/registry/infra_resource_table.dart';
import '../../widgets/registry/orphan_resource_banner.dart';
import '../../widgets/shared/search_bar.dart';

/// The infrastructure resources page at `/registry/infra`.
class InfraResourcesPage extends ConsumerWidget {
  /// Creates an [InfraResourcesPage].
  const InfraResourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(registryInfraResourcesProvider);
    final orphansAsync = ref.watch(registryOrphanedResourcesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Infrastructure Resources',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage cloud and infrastructure resources across services.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Resource'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref.invalidate(registryInfraResourcesProvider);
                  ref.invalidate(registryOrphanedResourcesProvider);
                },
                icon: const Icon(Icons.refresh, size: 20),
                color: CodeOpsColors.textSecondary,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Orphan banner
          orphansAsync.when(
            data: (orphans) => OrphanResourceBanner(
              orphans: orphans,
              onReassign: (r) => _showReassignDialog(context, ref, r),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Spacer after banner (only if orphans present)
          orphansAsync.when(
            data: (orphans) =>
                orphans.isNotEmpty ? const SizedBox(height: 16) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Filter bar
          const _InfraFilterBar(),
          const SizedBox(height: 16),

          // Table or states
          resourcesAsync.when(
            data: (page) {
              if (page.content.isEmpty) {
                final hasFilters =
                    ref.read(registryInfraTypeFilterProvider) != null ||
                    ref.read(registryInfraEnvironmentFilterProvider).isNotEmpty ||
                    ref.read(registryInfraSearchProvider).isNotEmpty ||
                    ref.read(registryInfraServiceFilterProvider) != null;
                if (!hasFilters) return const _EmptyState();
              }

              // Client-side filtering for search and service
              final search =
                  ref.watch(registryInfraSearchProvider).toLowerCase();
              final serviceFilter =
                  ref.watch(registryInfraServiceFilterProvider);
              var filtered = page.content.where((r) {
                if (search.isNotEmpty &&
                    !r.resourceName.toLowerCase().contains(search)) {
                  return false;
                }
                if (serviceFilter != null && r.serviceId != serviceFilter) {
                  return false;
                }
                return true;
              }).toList();

              // Sorting
              final sortField =
                  ref.watch(_infraSortFieldProvider);
              final sortAsc =
                  ref.watch(_infraSortAscProvider);
              filtered = _sortResources(filtered, sortField, sortAsc);

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: InfraResourceTable(
                      resources: filtered,
                      sortField: sortField,
                      sortAscending: sortAsc,
                      onSort: (field) {
                        if (ref.read(_infraSortFieldProvider) == field) {
                          ref.read(_infraSortAscProvider.notifier).state =
                              !sortAsc;
                        } else {
                          ref.read(_infraSortFieldProvider.notifier).state =
                              field;
                          ref.read(_infraSortAscProvider.notifier).state = true;
                        }
                      },
                      onEdit: (r) => _showEditDialog(context, ref, r),
                      onReassign: (r) => _showReassignDialog(context, ref, r),
                      onOrphan: (r) => _confirmOrphan(context, ref, r),
                      onDelete: (r) => _confirmDelete(context, ref, r),
                      onServiceTap: (id) =>
                          context.go('/registry/services/$id'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaginationBar(
                    currentPage: page.page,
                    totalItems: page.totalElements,
                    pageSize: page.size == 0 ? 20 : page.size,
                    isLast: page.isLast,
                    onPageChanged: (p) {
                      ref.read(registryInfraPageProvider.notifier).state = p;
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => _ErrorPanel(
              message: e.toString(),
              onRetry: () => ref.invalidate(registryInfraResourcesProvider),
            ),
          ),
        ],
      ),
    );
  }

  List<InfraResourceResponse> _sortResources(
    List<InfraResourceResponse> list,
    String field,
    bool ascending,
  ) {
    final sorted = List<InfraResourceResponse>.from(list);
    sorted.sort((a, b) {
      final cmp = switch (field) {
        'name' => a.resourceName.compareTo(b.resourceName),
        'type' =>
          a.resourceType.displayName.compareTo(b.resourceType.displayName),
        'service' =>
          (a.serviceName ?? '').compareTo(b.serviceName ?? ''),
        'environment' => a.environment.compareTo(b.environment),
        'region' => (a.region ?? '').compareTo(b.region ?? ''),
        _ => 0,
      };
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (_) => InfraResourceFormDialog(
        teamId: ref.read(selectedTeamIdProvider),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, InfraResourceResponse r) {
    showDialog<bool>(
      context: context,
      builder: (_) => InfraResourceFormDialog(existingResource: r),
    );
  }

  void _showReassignDialog(
      BuildContext context, WidgetRef ref, InfraResourceResponse r) {
    final servicesAsync = ref.read(registryServicesProvider);
    final services = servicesAsync.valueOrNull?.content ?? [];

    String? selectedServiceId;
    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CodeOpsColors.surface,
          title: const Text('Reassign Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reassign "${r.resourceName}" to a service:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedServiceId,
                dropdownColor: CodeOpsColors.surface,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                ),
                items: services
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedServiceId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedServiceId == null
                  ? null
                  : () async {
                      final api = ref.read(registryApiProvider);
                      await api.reassignResource(
                        r.id,
                        newServiceId: selectedServiceId!,
                      );
                      ref.invalidate(registryInfraResourcesProvider);
                      ref.invalidate(registryOrphanedResourcesProvider);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: CodeOpsColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reassign'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmOrphan(
      BuildContext context, WidgetRef ref, InfraResourceResponse r) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Mark as Orphan'),
        content: Text(
          'Remove service ownership from "${r.resourceName}"? '
          'The resource will appear in the orphan list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final api = ref.read(registryApiProvider);
              await api.orphanResource(r.id);
              ref.invalidate(registryInfraResourcesProvider);
              ref.invalidate(registryOrphanedResourcesProvider);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: CodeOpsColors.warning,
              foregroundColor: Colors.black,
            ),
            child: const Text('Mark as Orphan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, InfraResourceResponse r) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Resource'),
        content: Text('Permanently delete "${r.resourceName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final api = ref.read(registryApiProvider);
              await api.deleteInfraResource(r.id);
              ref.invalidate(registryInfraResourcesProvider);
              ref.invalidate(registryOrphanedResourcesProvider);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page-scoped providers
// ---------------------------------------------------------------------------

final _infraSortFieldProvider = StateProvider<String>((ref) => 'name');
final _infraSortAscProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _InfraFilterBar extends ConsumerWidget {
  const _InfraFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(registryInfraTypeFilterProvider);
    final envFilter = ref.watch(registryInfraEnvironmentFilterProvider);
    final serviceFilter = ref.watch(registryInfraServiceFilterProvider);
    final search = ref.watch(registryInfraSearchProvider);

    final hasFilter = typeFilter != null ||
        envFilter.isNotEmpty ||
        serviceFilter != null ||
        search.isNotEmpty;

    return Row(
      children: [
        // Search
        SizedBox(
          width: 220,
          child: CodeOpsSearchBar(
            hint: 'Search resources...',
            onChanged: (v) =>
                ref.read(registryInfraSearchProvider.notifier).state = v,
          ),
        ),
        const SizedBox(width: 12),

        // Type filter
        _FilterDropdown<InfraResourceType>(
          label: 'Type',
          value: typeFilter,
          items: InfraResourceType.values,
          displayName: (v) => v.displayName,
          onChanged: (v) {
            ref.read(registryInfraTypeFilterProvider.notifier).state = v;
            ref.read(registryInfraPageProvider.notifier).state = 0;
          },
        ),
        const SizedBox(width: 8),

        // Environment filter
        SizedBox(
          width: 120,
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Env',
              filled: true,
              fillColor: CodeOpsColors.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textPrimary,
            ),
            onChanged: (v) {
              ref.read(registryInfraEnvironmentFilterProvider.notifier).state =
                  v;
              ref.read(registryInfraPageProvider.notifier).state = 0;
            },
          ),
        ),
        const SizedBox(width: 8),

        // Service filter
        _ServiceFilterDropdown(
          value: serviceFilter,
          onChanged: (v) =>
              ref.read(registryInfraServiceFilterProvider.notifier).state = v,
        ),

        // Clear
        if (hasFilter) ...[
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(registryInfraSearchProvider.notifier).state = '';
              ref.read(registryInfraTypeFilterProvider.notifier).state = null;
              ref.read(registryInfraEnvironmentFilterProvider.notifier).state =
                  '';
              ref.read(registryInfraServiceFilterProvider.notifier).state = null;
              ref.read(registryInfraPageProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.clear_all,
                size: 18, color: CodeOpsColors.textSecondary),
            label: const Text(
              'Clear',
              style:
                  TextStyle(fontSize: 13, color: CodeOpsColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Service filter dropdown (reads services from provider)
// ---------------------------------------------------------------------------

class _ServiceFilterDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ServiceFilterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(registryServicesProvider);
    final services = servicesAsync.valueOrNull?.content ?? [];

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
        child: DropdownButton<String?>(
          value: value,
          isDense: true,
          hint: const Text(
            'Service',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down,
              color: CodeOpsColors.textTertiary, size: 20),
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textPrimary,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Services'),
            ),
            ...services.map((s) => DropdownMenuItem<String?>(
                  value: s.id,
                  child: Text(s.name),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic filter dropdown
// ---------------------------------------------------------------------------

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
          icon: const Icon(Icons.arrow_drop_down,
              color: CodeOpsColors.textTertiary, size: 20),
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textPrimary,
          ),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text('All $label')),
            ...items.map((item) => DropdownMenuItem<T?>(
                  value: item,
                  child: Text(displayName(item)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination Bar
// ---------------------------------------------------------------------------

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final bool isLast;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.isLast,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = pageSize > 0 ? (totalItems / pageSize).ceil() : 0;
    final start = totalItems == 0 ? 0 : currentPage * pageSize + 1;
    final end = math.min((currentPage + 1) * pageSize, totalItems);

    return Row(
      children: [
        Text(
          'Showing $start\u2013$end of $totalItems resources',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          color: CodeOpsColors.textSecondary,
          onPressed:
              currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          tooltip: 'Previous page',
        ),
        ...List.generate(
          math.min(totalPages, 5),
          (i) {
            final pageIndex = _pageIndexForButton(i, totalPages);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: 32,
                height: 32,
                child: TextButton(
                  onPressed: () => onPageChanged(pageIndex),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: pageIndex == currentPage
                        ? CodeOpsColors.primary
                        : null,
                    foregroundColor: pageIndex == currentPage
                        ? Colors.white
                        : CodeOpsColors.textSecondary,
                  ),
                  child: Text(
                    '${pageIndex + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          color: CodeOpsColors.textSecondary,
          onPressed: !isLast ? () => onPageChanged(currentPage + 1) : null,
          tooltip: 'Next page',
        ),
      ],
    );
  }

  int _pageIndexForButton(int buttonIndex, int totalPages) {
    if (totalPages <= 5) return buttonIndex;
    if (currentPage < 3) return buttonIndex;
    if (currentPage > totalPages - 4) return totalPages - 5 + buttonIndex;
    return currentPage - 2 + buttonIndex;
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.cloud_outlined, size: 56,
                color: CodeOpsColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'No infrastructure resources',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add infrastructure resources to track cloud assets across services.',
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Panel
// ---------------------------------------------------------------------------

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CodeOpsColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CodeOpsColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: CodeOpsColors.error, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: CodeOpsColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CodeOpsColors.error,
                side: const BorderSide(color: CodeOpsColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
