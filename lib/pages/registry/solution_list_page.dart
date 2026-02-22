/// Solutions list page.
///
/// Displays solution cards with status/category filtering and text
/// search. Supports creating new solutions via [SolutionFormDialog].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/solution_card.dart';
import '../../widgets/registry/solution_form_dialog.dart';
import '../../widgets/shared/error_panel.dart';

/// Solutions list page.
///
/// Watches [registrySolutionsProvider] for paginated solution data
/// and [filteredRegistrySolutionsProvider] for client-side search.
/// Provides status/category dropdown filters and a create button.
class SolutionListPage extends ConsumerWidget {
  /// Creates a [SolutionListPage].
  const SolutionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutionsAsync = ref.watch(registrySolutionsProvider);

    return Column(
      children: [
        // Header
        _HeaderBar(),
        // Content
        Expanded(
          child: solutionsAsync.when(
            data: (page) {
              final solutions = ref.watch(filteredRegistrySolutionsProvider);
              if (page.content.isEmpty) {
                return _EmptyState();
              }
              if (solutions.isEmpty) {
                return const Center(
                  child: Text(
                    'No solutions match your filters.',
                    style: TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                );
              }
              return _SolutionGrid(solutions: solutions);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel(
              title: 'Failed to Load Solutions',
              message: e.toString(),
              onRetry: () => ref.invalidate(registrySolutionsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

/// Header bar with title, filters, and create button.
class _HeaderBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(registrySolutionStatusFilterProvider);
    final categoryFilter = ref.watch(registrySolutionCategoryFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              const Text(
                'Solutions',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showSolutionFormDialog(context);
                  if (result != null && context.mounted) {
                    context.go('/registry/solutions/${result.id}');
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Solution'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CodeOpsColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              // Status filter
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<SolutionStatus?>(
                  initialValue: statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: CodeOpsColors.surface,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Statuses')),
                    ...SolutionStatus.values.map((s) => DropdownMenuItem(
                        value: s, child: Text(s.displayName))),
                  ],
                  onChanged: (v) => ref
                      .read(registrySolutionStatusFilterProvider.notifier)
                      .state = v,
                ),
              ),
              const SizedBox(width: 12),
              // Category filter
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<SolutionCategory?>(
                  initialValue: categoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: CodeOpsColors.surface,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Categories')),
                    ...SolutionCategory.values.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.displayName))),
                  ],
                  onChanged: (v) => ref
                      .read(registrySolutionCategoryFilterProvider.notifier)
                      .state = v,
                ),
              ),
              const SizedBox(width: 12),
              // Search
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search solutions...',
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: CodeOpsColors.textTertiary),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => ref
                      .read(registrySolutionSearchProvider.notifier)
                      .state = v,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty state when no solutions exist.
class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_outlined,
              size: 48, color: CodeOpsColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'No solutions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create a solution to group related services.',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await showSolutionFormDialog(context);
              if (result != null && context.mounted) {
                context.go('/registry/solutions/${result.id}');
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Solution'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable grid of solution cards.
class _SolutionGrid extends StatelessWidget {
  final List<SolutionResponse> solutions;

  const _SolutionGrid({required this.solutions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: solutions.map((solution) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SolutionCard(
              solution: solution,
              onTap: () =>
                  context.go('/registry/solutions/${solution.id}'),
            ),
          );
        }).toList(),
      ),
    );
  }
}
