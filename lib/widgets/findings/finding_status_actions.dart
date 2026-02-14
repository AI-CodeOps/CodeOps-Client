/// Finding status action buttons.
///
/// Provides single and bulk status transition buttons for findings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/finding.dart';
import '../../providers/finding_providers.dart';
import '../../services/cloud/finding_api.dart';
import '../../theme/colors.dart';
import '../shared/confirm_dialog.dart';
import '../shared/notification_toast.dart';

/// Status actions for a single finding or bulk selection.
class FindingStatusActions extends ConsumerWidget {
  /// Single finding to act on (null for bulk mode).
  final Finding? finding;

  /// Finding IDs for bulk mode.
  final Set<String> selectedIds;

  /// The FindingApi instance.
  final FindingApi findingApi;

  /// Job ID for invalidating providers after updates.
  final String jobId;

  /// Called after a successful status update.
  final VoidCallback? onStatusChanged;

  /// Creates [FindingStatusActions].
  const FindingStatusActions({
    super.key,
    this.finding,
    this.selectedIds = const {},
    required this.findingApi,
    required this.jobId,
    this.onStatusChanged,
  });

  bool get _isBulkMode => finding == null && selectedIds.isNotEmpty;

  List<FindingStatus> get _availableStatuses {
    if (_isBulkMode) {
      return [
        FindingStatus.acknowledged,
        FindingStatus.falsePositive,
        FindingStatus.fixed,
        FindingStatus.wontFix,
      ];
    }
    final current = finding!.status;
    return FindingStatus.values
        .where((s) => s != current)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = _isBulkMode ? selectedIds.length : 1;
    final label = _isBulkMode ? '$count selected' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
        ],
        ..._availableStatuses.map((status) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _StatusButton(
                status: status,
                onPressed: () => _updateStatus(context, ref, status),
              ),
            )),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    FindingStatus newStatus,
  ) async {
    final count = _isBulkMode ? selectedIds.length : 1;
    final confirmMessage = _isBulkMode
        ? 'Change status of $count findings to ${newStatus.displayName}?'
        : 'Change status to ${newStatus.displayName}?';

    final confirmed = await showConfirmDialog(
      context,
      title: 'Update Status',
      message: confirmMessage,
    );

    if (confirmed != true) return;

    try {
      if (_isBulkMode) {
        await findingApi.bulkUpdateStatus(
          selectedIds.toList(),
          newStatus,
        );
        ref.read(selectedFindingIdsProvider.notifier).state = {};
      } else {
        await findingApi.updateFindingStatus(finding!.id, newStatus);
      }

      // Invalidate providers to refresh data
      ref.invalidate(jobFindingsProvider);
      ref.invalidate(findingSeverityCountsProvider(jobId));

      onStatusChanged?.call();

      if (context.mounted) {
        showToast(
          context,
          message: 'Status updated to ${newStatus.displayName}',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showToast(
          context,
          message: 'Failed to update status: $e',
          type: ToastType.error,
        );
      }
    }
  }
}

class _StatusButton extends StatelessWidget {
  final FindingStatus status;
  final VoidCallback onPressed;

  const _StatusButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FindingStatus.open => CodeOpsColors.textTertiary,
      FindingStatus.acknowledged => CodeOpsColors.primary,
      FindingStatus.falsePositive => CodeOpsColors.textSecondary,
      FindingStatus.fixed => CodeOpsColors.success,
      FindingStatus.wontFix => CodeOpsColors.warning,
    };

    final icon = switch (status) {
      FindingStatus.open => Icons.radio_button_unchecked,
      FindingStatus.acknowledged => Icons.visibility,
      FindingStatus.falsePositive => Icons.do_not_disturb,
      FindingStatus.fixed => Icons.check_circle_outline,
      FindingStatus.wontFix => Icons.block,
    };

    return Tooltip(
      message: status.displayName,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                status.displayName,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
