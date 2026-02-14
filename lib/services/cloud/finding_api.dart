/// API service for finding-related endpoints.
///
/// Supports paginated queries, filtering by severity/status/agent,
/// and bulk status updates.
library;

import '../../models/enums.dart';
import '../../models/finding.dart';
import '../../models/health_snapshot.dart';
import 'api_client.dart';

/// API service for finding-related endpoints.
///
/// Provides typed methods for creating, querying, and updating
/// findings produced by QA agent runs.
class FindingApi {
  final ApiClient _client;

  /// Creates a [FindingApi] backed by the given [client].
  FindingApi(this._client);

  /// Creates a single finding.
  Future<Finding> createFinding({
    required String jobId,
    required AgentType agentType,
    required Severity severity,
    required String title,
    String? description,
    String? filePath,
    int? lineNumber,
    String? recommendation,
    String? evidence,
    Effort? effortEstimate,
    DebtCategory? debtCategory,
  }) async {
    final body = <String, dynamic>{
      'jobId': jobId,
      'agentType': agentType.toJson(),
      'severity': severity.toJson(),
      'title': title,
    };
    if (description != null) body['description'] = description;
    if (filePath != null) body['filePath'] = filePath;
    if (lineNumber != null) body['lineNumber'] = lineNumber;
    if (recommendation != null) body['recommendation'] = recommendation;
    if (evidence != null) body['evidence'] = evidence;
    if (effortEstimate != null) {
      body['effortEstimate'] = effortEstimate.toJson();
    }
    if (debtCategory != null) body['debtCategory'] = debtCategory.toJson();

    final response = await _client.post<Map<String, dynamic>>(
      '/findings',
      data: body,
    );
    return Finding.fromJson(response.data!);
  }

  /// Creates multiple findings in batch.
  Future<List<Finding>> createFindingsBatch(
    List<Map<String, dynamic>> findings,
  ) async {
    final response = await _client.post<List<dynamic>>(
      '/findings/batch',
      data: findings,
    );
    return response.data!
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches paginated findings for a job.
  Future<PageResponse<Finding>> getJobFindings(
    String jobId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/findings/job/$jobId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => Finding.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches a single finding by [findingId].
  Future<Finding> getFinding(String findingId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/findings/$findingId');
    return Finding.fromJson(response.data!);
  }

  /// Fetches findings filtered by [severity] for a job.
  Future<List<Finding>> getFindingsBySeverity(
    String jobId,
    Severity severity,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/findings/job/$jobId/severity/${severity.toJson()}',
    );
    return response.data!
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches findings filtered by [status] for a job.
  Future<List<Finding>> getFindingsByStatus(
    String jobId,
    FindingStatus status,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/findings/job/$jobId/status/${status.toJson()}',
    );
    return response.data!
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches findings filtered by [agentType] for a job.
  Future<List<Finding>> getFindingsByAgent(
    String jobId,
    AgentType agentType,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/findings/job/$jobId/agent/${agentType.toJson()}',
    );
    return response.data!
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches finding counts grouped by severity for a job.
  Future<Map<String, dynamic>> getFindingCounts(String jobId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/findings/job/$jobId/counts',
    );
    return response.data!;
  }

  /// Updates a single finding's status.
  Future<Finding> updateFindingStatus(
    String findingId,
    FindingStatus status,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/findings/$findingId/status',
      data: {'status': status.toJson()},
    );
    return Finding.fromJson(response.data!);
  }

  /// Bulk-updates the status of multiple findings.
  Future<List<Finding>> bulkUpdateStatus(
    List<String> findingIds,
    FindingStatus status,
  ) async {
    final response = await _client.put<List<dynamic>>(
      '/findings/bulk-status',
      data: {'findingIds': findingIds, 'status': status.toJson()},
    );
    return response.data!
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
