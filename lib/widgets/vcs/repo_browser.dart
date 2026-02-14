/// Repository browser widget.
///
/// Displays repo cards for the selected organization with language badge,
/// star/fork counts, and clone status indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';

/// Displays repository cards for the selected GitHub org.
class RepoBrowser extends ConsumerWidget {
  /// Creates a [RepoBrowser].
  const RepoBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(selectedOrgProvider);
    if (org == null) {
      return const EmptyState(
        icon: Icons.folder_open,
        title: 'Select an Organization',
        subtitle: 'Choose an organization from the sidebar to browse repos.',
      );
    }

    final reposAsync = ref.watch(orgReposProvider(org));
    final clonedAsync = ref.watch(clonedReposProvider);
    final clonedMap = clonedAsync.valueOrNull ?? {};

    return reposAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(orgReposProvider(org)),
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return const EmptyState(
            icon: Icons.source,
            title: 'No Repositories',
            subtitle: 'This organization has no repositories.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: repos.length,
          itemBuilder: (context, index) {
            final repo = repos[index];
            final isCloned = clonedMap.containsKey(repo.fullName);
            final isSelected =
                ref.watch(selectedRepoProvider) == repo.fullName;

            return _RepoCard(
              repo: repo,
              isCloned: isCloned,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedRepoProvider.notifier).state =
                    repo.fullName;
              },
            );
          },
        );
      },
    );
  }
}

class _RepoCard extends StatelessWidget {
  final VcsRepository repo;
  final bool isCloned;
  final bool isSelected;
  final VoidCallback onTap;

  const _RepoCard({
    required this.repo,
    required this.isCloned,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? CodeOpsColors.primary.withValues(alpha: 0.12)
          : CodeOpsColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? const BorderSide(color: CodeOpsColors.primary)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (repo.isPrivate)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.lock, size: 14,
                          color: CodeOpsColors.textTertiary),
                    ),
                  Expanded(
                    child: Text(
                      repo.name,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isCloned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cloned',
                        style: TextStyle(
                          color: CodeOpsColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (repo.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  repo.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (repo.language != null) ...[
                    _LanguageBadge(language: repo.language!),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.star_border, size: 14,
                      color: CodeOpsColors.textTertiary),
                  const SizedBox(width: 2),
                  Text(
                    '${repo.stargazersCount}',
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.call_split, size: 14,
                      color: CodeOpsColors.textTertiary),
                  const SizedBox(width: 2),
                  Text(
                    '${repo.forksCount}',
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;

  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _languageColor(language),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          language,
          style: const TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static Color _languageColor(String language) => switch (language) {
        'Dart' => const Color(0xFF00B4AB),
        'Java' => const Color(0xFFB07219),
        'Kotlin' => const Color(0xFFA97BFF),
        'Python' => const Color(0xFF3572A5),
        'JavaScript' => const Color(0xFFF1E05A),
        'TypeScript' => const Color(0xFF3178C6),
        'Go' => const Color(0xFF00ADD8),
        'Rust' => const Color(0xFFDEA584),
        'Swift' => const Color(0xFFFFAC45),
        'Ruby' => const Color(0xFF701516),
        'C#' => const Color(0xFF178600),
        'C++' => const Color(0xFFF34B7D),
        _ => CodeOpsColors.textTertiary,
      };
}
