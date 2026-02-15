/// Full GitHub browser page with a master-detail layout.
///
/// Layout:
/// - Left panel (300px): RepoSidebar with org picker, search, repo list
/// - Right panel: RepoDetailPanel with header, action bar, and tabs
/// - "Connect GitHub" button if not authenticated
/// - "Create Project from Repo" action available from RepoSidebar
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/github_providers.dart';
import '../providers/project_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/notification_toast.dart';
import '../widgets/vcs/github_auth_dialog.dart';
import '../widgets/vcs/repo_detail_panel.dart';
import '../widgets/vcs/repo_sidebar.dart';

/// The GitHub browser page with master-detail layout.
class GitHubBrowserPage extends ConsumerWidget {
  /// Creates a [GitHubBrowserPage].
  const GitHubBrowserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return const Row(
      children: [
        SizedBox(width: 300, child: RepoSidebar()),
        VerticalDivider(width: 1, color: CodeOpsColors.divider),
        Expanded(child: RepoDetailPanel()),
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
