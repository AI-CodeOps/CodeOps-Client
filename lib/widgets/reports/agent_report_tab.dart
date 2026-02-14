/// Agent report tab widget.
///
/// Lazy-loads a single agent's report from S3 via [agentReportMarkdownProvider]
/// and renders it with [MarkdownRenderer].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agent_run.dart';
import '../../models/enums.dart';
import '../../providers/report_providers.dart';
import '../../theme/colors.dart';
import '../shared/error_panel.dart';
import 'markdown_renderer.dart';

/// Displays a single agent's detailed report.
class AgentReportTab extends ConsumerWidget {
  /// The agent run to display.
  final AgentRun agentRun;

  /// Creates an [AgentReportTab].
  const AgentReportTab({super.key, required this.agentRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show metadata header
    final resultColor = switch (agentRun.result) {
      AgentResult.pass => CodeOpsColors.success,
      AgentResult.warn => CodeOpsColors.warning,
      AgentResult.fail => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agent metadata header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: resultColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: resultColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resultColor.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    '${agentRun.score ?? "-"}',
                    style: TextStyle(
                      color: resultColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentRun.agentType.displayName,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${agentRun.result?.displayName ?? "N/A"} · '
                      '${agentRun.findingsCount ?? 0} findings',
                      style: const TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (agentRun.criticalCount != null && agentRun.criticalCount! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.critical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${agentRun.criticalCount} critical',
                    style: const TextStyle(
                      color: CodeOpsColors.critical,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Report content
        if (agentRun.reportS3Key != null)
          Expanded(
            child: _ReportContent(s3Key: agentRun.reportS3Key!),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'No detailed report available',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportContent extends ConsumerWidget {
  final String s3Key;

  const _ReportContent({required this.s3Key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(agentReportMarkdownProvider(s3Key));

    return reportAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => ErrorPanel.fromException(e,
          onRetry: () => ref.invalidate(agentReportMarkdownProvider(s3Key))),
      data: (content) => MarkdownRenderer(
        content: content,
        selectable: true,
        padding: const EdgeInsets.all(0),
      ),
    );
  }
}
