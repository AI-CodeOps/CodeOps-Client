/// Manages cloned repositories on the local filesystem.
///
/// Tracks repo locations in the Drift database and provides methods
/// for registering, unregistering, and querying cloned repos.
library;

import 'dart:io';

import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../models/vcs_models.dart';
import 'git_service.dart';

/// Manages the local directory of cloned git repositories.
class RepoManager {
  final GitService _gitService;
  final CodeOpsDatabase _database;

  /// Creates a [RepoManager].
  RepoManager({
    required GitService gitService,
    required CodeOpsDatabase database,
  })  : _gitService = gitService,
        _database = database;

  /// Returns the default directory for cloned repos.
  ///
  /// `~/CodeOps/repos/` on macOS and Linux.
  String getDefaultRepoDir() {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/CodeOps/repos';
  }

  /// Returns the expected local path for a repository by [fullName].
  String getRepoPath(String fullName) {
    return '${getDefaultRepoDir()}/$fullName';
  }

  /// Registers a cloned repository in the database.
  Future<void> registerRepo({
    required String repoFullName,
    required String localPath,
    String? projectId,
  }) async {
    await _database.into(_database.clonedRepos).insertOnConflictUpdate(
          ClonedReposCompanion.insert(
            repoFullName: repoFullName,
            localPath: localPath,
            projectId: Value(projectId),
            clonedAt: Value(DateTime.now()),
            lastAccessedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Removes a cloned repository from the database.
  ///
  /// Does NOT delete files on disk.
  Future<void> unregisterRepo(String repoFullName) async {
    await (_database.delete(_database.clonedRepos)
          ..where((t) => t.repoFullName.equals(repoFullName)))
        .go();
  }

  /// Returns all registered repos as a map of fullName → localPath.
  Future<Map<String, String>> getAllRepos() async {
    final rows = await _database.select(_database.clonedRepos).get();
    return {for (final row in rows) row.repoFullName: row.localPath};
  }

  /// Whether a repo is registered and its directory exists on disk.
  Future<bool> isCloned(String repoFullName) async {
    final rows = await (_database.select(_database.clonedRepos)
          ..where((t) => t.repoFullName.equals(repoFullName)))
        .get();
    if (rows.isEmpty) return false;
    return Directory(rows.first.localPath).existsSync();
  }

  /// Returns the working tree status for a registered repo.
  ///
  /// Returns `null` if the repo is not cloned.
  Future<RepoStatus?> getRepoStatus(String repoFullName) async {
    final rows = await (_database.select(_database.clonedRepos)
          ..where((t) => t.repoFullName.equals(repoFullName)))
        .get();
    if (rows.isEmpty) return null;
    final localPath = rows.first.localPath;
    if (!Directory(localPath).existsSync()) return null;

    // Update last accessed time.
    await (_database.update(_database.clonedRepos)
          ..where((t) => t.repoFullName.equals(repoFullName)))
        .write(
      ClonedReposCompanion(lastAccessedAt: Value(DateTime.now())),
    );

    return _gitService.status(localPath);
  }

  /// Opens the repo directory in the platform file manager.
  Future<void> openInFileManager(String localPath) async {
    if (Platform.isMacOS) {
      await Process.run('open', [localPath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [localPath]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [localPath]);
    }
  }

  /// Checks whether [path] is a valid git repository.
  Future<bool> isValidGitRepo(String path) async {
    if (!Directory(path).existsSync()) return false;
    try {
      await _gitService.currentBranch(path);
      return true;
    } on GitException {
      return false;
    }
  }
}
