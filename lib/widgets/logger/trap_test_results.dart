/// Displays results of testing a log trap against historical data.
///
/// Shows match count, match percentage, evaluation window, and
/// sample matching entry IDs from a [TrapTestResult].
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// A panel that displays [TrapTestResult] data.
///
/// Renders match count, match rate percentage, evaluation window
/// timestamps, and a list of sample matching log entry IDs.
class TrapTestResults extends StatelessWidget {
  /// The test result to display.
  final TrapTestResult result;

  /// Creates a [TrapTestResults].
  const TrapTestResults({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final matchRate = result.matchPercentage;
    final rateColor = matchRate > 10
        ? CodeOpsColors.error
        : matchRate > 1
            ? CodeOpsColors.warning
            : CodeOpsColors.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header.
          const Text(
            'Test Results',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Stats row.
          Row(
            children: [
              _StatCard(
                label: 'Matches',
                value: result.matchCount.toString(),
                color: result.matchCount > 0
                    ? CodeOpsColors.warning
                    : CodeOpsColors.success,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Evaluated',
                value: result.totalEvaluated.toString(),
                color: CodeOpsColors.textSecondary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Match Rate',
                value: '${matchRate.toStringAsFixed(1)}%',
                color: rateColor,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Evaluation window.
          Text(
            'Window: ${_formatDateTime(result.evaluatedFrom)} — ${_formatDateTime(result.evaluatedTo)}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),

          // Sample matches.
          if (result.sampleMatchIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Sample Match IDs',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.sampleMatchIds.map((id) {
                final shortId =
                    id.length > 8 ? '${id.substring(0, 8)}...' : id;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: CodeOpsColors.border),
                  ),
                  child: Text(
                    shortId,
                    style: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a [DateTime] for compact display.
  String _formatDateTime(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d $h:$min';
  }
}

/// A small stat card with label and colored value.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
