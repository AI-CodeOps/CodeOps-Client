/// Sidebar for the GitHub Browser master-detail layout.
///
/// Contains an org picker dropdown, a search field, and a scrollable
/// list of repositories for the selected organization.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';

/// Left-panel sidebar showing org picker, search, and repo list.
class RepoSidebar extends ConsumerStatefulWidget {
  /// Creates a [RepoSidebar].
  const RepoSidebar({super.key});

  @override
  ConsumerState<RepoSidebar> createState() => _RepoSidebarState();
}

class _RepoSidebarState extends ConsumerState<RepoSidebar> {
  @override
  void initState() {
    super.initState();
    // Auto-select first org when orgs load and none is selected.
    ref.listenManual(githubOrgsProvider, (_, next) {
      next.whenData((orgs) {
        if (orgs.isNotEmpty && ref.read(selectedGithubOrgProvider) == null) {
          ref.read(selectedGithubOrgProvider.notifier).state = orgs.first;
        }
      });
    });
    // Auto-select first repo when repos load and none is selected.
    ref.listenManual(githubReposForOrgProvider, (_, next) {
      next.whenData((repos) {
        if (repos.isNotEmpty && ref.read(selectedGithubRepoProvider) == null) {
          ref.read(selectedGithubRepoProvider.notifier).state = repos.first;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        children: [
          const _OrgPicker(),
          const _SearchBar(),
          const Divider(height: 1, color: CodeOpsColors.divider),
          const Expanded(child: _RepoList()),
        ],
      ),
    );
  }
}

class _OrgPicker extends ConsumerWidget {
  const _OrgPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(githubOrgsProvider);
    final selectedOrg = ref.watch(selectedGithubOrgProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: orgsAsync.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CodeOpsColors.primary,
              ),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (orgs) {
          if (orgs.isEmpty) return const SizedBox.shrink();
          return DropdownButtonFormField<VcsOrganization>(
            initialValue: selectedOrg,
            isExpanded: true,
            dropdownColor: CodeOpsColors.surfaceVariant,
            decoration: InputDecoration(
              filled: true,
              fillColor: CodeOpsColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: orgs
                .map((org) => DropdownMenuItem<VcsOrganization>(
                      value: org,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: CodeOpsColors.surfaceVariant,
                            backgroundImage: org.avatarUrl != null
                                ? NetworkImage(org.avatarUrl!)
                                : null,
                            child: org.avatarUrl == null
                                ? Text(
                                    org.login[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: CodeOpsColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              org.name ?? org.login,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CodeOpsColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (org) {
              if (org == null) return;
              ref.read(selectedGithubOrgProvider.notifier).state = org;
              ref.read(selectedGithubRepoProvider.notifier).state = null;
              ref.read(githubRepoSearchQueryProvider.notifier).state = '';
            },
          );
        },
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _controller,
        style: const TextStyle(
          color: CodeOpsColors.textPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Search repositories...',
          hintStyle: const TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: CodeOpsColors.textTertiary,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _controller.clear();
                    ref.read(githubRepoSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: CodeOpsColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (value) {
          ref.read(githubRepoSearchQueryProvider.notifier).state = value;
          setState(() {}); // Rebuild to show/hide clear button.
        },
      ),
    );
  }
}

class _RepoList extends ConsumerWidget {
  const _RepoList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredGithubReposProvider);
    final selectedRepo = ref.watch(selectedGithubRepoProvider);

    return filteredAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(githubReposForOrgProvider),
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox,
            title: 'No repositories',
            subtitle: 'No repositories match your search.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: repos.length,
          itemBuilder: (context, index) {
            final repo = repos[index];
            final isSelected = selectedRepo?.fullName == repo.fullName;
            return _RepoListItem(
              repo: repo,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedGithubRepoProvider.notifier).state = repo;
                ref.read(githubDetailTabProvider.notifier).state = 0;
              },
            );
          },
        );
      },
    );
  }
}

class _RepoListItem extends StatelessWidget {
  final VcsRepository repo;
  final bool isSelected;
  final VoidCallback onTap;

  const _RepoListItem({
    required this.repo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected ? CodeOpsColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
          color: isSelected
              ? CodeOpsColors.primary.withValues(alpha: 0.08)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (repo.isPrivate)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.lock,
                      size: 14,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    repo.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? CodeOpsColors.primary
                          : CodeOpsColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (repo.description != null && repo.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                repo.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (repo.language != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _languageColor(repo.language!),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    repo.language!,
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Icon(
                  Icons.star_outline,
                  size: 13,
                  color: CodeOpsColors.textTertiary,
                ),
                const SizedBox(width: 2),
                Text(
                  '${repo.stargazersCount}',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _languageColor(String language) {
    return switch (language.toLowerCase()) {
      'dart' => const Color(0xFF00B4AB),
      'java' => const Color(0xFFB07219),
      'kotlin' => const Color(0xFFA97BFF),
      'javascript' => const Color(0xFFF1E05A),
      'typescript' => const Color(0xFF3178C6),
      'python' => const Color(0xFF3572A5),
      'go' => const Color(0xFF00ADD8),
      'rust' => const Color(0xFFDEA584),
      'c#' => const Color(0xFF178600),
      'c++' => const Color(0xFFF34B7D),
      'swift' => const Color(0xFFFFAC45),
      'ruby' => const Color(0xFF701516),
      'php' => const Color(0xFF4F5D95),
      'html' => const Color(0xFFE34C26),
      'css' => const Color(0xFF563D7C),
      'shell' => const Color(0xFF89E051),
      _ => CodeOpsColors.textTertiary,
    };
  }
}
