/// Cloud sync service for project data.
///
/// Fetches projects from the server and upserts them into the local
/// Drift database. Handles offline scenarios gracefully.
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/database.dart' as db;
import '../../models/project.dart';
import '../cloud/api_exceptions.dart';
import '../cloud/project_api.dart';

/// Current state of a sync operation.
enum SyncState {
  /// No sync in progress.
  idle,

  /// Sync is actively running.
  syncing,

  /// Sync completed successfully.
  synced,

  /// Sync failed (offline or server error).
  error,
}

/// Synchronizes project data between the server and local database.
class SyncService {
  final ProjectApi _projectApi;
  final db.CodeOpsDatabase _database;

  /// Creates a [SyncService] backed by the given [projectApi] and [database].
  SyncService({
    required ProjectApi projectApi,
    required db.CodeOpsDatabase database,
  })  : _projectApi = projectApi,
        _database = database;

  /// Syncs all projects for a team from the server to local DB.
  ///
  /// Fetches the full project list, upserts each into the local
  /// [Projects] table, removes stale local records, and updates
  /// [SyncMetadata] with the current timestamp.
  ///
  /// Returns the synced project list on success. Falls back to
  /// locally cached data on network/timeout errors.
  Future<List<Project>> syncProjects(String teamId) async {
    try {
      final projects = await _projectApi.getTeamProjects(
        teamId,
        includeArchived: true,
      );

      // Upsert each project into local DB.
      for (final project in projects) {
        await _database.into(_database.projects).insertOnConflictUpdate(
              db.ProjectsCompanion(
                id: Value(project.id),
                teamId: Value(project.teamId),
                name: Value(project.name),
                description: Value(project.description),
                githubConnectionId: Value(project.githubConnectionId),
                repoUrl: Value(project.repoUrl),
                repoFullName: Value(project.repoFullName),
                defaultBranch: Value(project.defaultBranch),
                jiraConnectionId: Value(project.jiraConnectionId),
                jiraProjectKey: Value(project.jiraProjectKey),
                techStack: Value(project.techStack),
                healthScore: Value(project.healthScore),
                isArchived: Value(project.isArchived ?? false),
              ),
            );
      }

      // Remove local projects not present on server.
      final serverIds = projects.map((p) => p.id).toSet();
      final localProjects = await (_database.select(_database.projects)
            ..where((t) => t.teamId.equals(teamId)))
          .get();
      for (final local in localProjects) {
        if (!serverIds.contains(local.id)) {
          await (_database.delete(_database.projects)
                ..where((t) => t.id.equals(local.id)))
              .go();
        }
      }

      // Update sync metadata.
      await _database.into(_database.syncMetadata).insertOnConflictUpdate(
            db.SyncMetadataCompanion(
              syncTableName: const Value('projects'),
              lastSyncAt: Value(DateTime.now()),
            ),
          );

      return projects;
    } on NetworkException {
      return _readLocalProjects(teamId);
    } on TimeoutException {
      return _readLocalProjects(teamId);
    }
  }

  /// Pushes a local project to the server via create or update.
  ///
  /// If the project has no server-side ID (new), creates it.
  /// Otherwise updates the existing record.
  Future<Project> syncProjectToCloud(
    Project project,
    String teamId,
  ) async {
    try {
      // Try update first — if 404, fall through to create.
      return await _projectApi.updateProject(
        project.id,
        name: project.name,
        description: project.description,
        githubConnectionId: project.githubConnectionId,
        repoUrl: project.repoUrl,
        repoFullName: project.repoFullName,
        defaultBranch: project.defaultBranch,
        jiraConnectionId: project.jiraConnectionId,
        jiraProjectKey: project.jiraProjectKey,
        techStack: project.techStack,
      );
    } on NotFoundException {
      return await _projectApi.createProject(
        teamId,
        name: project.name,
        description: project.description,
        githubConnectionId: project.githubConnectionId,
        repoUrl: project.repoUrl,
        repoFullName: project.repoFullName,
        defaultBranch: project.defaultBranch,
        jiraConnectionId: project.jiraConnectionId,
        jiraProjectKey: project.jiraProjectKey,
        techStack: project.techStack,
      );
    }
  }

  /// Reads projects from local DB when offline.
  Future<List<Project>> _readLocalProjects(String teamId) async {
    final rows = await (_database.select(_database.projects)
          ..where((t) => t.teamId.equals(teamId)))
        .get();
    return rows
        .map((r) => Project(
              id: r.id,
              teamId: r.teamId,
              name: r.name,
              description: r.description,
              githubConnectionId: r.githubConnectionId,
              repoUrl: r.repoUrl,
              repoFullName: r.repoFullName,
              defaultBranch: r.defaultBranch,
              jiraConnectionId: r.jiraConnectionId,
              jiraProjectKey: r.jiraProjectKey,
              techStack: r.techStack,
              healthScore: r.healthScore,
              isArchived: r.isArchived,
            ))
        .toList();
  }
}
