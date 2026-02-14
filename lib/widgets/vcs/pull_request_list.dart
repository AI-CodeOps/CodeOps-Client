/// Pull request list widget.
///
/// Shows open/closed tabs, PR cards with status icons,
/// and a "Create PR" button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';
import 'create_pr_dialog.dart';

/// Displays pull requests for a repository.
class PullRequestList extends ConsumerWidget {
  /// Full name (owner/repo) of the repository.
  final String repoFullName;

  /// Creates a [PullRequestList].
  const PullRequestList({super.key, required this.repoFullName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(repoPullRequestsProvider(repoFullName));

    return Column(
      children: [
        // Header with Create PR button.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Pull Requests',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) =>
                        CreatePRDialog(repoFullName: repoFullName),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create PR', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(color: CodeOpsColors.border, height: 1),
        Expanded(
          child: prsAsync.when(
            loading: () => const Center(
              child:
                  CircularProgressIndicator(color: CodeOpsColors.primary),
            ),
            error: (error, _) => ErrorPanel.fromException(
              error,
              onRetry: () =>
                  ref.invalidate(repoPullRequestsProvider(repoFullName)),
            ),
            data: (prs) {
              if (prs.isEmpty) {
                return const EmptyState(
                  icon: Icons.merge_type,
                  title: 'No Pull Requests',
                  subtitle: 'No open pull requests for this repository.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: prs.length,
                itemBuilder: (context, index) =>
                    _PRTile(pr: prs[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PRTile extends StatelessWidget {
  final VcsPullRequest pr;

  const _PRTile({required this.pr});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        _statusIcon,
        size: 20,
        color: _statusColor,
      ),
      title: Text(
        '#${pr.number} ${pr.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: CodeOpsColors.textPrimary,
          fontSize: 13,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            '${pr.headBranch} \u2192 ${pr.baseBranch}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
          if (pr.authorLogin != null) ...[
            const Text(' \u00B7 ',
                style: TextStyle(
                    color: CodeOpsColors.textTertiary, fontSize: 11)),
            Text(
              pr.authorLogin!,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
          if (pr.isDraft) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: CodeOpsColors.textTertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Draft',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _statusIcon {
    if (pr.isMerged) return Icons.merge;
    if (pr.state == 'closed') return Icons.cancel_outlined;
    return Icons.merge_type;
  }

  Color get _statusColor {
    if (pr.isMerged) return const Color(0xFF8B5CF6);
    if (pr.state == 'closed') return CodeOpsColors.error;
    return CodeOpsColors.success;
  }
}
