/// Horizontal status bar for a cloned repository.
///
/// Shows branch name, clean/dirty state, ahead/behind counts,
/// and pull/push/fetch action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';

/// Horizontal bar showing the working-tree status of a repository.
class RepoStatusBar extends ConsumerWidget {
  /// The repo status to display.
  final RepoStatus status;

  /// Local path of the repository (for git operations).
  final String repoDir;

  /// Creates a [RepoStatusBar].
  const RepoStatusBar({
    super.key,
    required this.status,
    required this.repoDir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Row(
        children: [
          // Branch name.
          const Icon(Icons.call_split, size: 16,
              color: CodeOpsColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            status.branch,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          // Clean/dirty indicator.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status.isClean
                  ? CodeOpsColors.success.withValues(alpha: 0.12)
                  : CodeOpsColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.isClean
                  ? 'Clean'
                  : '${status.changes.length} change${status.changes.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: status.isClean
                    ? CodeOpsColors.success
                    : CodeOpsColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ahead/behind.
          if (status.ahead > 0) ...[
            const Icon(Icons.arrow_upward, size: 14,
                color: CodeOpsColors.success),
            const SizedBox(width: 2),
            Text(
              '${status.ahead}',
              style: const TextStyle(
                color: CodeOpsColors.success,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (status.behind > 0) ...[
            const Icon(Icons.arrow_downward, size: 14,
                color: CodeOpsColors.warning),
            const SizedBox(width: 2),
            Text(
              '${status.behind}',
              style: const TextStyle(
                color: CodeOpsColors.warning,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          // Action buttons.
          _ActionButton(
            icon: Icons.download,
            label: 'Fetch',
            onPressed: () async {
              final gitService = ref.read(gitServiceProvider);
              await gitService.fetchAll(repoDir);
              ref.invalidate(selectedRepoStatusProvider);
            },
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.arrow_downward,
            label: 'Pull',
            onPressed: () async {
              final gitService = ref.read(gitServiceProvider);
              await gitService.pull(repoDir);
              ref.invalidate(selectedRepoStatusProvider);
            },
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.arrow_upward,
            label: 'Push',
            onPressed: status.ahead > 0
                ? () async {
                    final gitService = ref.read(gitServiceProvider);
                    await gitService.push(repoDir);
                    ref.invalidate(selectedRepoStatusProvider);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SizedBox(
        height: 28,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: CodeOpsColors.textSecondary,
            disabledForegroundColor:
                CodeOpsColors.textTertiary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
