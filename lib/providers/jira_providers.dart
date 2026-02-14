/// Riverpod providers for Jira integration state management.
///
/// Manages Jira connections, the configured [JiraService] instance,
/// search state, issue details, and metadata (projects, types, users).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/jira_models.dart';
import '../services/auth/secure_storage.dart';
import '../services/jira/jira_service.dart';
import 'auth_providers.dart';
import 'task_providers.dart';
import 'team_providers.dart';

// ---------------------------------------------------------------------------
// Secure storage keys for Jira credentials
// ---------------------------------------------------------------------------

/// Secure storage key prefix for Jira API tokens.
const _jiraTokenKeyPrefix = 'jira_api_token_';

/// Builds the secure storage key for a Jira connection's API token.
String jiraTokenKey(String connectionId) =>
    '$_jiraTokenKeyPrefix$connectionId';

// ---------------------------------------------------------------------------
// Connection state
// ---------------------------------------------------------------------------

/// Fetches Jira connections for the selected team.
final jiraConnectionsProvider =
    FutureProvider<List<JiraConnection>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getTeamJiraConnections(teamId);
});

/// The currently selected/active Jira connection.
final activeJiraConnectionProvider =
    StateProvider<JiraConnection?>((ref) => null);

/// Configured [JiraService] instance.
///
/// Automatically reconfigures when the active connection changes.
/// Returns `null` if no connection is active or the API token is not available.
final jiraServiceProvider = FutureProvider<JiraService?>((ref) async {
  final connection = ref.watch(activeJiraConnectionProvider);
  if (connection == null) return null;

  final secureStorage = ref.watch(secureStorageProvider);
  final apiToken = await secureStorage.read(jiraTokenKey(connection.id));
  if (apiToken == null) return null;

  final service = JiraService();
  service.configure(
    instanceUrl: connection.instanceUrl,
    email: connection.email,
    apiToken: apiToken,
  );
  return service;
});

/// Whether Jira is currently configured and usable.
final isJiraConfiguredProvider = Provider<bool>((ref) {
  final serviceAsync = ref.watch(jiraServiceProvider);
  return serviceAsync.valueOrNull != null;
});

// ---------------------------------------------------------------------------
// Issue state
// ---------------------------------------------------------------------------

/// Current JQL search query.
final jiraSearchQueryProvider = StateProvider<String>((ref) => '');

/// Current search page offset.
final jiraSearchStartAtProvider = StateProvider<int>((ref) => 0);

/// Jira search results (paginated).
///
/// Watches the search query and re-fetches when it changes.
final jiraSearchResultsProvider =
    FutureProvider.autoDispose<JiraSearchResult?>((ref) async {
  final jql = ref.watch(jiraSearchQueryProvider);
  if (jql.isEmpty) return null;

  final service = await ref.watch(jiraServiceProvider.future);
  if (service == null) return null;

  final startAt = ref.watch(jiraSearchStartAtProvider);
  return service.searchIssues(jql: jql, startAt: startAt);
});

/// Single issue detail (by key).
final jiraIssueProvider =
    FutureProvider.autoDispose.family<JiraIssue?, String>(
  (ref, issueKey) async {
    final service = await ref.watch(jiraServiceProvider.future);
    if (service == null) return null;
    return service.getIssue(issueKey);
  },
);

/// Comments for an issue.
final jiraCommentsProvider =
    FutureProvider.autoDispose.family<List<JiraComment>, String>(
  (ref, issueKey) async {
    final service = await ref.watch(jiraServiceProvider.future);
    if (service == null) return [];
    return service.getComments(issueKey);
  },
);

// ---------------------------------------------------------------------------
// Currently selected issue in the browser
// ---------------------------------------------------------------------------

/// The currently selected issue key in the Jira browser.
final selectedJiraIssueKeyProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Metadata providers
// ---------------------------------------------------------------------------

/// Jira projects the user has access to.
final jiraProjectsProvider =
    FutureProvider.autoDispose<List<JiraProject>>((ref) async {
  final service = await ref.watch(jiraServiceProvider.future);
  if (service == null) return [];
  return service.getProjects();
});

/// Issue types for a specific Jira project.
final jiraIssueTypesProvider =
    FutureProvider.autoDispose.family<List<JiraIssueType>, String>(
  (ref, projectKey) async {
    final service = await ref.watch(jiraServiceProvider.future);
    if (service == null) return [];
    return service.getIssueTypes(projectKey);
  },
);

/// Jira user search results (for assignee picker).
final jiraUserSearchProvider =
    FutureProvider.autoDispose.family<List<JiraUser>, String>(
  (ref, query) async {
    final service = await ref.watch(jiraServiceProvider.future);
    if (service == null) return [];
    if (query.isEmpty) return [];
    return service.searchUsers(query);
  },
);

/// Jira priorities.
final jiraPrioritiesProvider =
    FutureProvider.autoDispose<List<JiraPriority>>((ref) async {
  final service = await ref.watch(jiraServiceProvider.future);
  if (service == null) return [];
  return service.getPriorities();
});

/// Sprints for a board.
final jiraSprintsProvider =
    FutureProvider.autoDispose.family<List<JiraSprint>, int>(
  (ref, boardId) async {
    final service = await ref.watch(jiraServiceProvider.future);
    if (service == null) return [];
    return service.getSprints(boardId);
  },
);

/// Transitions for an issue.
final jiraTransitionsProvider =
    FutureProvider.autoDispose.family<List<JiraTransition>, String>(
  (ref, issueKey) async {
    final service = await ref.watch(jiraServiceProvider.future);
    if (service == null) return [];
    return service.getTransitions(issueKey);
  },
);

// ---------------------------------------------------------------------------
// Helper: save/delete Jira API token in secure storage
// ---------------------------------------------------------------------------

/// Saves a Jira API token to secure storage.
Future<void> saveJiraApiToken(
  SecureStorageService storage,
  String connectionId,
  String apiToken,
) async {
  await storage.write(jiraTokenKey(connectionId), apiToken);
}

/// Deletes a Jira API token from secure storage.
Future<void> deleteJiraApiToken(
  SecureStorageService storage,
  String connectionId,
) async {
  await storage.delete(jiraTokenKey(connectionId));
}
