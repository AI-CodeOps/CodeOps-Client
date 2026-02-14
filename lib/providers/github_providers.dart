/// Riverpod providers for GitHub connection data.
///
/// Connection data comes from the cloud service. Local git operations
/// and GitHub API calls are added in COC-004.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import 'task_providers.dart';
import 'team_providers.dart';

/// Fetches GitHub connections for the selected team.
final githubConnectionsProvider =
    FutureProvider<List<GitHubConnection>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getTeamGitHubConnections(teamId);
});
