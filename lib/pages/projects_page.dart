/// Projects list page with search, sort, favorites, and create dialog.
///
/// Displays project cards in a responsive grid. Favorites are pinned
/// at the top. Provides filtering, sorting, and a create project dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/project.dart';
import '../providers/github_providers.dart';
import '../providers/project_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/shared/notification_toast.dart';
import '../widgets/shared/search_bar.dart';

/// The projects list page replacing the `/projects` placeholder.
class ProjectsPage extends ConsumerWidget {
  /// Creates a [ProjectsPage].
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(filteredProjectsProvider);
    final sortOrder = ref.watch(projectSortProvider);
    final showArchived = ref.watch(showArchivedProvider);

    return Column(
      children: [
        // Top bar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Projects',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 280,
                child: CodeOpsSearchBar(
                  hint: 'Search projects...',
                  onChanged: (value) {
                    ref.read(projectSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Sort dropdown.
              DropdownButton<ProjectSortOrder>(
                value: sortOrder,
                dropdownColor: CodeOpsColors.surface,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ProjectSortOrder.nameAsc,
                    child: Text('Name A-Z'),
                  ),
                  DropdownMenuItem(
                    value: ProjectSortOrder.healthScoreDesc,
                    child: Text('Health Score'),
                  ),
                  DropdownMenuItem(
                    value: ProjectSortOrder.lastAuditDesc,
                    child: Text('Last Audit'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(projectSortProvider.notifier).state = value;
                  }
                },
              ),
              const SizedBox(width: 12),
              // Show archived toggle.
              FilterChip(
                label: const Text(
                  'Archived',
                  style: TextStyle(fontSize: 12),
                ),
                selected: showArchived,
                selectedColor: CodeOpsColors.primaryVariant,
                onSelected: (value) {
                  ref.read(showArchivedProvider.notifier).state = value;
                },
              ),
              const Spacer(),
              // Refresh button.
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(teamProjectsProvider);
                },
              ),
              const SizedBox(width: 8),
              // New project button.
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Project'),
              ),
            ],
          ),
        ),
        // Body.
        Expanded(
          child: projectsAsync.when(
            loading: () => const LoadingOverlay(message: 'Loading projects...'),
            error: (error, _) => ErrorPanel.fromException(
              error,
              onRetry: () => ref.invalidate(teamProjectsProvider),
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return EmptyState(
                  icon: Icons.folder_open,
                  title: 'No projects yet',
                  subtitle: 'Create a project to start auditing your codebase.',
                  actionLabel: 'New Project',
                  onAction: () => _showCreateDialog(context, ref),
                );
              }
              return _ProjectGrid(projects: projects);
            },
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _CreateProjectDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Project grid
// ---------------------------------------------------------------------------

class _ProjectGrid extends ConsumerWidget {
  final List<Project> projects;

  const _ProjectGrid({required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return _ProjectCard(project: projects[index]);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Project card
// ---------------------------------------------------------------------------

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProjectIdsProvider);
    final isFavorite = favorites.contains(project.id);
    final healthScore = project.healthScore;
    final healthColor = _healthColor(healthScore);
    final isArchived = project.isArchived == true;

    return Material(
      color: CodeOpsColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/projects/${project.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + favorite.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isArchived)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.textTertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Archived',
                        style: TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => ref
                        .read(favoriteProjectIdsProvider.notifier)
                        .toggle(project.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFavorite
                          ? CodeOpsColors.warning
                          : CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Repo name.
              if (project.repoFullName != null)
                Text(
                  project.repoFullName!,
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              // Bottom row: tech stack, health score, last audit.
              Row(
                children: [
                  if (project.techStack != null) ...[
                    _TechStackBadge(techStack: project.techStack!),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  // Health score indicator.
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: healthColor, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      healthScore != null ? '$healthScore' : '—',
                      style: TextStyle(
                        color: healthColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Last audit.
              Text(
                'Last audit: ${formatTimeAgo(project.lastAuditAt)}',
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _healthColor(int? score) {
    if (score == null) return CodeOpsColors.textTertiary;
    if (score >= AppConstants.healthScoreGreenThreshold) {
      return CodeOpsColors.success;
    }
    if (score >= AppConstants.healthScoreYellowThreshold) {
      return CodeOpsColors.warning;
    }
    return CodeOpsColors.error;
  }
}

// ---------------------------------------------------------------------------
// Tech stack badge
// ---------------------------------------------------------------------------

class _TechStackBadge extends StatelessWidget {
  final String techStack;

  const _TechStackBadge({required this.techStack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: CodeOpsColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        techStack,
        style: const TextStyle(
          color: CodeOpsColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create project dialog
// ---------------------------------------------------------------------------

class _CreateProjectDialog extends ConsumerStatefulWidget {
  const _CreateProjectDialog();

  @override
  ConsumerState<_CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _repoUrlController;
  late final TextEditingController _repoFullNameController;
  late final TextEditingController _defaultBranchController;
  late final TextEditingController _jiraProjectKeyController;
  late final TextEditingController _jiraDefaultIssueTypeController;
  late final TextEditingController _jiraLabelsController;
  late final TextEditingController _jiraComponentController;
  late final TextEditingController _techStackController;

  String? _selectedGitHubConnectionId;
  String? _selectedJiraConnectionId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _repoUrlController = TextEditingController();
    _repoFullNameController = TextEditingController();
    _defaultBranchController = TextEditingController();
    _jiraProjectKeyController = TextEditingController();
    _jiraDefaultIssueTypeController = TextEditingController();
    _jiraLabelsController = TextEditingController();
    _jiraComponentController = TextEditingController();
    _techStackController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repoUrlController.dispose();
    _repoFullNameController.dispose();
    _defaultBranchController.dispose();
    _jiraProjectKeyController.dispose();
    _jiraDefaultIssueTypeController.dispose();
    _jiraLabelsController.dispose();
    _jiraComponentController.dispose();
    _techStackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final githubConnectionsAsync = ref.watch(githubConnectionsProvider);
    final jiraConnectionsAsync = ref.watch(jiraConnectionsProvider);

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('New Project'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name.
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'My Project',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.length > 200) {
                      return 'Name must be 200 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Description.
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional project description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Tech stack.
                TextFormField(
                  controller: _techStackController,
                  decoration: const InputDecoration(
                    labelText: 'Tech Stack',
                    hintText: 'e.g. Spring Boot, React',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'GitHub',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                // GitHub connection.
                githubConnectionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text(
                    'Failed to load connections',
                    style: TextStyle(
                      color: CodeOpsColors.error,
                      fontSize: 12,
                    ),
                  ),
                  data: (connections) => DropdownButtonFormField<String>(
                    initialValue: _selectedGitHubConnectionId,
                    decoration: const InputDecoration(
                      labelText: 'GitHub Connection',
                    ),
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...connections.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedGitHubConnectionId = value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Repo URL.
                TextFormField(
                  controller: _repoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Repository URL',
                    hintText: 'https://github.com/owner/repo.git',
                  ),
                ),
                const SizedBox(height: 8),
                // Repo full name.
                TextFormField(
                  controller: _repoFullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Repository Full Name',
                    hintText: 'owner/repo',
                  ),
                ),
                const SizedBox(height: 8),
                // Default branch.
                TextFormField(
                  controller: _defaultBranchController,
                  decoration: const InputDecoration(
                    labelText: 'Default Branch',
                    hintText: 'main',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jira',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                // Jira connection.
                jiraConnectionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text(
                    'Failed to load connections',
                    style: TextStyle(
                      color: CodeOpsColors.error,
                      fontSize: 12,
                    ),
                  ),
                  data: (connections) => DropdownButtonFormField<String>(
                    initialValue: _selectedJiraConnectionId,
                    decoration: const InputDecoration(
                      labelText: 'Jira Connection',
                    ),
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...connections.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedJiraConnectionId = value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Jira project key.
                TextFormField(
                  controller: _jiraProjectKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Jira Project Key',
                    hintText: 'PROJ',
                  ),
                ),
                const SizedBox(height: 8),
                // Jira default issue type.
                TextFormField(
                  controller: _jiraDefaultIssueTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Default Issue Type',
                    hintText: 'Bug',
                  ),
                ),
                const SizedBox(height: 8),
                // Jira labels.
                TextFormField(
                  controller: _jiraLabelsController,
                  decoration: const InputDecoration(
                    labelText: 'Jira Labels',
                    hintText: 'label1, label2',
                  ),
                ),
                const SizedBox(height: 8),
                // Jira component.
                TextFormField(
                  controller: _jiraComponentController,
                  decoration: const InputDecoration(
                    labelText: 'Jira Component',
                    hintText: 'Backend',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) {
      setState(() => _submitting = false);
      return;
    }

    try {
      final labels = _jiraLabelsController.text.trim().isEmpty
          ? null
          : _jiraLabelsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final projectApi = ref.read(projectApiProvider);
      final project = await projectApi.createProject(
        teamId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        githubConnectionId: _selectedGitHubConnectionId,
        repoUrl: _repoUrlController.text.trim().isEmpty
            ? null
            : _repoUrlController.text.trim(),
        repoFullName: _repoFullNameController.text.trim().isEmpty
            ? null
            : _repoFullNameController.text.trim(),
        defaultBranch: _defaultBranchController.text.trim().isEmpty
            ? null
            : _defaultBranchController.text.trim(),
        jiraConnectionId: _selectedJiraConnectionId,
        jiraProjectKey: _jiraProjectKeyController.text.trim().isEmpty
            ? null
            : _jiraProjectKeyController.text.trim(),
        jiraDefaultIssueType:
            _jiraDefaultIssueTypeController.text.trim().isEmpty
                ? null
                : _jiraDefaultIssueTypeController.text.trim(),
        jiraLabels: labels,
        jiraComponent: _jiraComponentController.text.trim().isEmpty
            ? null
            : _jiraComponentController.text.trim(),
        techStack: _techStackController.text.trim().isEmpty
            ? null
            : _techStackController.text.trim(),
      );

      ref.invalidate(teamProjectsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        showToast(context,
            message: 'Project "${project.name}" created',
            type: ToastType.success);
        context.go('/projects/${project.id}');
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        showToast(context,
            message: 'Failed to create project: $e', type: ToastType.error);
      }
    }
  }
}
