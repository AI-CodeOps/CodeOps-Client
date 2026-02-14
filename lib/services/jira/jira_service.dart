/// Jira Cloud REST API client.
///
/// Communicates directly with Jira Cloud using Basic Auth (email:apiToken).
/// Uses a separate [Dio] instance from the CodeOps API client.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/jira_models.dart';

/// Jira Cloud REST API client.
///
/// Talks directly to a Jira Cloud instance using API token authentication.
/// The API token is stored locally in the OS keychain via secure storage.
///
/// Example:
/// ```dart
/// final service = JiraService();
/// service.configure(
///   instanceUrl: 'https://company.atlassian.net',
///   email: 'user@company.com',
///   apiToken: 'xxxxx',
/// );
/// final result = await service.searchIssues(jql: 'project = PAY');
/// ```
class JiraService {
  Dio _dio;
  String? _instanceUrl;
  String? _email;
  String? _apiToken;

  /// Creates a [JiraService] with an optional [Dio] instance for testing.
  JiraService({Dio? dio}) : _dio = dio ?? Dio();

  /// Configures the service with Jira connection details.
  ///
  /// Must be called before any API method. Called when user selects
  /// or changes a Jira connection.
  void configure({
    required String instanceUrl,
    required String email,
    required String apiToken,
  }) {
    _instanceUrl = instanceUrl.endsWith('/')
        ? instanceUrl.substring(0, instanceUrl.length - 1)
        : instanceUrl;
    _email = email;
    _apiToken = apiToken;

    _dio = Dio(BaseOptions(
      baseUrl: _instanceUrl!,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_email:$_apiToken'))}',
      },
    ));
  }

  /// Whether the service is currently configured with valid credentials.
  bool get isConfigured =>
      _instanceUrl != null && _email != null && _apiToken != null;

  /// Tests the current configuration by fetching the authenticated user.
  ///
  /// Returns `true` if authentication succeeds.
  Future<bool> testConnection() async {
    _ensureConfigured();
    try {
      final response = await _dio.get('/rest/api/3/myself');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Issue operations
  // ---------------------------------------------------------------------------

  /// Searches issues using JQL.
  ///
  /// Returns paginated results starting at [startAt] with up to [maxResults].
  /// Optionally specify [fields] to limit returned data and [expand] for
  /// additional data.
  Future<JiraSearchResult> searchIssues({
    required String jql,
    int startAt = 0,
    int maxResults = 50,
    List<String>? fields,
    List<String>? expand,
  }) async {
    _ensureConfigured();
    final body = <String, dynamic>{
      'jql': jql,
      'startAt': startAt,
      'maxResults': maxResults,
    };
    if (fields != null) body['fields'] = fields;
    if (expand != null) body['expand'] = expand;

    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/rest/api/3/search',
      data: body,
    );
    return JiraSearchResult.fromJson(response.data!);
  }

  /// Gets a single issue by [issueKey] (e.g. 'PAY-456').
  ///
  /// Optionally [expand] additional fields.
  Future<JiraIssue> getIssue(String issueKey, {List<String>? expand}) async {
    _ensureConfigured();
    final queryParams = <String, dynamic>{};
    if (expand != null) queryParams['expand'] = expand.join(',');

    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/rest/api/3/issue/$issueKey',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return JiraIssue.fromJson(response.data!);
  }

  /// Gets comments on an issue.
  Future<List<JiraComment>> getComments(
    String issueKey, {
    int maxResults = 100,
  }) async {
    _ensureConfigured();
    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/rest/api/3/issue/$issueKey/comment',
      queryParameters: {'maxResults': maxResults},
    );
    final data = response.data!;
    final comments = (data['comments'] as List<dynamic>?) ?? [];
    return comments
        .map((c) => JiraComment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Posts a comment to an issue.
  ///
  /// The [bodyMarkdown] is converted to Atlassian Document Format (ADF)
  /// before posting.
  Future<JiraComment> postComment(String issueKey, String bodyMarkdown) async {
    _ensureConfigured();
    final adfBody = _markdownToAdf(bodyMarkdown);
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/rest/api/3/issue/$issueKey/comment',
      data: {'body': jsonDecode(adfBody)},
    );
    return JiraComment.fromJson(response.data!);
  }

  /// Creates a new issue.
  Future<JiraIssue> createIssue(CreateJiraIssueRequest request) async {
    _ensureConfigured();
    final body = _buildCreateIssueBody(request);
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/rest/api/3/issue',
      data: body,
    );
    // Jira create returns minimal data — fetch full issue.
    final key = response.data!['key'] as String;
    return getIssue(key);
  }

  /// Creates a sub-task under a parent issue.
  Future<JiraIssue> createSubTask(CreateJiraSubTaskRequest request) async {
    _ensureConfigured();
    final fields = <String, dynamic>{
      'project': {'key': request.projectKey},
      'parent': {'key': request.parentKey},
      'issuetype': {'name': 'Sub-task'},
      'summary': request.summary,
    };
    if (request.description != null) {
      fields['description'] = jsonDecode(_markdownToAdf(request.description!));
    }
    if (request.assigneeAccountId != null) {
      fields['assignee'] = {'accountId': request.assigneeAccountId};
    }
    if (request.priorityName != null) {
      fields['priority'] = {'name': request.priorityName};
    }

    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/rest/api/3/issue',
      data: {'fields': fields},
    );
    final key = response.data!['key'] as String;
    return getIssue(key);
  }

  /// Creates multiple issues sequentially.
  ///
  /// Returns created issues. Continues on failure, skipping failed ones.
  Future<List<JiraIssue>> createIssuesBulk(
    List<CreateJiraIssueRequest> requests,
  ) async {
    _ensureConfigured();
    final results = <JiraIssue>[];
    for (final request in requests) {
      try {
        final issue = await createIssue(request);
        results.add(issue);
      } on DioException {
        // Skip failed creates — caller handles partial results.
        continue;
      }
    }
    return results;
  }

  /// Updates an issue's fields.
  Future<void> updateIssue(
    String issueKey,
    UpdateJiraIssueRequest request,
  ) async {
    _ensureConfigured();
    final fields = <String, dynamic>{};
    if (request.summary != null) fields['summary'] = request.summary;
    if (request.description != null) {
      fields['description'] =
          jsonDecode(_markdownToAdf(request.description!));
    }
    if (request.assigneeAccountId != null) {
      fields['assignee'] = {'accountId': request.assigneeAccountId};
    }
    if (request.priorityName != null) {
      fields['priority'] = {'name': request.priorityName};
    }
    if (request.labels != null) fields['labels'] = request.labels;

    await _request<dynamic>(
      'PUT',
      '/rest/api/3/issue/$issueKey',
      data: {'fields': fields},
    );
  }

  /// Gets available workflow transitions for an issue.
  Future<List<JiraTransition>> getTransitions(String issueKey) async {
    _ensureConfigured();
    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/rest/api/3/issue/$issueKey/transitions',
    );
    final transitions = (response.data!['transitions'] as List<dynamic>?) ?? [];
    return transitions
        .map((t) => JiraTransition.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Transitions an issue to a new status.
  Future<void> transitionIssue(String issueKey, String transitionId) async {
    _ensureConfigured();
    await _request<dynamic>(
      'POST',
      '/rest/api/3/issue/$issueKey/transitions',
      data: {
        'transition': {'id': transitionId},
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Project & metadata
  // ---------------------------------------------------------------------------

  /// Gets all Jira projects the authenticated user has access to.
  Future<List<JiraProject>> getProjects() async {
    _ensureConfigured();
    final response = await _request<List<dynamic>>(
      'GET',
      '/rest/api/3/project',
    );
    return response.data!
        .map((p) => JiraProject.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Gets sprints for a board.
  ///
  /// Optionally filter by [state] ('active', 'closed', 'future').
  Future<List<JiraSprint>> getSprints(int boardId, {String? state}) async {
    _ensureConfigured();
    final queryParams = <String, dynamic>{};
    if (state != null) queryParams['state'] = state;

    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/rest/agile/1.0/board/$boardId/sprint',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final values = (response.data!['values'] as List<dynamic>?) ?? [];
    return values
        .map((s) => JiraSprint.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Gets issue types available for a project.
  Future<List<JiraIssueType>> getIssueTypes(String projectKey) async {
    _ensureConfigured();
    final response = await _request<List<dynamic>>(
      'GET',
      '/rest/api/3/project/$projectKey/statuses',
    );
    // Jira returns statuses grouped by issue type — extract unique types.
    final seen = <String>{};
    final types = <JiraIssueType>[];
    for (final entry in response.data!) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;
      if (seen.add(id)) {
        types.add(JiraIssueType(
          id: id,
          name: map['name'] as String,
          subtask: map['subtask'] as bool? ?? false,
          iconUrl: map['iconUrl'] as String?,
        ));
      }
    }
    return types;
  }

  /// Searches users for the assignee picker.
  Future<List<JiraUser>> searchUsers(
    String query, {
    int maxResults = 20,
  }) async {
    _ensureConfigured();
    final response = await _request<List<dynamic>>(
      'GET',
      '/rest/api/3/user/search',
      queryParameters: {'query': query, 'maxResults': maxResults},
    );
    return response.data!
        .map((u) => JiraUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  /// Gets all issue priorities.
  Future<List<JiraPriority>> getPriorities() async {
    _ensureConfigured();
    final response = await _request<List<dynamic>>(
      'GET',
      '/rest/api/3/priority',
    );
    return response.data!
        .map((p) => JiraPriority.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Ensures the service is configured before making API calls.
  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'JiraService is not configured. Call configure() first.',
      );
    }
  }

  /// Makes a request with rate-limit handling.
  Future<Response<T>> _request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Rate limited — retry after the specified delay.
        final retryAfter = int.tryParse(
              e.response?.headers.value('retry-after') ?? '',
            ) ??
            5;
        await Future<void>.delayed(Duration(seconds: retryAfter));
        return _dio.request<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: Options(method: method),
        );
      }
      rethrow;
    }
  }

  /// Builds the Jira API request body for creating an issue.
  Map<String, dynamic> _buildCreateIssueBody(CreateJiraIssueRequest request) {
    final fields = <String, dynamic>{
      'project': {'key': request.projectKey},
      'issuetype': {'name': request.issueTypeName},
      'summary': request.summary,
    };
    if (request.description != null) {
      fields['description'] =
          jsonDecode(_markdownToAdf(request.description!));
    }
    if (request.assigneeAccountId != null) {
      fields['assignee'] = {'accountId': request.assigneeAccountId};
    }
    if (request.priorityName != null) {
      fields['priority'] = {'name': request.priorityName};
    }
    if (request.labels != null) fields['labels'] = request.labels;
    if (request.componentName != null) {
      fields['components'] = [
        {'name': request.componentName},
      ];
    }
    if (request.parentKey != null) {
      fields['parent'] = {'key': request.parentKey};
    }

    return {'fields': fields};
  }

  /// Converts markdown text to Jira ADF (Atlassian Document Format) JSON.
  ///
  /// Performs a basic conversion — full ADF is complex, but this covers
  /// common patterns (paragraphs, code blocks, headings, lists).
  static String _markdownToAdf(String markdown) {
    final paragraphs = markdown.split('\n\n');
    final content = <Map<String, dynamic>>[];

    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('```')) {
        // Code block
        final code = trimmed
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
        content.add({
          'type': 'codeBlock',
          'content': [
            {'type': 'text', 'text': code},
          ],
        });
      } else if (trimmed.startsWith('# ')) {
        content.add({
          'type': 'heading',
          'attrs': {'level': 1},
          'content': [
            {'type': 'text', 'text': trimmed.substring(2)},
          ],
        });
      } else if (trimmed.startsWith('## ')) {
        content.add({
          'type': 'heading',
          'attrs': {'level': 2},
          'content': [
            {'type': 'text', 'text': trimmed.substring(3)},
          ],
        });
      } else if (trimmed.startsWith('### ')) {
        content.add({
          'type': 'heading',
          'attrs': {'level': 3},
          'content': [
            {'type': 'text', 'text': trimmed.substring(4)},
          ],
        });
      } else {
        content.add({
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': trimmed},
          ],
        });
      }
    }

    if (content.isEmpty) {
      content.add({
        'type': 'paragraph',
        'content': [
          {'type': 'text', 'text': markdown},
        ],
      });
    }

    return jsonEncode({
      'version': 1,
      'type': 'doc',
      'content': content,
    });
  }
}
