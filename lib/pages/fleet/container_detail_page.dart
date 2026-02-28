/// Container detail page with tabbed navigation.
///
/// Shows five tabs: Overview, Logs, Stats, Health, and Exec.
/// Uses [FleetContainerDetail] from the detail provider for the
/// overview and passes the container ID to child tab widgets for
/// their own data fetching.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fleet_enums.dart';
import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/fleet/container_exec_tab.dart';
import '../../widgets/fleet/container_health_tab.dart';
import '../../widgets/fleet/container_logs_tab.dart';
import '../../widgets/fleet/container_overview_tab.dart';
import '../../widgets/fleet/container_stats_tab.dart';
import '../../widgets/shared/confirm_dialog.dart';

/// Detail page for a single container with 5 tabs.
class ContainerDetailPage extends ConsumerStatefulWidget {
  /// The container ID to display.
  final String containerId;

  /// Creates a [ContainerDetailPage].
  const ContainerDetailPage({super.key, required this.containerId});

  @override
  ConsumerState<ContainerDetailPage> createState() =>
      _ContainerDetailPageState();
}

class _ContainerDetailPageState extends ConsumerState<ContainerDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  bool _isCheckRunning = false;
  int _logTailLines = 100;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const Center(
        child: Text('No team selected',
            style: TextStyle(color: CodeOpsColors.textSecondary)),
      );
    }

    final params = (teamId: teamId, containerId: widget.containerId);
    final detailAsync = ref.watch(fleetContainerDetailProvider(params));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Something Went Wrong',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(fleetContainerDetailProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (detail) => _buildContent(teamId, detail),
    );
  }

  /// Builds the page content with header and tabbed body.
  Widget _buildContent(String teamId, FleetContainerDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(detail),
        _buildTabBar(),
        Expanded(child: _buildTabBarView(teamId, detail)),
      ],
    );
  }

  /// Builds the page header with container name and status.
  Widget _buildHeader(FleetContainerDetail detail) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Text(
            detail.containerName ?? 'Container',
            style: CodeOpsTypography.titleLarge,
          ),
          const SizedBox(width: 12),
          Text(
            '${detail.imageName ?? ""}:${detail.imageTag ?? "latest"}',
            style: CodeOpsTypography.bodySmall
                .copyWith(color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }

  /// Builds the tab bar.
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: CodeOpsColors.primary,
        unselectedLabelColor: CodeOpsColors.textSecondary,
        indicatorColor: CodeOpsColors.primary,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Logs'),
          Tab(text: 'Stats'),
          Tab(text: 'Health'),
          Tab(text: 'Exec'),
        ],
      ),
    );
  }

  /// Builds the tab bar view with all 5 tabs.
  Widget _buildTabBarView(String teamId, FleetContainerDetail detail) {
    return TabBarView(
      controller: _tabController,
      children: [
        // 1. Overview
        ContainerOverviewTab(
          detail: detail,
          callbacks: (
            onStop: () => _stopContainer(teamId),
            onRestart: () => _restartContainer(teamId),
            onRemove: () => _removeContainer(teamId),
          ),
        ),
        // 2. Logs
        _buildLogsTab(teamId),
        // 3. Stats
        ContainerStatsTab(
          teamId: teamId,
          containerId: widget.containerId,
        ),
        // 4. Health
        _buildHealthTab(teamId),
        // 5. Exec
        ContainerExecTab(
          isRunning: detail.status == ContainerStatus.running,
          onExec: (cmd) => _execCommand(teamId, cmd),
        ),
      ],
    );
  }

  /// Builds the logs tab with provider data.
  Widget _buildLogsTab(String teamId) {
    final params = (teamId: teamId, containerId: widget.containerId);
    final logsAsync = ref.watch(fleetContainerLogsProvider(params));

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load logs',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(fleetContainerLogsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (logs) => ContainerLogsTab(
        logs: logs,
        onTailChanged: (tail) {
          setState(() => _logTailLines = tail);
          ref.invalidate(fleetContainerLogsProvider);
        },
        onRefresh: () => ref.invalidate(fleetContainerLogsProvider),
      ),
    );
  }

  /// Builds the health tab with provider data.
  Widget _buildHealthTab(String teamId) {
    final checksAsync =
        ref.watch(fleetHealthCheckHistoryProvider(widget.containerId));

    return checksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load health checks',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(fleetHealthCheckHistoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (checks) => ContainerHealthTab(
        checks: checks,
        isCheckRunning: _isCheckRunning,
        onRunCheck: () => _runHealthCheck(teamId),
        onRefresh: () =>
            ref.invalidate(fleetHealthCheckHistoryProvider),
      ),
    );
  }

  /// Stops the container after confirmation.
  Future<void> _stopContainer(String teamId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Stop Container',
      message:
          'Are you sure you want to stop this container?',
      confirmLabel: 'Stop',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final api = ref.read(fleetApiProvider);
    await api.stopContainer(teamId, widget.containerId);
    ref.invalidate(fleetContainerDetailProvider);
  }

  /// Restarts the container.
  Future<void> _restartContainer(String teamId) async {
    final api = ref.read(fleetApiProvider);
    await api.restartContainer(teamId, widget.containerId);
    ref.invalidate(fleetContainerDetailProvider);
  }

  /// Removes the container after confirmation.
  Future<void> _removeContainer(String teamId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Container',
      message:
          'Are you sure you want to remove this container? This action cannot be undone.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final api = ref.read(fleetApiProvider);
    await api.removeContainer(teamId, widget.containerId);
    // ignore: use_build_context_synchronously
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  /// Runs a manual health check.
  Future<void> _runHealthCheck(String teamId) async {
    setState(() => _isCheckRunning = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.checkContainerHealth(teamId, widget.containerId);
      ref.invalidate(fleetHealthCheckHistoryProvider);
    } finally {
      if (mounted) {
        setState(() => _isCheckRunning = false);
      }
    }
  }

  /// Executes a command in the container.
  Future<String> _execCommand(String teamId, String command) async {
    final api = ref.read(fleetApiProvider);
    return api.execInContainer(
      teamId,
      widget.containerId,
      ContainerExecRequest(
        command: command,
        attachStdout: true,
        attachStderr: true,
      ),
    );
  }
}
