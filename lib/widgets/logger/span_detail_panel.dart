/// Detail panel for a selected trace span.
///
/// Shows span metadata including service name, operation, duration, status,
/// timing information, and parsed tags. Displayed alongside the waterfall
/// timeline in the trace detail page.
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Displays metadata for a selected [WaterfallSpan].
class SpanDetailPanel extends StatelessWidget {
  /// The span to display.
  final WaterfallSpan span;

  /// Creates a [SpanDetailPanel].
  const SpanDetailPanel({super.key, required this.span});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(left: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: CodeOpsColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: CodeOpsColors.primary),
                SizedBox(width: 8),
                Text(
                  'Span Detail',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Body.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Operation', value: span.operationName),
                  _DetailRow(label: 'Service', value: span.serviceName),
                  _DetailRow(
                    label: 'Duration',
                    value: _formatDuration(span.durationMs),
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: span.status.displayName,
                    valueColor: span.status == SpanStatus.error
                        ? CodeOpsColors.error
                        : CodeOpsColors.success,
                  ),
                  _DetailRow(
                    label: 'Offset',
                    value: '${span.offsetMs}ms from trace start',
                  ),
                  _DetailRow(label: 'Span ID', value: span.spanId),
                  if (span.parentSpanId != null)
                    _DetailRow(
                        label: 'Parent Span', value: span.parentSpanId!),
                  _DetailRow(label: 'Depth', value: '${span.depth}'),
                  if (span.statusMessage != null &&
                      span.statusMessage!.isNotEmpty)
                    _DetailRow(
                        label: 'Status Message',
                        value: span.statusMessage!),
                  if (span.relatedLogIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Related Log Entries',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...span.relatedLogIds.map(
                      (id) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          id,
                          style: const TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats milliseconds into a human-readable string.
  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}m';
  }
}

/// A label–value row used in the span detail panel.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? CodeOpsColors.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
