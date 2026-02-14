/// Commit history timeline widget.
///
/// Displays commits with short SHA, message, author, and relative time.
/// Supports both local (git log) and remote (GitHub API) sources.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';

/// Displays a commit timeline for a repository.
class CommitHistory extends ConsumerWidget {
  /// Full name (owner/repo) of the repository.
  final String repoFullName;

  /// Creates a [CommitHistory].
  const CommitHistory({super.key, required this.repoFullName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitsAsync = ref.watch(repoCommitsProvider(repoFullName));

    return commitsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(repoCommitsProvider(repoFullName)),
      ),
      data: (commits) {
        if (commits.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'No Commits',
            subtitle: 'No commit history found for this repository.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: commits.length,
          itemBuilder: (context, index) =>
              _CommitTile(commit: commits[index]),
        );
      },
    );
  }
}

class _CommitTile extends StatelessWidget {
  final VcsCommit commit;

  const _CommitTile({required this.commit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot.
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: CodeOpsColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SHA + message.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        commit.shortSha,
                        style: const TextStyle(
                          color: CodeOpsColors.secondary,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        commit.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CodeOpsColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Author + time.
                Row(
                  children: [
                    if (commit.authorName != null)
                      Text(
                        commit.authorName!,
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    if (commit.date != null) ...[
                      const Text(
                        ' \u00B7 ',
                        style: TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _relativeTime(commit.date!),
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}
