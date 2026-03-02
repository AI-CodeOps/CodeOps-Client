/// Metrics explorer page — browse, visualize, and aggregate metric data.
///
/// **Layout:** Three-column: Logger sidebar, metric browser (left pane),
/// chart + data table (right pane). The left pane contains a searchable
/// metric tree grouped by service and a metric detail panel. The right
/// pane has the fl_chart time-series visualization, aggregation/time
/// range pickers, overlay controls, and a raw data table.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/aggregation_picker.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/logger/metric_browser_tree.dart';
import '../../widgets/logger/metric_chart.dart';
import '../../widgets/logger/metric_detail_panel.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The metrics explorer page.
class MetricsExplorerPage extends ConsumerStatefulWidget {
  /// Creates a [MetricsExplorerPage].
  const MetricsExplorerPage({super.key});

  @override
  ConsumerState<MetricsExplorerPage> createState() =>
      _MetricsExplorerPageState();
}

class _MetricsExplorerPageState extends ConsumerState<MetricsExplorerPage> {
  MetricResponse? _selectedMetric;
  MetricTimeSeriesResponse? _timeSeries;
  final List<MetricTimeSeriesResponse> _overlays = [];
  AggregationFunction _aggregation = AggregationFunction.avg;
  TimeRange _timeRange = TimeRange.h1;
  Timer? _autoRefreshTimer;
  bool _loading = false;

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadTimeSeries(),
    );
  }

  Future<void> _loadTimeSeries() async {
    if (_selectedMetric == null) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(loggerApiProvider);
      final end = DateTime.now().toUtc();
      final start = end.subtract(_timeRange.duration);

      final ts = await api.getMetricTimeSeries(
        _selectedMetric!.id,
        startTime: start,
        endTime: end,
      );
      if (mounted) setState(() => _timeSeries = ts);
    } catch (_) {
      // Silently fail on auto-refresh; error will show in chart.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectMetric(MetricResponse metric) {
    setState(() {
      _selectedMetric = metric;
      _timeSeries = null;
      _overlays.clear();
    });
    _loadTimeSeries();
    _startAutoRefresh();
  }

  Future<void> _addOverlay(List<MetricResponse> metrics) async {
    final choices = metrics
        .where((m) =>
            m.id != _selectedMetric?.id &&
            !_overlays.any((o) => o.metricId == m.id))
        .toList();

    if (choices.isEmpty) return;

    final picked = await showDialog<MetricResponse>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(
          'Overlay Metric',
          style: TextStyle(color: CodeOpsColors.textPrimary),
        ),
        backgroundColor: CodeOpsColors.surface,
        children: choices
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(m),
                  child: Text(
                    '${m.serviceName} / ${m.name}',
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;

    final api = ref.read(loggerApiProvider);
    final end = DateTime.now().toUtc();
    final start = end.subtract(_timeRange.duration);
    final ts = await api.getMetricTimeSeries(
      picked.id,
      startTime: start,
      endTime: end,
    );
    if (mounted) setState(() => _overlays.add(ts));
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return Row(
        children: [
          const LoggerSidebar(),
          const VerticalDivider(width: 1, color: CodeOpsColors.border),
          const Expanded(
            child: EmptyState(
              icon: Icons.group_off,
              title: 'No team selected',
              subtitle: 'Select a team to explore metrics.',
            ),
          ),
        ],
      );
    }

    final metricsAsync = ref.watch(loggerMetricsProvider);

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: metricsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => ErrorPanel(
                    title: 'Failed to load metrics',
                    message: err.toString(),
                  ),
                  data: (metrics) => _buildBody(metrics),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Top toolbar.
  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Metrics Explorer',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(loggerMetricsProvider);
              _loadTimeSeries();
            },
          ),
        ],
      ),
    );
  }

  /// Main body: left browser + right chart/table.
  Widget _buildBody(List<MetricResponse> metrics) {
    return Row(
      children: [
        // Left pane: metric browser + detail
        SizedBox(
          width: 280,
          child: Column(
            children: [
              Expanded(
                child: MetricBrowserTree(
                  metrics: metrics,
                  selectedId: _selectedMetric?.id,
                  onSelect: _selectMetric,
                ),
              ),
              if (_selectedMetric != null)
                MetricDetailPanel(
                  metric: _selectedMetric!,
                  latestValue: _timeSeries?.dataPoints.isNotEmpty == true
                      ? _timeSeries!.dataPoints.last.value
                      : null,
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),

        // Right pane: chart + controls + data table
        Expanded(
          child: _selectedMetric == null
              ? const Center(
                  child: Text(
                    'Select a metric to visualize',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Aggregation + time range bar
                    Container(
                      height: 40,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: CodeOpsColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AggregationPicker(
                              aggregation: _aggregation,
                              timeRange: _timeRange,
                              onAggregationChanged: (v) {
                                setState(() => _aggregation = v);
                              },
                              onTimeRangeChanged: (v) {
                                setState(() => _timeRange = v);
                                _loadTimeSeries();
                              },
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Overlay Metric'),
                            style: TextButton.styleFrom(
                              textStyle:
                                  const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _addOverlay(metrics),
                          ),
                        ],
                      ),
                    ),

                    // Chart area
                    Expanded(
                      flex: 3,
                      child: _loading && _timeSeries == null
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : MetricChart(
                              series: _timeSeries,
                              overlays: _overlays,
                            ),
                    ),

                    // Data table
                    const Divider(
                        height: 1, color: CodeOpsColors.border),
                    Expanded(
                      flex: 2,
                      child: _buildDataTable(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Raw data table showing time-series points.
  Widget _buildDataTable() {
    final points = _timeSeries?.dataPoints ?? [];
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'No data points',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 12,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 28,
        columnSpacing: 24,
        columns: const [
          DataColumn(
            label: Text(
              'Time',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Value',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            numeric: true,
          ),
        ],
        rows: points.reversed
            .take(50)
            .map(
              (dp) => DataRow(cells: [
                DataCell(Text(
                  DateFormat('HH:mm:ss').format(dp.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textPrimary,
                  ),
                )),
                DataCell(Text(
                  dp.value == dp.value.roundToDouble()
                      ? dp.value.toInt().toString()
                      : dp.value.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                )),
              ]),
            )
            .toList(),
      ),
    );
  }
}
