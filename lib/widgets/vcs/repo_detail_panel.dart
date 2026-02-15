/// Detail panel for the GitHub Browser master-detail layout.
///
/// Shows a repo header, action bar, and tabbed content (README, Branches,
/// PRs, Commits) for the selected repository.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';
import 'clone_dialog.dart';

/// Right-panel detail view showing repo info and tabbed content.
class RepoDetailPanel extends ConsumerStatefulWidget {
  /// Creates a [RepoDetailPanel].
  const RepoDetailPanel({super.key});

  @override
  ConsumerState<RepoDetailPanel> createState() => _RepoDetailPanelState();
}

class _RepoDetailPanelState extends ConsumerState<RepoDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Sync tab controller with provider.
    ref.listenManual(githubDetailTabProvider, (_, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(githubDetailTabProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(selectedGithubRepoProvider);

    if (repo == null) {
      return const EmptyState(
        icon: Icons.source,
        title: 'Select a repository',
        subtitle: 'Choose a repository from the sidebar to view details.',
      );
    }

    final branchesAsync = ref.watch(githubRepoBranchesProvider);
    final prsAsync = ref.watch(githubRepoPullRequestsProvider);
    final commitsAsync = ref.watch(githubRepoCommitsProvider);

    return Column(
      children: [
        _RepoHeader(repo: repo),
        const Divider(height: 1, color: CodeOpsColors.divider),
        _ActionBar(repo: repo),
        TabBar(
          controller: _tabController,
          labelColor: CodeOpsColors.primary,
          unselectedLabelColor: CodeOpsColors.textTertiary,
          indicatorColor: CodeOpsColors.primary,
          tabs: [
            const Tab(text: 'README'),
            Tab(
              text: branchesAsync.whenOrNull(
                    data: (b) => 'Branches (${b.length})',
                  ) ??
                  'Branches',
            ),
            Tab(
              text: prsAsync.whenOrNull(
                    data: (p) => 'PRs (${p.length})',
                  ) ??
                  'PRs',
            ),
            Tab(
              text: commitsAsync.whenOrNull(
                    data: (c) => 'Commits (${c.length})',
                  ) ??
                  'Commits',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ReadmeTab(),
              _BranchesTab(),
              _PullRequestsTab(),
              _CommitsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepoHeader extends StatelessWidget {
  final VcsRepository repo;

  const _RepoHeader({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row.
          Text(
            '${repo.ownerLogin ?? ''} / ${repo.name}',
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (repo.description != null && repo.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              repo.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Metadata row.
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (repo.language != null) _metadataChip(repo.language!),
              _iconChip(Icons.star_outline, '${repo.stargazersCount}'),
              _iconChip(Icons.call_split, '${repo.forksCount}'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: repo.isPrivate
                      ? CodeOpsColors.warning.withValues(alpha: 0.15)
                      : CodeOpsColors.success.withValues(alpha: 0.15),
                ),
                child: Text(
                  repo.isPrivate ? 'Private' : 'Public',
                  style: TextStyle(
                    color: repo.isPrivate
                        ? CodeOpsColors.warning
                        : CodeOpsColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CodeOpsColors.surfaceVariant,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_tree,
                      size: 12,
                      color: CodeOpsColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      repo.defaultBranch,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metadataChip(String language) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CodeOpsColors.primary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          language,
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _iconChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CodeOpsColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final VcsRepository repo;

  const _ActionBar({required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClonedAsync = ref.watch(isRepoClonedProvider);
    final clonedMap = ref.watch(clonedReposProvider).valueOrNull ?? {};

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Clone / Open button.
          isClonedAsync.when(
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CodeOpsColors.primary,
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (isCloned) {
              if (isCloned) {
                final path = clonedMap[repo.fullName];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Open in Finder via url_launcher.
                        if (path != null) {
                          launchUrl(Uri.parse('file://$path'));
                        }
                      },
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Open in Finder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CodeOpsColors.textPrimary,
                        side: const BorderSide(color: CodeOpsColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    if (path != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        path,
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                );
              }
              return ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => CloneDialog(repo: repo),
                  );
                  if (result == true) {
                    ref.invalidate(isRepoClonedProvider);
                    ref.invalidate(clonedReposProvider);
                  }
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Clone'),
              );
            },
          ),
          const SizedBox(width: 8),
          // View on GitHub.
          if (repo.htmlUrl != null)
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(repo.htmlUrl!)),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('View on GitHub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CodeOpsColors.textPrimary,
                side: const BorderSide(color: CodeOpsColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          const Spacer(),
          // Refresh.
          IconButton(
            icon: const Icon(
              Icons.refresh,
              size: 20,
              color: CodeOpsColors.textSecondary,
            ),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(githubReadmeProvider);
              ref.invalidate(githubRepoBranchesProvider);
              ref.invalidate(githubRepoPullRequestsProvider);
              ref.invalidate(githubRepoCommitsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _ReadmeTab extends ConsumerWidget {
  const _ReadmeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readmeAsync = ref.watch(githubReadmeProvider);

    return readmeAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(githubReadmeProvider),
      ),
      data: (content) {
        if (content == null || content.isEmpty) {
          return const EmptyState(
            icon: Icons.description,
            title: 'No README found',
            subtitle: 'This repository does not have a README file.',
          );
        }
        return Markdown(
          data: content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
            h1: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            h2: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            h3: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            code: TextStyle(
              color: CodeOpsColors.textPrimary,
              backgroundColor: CodeOpsColors.surfaceVariant,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            a: const TextStyle(color: CodeOpsColors.primary),
            blockquote: const TextStyle(color: CodeOpsColors.textSecondary),
            listBullet: const TextStyle(color: CodeOpsColors.textSecondary),
          ),
          padding: const EdgeInsets.all(20),
        );
      },
    );
  }
}

class _BranchesTab extends ConsumerWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(githubRepoBranchesProvider);
    final repo = ref.watch(selectedGithubRepoProvider);

    return branchesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(githubRepoBranchesProvider),
      ),
      data: (branches) {
        if (branches.isEmpty) {
          return const EmptyState(
            icon: Icons.account_tree,
            title: 'No branches',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: branches.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: CodeOpsColors.divider),
          itemBuilder: (context, index) {
            final branch = branches[index];
            final isDefault = branch.name == repo?.defaultBranch;
            return ListTile(
              dense: true,
              title: Row(
                children: [
                  Text(
                    branch.name,
                    style: TextStyle(
                      color: isDefault
                          ? CodeOpsColors.primary
                          : CodeOpsColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          isDefault ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 14, color: CodeOpsColors.primary),
                  ],
                  if (branch.isProtected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock, size: 14, color: CodeOpsColors.warning),
                  ],
                ],
              ),
              trailing: branch.sha != null
                  ? Text(
                      branch.sha!.length >= 7
                          ? branch.sha!.substring(0, 7)
                          : branch.sha!,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _PullRequestsTab extends ConsumerWidget {
  const _PullRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(githubRepoPullRequestsProvider);

    return prsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(githubRepoPullRequestsProvider),
      ),
      data: (prs) {
        if (prs.isEmpty) {
          return const EmptyState(
            icon: Icons.merge_type,
            title: 'No pull requests',
            subtitle: 'No open pull requests found.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: prs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: CodeOpsColors.divider),
          itemBuilder: (context, index) {
            final pr = prs[index];
            return ListTile(
              dense: true,
              title: Row(
                children: [
                  Text(
                    '#${pr.number}',
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pr.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (pr.authorLogin != null)
                      Text(
                        pr.authorLogin!,
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    if (pr.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _relativeDate(pr.createdAt!),
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: _prStateChip(pr),
            );
          },
        );
      },
    );
  }

  Widget _prStateChip(VcsPullRequest pr) {
    final (label, color) = pr.isMerged
        ? ('Merged', CodeOpsColors.primary)
        : pr.state == 'open'
            ? ('Open', CodeOpsColors.success)
            : ('Closed', CodeOpsColors.error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CommitsTab extends ConsumerWidget {
  const _CommitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitsAsync = ref.watch(githubRepoCommitsProvider);

    return commitsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(githubRepoCommitsProvider),
      ),
      data: (commits) {
        if (commits.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'No commits',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: commits.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: CodeOpsColors.divider),
          itemBuilder: (context, index) {
            final commit = commits[index];
            return ListTile(
              dense: true,
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: CodeOpsColors.surfaceVariant,
                    ),
                    child: Text(
                      commit.shortSha,
                      style: const TextStyle(
                        color: CodeOpsColors.primary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      commit.message.split('\n').first,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (commit.authorName != null)
                      Text(
                        commit.authorName!,
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    if (commit.date != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _relativeDate(commit.date!),
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Formats a [DateTime] as a human-readable relative time string.
String _relativeDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
  if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}
