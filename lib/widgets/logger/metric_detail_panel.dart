/// Metric detail panel — displays metadata for the selected metric.
///
/// Shows metric name, type badge, service name, unit, description,
/// and latest value. Used in the left pane of the metrics explorer below
/// the metric browser tree.
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Displays metadata for a single metric.
class MetricDetailPanel extends StatelessWidget {
  /// The metric to display details for.
  final MetricResponse metric;

  /// Optional latest value to show.
  final double? latestValue;

  /// Creates a [MetricDetailPanel].
  const MetricDetailPanel({
    super.key,
    required this.metric,
    this.latestValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Metric Detail',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Metric name
          Text(
            metric.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Type',
            value: metric.metricType.displayName,
          ),
          _DetailRow(label: 'Service', value: metric.serviceName),
          if (metric.unit != null && metric.unit!.isNotEmpty)
            _DetailRow(label: 'Unit', value: metric.unit!),
          if (latestValue != null)
            _DetailRow(
              label: 'Latest',
              value: _formatLatest(latestValue!, metric.unit),
            ),
          if (metric.description != null &&
              metric.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              metric.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatLatest(double value, String? unit) {
    final formatted =
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(2);
    if (unit != null && unit.isNotEmpty) return '$formatted $unit';
    return formatted;
  }
}

/// A single label–value row in the detail panel.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
