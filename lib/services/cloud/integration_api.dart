/// API service for integration connection management.
///
/// Handles GitHub connections, Jira connections, dependency scans,
/// vulnerabilities, compliance items, specifications, remediation tasks,
/// tech debt items, and health monitor schedules/snapshots.
library;

import '../../models/compliance_item.dart';
import '../../models/dependency_scan.dart';
import '../../models/enums.dart';
import '../../models/health_snapshot.dart';
import '../../models/remediation_task.dart';
import '../../models/specification.dart';
import '../../models/tech_debt_item.dart';
import 'api_client.dart';

/// API service for integration connection management.
///
/// Provides typed methods for managing GitHub/Jira connections,
/// dependency scans, vulnerabilities, compliance, remediation tasks,
/// tech debt items, and health monitoring schedules/snapshots.
class IntegrationApi {
  final ApiClient _client;

  /// Creates an [IntegrationApi] backed by the given [client].
  IntegrationApi(this._client);

  // ---------------------------------------------------------------------------
  // GitHub Connections
  // ---------------------------------------------------------------------------

  /// Creates a GitHub connection for a team.
  Future<GitHubConnection> createGitHubConnection(
    String teamId, {
    required String name,
    required GitHubAuthType authType,
    required String credentials,
    String? githubUsername,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'authType': authType.toJson(),
      'credentials': credentials,
    };
    if (githubUsername != null) body['githubUsername'] = githubUsername;

    final response = await _client.post<Map<String, dynamic>>(
      '/integrations/github/$teamId',
      data: body,
    );
    return GitHubConnection.fromJson(response.data!);
  }

  /// Fetches all GitHub connections for a team.
  Future<List<GitHubConnection>> getTeamGitHubConnections(
    String teamId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/integrations/github/$teamId',
    );
    return response.data!
        .map((e) => GitHubConnection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a specific GitHub connection.
  Future<GitHubConnection> getGitHubConnection(
    String teamId,
    String connectionId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/integrations/github/$teamId/$connectionId',
    );
    return GitHubConnection.fromJson(response.data!);
  }

  /// Deletes a GitHub connection.
  Future<void> deleteGitHubConnection(
    String teamId,
    String connectionId,
  ) async {
    await _client.delete('/integrations/github/$teamId/$connectionId');
  }

  // ---------------------------------------------------------------------------
  // Jira Connections
  // ---------------------------------------------------------------------------

  /// Creates a Jira connection for a team.
  Future<JiraConnection> createJiraConnection(
    String teamId, {
    required String name,
    required String instanceUrl,
    required String email,
    required String apiToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/integrations/jira/$teamId',
      data: {
        'name': name,
        'instanceUrl': instanceUrl,
        'email': email,
        'apiToken': apiToken,
      },
    );
    return JiraConnection.fromJson(response.data!);
  }

  /// Fetches all Jira connections for a team.
  Future<List<JiraConnection>> getTeamJiraConnections(String teamId) async {
    final response = await _client.get<List<dynamic>>(
      '/integrations/jira/$teamId',
    );
    return response.data!
        .map((e) => JiraConnection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a specific Jira connection.
  Future<JiraConnection> getJiraConnection(
    String teamId,
    String connectionId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/integrations/jira/$teamId/$connectionId',
    );
    return JiraConnection.fromJson(response.data!);
  }

  /// Deletes a Jira connection.
  Future<void> deleteJiraConnection(
    String teamId,
    String connectionId,
  ) async {
    await _client.delete('/integrations/jira/$teamId/$connectionId');
  }

  // ---------------------------------------------------------------------------
  // Dependency Scans
  // ---------------------------------------------------------------------------

  /// Creates a dependency scan record.
  Future<DependencyScan> createDependencyScan({
    required String projectId,
    String? jobId,
    String? manifestFile,
    int? totalDependencies,
    int? outdatedCount,
    int? vulnerableCount,
    String? scanDataJson,
  }) async {
    final body = <String, dynamic>{'projectId': projectId};
    if (jobId != null) body['jobId'] = jobId;
    if (manifestFile != null) body['manifestFile'] = manifestFile;
    if (totalDependencies != null) {
      body['totalDependencies'] = totalDependencies;
    }
    if (outdatedCount != null) body['outdatedCount'] = outdatedCount;
    if (vulnerableCount != null) body['vulnerableCount'] = vulnerableCount;
    if (scanDataJson != null) body['scanDataJson'] = scanDataJson;

    final response = await _client.post<Map<String, dynamic>>(
      '/dependencies/scans',
      data: body,
    );
    return DependencyScan.fromJson(response.data!);
  }

  /// Fetches a dependency scan by [scanId].
  Future<DependencyScan> getDependencyScan(String scanId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/dependencies/scans/$scanId',
    );
    return DependencyScan.fromJson(response.data!);
  }

  /// Fetches all dependency scans for a project.
  Future<List<DependencyScan>> getProjectScans(String projectId) async {
    final response = await _client.get<List<dynamic>>(
      '/dependencies/scans/project/$projectId',
    );
    return response.data!
        .map((e) => DependencyScan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the latest dependency scan for a project.
  Future<DependencyScan?> getLatestScan(String projectId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/dependencies/scans/project/$projectId/latest',
    );
    return response.data != null
        ? DependencyScan.fromJson(response.data!)
        : null;
  }

  // ---------------------------------------------------------------------------
  // Vulnerabilities
  // ---------------------------------------------------------------------------

  /// Adds a vulnerability to a dependency scan.
  Future<DependencyVulnerability> addVulnerability({
    required String scanId,
    required String dependencyName,
    required Severity severity,
    String? currentVersion,
    String? fixedVersion,
    String? cveId,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'scanId': scanId,
      'dependencyName': dependencyName,
      'severity': severity.toJson(),
    };
    if (currentVersion != null) body['currentVersion'] = currentVersion;
    if (fixedVersion != null) body['fixedVersion'] = fixedVersion;
    if (cveId != null) body['cveId'] = cveId;
    if (description != null) body['description'] = description;

    final response = await _client.post<Map<String, dynamic>>(
      '/dependencies/vulnerabilities',
      data: body,
    );
    return DependencyVulnerability.fromJson(response.data!);
  }

  /// Adds multiple vulnerabilities in batch.
  Future<List<DependencyVulnerability>> addVulnerabilitiesBatch(
    List<Map<String, dynamic>> vulnerabilities,
  ) async {
    final response = await _client.post<List<dynamic>>(
      '/dependencies/vulnerabilities/batch',
      data: vulnerabilities,
    );
    return response.data!
        .map((e) =>
            DependencyVulnerability.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all vulnerabilities for a scan.
  Future<List<DependencyVulnerability>> getScanVulnerabilities(
    String scanId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/dependencies/vulnerabilities/scan/$scanId',
    );
    return response.data!
        .map((e) =>
            DependencyVulnerability.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches open vulnerabilities for a scan.
  Future<List<DependencyVulnerability>> getOpenVulnerabilities(
    String scanId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/dependencies/vulnerabilities/scan/$scanId/open',
    );
    return response.data!
        .map((e) =>
            DependencyVulnerability.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates a vulnerability's status.
  Future<DependencyVulnerability> updateVulnerabilityStatus(
    String vulnerabilityId,
    VulnerabilityStatus status,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/dependencies/vulnerabilities/$vulnerabilityId/status',
      queryParameters: {'status': status.toJson()},
    );
    return DependencyVulnerability.fromJson(response.data!);
  }

  // ---------------------------------------------------------------------------
  // Compliance
  // ---------------------------------------------------------------------------

  /// Creates a specification record for a job.
  Future<Specification> createSpecification({
    required String jobId,
    required String name,
    required String s3Key,
    SpecType? specType,
  }) async {
    final body = <String, dynamic>{
      'jobId': jobId,
      'name': name,
      's3Key': s3Key,
    };
    if (specType != null) body['specType'] = specType.toJson();

    final response = await _client.post<Map<String, dynamic>>(
      '/compliance/specs',
      data: body,
    );
    return Specification.fromJson(response.data!);
  }

  /// Fetches all specifications for a job.
  Future<List<Specification>> getJobSpecifications(String jobId) async {
    final response = await _client.get<List<dynamic>>(
      '/compliance/specs/job/$jobId',
    );
    return response.data!
        .map((e) => Specification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a compliance item for a job.
  Future<ComplianceItem> createComplianceItem({
    required String jobId,
    required String requirement,
    required ComplianceStatus status,
    String? specId,
    String? evidence,
    AgentType? agentType,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'jobId': jobId,
      'requirement': requirement,
      'status': status.toJson(),
    };
    if (specId != null) body['specId'] = specId;
    if (evidence != null) body['evidence'] = evidence;
    if (agentType != null) body['agentType'] = agentType.toJson();
    if (notes != null) body['notes'] = notes;

    final response = await _client.post<Map<String, dynamic>>(
      '/compliance/items',
      data: body,
    );
    return ComplianceItem.fromJson(response.data!);
  }

  /// Creates multiple compliance items in batch.
  Future<List<ComplianceItem>> createComplianceItemsBatch(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _client.post<List<dynamic>>(
      '/compliance/items/batch',
      data: items,
    );
    return response.data!
        .map((e) => ComplianceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all compliance items for a job.
  Future<List<ComplianceItem>> getJobComplianceItems(String jobId) async {
    final response = await _client.get<List<dynamic>>(
      '/compliance/items/job/$jobId',
    );
    return response.data!
        .map((e) => ComplianceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a compliance summary for a job.
  Future<Map<String, dynamic>> getComplianceSummary(String jobId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/compliance/summary/job/$jobId',
    );
    return response.data!;
  }

  // ---------------------------------------------------------------------------
  // Remediation Tasks
  // ---------------------------------------------------------------------------

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

  /// Fetches all remediation tasks for a job.
  Future<List<RemediationTask>> getJobTasks(String jobId) async {
    final response =
        await _client.get<List<dynamic>>('/tasks/job/$jobId');
    return response.data!
        .map((e) => RemediationTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches remediation tasks assigned to the current user.
  Future<List<RemediationTask>> getMyTasks() async {
    final response =
        await _client.get<List<dynamic>>('/tasks/assigned-to-me');
    return response.data!
        .map((e) => RemediationTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Tech Debt
  // ---------------------------------------------------------------------------

  /// Creates a tech debt item.
  Future<TechDebtItem> createTechDebtItem({
    required String projectId,
    required DebtCategory category,
    required String title,
    String? description,
    String? filePath,
    Effort? effortEstimate,
    BusinessImpact? businessImpact,
    String? firstDetectedJobId,
  }) async {
    final body = <String, dynamic>{
      'projectId': projectId,
      'category': category.toJson(),
      'title': title,
    };
    if (description != null) body['description'] = description;
    if (filePath != null) body['filePath'] = filePath;
    if (effortEstimate != null) {
      body['effortEstimate'] = effortEstimate.toJson();
    }
    if (businessImpact != null) {
      body['businessImpact'] = businessImpact.toJson();
    }
    if (firstDetectedJobId != null) {
      body['firstDetectedJobId'] = firstDetectedJobId;
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/tech-debt',
      data: body,
    );
    return TechDebtItem.fromJson(response.data!);
  }

  /// Creates multiple tech debt items in batch.
  Future<List<TechDebtItem>> createTechDebtItemsBatch(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _client.post<List<dynamic>>(
      '/tech-debt/batch',
      data: items,
    );
    return response.data!
        .map((e) => TechDebtItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a tech debt item by [itemId].
  Future<TechDebtItem> getTechDebtItem(String itemId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/tech-debt/$itemId');
    return TechDebtItem.fromJson(response.data!);
  }

  /// Fetches all tech debt items for a project.
  Future<List<TechDebtItem>> getProjectTechDebt(String projectId) async {
    final response = await _client.get<List<dynamic>>(
      '/tech-debt/project/$projectId',
    );
    return response.data!
        .map((e) => TechDebtItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches tech debt items filtered by [status].
  Future<List<TechDebtItem>> getProjectTechDebtByStatus(
    String projectId,
    DebtStatus status,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/tech-debt/project/$projectId/status/${status.toJson()}',
    );
    return response.data!
        .map((e) => TechDebtItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches tech debt items filtered by [category].
  Future<List<TechDebtItem>> getProjectTechDebtByCategory(
    String projectId,
    DebtCategory category,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/tech-debt/project/$projectId/category/${category.toJson()}',
    );
    return response.data!
        .map((e) => TechDebtItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a debt summary for a project.
  Future<Map<String, dynamic>> getDebtSummary(String projectId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/tech-debt/project/$projectId/summary',
    );
    return response.data!;
  }

  /// Updates a tech debt item's status.
  Future<TechDebtItem> updateTechDebtStatus(
    String itemId,
    DebtStatus status, {
    String? resolvedJobId,
  }) async {
    final body = <String, dynamic>{'status': status.toJson()};
    if (resolvedJobId != null) body['resolvedJobId'] = resolvedJobId;

    final response = await _client.put<Map<String, dynamic>>(
      '/tech-debt/$itemId/status',
      data: body,
    );
    return TechDebtItem.fromJson(response.data!);
  }

  /// Deletes a tech debt item.
  Future<void> deleteTechDebtItem(String itemId) async {
    await _client.delete('/tech-debt/$itemId');
  }

  // ---------------------------------------------------------------------------
  // Health Monitor — Schedules
  // ---------------------------------------------------------------------------

  /// Creates a health monitoring schedule.
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
  Future<List<HealthSchedule>> getProjectSchedules(
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
  // Health Monitor — Snapshots
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

  /// Fetches health snapshots for a project (trend view).
  ///
  /// Returns the last [limit] snapshots (default 30).
  Future<List<HealthSnapshot>> getProjectSnapshots(
    String projectId, {
    int limit = 30,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/health-monitor/snapshots/project/$projectId/trend',
      queryParameters: {'limit': limit},
    );
    return response.data!
        .map((e) => HealthSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
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
}
