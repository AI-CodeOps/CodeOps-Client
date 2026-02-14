/// API service for directive management endpoints.
///
/// Covers CRUD, team/project scoping, and project-directive assignment toggling.
library;

import '../../models/directive.dart';
import '../../models/enums.dart';
import 'api_client.dart';

/// API service for directive management endpoints.
///
/// Provides typed methods for creating, updating, listing, and managing
/// directives and their assignment to projects.
class DirectiveApi {
  final ApiClient _client;

  /// Creates a [DirectiveApi] backed by the given [client].
  DirectiveApi(this._client);

  /// Creates a new directive.
  Future<Directive> createDirective({
    required String name,
    required String contentMd,
    required DirectiveScope scope,
    String? description,
    DirectiveCategory? category,
    String? teamId,
    String? projectId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'contentMd': contentMd,
      'scope': scope.toJson(),
    };
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category.toJson();
    if (teamId != null) body['teamId'] = teamId;
    if (projectId != null) body['projectId'] = projectId;

    final response = await _client.post<Map<String, dynamic>>(
      '/directives',
      data: body,
    );
    return Directive.fromJson(response.data!);
  }

  /// Fetches a directive by [directiveId].
  Future<Directive> getDirective(String directiveId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/directives/$directiveId');
    return Directive.fromJson(response.data!);
  }

  /// Updates a directive.
  ///
  /// Only [name], [description], [contentMd], and [category] can be updated.
  Future<Directive> updateDirective(
    String directiveId, {
    String? name,
    String? description,
    String? contentMd,
    DirectiveCategory? category,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (contentMd != null) body['contentMd'] = contentMd;
    if (category != null) body['category'] = category.toJson();

    final response = await _client.put<Map<String, dynamic>>(
      '/directives/$directiveId',
      data: body,
    );
    return Directive.fromJson(response.data!);
  }

  /// Deletes a directive by [directiveId].
  Future<void> deleteDirective(String directiveId) async {
    await _client.delete('/directives/$directiveId');
  }

  /// Fetches all directives for a team.
  Future<List<Directive>> getTeamDirectives(String teamId) async {
    final response =
        await _client.get<List<dynamic>>('/directives/team/$teamId');
    return response.data!
        .map((e) => Directive.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches directives scoped to a project.
  Future<List<Directive>> getProjectDirectives(String projectId) async {
    final response =
        await _client.get<List<dynamic>>('/directives/project/$projectId');
    return response.data!
        .map((e) => Directive.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches enabled directives for a project.
  Future<List<Directive>> getProjectEnabledDirectives(
    String projectId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/directives/project/$projectId/enabled',
    );
    return response.data!
        .map((e) => Directive.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches directive assignments for a project.
  Future<List<ProjectDirective>> getProjectDirectiveAssignments(
    String projectId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/directives/project/$projectId/assignments',
    );
    return response.data!
        .map((e) => ProjectDirective.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Assigns a directive to a project.
  Future<ProjectDirective> assignToProject({
    required String projectId,
    required String directiveId,
    bool enabled = true,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/directives/assign',
      data: {
        'projectId': projectId,
        'directiveId': directiveId,
        'enabled': enabled,
      },
    );
    return ProjectDirective.fromJson(response.data!);
  }

  /// Toggles a directive's enabled state on a project.
  Future<ProjectDirective> toggleDirective(
    String projectId,
    String directiveId,
    bool enabled,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/directives/project/$projectId/directive/$directiveId/toggle',
      queryParameters: {'enabled': enabled},
    );
    return ProjectDirective.fromJson(response.data!);
  }

  /// Removes a directive from a project.
  Future<void> removeFromProject(
    String projectId,
    String directiveId,
  ) async {
    await _client.delete(
      '/directives/project/$projectId/directive/$directiveId',
    );
  }
}
