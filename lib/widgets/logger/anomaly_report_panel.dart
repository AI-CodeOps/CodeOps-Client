/// Panel displaying anomaly detection report results.
///
/// Shows summary statistics, a list of detected anomalies with
/// status badges, and z-score values for each baseline check.
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Displays an [AnomalyReportResponse] with anomaly highlights.
class AnomalyReportPanel extends StatelessWidget {
  /// The anomaly report.
  final AnomalyReportResponse report;

  /// Creates an [AnomalyReportPanel].
  const AnomalyReportPanel({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: CodeOpsColors.surface,
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              _SummaryChip(
                label: 'Baselines',
                value: '${report.totalBaselines}',
              ),
              const SizedBox(width: 24),
              _SummaryChip(
                label: 'Anomalies',
                value: '${report.anomaliesDetected}',
                valueColor: report.anomaliesDetected > 0
                    ? CodeOpsColors.error
                    : CodeOpsColors.success,
              ),
              const SizedBox(width: 24),
              _SummaryChip(
                label: 'Checks',
                value: '${report.allChecks.length}',
              ),
            ],
          ),
        ),

        // Anomaly list.
        Expanded(
          child: report.allChecks.isEmpty
              ? const Center(
                  child: Text(
                    'No baseline checks available',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: report.allChecks.length,
                  itemBuilder: (ctx, i) {
                    final check = report.allChecks[i];
                    return _CheckRow(check: check);
                  },
                ),
        ),
      ],
    );
  }
}

/// A single anomaly check result row.
class _CheckRow extends StatelessWidget {
  final AnomalyCheckResponse check;

  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: check.isAnomaly
            ? CodeOpsColors.error.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: check.isAnomaly
              ? CodeOpsColors.error.withValues(alpha: 0.3)
              : CodeOpsColors.border,
        ),
      ),
      child: Row(
        children: [
          // Status badge.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: check.isAnomaly
                  ? CodeOpsColors.error.withValues(alpha: 0.2)
                  : CodeOpsColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              check.isAnomaly ? 'ANOMALY' : 'NORMAL',
              style: TextStyle(
                color: check.isAnomaly
                    ? CodeOpsColors.error
                    : CodeOpsColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Service / metric.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${check.serviceName} / ${check.metricName}',
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Current: ${check.currentValue.toStringAsFixed(2)} '
                  '(baseline: ${check.baselineValue.toStringAsFixed(2)})',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Z-score.
          Text(
            'z=${check.zScore.toStringAsFixed(2)}',
            style: TextStyle(
              color: check.isAnomaly
                  ? CodeOpsColors.error
                  : CodeOpsColors.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),

          // Direction.
          if (check.isAnomaly)
            Icon(
              check.direction == 'above'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: CodeOpsColors.error,
            ),
        ],
      ),
    );
  }
}

/// A summary chip showing label and value.
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? CodeOpsColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
