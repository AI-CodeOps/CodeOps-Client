/// Riverpod providers for health metrics and monitoring data.
///
/// Exposes the [MetricsApi] service, team and project metrics,
/// health snapshot history, and health schedules.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../services/cloud/metrics_api.dart';
import 'auth_providers.dart';
import 'task_providers.dart';
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
    final integrationApi = ref.watch(integrationApiProvider);
    return integrationApi.getProjectSnapshots(projectId);
  },
);

/// Fetches health schedules for a project.
final healthSchedulesProvider =
    FutureProvider.family<List<HealthSchedule>, String>(
  (ref, projectId) async {
    final integrationApi = ref.watch(integrationApiProvider);
    return integrationApi.getProjectSchedules(projectId);
  },
);
