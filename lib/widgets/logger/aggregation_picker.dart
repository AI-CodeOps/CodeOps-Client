/// Aggregation function and time range picker for the metrics explorer.
///
/// Displays two compact dropdowns: one for the aggregation function
/// (AVG, SUM, MIN, MAX, COUNT, P50, P95, P99) and one for the time
/// range (5m, 15m, 1h, 6h, 24h, 7d). Notifies parent via callbacks.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Available aggregation functions.
enum AggregationFunction {
  /// Arithmetic mean.
  avg,

  /// Sum of values.
  sum,

  /// Minimum value.
  min,

  /// Maximum value.
  max,

  /// Count of data points.
  count,

  /// 50th percentile.
  p50,

  /// 95th percentile.
  p95,

  /// 99th percentile.
  p99;

  /// Human-readable display label.
  String get displayName => switch (this) {
        AggregationFunction.avg => 'AVG',
        AggregationFunction.sum => 'SUM',
        AggregationFunction.min => 'MIN',
        AggregationFunction.max => 'MAX',
        AggregationFunction.count => 'COUNT',
        AggregationFunction.p50 => 'P50',
        AggregationFunction.p95 => 'P95',
        AggregationFunction.p99 => 'P99',
      };
}

/// Available time ranges with display label and duration.
enum TimeRange {
  /// Last 5 minutes.
  m5('5m', Duration(minutes: 5)),

  /// Last 15 minutes.
  m15('15m', Duration(minutes: 15)),

  /// Last 1 hour.
  h1('1h', Duration(hours: 1)),

  /// Last 6 hours.
  h6('6h', Duration(hours: 6)),

  /// Last 24 hours.
  h24('24h', Duration(hours: 24)),

  /// Last 7 days.
  d7('7d', Duration(days: 7));

  /// Display label.
  final String label;

  /// Duration of the range.
  final Duration duration;

  const TimeRange(this.label, this.duration);
}

/// A row of compact dropdowns for aggregation and time range.
class AggregationPicker extends StatelessWidget {
  /// Currently selected aggregation function.
  final AggregationFunction aggregation;

  /// Currently selected time range.
  final TimeRange timeRange;

  /// Called when the aggregation function changes.
  final ValueChanged<AggregationFunction> onAggregationChanged;

  /// Called when the time range changes.
  final ValueChanged<TimeRange> onTimeRangeChanged;

  /// Creates an [AggregationPicker].
  const AggregationPicker({
    super.key,
    required this.aggregation,
    required this.timeRange,
    required this.onAggregationChanged,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Aggregation dropdown
        const Text(
          'Aggregation: ',
          style: TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        DropdownButton<AggregationFunction>(
          value: aggregation,
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
          ),
          underline: const SizedBox.shrink(),
          isDense: true,
          items: AggregationFunction.values
              .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.displayName),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onAggregationChanged(v);
          },
        ),
        const SizedBox(width: 16),

        // Time range dropdown
        const Text(
          'Time Range: ',
          style: TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        DropdownButton<TimeRange>(
          value: timeRange,
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
          ),
          underline: const SizedBox.shrink(),
          isDense: true,
          items: TimeRange.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onTimeRangeChanged(v);
          },
        ),
      ],
    );
  }
}
