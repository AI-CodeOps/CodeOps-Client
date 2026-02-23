/// Workstation profiles list page.
///
/// Displays workstation profile cards with a create button and
/// "Create from Solution" dropdown. Supports navigating to
/// profile detail pages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/workstation_card.dart';
import '../../widgets/registry/workstation_form_dialog.dart';
import '../../widgets/shared/error_panel.dart';
import '../../widgets/shared/notification_toast.dart';

/// Workstation profiles list page.
///
/// Watches [registryWorkstationProfilesProvider] for the profile list.
/// Provides create, create-from-solution, and navigate-to-detail actions.
class WorkstationListPage extends ConsumerWidget {
  /// Creates a [WorkstationListPage].
  const WorkstationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(registryWorkstationProfilesProvider);

    return Column(
      children: [
        // Header
        _HeaderBar(),
        // Content
        Expanded(
          child: profilesAsync.when(
            data: (profiles) {
              if (profiles.isEmpty) return _EmptyState();
              return _ProfileGrid(profiles: profiles);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel(
              title: 'Failed to Load Workstation Profiles',
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(registryWorkstationProfilesProvider),
            ),
          ),
        ),
      ],
    );
  }
}

/// Header bar with title, create button, and create-from-solution action.
class _HeaderBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutionsAsync = ref.watch(registrySolutionsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Workstation Profiles',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Create from solution
          solutionsAsync.when(
            data: (page) {
              final solutions = page.content;
              if (solutions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FromSolutionButton(solutions: solutions),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Create button
          OutlinedButton.icon(
            onPressed: () async {
              final result = await showWorkstationFormDialog(context);
              if (result != null && context.mounted) {
                context.go('/registry/workstations/${result.id}');
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Profile'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown button for creating a profile from an existing solution.
class _FromSolutionButton extends ConsumerWidget {
  final List<SolutionResponse> solutions;

  const _FromSolutionButton({required this.solutions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<SolutionResponse>(
      tooltip: 'Create from solution',
      offset: const Offset(0, 40),
      color: CodeOpsColors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: CodeOpsColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_outlined,
                size: 16, color: CodeOpsColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'From Solution',
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 18, color: CodeOpsColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (_) => solutions.map((sol) {
        return PopupMenuItem(
          value: sol,
          child: Text(
            sol.name,
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textPrimary,
            ),
          ),
        );
      }).toList(),
      onSelected: (sol) => _createFromSolution(context, ref, sol),
    );
  }

  Future<void> _createFromSolution(
      BuildContext context, WidgetRef ref, SolutionResponse solution) async {
    try {
      final api = ref.read(registryApiProvider);
      final teamId = ref.read(selectedTeamIdProvider);
      if (teamId == null) return;
      final result = await api.createWorkstationFromSolution(
        solution.id,
        teamId: teamId,
      );
      ref.invalidate(registryWorkstationProfilesProvider);
      if (context.mounted) {
        showToast(context,
            message: 'Profile created from "${solution.name}"',
            type: ToastType.success);
        context.go('/registry/workstations/${result.id}');
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Create from solution failed: $e',
            type: ToastType.error);
      }
    }
  }
}

/// Empty state when no profiles exist.
class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.computer,
              size: 48, color: CodeOpsColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'No workstation profiles yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create a profile to manage your local dev environment.',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await showWorkstationFormDialog(context);
              if (result != null && context.mounted) {
                context.go('/registry/workstations/${result.id}');
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Profile'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of workstation profile cards.
class _ProfileGrid extends StatelessWidget {
  final List<WorkstationProfileResponse> profiles;

  const _ProfileGrid({required this.profiles});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: profiles.map((profile) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkstationCard(
              profile: profile,
              onTap: () =>
                  context.go('/registry/workstations/${profile.id}'),
              onStartAll: () {
                // Informational: startup intent logged; actual start is OS-level.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Start All for "${profile.name}" — '
                      'actual service start is OS-level.',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
