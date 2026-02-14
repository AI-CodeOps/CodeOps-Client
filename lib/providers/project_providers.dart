/// Riverpod providers for project-related data.
///
/// Exposes the [ProjectApi] service, team project lists,
/// selected project state, favorites, filtering, sorting, and sync.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/project.dart';
import '../models/qa_job.dart';
import '../services/cloud/project_api.dart';
import '../services/data/sync_service.dart';
import 'auth_providers.dart';
import 'health_providers.dart';
import 'job_providers.dart';
import 'task_providers.dart';
import 'team_providers.dart';

// ---------------------------------------------------------------------------
// Sort & filter enums
// ---------------------------------------------------------------------------

/// Sort order options for the projects list.
enum ProjectSortOrder {
  /// Sort alphabetically by name (A-Z).
  nameAsc,

  /// Sort by health score (lowest first).
  healthScoreAsc,

  /// Sort by health score (highest first).
  healthScoreDesc,

  /// Sort by last audit date (most recent first).
  lastAuditDesc,
}

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

/// Provides [ProjectApi] for project endpoints.
final projectApiProvider = Provider<ProjectApi>(
  (ref) => ProjectApi(ref.watch(apiClientProvider)),
);

/// Provides [SyncService] for project cloud sync.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    projectApi: ref.watch(projectApiProvider),
    database: ref.watch(databaseProvider),
  );
});

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------

/// The currently selected project ID (for detail pages).
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

/// Current sync state for project data.
final projectSyncStateProvider = StateProvider<SyncState>((ref) {
  return SyncState.idle;
});

/// Search query for filtering the projects list.
final projectSearchQueryProvider = StateProvider<String>((ref) => '');

/// Sort order for the projects list.
final projectSortProvider = StateProvider<ProjectSortOrder>((ref) {
  return ProjectSortOrder.nameAsc;
});

/// Whether to show archived projects.
final showArchivedProvider = StateProvider<bool>((ref) => false);

/// Set of project IDs marked as favorites.
final favoriteProjectIdsProvider =
    StateNotifierProvider<FavoriteProjectsNotifier, Set<String>>(
  (ref) => FavoriteProjectsNotifier(),
);

/// Notifier for managing favorite project IDs.
class FavoriteProjectsNotifier extends StateNotifier<Set<String>> {
  /// Creates a [FavoriteProjectsNotifier] with an empty initial set.
  FavoriteProjectsNotifier() : super({});

  /// Toggles a project ID in or out of the favorites set.
  void toggle(String projectId) {
    if (state.contains(projectId)) {
      state = {...state}..remove(projectId);
    } else {
      state = {...state, projectId};
    }
  }

  /// Returns whether a project is favorited.
  bool isFavorite(String projectId) => state.contains(projectId);
}

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// Fetches all projects for the selected team.
final teamProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final projectApi = ref.watch(projectApiProvider);
  return projectApi.getTeamProjects(teamId, includeArchived: true);
});

/// The currently selected project.
final selectedProjectProvider = FutureProvider<Project?>((ref) async {
  final projectId = ref.watch(selectedProjectIdProvider);
  if (projectId == null) return null;
  final projectApi = ref.watch(projectApiProvider);
  return projectApi.getProject(projectId);
});

/// Fetches a single project by ID.
final projectProvider =
    FutureProvider.family<Project, String>((ref, projectId) async {
  final projectApi = ref.watch(projectApiProvider);
  return projectApi.getProject(projectId);
});

/// Fetches recent jobs for a project (first page, small size).
final projectRecentJobsProvider =
    FutureProvider.family<PageResponse<JobSummary>, String>(
  (ref, projectId) async {
    final jobApi = ref.watch(jobApiProvider);
    return jobApi.getProjectJobs(projectId, page: 0, size: 10);
  },
);

/// Fetches health trend data for a project.
final projectHealthTrendProvider =
    FutureProvider.family<List<HealthSnapshot>, String>(
  (ref, projectId) async {
    final metricsApi = ref.watch(metricsApiProvider);
    return metricsApi.getProjectTrend(projectId);
  },
);

// ---------------------------------------------------------------------------
// Filtered / sorted provider
// ---------------------------------------------------------------------------

/// Projects filtered by search query, sort order, archived flag, and favorites.
final filteredProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final projectsAsync = ref.watch(teamProjectsProvider);
  final query = ref.watch(projectSearchQueryProvider).toLowerCase();
  final sortOrder = ref.watch(projectSortProvider);
  final showArchived = ref.watch(showArchivedProvider);
  final favorites = ref.watch(favoriteProjectIdsProvider);

  return projectsAsync.whenData((projects) {
    // Filter archived.
    var filtered = showArchived
        ? projects
        : projects.where((p) => p.isArchived != true).toList();

    // Filter by search query.
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.repoFullName?.toLowerCase().contains(query) ?? false) ||
            (p.techStack?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort.
    filtered.sort((a, b) {
      // Favorites always sort first.
      final aFav = favorites.contains(a.id);
      final bFav = favorites.contains(b.id);
      if (aFav != bFav) return aFav ? -1 : 1;

      return switch (sortOrder) {
        ProjectSortOrder.nameAsc =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        ProjectSortOrder.healthScoreAsc =>
          (a.healthScore ?? 0).compareTo(b.healthScore ?? 0),
        ProjectSortOrder.healthScoreDesc =>
          (b.healthScore ?? 0).compareTo(a.healthScore ?? 0),
        ProjectSortOrder.lastAuditDesc => (b.lastAuditAt ?? DateTime(2000))
            .compareTo(a.lastAuditAt ?? DateTime(2000)),
      };
    });

    return filtered;
  });
});

/// Jira connections for the selected team (for create/edit dialogs).
final jiraConnectionsProvider =
    FutureProvider<List<JiraConnection>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getTeamJiraConnections(teamId);
});
