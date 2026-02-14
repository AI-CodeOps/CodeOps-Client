/// Dedicated API service for remediation task endpoints.
///
/// Wraps the same backend endpoints as [IntegrationApi] but provides
/// a focused interface for task management operations.
library;

import '../../models/enums.dart';
import '../../models/remediation_task.dart';
import 'api_client.dart';

/// Dedicated API service for remediation task endpoints.
///
/// Provides typed methods for creating, querying, and updating
/// remediation tasks generated from audit findings.
class TaskApi {
  final ApiClient _client;

  /// Creates a [TaskApi] backed by the given [client].
  TaskApi(this._client);

  /// Creates a remediation task for a job.
  Future<RemediationTask> createTask({
    required String jobId,
    required int taskNumber,
    required String title,
    String? description,
    String? promptMd,
    String? promptS3Key,
    List<String>? findingIds,
    Priority? priority,
  }) async {
    final body = <String, dynamic>{
      'jobId': jobId,
      'taskNumber': taskNumber,
      'title': title,
    };
    if (description != null) body['description'] = description;
    if (promptMd != null) body['promptMd'] = promptMd;
    if (promptS3Key != null) body['promptS3Key'] = promptS3Key;
    if (findingIds != null) body['findingIds'] = findingIds;
    if (priority != null) body['priority'] = priority.toJson();

    final response = await _client.post<Map<String, dynamic>>(
      '/tasks',
      data: body,
    );
    return RemediationTask.fromJson(response.data!);
  }

  /// Creates multiple remediation tasks in batch.
  Future<List<RemediationTask>> createTasksBatch(
    List<Map<String, dynamic>> tasks,
  ) async {
    final response = await _client.post<List<dynamic>>(
      '/tasks/batch',
      data: tasks,
    );
    return response.data!
        .map((e) => RemediationTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all remediation tasks for a job.
  Future<List<RemediationTask>> getTasksForJob(String jobId) async {
    final response =
        await _client.get<List<dynamic>>('/tasks/job/$jobId');
    return response.data!
        .map((e) => RemediationTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a remediation task by [taskId].
  Future<RemediationTask> getTask(String taskId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/tasks/$taskId');
    return RemediationTask.fromJson(response.data!);
  }

  /// Updates a remediation task.
  Future<RemediationTask> updateTask(
    String taskId, {
    TaskStatus? status,
    String? assignedTo,
    String? jiraKey,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.toJson();
    if (assignedTo != null) body['assignedTo'] = assignedTo;
    if (jiraKey != null) body['jiraKey'] = jiraKey;

    final response = await _client.put<Map<String, dynamic>>(
      '/tasks/$taskId',
      data: body,
    );
    return RemediationTask.fromJson(response.data!);
  }

  /// Fetches remediation tasks assigned to the current user.
  Future<List<RemediationTask>> getAssignedTasks() async {
    final response =
        await _client.get<List<dynamic>>('/tasks/assigned-to-me');
    return response.data!
        .map((e) => RemediationTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
