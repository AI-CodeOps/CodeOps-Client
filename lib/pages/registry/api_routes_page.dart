/// API routes management page.
///
/// Displays a filterable, sortable table of registered API route prefixes
/// with collision detection banner, search, service/env filter controls,
/// and a route creation dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/route_collision_banner.dart';
import '../../widgets/registry/route_form_dialog.dart';
import '../../widgets/registry/route_table.dart';
import '../../widgets/shared/search_bar.dart';

/// The API routes page at `/registry/routes`.
class ApiRoutesPage extends ConsumerWidget {
  /// Creates an [ApiRoutesPage].
  const ApiRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(registryAllRoutesProvider);

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
                      'API Routes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage registered API route prefixes and detect collisions.',
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
                label: const Text('Register Route'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => ref.invalidate(registryAllRoutesProvider),
                icon: const Icon(Icons.refresh, size: 20),
                color: CodeOpsColors.textSecondary,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Collision banner
          routesAsync.when(
            data: (routes) {
              final collisions = _detectCollisions(routes);
              if (collisions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RouteCollisionBanner(collisions: collisions),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Filter bar
          const _RouteFilterBar(),
          const SizedBox(height: 16),

          // Table or states
          routesAsync.when(
            data: (routes) {
              if (routes.isEmpty) {
                return const _EmptyState();
              }

              // Client-side filtering
              final search =
                  ref.watch(registryRouteSearchProvider).toLowerCase();
              final serviceFilter =
                  ref.watch(registryRouteServiceFilterProvider);
              final envFilter =
                  ref.watch(registryRouteEnvironmentFilterProvider);
              var filtered = routes.where((r) {
                if (search.isNotEmpty &&
                    !r.routePrefix.toLowerCase().contains(search)) {
                  return false;
                }
                if (serviceFilter != null && r.serviceId != serviceFilter) {
                  return false;
                }
                if (envFilter.isNotEmpty &&
                    (r.environment ?? '').toLowerCase() !=
                        envFilter.toLowerCase()) {
                  return false;
                }
                return true;
              }).toList();

              // Sorting
              final sortField = ref.watch(_routeSortFieldProvider);
              final sortAsc = ref.watch(_routeSortAscProvider);
              filtered = _sortRoutes(filtered, sortField, sortAsc);

              // Detect collision prefixes
              final collisionPrefixes = _collisionPrefixes(routes);

              return SizedBox(
                width: double.infinity,
                child: RouteTable(
                  routes: filtered,
                  collisionPrefixes: collisionPrefixes,
                  sortField: sortField,
                  sortAscending: sortAsc,
                  onSort: (field) {
                    if (ref.read(_routeSortFieldProvider) == field) {
                      ref.read(_routeSortAscProvider.notifier).state =
                          !sortAsc;
                    } else {
                      ref.read(_routeSortFieldProvider.notifier).state = field;
                      ref.read(_routeSortAscProvider.notifier).state = true;
                    }
                  },
                  onDelete: (r) => _confirmDelete(context, ref, r),
                  onServiceTap: (id) =>
                      context.go('/registry/services/$id'),
                ),
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
              onRetry: () => ref.invalidate(registryAllRoutesProvider),
            ),
          ),
        ],
      ),
    );
  }

  /// Detects collisions — prefixes claimed by >1 service in the same env.
  List<RouteCheckResponse> _detectCollisions(List<ApiRouteResponse> routes) {
    final grouped = <String, List<ApiRouteResponse>>{};
    for (final r in routes) {
      final key = '${r.routePrefix}|${r.environment ?? ''}';
      (grouped[key] ??= []).add(r);
    }
    final collisions = <RouteCheckResponse>[];
    for (final entry in grouped.entries) {
      if (entry.value.length > 1) {
        final serviceIds =
            entry.value.map((r) => r.serviceId).toSet();
        if (serviceIds.length > 1) {
          final parts = entry.key.split('|');
          collisions.add(RouteCheckResponse(
            routePrefix: parts[0],
            environment: parts.length > 1 ? parts[1] : '',
            available: false,
            conflictingRoutes: entry.value,
          ));
        }
      }
    }
    return collisions;
  }

  /// Returns the set of route prefixes that have collisions.
  Set<String> _collisionPrefixes(List<ApiRouteResponse> routes) {
    final grouped = <String, Set<String>>{};
    for (final r in routes) {
      final key = '${r.routePrefix}|${r.environment ?? ''}';
      (grouped[key] ??= {}).add(r.serviceId);
    }
    final prefixes = <String>{};
    for (final entry in grouped.entries) {
      if (entry.value.length > 1) {
        prefixes.add(entry.key.split('|')[0]);
      }
    }
    return prefixes;
  }

  List<ApiRouteResponse> _sortRoutes(
    List<ApiRouteResponse> list,
    String field,
    bool ascending,
  ) {
    final sorted = List<ApiRouteResponse>.from(list);
    sorted.sort((a, b) {
      final cmp = switch (field) {
        'prefix' => a.routePrefix.compareTo(b.routePrefix),
        'service' =>
          (a.serviceName ?? '').compareTo(b.serviceName ?? ''),
        'environment' =>
          (a.environment ?? '').compareTo(b.environment ?? ''),
        _ => 0,
      };
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.read(registryServicesProvider);
    final services = servicesAsync.valueOrNull?.content ?? [];
    showDialog<bool>(
      context: context,
      builder: (_) => RouteFormDialog(services: services),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ApiRouteResponse r) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Route'),
        content: Text('Permanently delete route "${r.routePrefix}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final api = ref.read(registryApiProvider);
              await api.deleteRoute(r.id);
              ref.invalidate(registryAllRoutesProvider);
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

final _routeSortFieldProvider = StateProvider<String>((ref) => 'prefix');
final _routeSortAscProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _RouteFilterBar extends ConsumerWidget {
  const _RouteFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(registryRouteSearchProvider);
    final serviceFilter = ref.watch(registryRouteServiceFilterProvider);
    final envFilter = ref.watch(registryRouteEnvironmentFilterProvider);

    final hasFilter =
        search.isNotEmpty || serviceFilter != null || envFilter.isNotEmpty;

    return Row(
      children: [
        // Search
        SizedBox(
          width: 240,
          child: CodeOpsSearchBar(
            hint: 'Search prefix...',
            onChanged: (v) =>
                ref.read(registryRouteSearchProvider.notifier).state = v,
          ),
        ),
        const SizedBox(width: 12),

        // Service filter
        _ServiceFilterDropdown(
          value: serviceFilter,
          onChanged: (v) =>
              ref.read(registryRouteServiceFilterProvider.notifier).state = v,
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
            onChanged: (v) =>
                ref.read(registryRouteEnvironmentFilterProvider.notifier).state =
                    v,
          ),
        ),

        // Clear
        if (hasFilter) ...[
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(registryRouteSearchProvider.notifier).state = '';
              ref.read(registryRouteServiceFilterProvider.notifier).state = null;
              ref.read(registryRouteEnvironmentFilterProvider.notifier).state =
                  '';
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
// Service filter dropdown
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
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textSecondary),
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
            Icon(Icons.alt_route_outlined, size: 56,
                color: CodeOpsColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'No routes registered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Register API routes to track prefixes, detect collisions, and manage gateway routing.',
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
