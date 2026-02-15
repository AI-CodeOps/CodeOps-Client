/// API service for integration connection management.
///
/// Handles GitHub and Jira connection CRUD operations only.
/// All other domain endpoints are served by dedicated API services:
/// - [DependencyApi] for dependency scans and vulnerabilities
/// - [ComplianceApi] for compliance specs and items
/// - [TaskApi] for remediation tasks
/// - [TechDebtApi] for tech debt items
/// - [HealthMonitorApi] for health schedules and snapshots
library;

import '../../models/enums.dart';
import '../../models/health_snapshot.dart';
import 'api_client.dart';

/// API service for GitHub and Jira integration connection management.
///
/// Provides typed methods for creating, reading, and deleting
/// GitHub and Jira connections for a team.
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
}
