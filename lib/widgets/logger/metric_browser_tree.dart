/// Searchable metric browser tree grouped by service name.
///
/// Displays a flat list of [MetricResponse] entries grouped under
/// expandable service-name headers. A search field filters metrics
/// by name. Tapping a metric selects it and notifies via [onSelect].
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// A searchable tree/list of metrics grouped by service.
class MetricBrowserTree extends StatefulWidget {
  /// All available metrics.
  final List<MetricResponse> metrics;

  /// Currently selected metric ID.
  final String? selectedId;

  /// Called when a metric is tapped.
  final ValueChanged<MetricResponse> onSelect;

  /// Creates a [MetricBrowserTree].
  const MetricBrowserTree({
    super.key,
    required this.metrics,
    this.selectedId,
    required this.onSelect,
  });

  @override
  State<MetricBrowserTree> createState() => _MetricBrowserTreeState();
}

class _MetricBrowserTreeState extends State<MetricBrowserTree> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.metrics
        : widget.metrics
            .where(
              (m) => m.name.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    // Group by service name.
    final grouped = <String, List<MetricResponse>>{};
    for (final m in filtered) {
      grouped.putIfAbsent(m.serviceName, () => []).add(m);
    }
    final serviceNames = grouped.keys.toList()..sort();

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              hintText: 'Search metrics…',
              prefixIcon: Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Grouped metric list
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No metrics found',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final service in serviceNames) ...[
                      _ServiceHeader(name: service),
                      for (final m in grouped[service]!)
                        _MetricItem(
                          metric: m,
                          isSelected: m.id == widget.selectedId,
                          onTap: () => widget.onSelect(m),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Expandable section header for a service group.
class _ServiceHeader extends StatelessWidget {
  final String name;
  const _ServiceHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CodeOpsColors.textTertiary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// A single metric item in the tree.
class _MetricItem extends StatelessWidget {
  final MetricResponse metric;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricItem({
    required this.metric,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  _iconForType(metric.metricType),
                  size: 14,
                  color: isSelected
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? CodeOpsColors.textPrimary
                          : CodeOpsColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  metric.metricType.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(MetricType type) => switch (type) {
        MetricType.counter => Icons.add_circle_outline,
        MetricType.gauge => Icons.speed,
        MetricType.histogram => Icons.bar_chart,
        MetricType.timer => Icons.timer_outlined,
      };
}
