/// API service for metrics and health trend endpoints.
///
/// Provides team-level and project-level aggregated metrics.
library;

import '../../models/health_snapshot.dart';
import 'api_client.dart';

/// API service for metrics and health trend endpoints.
///
/// Provides typed methods for fetching aggregated metrics at
/// team and project levels, plus project health trends.
class MetricsApi {
  final ApiClient _client;

  /// Creates a [MetricsApi] backed by the given [client].
  MetricsApi(this._client);

  /// Fetches aggregated metrics for a team.
  Future<TeamMetrics> getTeamMetrics(String teamId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/metrics/team/$teamId');
    return TeamMetrics.fromJson(response.data!);
  }

  /// Fetches metrics for a specific project.
  Future<ProjectMetrics> getProjectMetrics(String projectId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/metrics/project/$projectId',
    );
    return ProjectMetrics.fromJson(response.data!);
  }

  /// Fetches health snapshot trend for a project.
  ///
  /// Returns a list of snapshots over the last [days] days (default 30).
  Future<List<HealthSnapshot>> getProjectTrend(
    String projectId, {
    int days = 30,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/metrics/project/$projectId/trend',
      queryParameters: {'days': days},
    );
    return response.data!
        .map((e) => HealthSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
