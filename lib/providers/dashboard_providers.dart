// Riverpod providers for the unified home dashboard.
//
// Aggregates health status, fleet summary, relay unread counts,
// and quick actions from existing module-specific providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fleet_models.dart';
import '../models/relay_models.dart';
import '../providers/courier_providers.dart';
import '../providers/datalens_providers.dart';
import '../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../providers/logger_providers.dart';
import '../providers/mcp_dashboard_providers.dart';
import '../providers/registry_providers.dart';
import '../providers/relay_providers.dart';
import '../providers/team_providers.dart';
import '../providers/vault_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Module Health
// ─────────────────────────────────────────────────────────────────────────────

/// Health status for a single module on the dashboard.
class ModuleHealth {
  /// Module display name.
  final String name;

  /// Module icon.
  final IconData icon;

  /// Route to module dashboard.
  final String route;

  /// Health state: healthy, degraded, down, or unknown.
  final ModuleHealthStatus status;

  /// Short metric label (e.g. "5 services", "3/8 running").
  final String metric;

  /// Creates a [ModuleHealth].
  const ModuleHealth({
    required this.name,
    required this.icon,
    required this.route,
    required this.status,
    required this.metric,
  });
}

/// Possible health states for a module.
enum ModuleHealthStatus { healthy, degraded, down, unknown }

/// Provides aggregated module health across all 8 modules.
final moduleHealthProvider =
    FutureProvider.autoDispose<List<ModuleHealth>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);

  // Registry — count services.
  final registryAsync = ref.watch(registryServicesProvider);
  final registryCount =
      registryAsync.whenOrNull(data: (page) => page.totalElements) ?? 0;

  // Vault — seal status + secret count.
  final sealAsync = ref.watch(sealStatusProvider);
  final sealStatus = sealAsync.whenOrNull(data: (s) => s.status);
  final secretStatsAsync = ref.watch(vaultSecretStatsProvider);
  final secretCount = secretStatsAsync.whenOrNull(
        data: (stats) => stats.values.fold<int>(0, (a, b) => a + b),
      ) ??
      0;

  // Logger — source count.
  final loggerSourcesAsync = ref.watch(loggerSourcesProvider);
  final sourceCount =
      loggerSourcesAsync.whenOrNull(data: (s) => s.length) ?? 0;

  // Courier — collection count.
  final courierAsync = ref.watch(courierCollectionsProvider);
  final collectionCount =
      courierAsync.whenOrNull(data: (c) => c.length) ?? 0;

  // Fleet — container health.
  FleetHealthSummary? fleetSummary;
  if (teamId != null) {
    final fleetAsync = ref.watch(fleetHealthSummaryProvider(teamId));
    fleetSummary = fleetAsync.whenOrNull(data: (s) => s);
  }
  final running = fleetSummary?.runningContainers ?? 0;
  final total = fleetSummary?.totalContainers ?? 0;
  final unhealthy = fleetSummary?.unhealthyContainers ?? 0;

  // DataLens — connection count.
  final datalensAsync = ref.watch(datalensConnectionsProvider);
  final connectionCount =
      datalensAsync.whenOrNull(data: (c) => c.length) ?? 0;

  // Relay — unread count.
  List<UnreadCountResponse> unreadList = [];
  if (teamId != null) {
    final relayAsync = ref.watch(unreadCountsProvider(teamId));
    unreadList = relayAsync.whenOrNull(data: (u) => u) ?? [];
  }
  final totalUnread =
      unreadList.fold<int>(0, (sum, u) => sum + (u.unreadCount ?? 0));

  // MCP — active session count.
  final activeSessions = ref.watch(mcpActiveSessionCountProvider);

  return [
    ModuleHealth(
      name: 'Registry',
      icon: Icons.app_registration_outlined,
      route: '/registry',
      status: registryAsync.hasError
          ? ModuleHealthStatus.down
          : ModuleHealthStatus.healthy,
      metric: '$registryCount services',
    ),
    ModuleHealth(
      name: 'Vault',
      icon: Icons.lock_outlined,
      route: '/vault',
      status: sealAsync.hasError
          ? ModuleHealthStatus.down
          : sealStatus?.name == 'sealed'
              ? ModuleHealthStatus.degraded
              : ModuleHealthStatus.healthy,
      metric: '$secretCount secrets',
    ),
    ModuleHealth(
      name: 'Logger',
      icon: Icons.receipt_long_outlined,
      route: '/logger',
      status: loggerSourcesAsync.hasError
          ? ModuleHealthStatus.down
          : ModuleHealthStatus.healthy,
      metric: '$sourceCount sources',
    ),
    ModuleHealth(
      name: 'Courier',
      icon: Icons.send_outlined,
      route: '/courier',
      status: courierAsync.hasError
          ? ModuleHealthStatus.down
          : ModuleHealthStatus.healthy,
      metric: '$collectionCount collections',
    ),
    ModuleHealth(
      name: 'Fleet',
      icon: Icons.dns_outlined,
      route: '/fleet',
      status: teamId == null
          ? ModuleHealthStatus.unknown
          : unhealthy > 0
              ? ModuleHealthStatus.degraded
              : ModuleHealthStatus.healthy,
      metric: '$running/$total running',
    ),
    ModuleHealth(
      name: 'DataLens',
      icon: Icons.storage_outlined,
      route: '/datalens',
      status: connectionCount > 0
          ? ModuleHealthStatus.healthy
          : ModuleHealthStatus.unknown,
      metric: '$connectionCount connections',
    ),
    ModuleHealth(
      name: 'Relay',
      icon: Icons.forum_outlined,
      route: '/relay',
      status: teamId == null
          ? ModuleHealthStatus.unknown
          : ModuleHealthStatus.healthy,
      metric: '$totalUnread unread',
    ),
    ModuleHealth(
      name: 'MCP',
      icon: Icons.smart_toy_outlined,
      route: '/mcp',
      status: ModuleHealthStatus.healthy,
      metric: '$activeSessions active',
    ),
  ];
});

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────

/// A quick action for the dashboard.
class QuickAction {
  /// Display label.
  final String label;

  /// Icon.
  final IconData icon;

  /// GoRouter path.
  final String route;

  /// Creates a [QuickAction].
  const QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Provides the list of quick actions for the dashboard.
final quickActionsProvider = Provider<List<QuickAction>>((ref) {
  return const [
    QuickAction(
      label: 'Start Workstation',
      icon: Icons.rocket_launch_outlined,
      route: '/fleet/workstation-profiles',
    ),
    QuickAction(
      label: 'Run Audit',
      icon: Icons.search_outlined,
      route: '/audit',
    ),
    QuickAction(
      label: 'New Request',
      icon: Icons.send_outlined,
      route: '/courier',
    ),
    QuickAction(
      label: 'Open Relay',
      icon: Icons.forum_outlined,
      route: '/relay',
    ),
    QuickAction(
      label: 'Open DataLens',
      icon: Icons.storage_outlined,
      route: '/datalens',
    ),
    QuickAction(
      label: 'New Collection',
      icon: Icons.create_new_folder_outlined,
      route: '/courier/import',
    ),
  ];
});
