/// Riverpod providers for Jira connection data.
///
/// Connection data comes from the cloud service. Jira REST API calls
/// are added in COC-009.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import 'task_providers.dart';
import 'team_providers.dart';

/// Fetches Jira connections for the selected team.
final jiraConnectionsProvider =
    FutureProvider<List<JiraConnection>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getTeamJiraConnections(teamId);
});
