// Fleet status summary for the unified dashboard.
//
// Shows container counts, CPU/memory usage, and unhealthy alerts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';

/// Compact fleet status summary for the home dashboard.
class FleetStatusSummary extends ConsumerWidget {
  /// Creates a [FleetStatusSummary].
  const FleetStatusSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = ref.watch(selectedTeamIdProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_outlined, size: 18, color: CodeOpsColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Fleet Status',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/fleet'),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: CodeOpsColors.primary,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                      decorationColor: CodeOpsColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (teamId == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No team selected',
                  style: TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            _FleetContent(teamId: teamId),
        ],
      ),
    );
  }
}

class _FleetContent extends ConsumerWidget {
  final String teamId;

  const _FleetContent({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(fleetHealthSummaryProvider(teamId));

    return healthAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CodeOpsColors.primary,
            ),
          ),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Failed to load fleet status',
          style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (summary) {
        final running = summary.runningContainers ?? 0;
        final stopped = summary.stoppedContainers ?? 0;
        final unhealthy = summary.unhealthyContainers ?? 0;
        final total = summary.totalContainers ?? 0;
        final cpuPercent = summary.totalCpuPercent ?? 0.0;
        final memBytes = summary.totalMemoryBytes ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container counts row.
            Row(
              children: [
                _CountBadge(
                  label: 'Running',
                  count: running,
                  color: CodeOpsColors.success,
                ),
                const SizedBox(width: 12),
                _CountBadge(
                  label: 'Stopped',
                  count: stopped,
                  color: CodeOpsColors.textTertiary,
                ),
                const SizedBox(width: 12),
                _CountBadge(
                  label: 'Unhealthy',
                  count: unhealthy,
                  color: unhealthy > 0
                      ? CodeOpsColors.error
                      : CodeOpsColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // CPU + Memory gauges.
            Row(
              children: [
                Expanded(
                  child: _MiniGauge(
                    label: 'CPU',
                    value: cpuPercent / 100,
                    displayValue: '${cpuPercent.toStringAsFixed(1)}%',
                    color: cpuPercent > 80
                        ? CodeOpsColors.error
                        : cpuPercent > 60
                            ? CodeOpsColors.warning
                            : CodeOpsColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MiniGauge(
                    label: 'Memory',
                    value: total > 0 ? (memBytes / (total * 512 * 1024 * 1024)).clamp(0.0, 1.0) : 0.0,
                    displayValue: _formatBytes(memBytes),
                    color: CodeOpsColors.secondary,
                  ),
                ),
              ],
            ),
            // Unhealthy alert.
            if (unhealthy > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: CodeOpsColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: CodeOpsColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: CodeOpsColors.error),
                    const SizedBox(width: 6),
                    Text(
                      '$unhealthy unhealthy container${unhealthy > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: CodeOpsColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _MiniGauge extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final Color color;

  const _MiniGauge({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: CodeOpsColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
