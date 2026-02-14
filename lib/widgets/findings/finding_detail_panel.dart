/// Finding detail panel widget.
///
/// Side panel displaying all finding fields, markdown rendering,
/// and status action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/finding.dart';
import '../../services/cloud/finding_api.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../reports/markdown_renderer.dart';
import 'finding_status_actions.dart';

/// Detail panel for viewing a single finding.
class FindingDetailPanel extends ConsumerWidget {
  /// The finding to display.
  final Finding finding;

  /// The FindingApi instance.
  final FindingApi findingApi;

  /// Job ID for provider invalidation.
  final String jobId;

  /// Called to close the panel.
  final VoidCallback? onClose;

  /// Called after a status change.
  final VoidCallback? onStatusChanged;

  /// Creates a [FindingDetailPanel].
  const FindingDetailPanel({
    super.key,
    required this.finding,
    required this.findingApi,
    required this.jobId,
    this.onClose,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = CodeOpsColors.severityColors[finding.severity] ??
        CodeOpsColors.textTertiary;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          left: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.divider),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    finding.severity.displayName,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finding.title,
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: CodeOpsColors.textTertiary),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata
                  _DetailRow(label: 'Agent', value: finding.agentType.displayName),
                  _DetailRow(label: 'Status', value: finding.status.displayName),
                  if (finding.filePath != null)
                    _DetailRow(label: 'File', value: finding.filePath!),
                  if (finding.lineNumber != null)
                    _DetailRow(label: 'Line', value: '${finding.lineNumber}'),
                  if (finding.effortEstimate != null)
                    _DetailRow(
                        label: 'Effort',
                        value: finding.effortEstimate!.displayName),
                  if (finding.debtCategory != null)
                    _DetailRow(
                        label: 'Debt Category',
                        value: finding.debtCategory!.displayName),
                  if (finding.createdAt != null)
                    _DetailRow(
                        label: 'Created',
                        value: formatTimeAgo(finding.createdAt!)),

                  const SizedBox(height: 12),
                  const Divider(color: CodeOpsColors.divider, height: 1),
                  const SizedBox(height: 12),

                  // Description
                  if (finding.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MarkdownRenderer(
                      content: finding.description!,
                      shrinkWrap: true,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Recommendation
                  if (finding.recommendation != null) ...[
                    const Text(
                      'Recommendation',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MarkdownRenderer(
                      content: finding.recommendation!,
                      shrinkWrap: true,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Evidence
                  if (finding.evidence != null) ...[
                    const Text(
                      'Evidence',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MarkdownRenderer(
                      content: finding.evidence!,
                      shrinkWrap: true,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Status actions footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: CodeOpsColors.divider),
              ),
            ),
            child: FindingStatusActions(
              finding: finding,
              findingApi: findingApi,
              jobId: jobId,
              onStatusChanged: onStatusChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
