/// Recent activity card for the home dashboard.
///
/// Displays the current user's recent jobs from [myJobsProvider],
/// showing mode icon, name, status, and relative timestamp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/qa_job.dart';
import '../../providers/job_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';

/// A card showing the current user's recent job activity.
class RecentActivity extends ConsumerWidget {
  /// Creates a [RecentActivity] widget.
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: jobsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => ErrorPanel.fromException(
                  error,
                  onRetry: () => ref.invalidate(myJobsProvider),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.history,
                      title: 'No recent activity',
                      subtitle: 'Run your first audit to get started.',
                    );
                  }
                  final items = jobs.take(8).toList();
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _ActivityItem(job: items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final JobSummary job;

  const _ActivityItem({required this.job});

  @override
  Widget build(BuildContext context) {
    final modeColor = _jobModeColor(job.mode);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(_jobModeIcon(job.mode), color: modeColor, size: 20),
      title: Text(
        job.name ?? job.mode.displayName,
        style: const TextStyle(fontSize: 13, color: CodeOpsColors.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        job.projectName ?? '',
        style: const TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(status: job.status),
          const SizedBox(width: 8),
          Text(
            formatTimeAgo(job.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _jobModeIcon(JobMode mode) => switch (mode) {
        JobMode.audit => Icons.security,
        JobMode.compliance => Icons.verified_outlined,
        JobMode.bugInvestigate => Icons.bug_report_outlined,
        JobMode.remediate => Icons.build_outlined,
        JobMode.techDebt => Icons.account_balance_outlined,
        JobMode.dependency => Icons.inventory_2_outlined,
        JobMode.healthMonitor => Icons.monitor_heart_outlined,
      };

  static Color _jobModeColor(JobMode mode) => switch (mode) {
        JobMode.audit => CodeOpsColors.primary,
        JobMode.compliance => CodeOpsColors.secondary,
        JobMode.bugInvestigate => CodeOpsColors.warning,
        JobMode.remediate => CodeOpsColors.success,
        JobMode.techDebt => CodeOpsColors.error,
        JobMode.dependency => CodeOpsColors.textSecondary,
        JobMode.healthMonitor => CodeOpsColors.success,
      };
}

class _StatusChip extends StatelessWidget {
  final JobStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = CodeOpsColors.jobStatusColors[status] ??
        CodeOpsColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
