/// Ecosystem topology viewer page.
///
/// Displays a full ecosystem map with service nodes, dependency edges,
/// solution cluster groupings, filterable by type/health/solution,
/// with statistics sidebar, zoom/pan controls, and legend.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/topology_canvas.dart';
import '../../widgets/registry/topology_filter_bar.dart';
import '../../widgets/registry/topology_legend.dart';
import '../../widgets/registry/topology_stats_panel.dart';
import '../../widgets/shared/error_panel.dart';

/// Ecosystem topology page.
///
/// Watches [registryTopologyProvider] for topology data and
/// [registryEcosystemStatsProvider] for statistics. Provides
/// filter controls, stats panel toggle, and an interactive canvas.
class TopologyPage extends ConsumerWidget {
  /// Creates a [TopologyPage].
  const TopologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topologyAsync = ref.watch(registryTopologyProvider);

    return Column(
      children: [
        _HeaderBar(),
        Expanded(
          child: topologyAsync.when(
            data: (topology) {
              if (topology == null) {
                return const Center(
                  child: Text(
                    'Select a team to view topology.',
                    style: TextStyle(
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                );
              }
              return _TopologyContent(topology: topology);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel(
              title: 'Failed to Load Topology',
              message: e.toString(),
              onRetry: () => ref.invalidate(registryTopologyProvider),
            ),
          ),
        ),
        const TopologyLegend(),
      ],
    );
  }
}

/// Header bar with title and stats toggle.
class _HeaderBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showStats = ref.watch(topologyStatsPanelVisibleProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Ecosystem Topology',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(topologyStatsPanelVisibleProvider.notifier).state =
                  !showStats;
            },
            icon: Icon(
              showStats
                  ? Icons.bar_chart
                  : Icons.bar_chart_outlined,
              size: 16,
            ),
            label: const Text('Stats'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main topology content with filter bar, optional stats sidebar, and canvas.
class _TopologyContent extends ConsumerWidget {
  final TopologyResponse topology;

  const _TopologyContent({required this.topology});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showStats = ref.watch(topologyStatsPanelVisibleProvider);
    final statsAsync = ref.watch(registryEcosystemStatsProvider);
    final visibleNodeIds = ref.watch(visibleTopologyNodeIdsProvider);
    final selectedNodeId = ref.watch(selectedTopologyNodeProvider);

    return Column(
      children: [
        TopologyFilterBar(
          solutionGroups: topology.solutionGroups ?? [],
        ),
        Expanded(
          child: Row(
            children: [
              // Stats sidebar
              if (showStats && statsAsync.valueOrNull != null)
                TopologyStatsPanel(stats: statsAsync.valueOrNull!),
              // Canvas
              Expanded(
                child: TopologyCanvas(
                  topology: topology,
                  visibleNodeIds: visibleNodeIds,
                  selectedNodeId: selectedNodeId,
                  onNodeTap: (node) {
                    final current =
                        ref.read(selectedTopologyNodeProvider);
                    ref
                        .read(selectedTopologyNodeProvider.notifier)
                        .state =
                        current == node.serviceId
                            ? null
                            : node.serviceId;
                  },
                  onNodeDoubleTap: (node) {
                    context.go('/registry/services/${node.serviceId}');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
