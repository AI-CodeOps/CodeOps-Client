/// Stats tab for the container detail page.
///
/// Displays real-time resource usage gauges for CPU, memory, network I/O,
/// block I/O, and PID count. Uses [FleetResourceGauges.colorForPercent]
/// for threshold-based coloring. Auto-refreshes every 3 seconds via a
/// [Timer.periodic] when the tab is active.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/file_utils.dart';
import 'fleet_resource_gauges.dart';

/// Displays real-time container resource statistics with auto-refresh.
class ContainerStatsTab extends ConsumerStatefulWidget {
  /// The team ID owning the container.
  final String teamId;

  /// The container ID to fetch stats for.
  final String containerId;

  /// Creates a [ContainerStatsTab].
  const ContainerStatsTab({
    super.key,
    required this.teamId,
    required this.containerId,
  });

  @override
  ConsumerState<ContainerStatsTab> createState() => _ContainerStatsTabState();
}

class _ContainerStatsTabState extends ConsumerState<ContainerStatsTab> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(fleetContainerStatsProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = (teamId: widget.teamId, containerId: widget.containerId);
    final statsAsync = ref.watch(fleetContainerStatsProvider(params));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load stats',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(fleetContainerStatsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (stats) => _buildStatsView(stats),
    );
  }

  /// Builds the stats display with all resource gauges.
  Widget _buildStatsView(FleetContainerStats stats) {
    final cpuPercent = (stats.cpuPercent ?? 0) / 100;
    final memUsage = stats.memoryUsageBytes ?? 0;
    final memLimit = stats.memoryLimitBytes ?? 1;
    final memPercent = memLimit > 0 ? memUsage / memLimit : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CPU & Memory gauges
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resource Usage', style: CodeOpsTypography.titleMedium),
                const SizedBox(height: 16),
                _GaugeRow(
                  label: 'CPU',
                  percent: cpuPercent,
                  detail:
                      '${(stats.cpuPercent ?? 0).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 12),
                _GaugeRow(
                  label: 'Memory',
                  percent: memPercent,
                  detail:
                      '${formatFileSize(memUsage)} / ${formatFileSize(memLimit)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Network & Block I/O
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I/O', style: CodeOpsTypography.titleMedium),
                const SizedBox(height: 16),
                _StatRow(
                  label: 'Network RX',
                  value: formatFileSize(stats.networkRxBytes ?? 0),
                ),
                _StatRow(
                  label: 'Network TX',
                  value: formatFileSize(stats.networkTxBytes ?? 0),
                ),
                _StatRow(
                  label: 'Block Read',
                  value: formatFileSize(stats.blockReadBytes ?? 0),
                ),
                _StatRow(
                  label: 'Block Write',
                  value: formatFileSize(stats.blockWriteBytes ?? 0),
                ),
                _StatRow(
                  label: 'PIDs',
                  value: '${stats.pids ?? 0}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeRow extends StatelessWidget {
  final String label;
  final double percent;
  final String detail;

  const _GaugeRow({
    required this.label,
    required this.percent,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final color = FleetResourceGauges.colorForPercent(clamped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            Text(detail,
                style: const TextStyle(
                    color: CodeOpsColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: CodeOpsColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: CodeOpsTypography.bodySmall
                  .copyWith(color: CodeOpsColors.textTertiary)),
          Text(value, style: CodeOpsTypography.bodyMedium),
        ],
      ),
    );
  }
}
