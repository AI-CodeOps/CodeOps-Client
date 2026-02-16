/// API service for QA job lifecycle endpoints.
///
/// Covers job creation, updates, querying, agent run management,
/// and bug investigation management.
library;

import '../../models/agent_run.dart';
import '../../models/enums.dart';
import '../../models/health_snapshot.dart';
import '../../models/qa_job.dart';
import 'api_client.dart';

/// API service for QA job lifecycle endpoints.
///
/// Provides typed methods for managing QA jobs, their agent runs,
/// and bug investigation records.
class JobApi {
  final ApiClient _client;

  /// Creates a [JobApi] backed by the given [client].
  JobApi(this._client);

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------

  /// Creates a new QA job.
  Future<QaJob> createJob({
    required String projectId,
    required JobMode mode,
    String? name,
    String? branch,
    String? configJson,
    String? jiraTicketKey,
  }) async {
    final body = <String, dynamic>{
      'projectId': projectId,
      'mode': mode.toJson(),
    };
    if (name != null) body['name'] = name;
    if (branch != null) body['branch'] = branch;
    if (configJson != null) body['configJson'] = configJson;
    if (jiraTicketKey != null) body['jiraTicketKey'] = jiraTicketKey;

    final response = await _client.post<Map<String, dynamic>>(
      '/jobs',
      data: body,
    );
    return QaJob.fromJson(response.data!);
  }

  /// Fetches a single job by [jobId].
  Future<QaJob> getJob(String jobId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/jobs/$jobId');
    return QaJob.fromJson(response.data!);
  }

  /// Updates a job's status, results, and summary.
  Future<QaJob> updateJob(
    String jobId, {
    JobStatus? status,
    String? summaryMd,
    JobResult? overallResult,
    int? healthScore,
    int? totalFindings,
    int? criticalCount,
    int? highCount,
    int? mediumCount,
    int? lowCount,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.toJson();
    if (summaryMd != null) body['summaryMd'] = summaryMd;
    if (overallResult != null) body['overallResult'] = overallResult.toJson();
    if (healthScore != null) body['healthScore'] = healthScore;
    if (totalFindings != null) body['totalFindings'] = totalFindings;
    if (criticalCount != null) body['criticalCount'] = criticalCount;
    if (highCount != null) body['highCount'] = highCount;
    if (mediumCount != null) body['mediumCount'] = mediumCount;
    if (lowCount != null) body['lowCount'] = lowCount;
    if (startedAt != null) {
      body['startedAt'] = startedAt.toUtc().toIso8601String();
    }
    if (completedAt != null) {
      body['completedAt'] = completedAt.toUtc().toIso8601String();
    }

    final response = await _client.put<Map<String, dynamic>>(
      '/jobs/$jobId',
      data: body,
    );
    return QaJob.fromJson(response.data!);
  }

  /// Deletes a job by [jobId].
  Future<void> deleteJob(String jobId) async {
    await _client.delete('/jobs/$jobId');
  }

  /// Fetches paginated job history for a project.
  Future<PageResponse<JobSummary>> getProjectJobs(
    String projectId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/jobs/project/$projectId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => JobSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches recent jobs started by the current user.
  Future<List<JobSummary>> getMyJobs() async {
    final response = await _client.get<Map<String, dynamic>>('/jobs/mine');
    final content = response.data!['content'] as List<dynamic>;
    return content
        .map((e) => JobSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Agent Runs
  // ---------------------------------------------------------------------------

  /// Creates an agent run within a job.
  Future<AgentRun> createAgentRun(
    String jobId, {
    required AgentType agentType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/jobs/$jobId/agents',
      data: {'jobId': jobId, 'agentType': agentType.toJson()},
    );
    return AgentRun.fromJson(response.data!);
  }

  /// Creates multiple agent runs in batch.
  Future<List<AgentRun>> createAgentRunsBatch(
    String jobId,
    List<AgentType> agentTypes,
  ) async {
    final response = await _client.post<List<dynamic>>(
      '/jobs/$jobId/agents/batch',
      data: agentTypes.map((t) => t.toJson()).toList(),
    );
    return response.data!
        .map((e) => AgentRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all agent runs for a job.
  Future<List<AgentRun>> getAgentRuns(String jobId) async {
    final response =
        await _client.get<List<dynamic>>('/jobs/$jobId/agents');
    return response.data!
        .map((e) => AgentRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates an agent run's status and results.
  Future<AgentRun> updateAgentRun(
    String agentRunId, {
    AgentStatus? status,
    AgentResult? result,
    String? reportS3Key,
    int? score,
    int? findingsCount,
    int? criticalCount,
    int? highCount,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.toJson();
    if (result != null) body['result'] = result.toJson();
    if (reportS3Key != null) body['reportS3Key'] = reportS3Key;
    if (score != null) body['score'] = score;
    if (findingsCount != null) body['findingsCount'] = findingsCount;
    if (criticalCount != null) body['criticalCount'] = criticalCount;
    if (highCount != null) body['highCount'] = highCount;
    if (startedAt != null) {
      body['startedAt'] = startedAt.toUtc().toIso8601String();
    }
    if (completedAt != null) {
      body['completedAt'] = completedAt.toUtc().toIso8601String();
    }

    final response = await _client.put<Map<String, dynamic>>(
      '/jobs/agents/$agentRunId',
      data: body,
    );
    return AgentRun.fromJson(response.data!);
  }

  // ---------------------------------------------------------------------------
  // Bug Investigations
  // ---------------------------------------------------------------------------

  /// Creates a bug investigation record for a job.
  Future<BugInvestigation> createInvestigation(
    String jobId, {
    String? jiraKey,
    String? jiraSummary,
    String? jiraDescription,
    String? jiraCommentsJson,
    String? jiraAttachmentsJson,
    String? jiraLinkedIssues,
    String? additionalContext,
  }) async {
    final body = <String, dynamic>{'jobId': jobId};
    if (jiraKey != null) body['jiraKey'] = jiraKey;
    if (jiraSummary != null) body['jiraSummary'] = jiraSummary;
    if (jiraDescription != null) body['jiraDescription'] = jiraDescription;
    if (jiraCommentsJson != null) {
      body['jiraCommentsJson'] = jiraCommentsJson;
    }
    if (jiraAttachmentsJson != null) {
      body['jiraAttachmentsJson'] = jiraAttachmentsJson;
    }
    if (jiraLinkedIssues != null) body['jiraLinkedIssues'] = jiraLinkedIssues;
    if (additionalContext != null) {
      body['additionalContext'] = additionalContext;
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/jobs/$jobId/investigation',
      data: body,
    );
    return BugInvestigation.fromJson(response.data!);
  }

  /// Fetches the bug investigation for a job.
  Future<BugInvestigation> getInvestigation(String jobId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/jobs/$jobId/investigation',
    );
    return BugInvestigation.fromJson(response.data!);
  }

  /// Updates a bug investigation (RCA results, Jira posting status).
  Future<BugInvestigation> updateInvestigation(
    String investigationId, {
    String? rcaMd,
    String? impactAssessmentMd,
    String? rcaS3Key,
    bool? rcaPostedToJira,
    bool? fixTasksCreatedInJira,
  }) async {
    final body = <String, dynamic>{};
    if (rcaMd != null) body['rcaMd'] = rcaMd;
    if (impactAssessmentMd != null) {
      body['impactAssessmentMd'] = impactAssessmentMd;
    }
    if (rcaS3Key != null) body['rcaS3Key'] = rcaS3Key;
    if (rcaPostedToJira != null) body['rcaPostedToJira'] = rcaPostedToJira;
    if (fixTasksCreatedInJira != null) {
      body['fixTasksCreatedInJira'] = fixTasksCreatedInJira;
    }

    final response = await _client.put<Map<String, dynamic>>(
      '/jobs/investigations/$investigationId',
      data: body,
    );
    return BugInvestigation.fromJson(response.data!);
  }
}
