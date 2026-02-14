/// Source selection step for the wizard.
///
/// Shows a searchable project list from [teamProjectsProvider],
/// a selected project detail card, and a branch picker.
/// Validation: project + branch must be selected.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../providers/project_providers.dart';
import '../../theme/colors.dart';
import '../shared/search_bar.dart';
import '../vcs/branch_picker.dart';

/// Source selection step for the wizard flow.
class SourceStep extends ConsumerStatefulWidget {
  /// The currently selected project.
  final Project? selectedProject;

  /// The currently selected branch.
  final String? selectedBranch;

  /// Called when a project is selected.
  final ValueChanged<Project> onProjectSelected;

  /// Called when a branch is selected.
  final ValueChanged<String> onBranchSelected;

  /// Creates a [SourceStep].
  const SourceStep({
    super.key,
    this.selectedProject,
    this.selectedBranch,
    required this.onProjectSelected,
    required this.onBranchSelected,
  });

  @override
  ConsumerState<SourceStep> createState() => _SourceStepState();
}

class _SourceStepState extends ConsumerState<SourceStep> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(teamProjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Source',
          style: TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the project and branch to analyze.',
          style: TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Selected project detail card
        if (widget.selectedProject != null) ...[
          _SelectedProjectCard(
            project: widget.selectedProject!,
            selectedBranch: widget.selectedBranch ?? 'main',
            onBranchSelected: widget.onBranchSelected,
          ),
          const SizedBox(height: 16),
          const Divider(color: CodeOpsColors.divider),
          const SizedBox(height: 12),
          const Text(
            'Change project:',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Search bar
        CodeOpsSearchBar(
          hint: 'Search projects...',
          onChanged: (query) => setState(() => _searchQuery = query),
        ),
        const SizedBox(height: 12),

        // Project list
        Expanded(
          child: projectsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text(
                'Failed to load projects: $e',
                style: const TextStyle(color: CodeOpsColors.error),
              ),
            ),
            data: (projects) {
              final filtered = _searchQuery.isEmpty
                  ? projects
                  : projects.where((p) {
                      final q = _searchQuery.toLowerCase();
                      return p.name.toLowerCase().contains(q) ||
                          (p.repoFullName?.toLowerCase().contains(q) ??
                              false);
                    }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No projects found',
                    style: TextStyle(color: CodeOpsColors.textTertiary),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final project = filtered[index];
                  final isSelected =
                      widget.selectedProject?.id == project.id;
                  return _ProjectTile(
                    project: project,
                    isSelected: isSelected,
                    onTap: () => widget.onProjectSelected(project),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectedProjectCard extends StatelessWidget {
  final Project project;
  final String selectedBranch;
  final ValueChanged<String> onBranchSelected;

  const _SelectedProjectCard({
    required this.project,
    required this.selectedBranch,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined,
                  size: 20, color: CodeOpsColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (project.healthScore != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _healthColor(project.healthScore!)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${project.healthScore}',
                    style: TextStyle(
                      color: _healthColor(project.healthScore!),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (project.repoFullName != null) ...[
            const SizedBox(height: 4),
            Text(
              project.repoFullName!,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Branch:',
                style: TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (project.repoFullName != null)
                BranchPicker(
                  repoFullName: project.repoFullName!,
                  currentBranch: selectedBranch,
                  onBranchSelected: onBranchSelected,
                )
              else
                Text(
                  selectedBranch,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 80) return CodeOpsColors.success;
    if (score >= 60) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.project,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? CodeOpsColors.primary.withValues(alpha: 0.08)
          : CodeOpsColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 18,
                color: isSelected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (project.techStack != null)
                      Text(
                        project.techStack!,
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    size: 16, color: CodeOpsColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
