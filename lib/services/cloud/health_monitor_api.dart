/// API service for health monitor schedule and snapshot endpoints.
///
/// Wraps the HealthMonitorController endpoints as a standalone service.
library;

import '../../models/enums.dart';
import '../../models/health_snapshot.dart';
import 'api_client.dart';

/// API service for health monitor schedule and snapshot management.
///
/// Provides typed methods for creating, reading, updating, and deleting
/// health monitoring schedules and snapshots.
class HealthMonitorApi {
  final ApiClient _client;

  /// Creates a [HealthMonitorApi] backed by the given [client].
  HealthMonitorApi(this._client);

  // ---------------------------------------------------------------------------
  // Schedules
  // ---------------------------------------------------------------------------

  /// Creates a health monitoring schedule for a project.
  Future<HealthSchedule> createSchedule({
    required String projectId,
    required ScheduleType scheduleType,
    required List<AgentType> agentTypes,
    String? cronExpression,
  }) async {
    final body = <String, dynamic>{
      'projectId': projectId,
      'scheduleType': scheduleType.toJson(),
      'agentTypes': agentTypes.map((t) => t.toJson()).toList(),
    };
    if (cronExpression != null) body['cronExpression'] = cronExpression;

    final response = await _client.post<Map<String, dynamic>>(
      '/health-monitor/schedules',
      data: body,
    );
    return HealthSchedule.fromJson(response.data!);
  }

  /// Fetches all health schedules for a project.
  Future<List<HealthSchedule>> getSchedulesForProject(
    String projectId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/health-monitor/schedules/project/$projectId',
    );
    return response.data!
        .map((e) => HealthSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates a schedule's active state.
  ///
  /// The [active] flag is sent as a query parameter.
  Future<HealthSchedule> updateSchedule(
    String scheduleId,
    bool active,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/health-monitor/schedules/$scheduleId',
      queryParameters: {'active': active},
    );
    return HealthSchedule.fromJson(response.data!);
  }

  /// Deletes a health schedule.
  Future<void> deleteSchedule(String scheduleId) async {
    await _client.delete('/health-monitor/schedules/$scheduleId');
  }

  // ---------------------------------------------------------------------------
  // Snapshots
  // ---------------------------------------------------------------------------

  /// Creates a health snapshot for a project.
  Future<HealthSnapshot> createSnapshot({
    required String projectId,
    required int healthScore,
    String? jobId,
    String? findingsBySeverity,
    int? techDebtScore,
    int? dependencyScore,
    double? testCoveragePercent,
  }) async {
    final body = <String, dynamic>{
      'projectId': projectId,
      'healthScore': healthScore,
    };
    if (jobId != null) body['jobId'] = jobId;
    if (findingsBySeverity != null) {
      body['findingsBySeverity'] = findingsBySeverity;
    }
    if (techDebtScore != null) body['techDebtScore'] = techDebtScore;
    if (dependencyScore != null) body['dependencyScore'] = dependencyScore;
    if (testCoveragePercent != null) {
      body['testCoveragePercent'] = testCoveragePercent;
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/health-monitor/snapshots',
      data: body,
    );
    return HealthSnapshot.fromJson(response.data!);
  }

  /// Fetches health snapshots for a project (paginated).
  Future<PageResponse<HealthSnapshot>> getSnapshots(
    String projectId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/health-monitor/snapshots/project/$projectId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => HealthSnapshot.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches the latest health snapshot for a project.
  Future<HealthSnapshot?> getLatestSnapshot(String projectId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/health-monitor/snapshots/project/$projectId/latest',
    );
    return response.data != null
        ? HealthSnapshot.fromJson(response.data!)
        : null;
  }

  /// Fetches health trend snapshots for a project.
  ///
  /// Returns snapshots over the last [days] days (default 30).
  Future<List<HealthSnapshot>> getHealthTrend(
    String projectId, {
    int days = 30,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/health-monitor/snapshots/project/$projectId/trend',
      queryParameters: {'limit': days},
    );
    return response.data!
        .map((e) => HealthSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
