/// Full GitHub browser page composing VCS widgets.
///
/// Layout:
/// - Left panel: OrgBrowser (org list) with search filter
/// - Main area: RepoBrowser (repo grid) or RepoSearch results
/// - "Connect GitHub" button if not authenticated
/// - When repo selected and cloned: RepoStatusBar + tabs
/// - Connection selector dropdown in header
/// - "Create Project from Repo" action on repo cards
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vcs_models.dart';
import '../providers/github_providers.dart';
import '../providers/project_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/notification_toast.dart';
import '../widgets/vcs/commit_history.dart';
import '../widgets/vcs/diff_viewer.dart';
import '../widgets/vcs/github_auth_dialog.dart';
import '../widgets/vcs/org_browser.dart';
import '../widgets/vcs/pull_request_list.dart';
import '../widgets/vcs/repo_browser.dart';
import '../widgets/vcs/repo_search.dart';
import '../widgets/vcs/repo_status_bar.dart';
import '../widgets/vcs/stash_manager.dart';

/// The GitHub browser page replacing the `/repos` placeholder.
class GitHubBrowserPage extends ConsumerStatefulWidget {
  /// Creates a [GitHubBrowserPage].
  const GitHubBrowserPage({super.key});

  @override
  ConsumerState<GitHubBrowserPage> createState() => _GitHubBrowserPageState();
}

class _GitHubBrowserPageState extends ConsumerState<GitHubBrowserPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(vcsAuthenticatedProvider);

    if (!authenticated) {
      return _UnauthenticatedView(
        onConnect: () async {
          await showDialog<bool>(
            context: context,
            builder: (_) => const GitHubAuthDialog(),
          );
        },
      );
    }

    final selectedRepo = ref.watch(selectedRepoProvider);
    final clonedAsync = ref.watch(clonedReposProvider);
    final clonedMap = clonedAsync.valueOrNull ?? {};
    final isCloned =
        selectedRepo != null && clonedMap.containsKey(selectedRepo);
    final repoStatusAsync = ref.watch(selectedRepoStatusProvider);
    final connectionsAsync = ref.watch(githubConnectionsProvider);

    return Row(
      children: [
        // Left sidebar: orgs + search toggle.
        SizedBox(
          width: 260,
          child: Column(
            children: [
              // Header with connection selector.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: CodeOpsColors.border),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'GitHub',
                          style: TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _showSearch ? Icons.list : Icons.search,
                            size: 18,
                          ),
                          tooltip: _showSearch
                              ? 'Show organizations'
                              : 'Search repositories',
                          onPressed: () =>
                              setState(() => _showSearch = !_showSearch),
                        ),
                      ],
                    ),
                    // Connection selector.
                    connectionsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (connections) {
                        if (connections.length <= 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: connections.isNotEmpty
                                ? connections.first.id
                                : null,
                            dropdownColor: CodeOpsColors.surfaceVariant,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(
                              color: CodeOpsColors.textSecondary,
                              fontSize: 12,
                            ),
                            items: connections
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (_) {
                              // Connection switching — placeholder for
                              // credential update logic.
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Body: org list or search.
              Expanded(
                child: _showSearch
                    ? const RepoSearch()
                    : const OrgBrowser(),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        // Main area.
        Expanded(
          child: Column(
            children: [
              // Repo browser.
              if (selectedRepo == null || !isCloned)
                const Expanded(child: RepoBrowser())
              else ...[
                // Repo status bar for cloned repos.
                repoStatusAsync.when(
                  loading: () => const LinearProgressIndicator(
                    color: CodeOpsColors.primary,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (status) {
                    if (status == null) return const SizedBox.shrink();
                    return RepoStatusBar(
                      status: status,
                      repoDir: clonedMap[selectedRepo]!,
                    );
                  },
                ),
                // Tabs for cloned repo.
                TabBar(
                  controller: _tabController,
                  labelColor: CodeOpsColors.primary,
                  unselectedLabelColor: CodeOpsColors.textTertiary,
                  indicatorColor: CodeOpsColors.primary,
                  tabs: const [
                    Tab(text: 'Commits'),
                    Tab(text: 'Pull Requests'),
                    Tab(text: 'Changes'),
                    Tab(text: 'Stashes'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      CommitHistory(repoFullName: selectedRepo),
                      PullRequestList(repoFullName: selectedRepo),
                      _ChangesTab(repoDir: clonedMap[selectedRepo]!),
                      StashManager(repoDir: clonedMap[selectedRepo]!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UnauthenticatedView extends StatelessWidget {
  final VoidCallback onConnect;

  const _UnauthenticatedView({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.code,
      title: 'Connect GitHub',
      subtitle: 'Connect your GitHub account to browse repositories,\n'
          'manage branches, and create pull requests.',
      actionLabel: 'Connect GitHub',
      onAction: onConnect,
    );
  }
}

class _ChangesTab extends ConsumerWidget {
  final String repoDir;

  const _ChangesTab({required this.repoDir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitService = ref.watch(gitServiceProvider);

    return FutureBuilder<List<DiffResult>>(
      future: gitService.diff(repoDir),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CodeOpsColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: CodeOpsColors.error),
            ),
          );
        }
        return DiffViewer(diffs: snapshot.data ?? []);
      },
    );
  }
}

/// Shows the create project dialog pre-filled with repository data.
///
/// Used by the RepoBrowser to create a project from a selected repo.
void showCreateProjectFromRepoDialog(
  BuildContext context, {
  required String repoName,
  required String repoUrl,
  required String repoFullName,
  String? defaultBranch,
}) {
  showDialog(
    context: context,
    builder: (_) => _CreateFromRepoDialog(
      repoName: repoName,
      repoUrl: repoUrl,
      repoFullName: repoFullName,
      defaultBranch: defaultBranch,
    ),
  );
}

class _CreateFromRepoDialog extends ConsumerStatefulWidget {
  final String repoName;
  final String repoUrl;
  final String repoFullName;
  final String? defaultBranch;

  const _CreateFromRepoDialog({
    required this.repoName,
    required this.repoUrl,
    required this.repoFullName,
    this.defaultBranch,
  });

  @override
  ConsumerState<_CreateFromRepoDialog> createState() =>
      _CreateFromRepoDialogState();
}

class _CreateFromRepoDialogState
    extends ConsumerState<_CreateFromRepoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _techStackController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.repoName);
    _techStackController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _techStackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Create Project from Repository'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.repoFullName,
                decoration:
                    const InputDecoration(labelText: 'Repository Full Name'),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.repoUrl,
                decoration: const InputDecoration(labelText: 'Repository URL'),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.defaultBranch ?? 'main',
                decoration:
                    const InputDecoration(labelText: 'Default Branch'),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _techStackController,
                decoration: const InputDecoration(
                  labelText: 'Tech Stack',
                  hintText: 'e.g. Spring Boot, React',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: CodeOpsColors.textSecondary)),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Project'),
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
      final projectApi = ref.read(projectApiProvider);
      await projectApi.createProject(
        teamId,
        name: _nameController.text.trim(),
        repoUrl: widget.repoUrl,
        repoFullName: widget.repoFullName,
        defaultBranch: widget.defaultBranch ?? 'main',
        techStack: _techStackController.text.trim().isEmpty
            ? null
            : _techStackController.text.trim(),
      );

      ref.invalidate(teamProjectsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        showToast(context,
            message: 'Project created from "${widget.repoName}"',
            type: ToastType.success);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        showToast(context, message: 'Failed: $e', type: ToastType.error);
      }
    }
  }
}
