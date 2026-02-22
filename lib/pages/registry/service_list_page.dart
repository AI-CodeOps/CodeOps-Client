/// Service list page for the Registry module.
///
/// Displays a filterable, sortable table of registered services with
/// health summary cards, search, filter controls, and pagination.
/// Replaces the CRF-001 placeholder as the primary `/registry` landing page.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/service_filter_bar.dart';
import '../../widgets/registry/service_table.dart';

/// The service list page at `/registry`.
class ServiceListPage extends ConsumerWidget {
  /// Creates a [ServiceListPage].
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(registryServicesProvider);
    final healthAsync = ref.watch(registryTeamHealthSummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Registry',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage registered services, health status, and dependencies.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/registry/services/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Register'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref.invalidate(registryServicesProvider);
                  ref.invalidate(registryTeamHealthSummaryProvider);
                },
                icon: const Icon(Icons.refresh, size: 20),
                color: CodeOpsColors.textSecondary,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary cards
          healthAsync.when(
            data: (health) {
              if (health == null) return const SizedBox.shrink();
              return _SummaryCards(
                total: health.totalServices,
                healthy: health.servicesUp,
                unhealthy: health.servicesDown,
                degraded: health.servicesDegraded,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Filter bar
          const ServiceFilterBar(),
          const SizedBox(height: 16),

          // Table or states
          servicesAsync.when(
            data: (page) {
              if (page.content.isEmpty &&
                  ref.read(registryServiceSearchProvider).isEmpty &&
                  ref.read(registryServiceStatusFilterProvider) == null &&
                  ref.read(registryServiceTypeFilterProvider) == null &&
                  ref.read(registryServiceHealthFilterProvider) == null) {
                return const _EmptyState();
              }

              final filtered = ref.watch(paginatedRegistryServicesProvider);
              final totalFiltered =
                  ref.watch(filteredRegistryServiceCountProvider);
              final currentPage =
                  ref.watch(registryServicePageProvider);
              final pageSize =
                  ref.watch(registryServicePageSizeProvider);
              final sortField =
                  ref.watch(registryServiceSortFieldProvider);
              final sortAsc =
                  ref.watch(registryServiceSortAscendingProvider);

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ServiceTable(
                      services: filtered,
                      sortField: sortField,
                      sortAscending: sortAsc,
                      onSort: (field) {
                        if (ref.read(registryServiceSortFieldProvider) ==
                            field) {
                          ref
                              .read(registryServiceSortAscendingProvider
                                  .notifier)
                              .state = !sortAsc;
                        } else {
                          ref
                              .read(
                                  registryServiceSortFieldProvider.notifier)
                              .state = field;
                          ref
                              .read(registryServiceSortAscendingProvider
                                  .notifier)
                              .state = true;
                        }
                      },
                      onTap: (service) {
                        context.go('/registry/services/${service.id}');
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaginationBar(
                    currentPage: currentPage,
                    pageSize: pageSize,
                    totalItems: totalFiltered,
                    onPageChanged: (p) {
                      ref.read(registryServicePageProvider.notifier).state =
                          p;
                    },
                    onPageSizeChanged: (s) {
                      ref.read(registryServicePageSizeProvider.notifier)
                          .state = s;
                      ref.read(registryServicePageProvider.notifier).state =
                          0;
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
              onRetry: () => ref.invalidate(registryServicesProvider),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Cards
// ---------------------------------------------------------------------------

class _SummaryCards extends StatelessWidget {
  final int total;
  final int healthy;
  final int unhealthy;
  final int degraded;

  const _SummaryCards({
    required this.total,
    required this.healthy,
    required this.unhealthy,
    required this.degraded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total',
            value: total,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Healthy',
            value: healthy,
            color: CodeOpsColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Unhealthy',
            value: unhealthy,
            color: CodeOpsColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Degraded',
            value: degraded,
            color: CodeOpsColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Icon(
              Icons.dns_outlined,
              size: 56,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No services registered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your first service to start tracking health, ports, and dependencies.',
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/registry/services/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Register Service'),
              style: FilledButton.styleFrom(
                backgroundColor: CodeOpsColors.primary,
                foregroundColor: Colors.white,
              ),
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
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.error,
              ),
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

// ---------------------------------------------------------------------------
// Pagination Bar
// ---------------------------------------------------------------------------

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / pageSize).ceil();
    final start = totalItems == 0 ? 0 : currentPage * pageSize + 1;
    final end = math.min((currentPage + 1) * pageSize, totalItems);

    return Row(
      children: [
        Text(
          'Showing $start\u2013$end of $totalItems services',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const Spacer(),

        // Page size selector
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              isDense: true,
              dropdownColor: CodeOpsColors.surface,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 / page')),
                DropdownMenuItem(value: 25, child: Text('25 / page')),
                DropdownMenuItem(value: 50, child: Text('50 / page')),
              ],
              onChanged: (v) {
                if (v != null) onPageSizeChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Page buttons
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
          onPressed: currentPage < totalPages - 1
              ? () => onPageChanged(currentPage + 1)
              : null,
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
