/// Riverpod providers for health metrics and monitoring data.
///
/// Exposes the [MetricsApi] service, [HealthMonitorApi] service,
/// team and project metrics, health snapshot history, health schedules,
/// trend data, and health dashboard UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../services/cloud/health_monitor_api.dart';
import '../services/cloud/metrics_api.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

/// Provides [MetricsApi] for metrics endpoints.
final metricsApiProvider = Provider<MetricsApi>(
  (ref) => MetricsApi(ref.watch(apiClientProvider)),
);

/// Fetches team-level aggregated metrics.
final teamMetricsProvider = FutureProvider<TeamMetrics?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final metricsApi = ref.watch(metricsApiProvider);
  return metricsApi.getTeamMetrics(teamId);
});

/// Fetches project-level metrics.
final projectMetricsProvider =
    FutureProvider.family<ProjectMetrics?, String>(
  (ref, projectId) async {
    final metricsApi = ref.watch(metricsApiProvider);
    return metricsApi.getProjectMetrics(projectId);
  },
);

/// Fetches health snapshot history for a project.
final healthHistoryProvider =
    FutureProvider.family<List<HealthSnapshot>, String>(
  (ref, projectId) async {
    final api = ref.watch(healthMonitorApiProvider);
    return api.getHealthTrend(projectId);
  },
);

/// Fetches health schedules for a project.
final healthSchedulesProvider =
    FutureProvider.family<List<HealthSchedule>, String>(
  (ref, projectId) async {
    final api = ref.watch(healthMonitorApiProvider);
    return api.getSchedulesForProject(projectId);
  },
);

// ---------------------------------------------------------------------------
// Health Monitor API
// ---------------------------------------------------------------------------

/// Provides [HealthMonitorApi] for health monitor endpoints.
final healthMonitorApiProvider = Provider<HealthMonitorApi>(
  (ref) => HealthMonitorApi(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// Health Dashboard UI state
// ---------------------------------------------------------------------------

/// Currently selected project ID on the health dashboard.
final selectedHealthProjectProvider = StateProvider<String?>((ref) => null);

/// Time range in days for health trend charts.
///
/// Valid values: 7, 14, 30, 60, 90. Default is 30.
final healthTrendRangeProvider = StateProvider<int>((ref) => 30);

// ---------------------------------------------------------------------------
// Health Dashboard data providers
// ---------------------------------------------------------------------------

/// Fetches the latest health snapshot for a project.
final latestSnapshotProvider =
    FutureProvider.family<HealthSnapshot?, String>(
  (ref, projectId) async {
    final api = ref.watch(healthMonitorApiProvider);
    return api.getLatestSnapshot(projectId);
  },
);

/// Computes the health score delta for a project.
///
/// Returns (currentHealthScore - previousHealthScore) from [ProjectMetrics].
/// Returns null if metrics are unavailable.
final healthScoreDeltaProvider = Provider.family<int?, String>(
  (ref, projectId) {
    final metricsAsync = ref.watch(projectMetricsProvider(projectId));
    return metricsAsync.whenOrNull(
      data: (metrics) {
        if (metrics == null) return null;
        final current = metrics.currentHealthScore;
        final previous = metrics.previousHealthScore;
        if (current == null || previous == null) return null;
        return current - previous;
      },
    );
  },
);

/// Fetches health trend data using [MetricsApi.getProjectTrend].
///
/// Uses [healthTrendRangeProvider] for the number of days.
final healthTrendProvider =
    FutureProvider.family<List<HealthSnapshot>, String>(
  (ref, projectId) async {
    final days = ref.watch(healthTrendRangeProvider);
    final metricsApi = ref.watch(metricsApiProvider);
    return metricsApi.getProjectTrend(projectId, days: days);
  },
);
