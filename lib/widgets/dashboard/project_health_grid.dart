/// Project health grid card for the home dashboard.
///
/// Shows a wrap of project cards with health score badges,
/// sourced from [teamProjectsProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';

/// A card displaying project health scores in a wrap layout.
class ProjectHealthGrid extends ConsumerWidget {
  /// Creates a [ProjectHealthGrid] widget.
  const ProjectHealthGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(teamProjectsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Project Health',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/projects'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: projectsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => ErrorPanel.fromException(
                  error,
                  onRetry: () => ref.invalidate(teamProjectsProvider),
                ),
                data: (projects) {
                  if (projects.isEmpty) {
                    return const EmptyState(
                      icon: Icons.folder_open,
                      title: 'No projects yet',
                      subtitle: 'Create a project to track its health.',
                    );
                  }
                  final shown = projects.take(6).toList();
                  final remaining = projects.length - shown.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: shown.map((p) {
                            return _ProjectHealthCard(
                              name: p.name,
                              healthScore: p.healthScore,
                              onTap: () => context.go('/projects/${p.id}'),
                            );
                          }).toList(),
                        ),
                      ),
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => context.go('/projects'),
                            child: Text('+$remaining more'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectHealthCard extends StatelessWidget {
  final String name;
  final int? healthScore;
  final VoidCallback onTap;

  const _ProjectHealthCard({
    required this.name,
    required this.healthScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(healthScore);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  healthScore != null ? '$healthScore' : '\u2014',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _healthColor(int? score) {
    if (score == null) return CodeOpsColors.textTertiary;
    if (score >= 80) return CodeOpsColors.success;
    if (score >= 60) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }
}
