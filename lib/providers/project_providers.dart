/// Riverpod providers for project-related data.
///
/// Exposes the [ProjectApi] service, team project lists,
/// and selected project state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../services/cloud/project_api.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

/// Provides [ProjectApi] for project endpoints.
final projectApiProvider = Provider<ProjectApi>(
  (ref) => ProjectApi(ref.watch(apiClientProvider)),
);

/// Fetches all projects for the selected team.
final teamProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final projectApi = ref.watch(projectApiProvider);
  return projectApi.getTeamProjects(teamId);
});

/// The currently selected project ID (for detail pages).
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

/// The currently selected project.
final selectedProjectProvider = FutureProvider<Project?>((ref) async {
  final projectId = ref.watch(selectedProjectIdProvider);
  if (projectId == null) return null;
  final projectApi = ref.watch(projectApiProvider);
  return projectApi.getProject(projectId);
});
