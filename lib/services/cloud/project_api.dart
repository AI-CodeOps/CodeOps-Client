/// API service for project management endpoints.
///
/// Handles project CRUD, archiving, and team-scoped project listing.
library;

import '../../models/project.dart';
import 'api_client.dart';

/// API service for project management endpoints.
///
/// Provides typed methods for creating, updating, listing, archiving,
/// and deleting projects within a team.
class ProjectApi {
  final ApiClient _client;

  /// Creates a [ProjectApi] backed by the given [client].
  ProjectApi(this._client);

  /// Creates a new project within a team.
  Future<Project> createProject(
    String teamId, {
    required String name,
    String? description,
    String? githubConnectionId,
    String? repoUrl,
    String? repoFullName,
    String? defaultBranch,
    String? jiraConnectionId,
    String? jiraProjectKey,
    String? jiraDefaultIssueType,
    List<String>? jiraLabels,
    String? jiraComponent,
    String? techStack,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (githubConnectionId != null) {
      body['githubConnectionId'] = githubConnectionId;
    }
    if (repoUrl != null) body['repoUrl'] = repoUrl;
    if (repoFullName != null) body['repoFullName'] = repoFullName;
    if (defaultBranch != null) body['defaultBranch'] = defaultBranch;
    if (jiraConnectionId != null) {
      body['jiraConnectionId'] = jiraConnectionId;
    }
    if (jiraProjectKey != null) body['jiraProjectKey'] = jiraProjectKey;
    if (jiraDefaultIssueType != null) {
      body['jiraDefaultIssueType'] = jiraDefaultIssueType;
    }
    if (jiraLabels != null) body['jiraLabels'] = jiraLabels;
    if (jiraComponent != null) body['jiraComponent'] = jiraComponent;
    if (techStack != null) body['techStack'] = techStack;

    final response = await _client.post<Map<String, dynamic>>(
      '/projects/$teamId',
      data: body,
    );
    return Project.fromJson(response.data!);
  }

  /// Fetches all projects for a team.
  ///
  /// Set [includeArchived] to `true` to include archived projects.
  Future<List<Project>> getTeamProjects(
    String teamId, {
    bool includeArchived = false,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/projects/team/$teamId',
      queryParameters: {'includeArchived': includeArchived},
    );
    return response.data!
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single project by [projectId].
  Future<Project> getProject(String projectId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/projects/$projectId');
    return Project.fromJson(response.data!);
  }

  /// Updates a project's properties.
  ///
  /// Only non-null parameters are included in the request body.
  Future<Project> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? githubConnectionId,
    String? repoUrl,
    String? repoFullName,
    String? defaultBranch,
    String? jiraConnectionId,
    String? jiraProjectKey,
    String? jiraDefaultIssueType,
    List<String>? jiraLabels,
    String? jiraComponent,
    String? techStack,
    bool? isArchived,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (githubConnectionId != null) {
      body['githubConnectionId'] = githubConnectionId;
    }
    if (repoUrl != null) body['repoUrl'] = repoUrl;
    if (repoFullName != null) body['repoFullName'] = repoFullName;
    if (defaultBranch != null) body['defaultBranch'] = defaultBranch;
    if (jiraConnectionId != null) {
      body['jiraConnectionId'] = jiraConnectionId;
    }
    if (jiraProjectKey != null) body['jiraProjectKey'] = jiraProjectKey;
    if (jiraDefaultIssueType != null) {
      body['jiraDefaultIssueType'] = jiraDefaultIssueType;
    }
    if (jiraLabels != null) body['jiraLabels'] = jiraLabels;
    if (jiraComponent != null) body['jiraComponent'] = jiraComponent;
    if (techStack != null) body['techStack'] = techStack;
    if (isArchived != null) body['isArchived'] = isArchived;

    final response = await _client.put<Map<String, dynamic>>(
      '/projects/$projectId',
      data: body,
    );
    return Project.fromJson(response.data!);
  }

  /// Deletes a project by [projectId].
  Future<void> deleteProject(String projectId) async {
    await _client.delete('/projects/$projectId');
  }

  /// Archives a project (soft delete).
  Future<void> archiveProject(String projectId) async {
    await _client.put('/projects/$projectId/archive');
  }

  /// Unarchives a previously archived project.
  Future<void> unarchiveProject(String projectId) async {
    await _client.put('/projects/$projectId/unarchive');
  }
}
