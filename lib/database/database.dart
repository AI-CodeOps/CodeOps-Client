/// CodeOps local SQLite database powered by Drift.
///
/// Provides offline caching of cloud data for the desktop application.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// The local Drift SQLite database for CodeOps.
///
/// Caches server data for offline access and fast local queries.
@DriftDatabase(tables: [
  Users,
  Teams,
  Projects,
  QaJobs,
  AgentRuns,
  Findings,
  RemediationTasks,
  Personas,
  Directives,
  TechDebtItems,
  DependencyScans,
  DependencyVulnerabilities,
  HealthSnapshots,
  ComplianceItems,
  Specifications,
  SyncMetadata,
  ClonedRepos,
  AnthropicModels,
  AgentDefinitions,
  AgentFiles,
  ProjectLocalConfig,
  ScribeTabs,
  ScribeSettings,
  DatalensConnections,
  DatalensQueryHistory,
  DatalensSavedQueries,
  UserPreferencesTable,
])
class CodeOpsDatabase extends _$CodeOpsDatabase {
  /// Creates a [CodeOpsDatabase] with the given [QueryExecutor].
  CodeOpsDatabase(super.e);

  /// Creates a [CodeOpsDatabase] using the platform-specific default location.
  factory CodeOpsDatabase.defaults() {
    return CodeOpsDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(clonedRepos);
          }
          if (from < 3) {
            await _safeAddColumn(m, qaJobs, qaJobs.configJson);
          }
          if (from < 4) {
            await _safeAddColumn(m, qaJobs, qaJobs.summaryMd);
            await _safeAddColumn(m, qaJobs, qaJobs.startedByName);
            await _safeAddColumn(m, findings, findings.statusChangedBy);
            await _safeAddColumn(m, findings, findings.statusChangedAt);
          }
          if (from < 5) {
            await m.createTable(anthropicModels);
            await m.createTable(agentDefinitions);
            await m.createTable(agentFiles);
          }
          if (from < 6) {
            await m.createTable(projectLocalConfig);
          }
          if (from < 7) {
            await m.createTable(scribeTabs);
            await m.createTable(scribeSettings);
          }
          if (from < 8) {
            await m.createTable(datalensConnections);
            await m.createTable(datalensQueryHistory);
            await m.createTable(datalensSavedQueries);
          }
          if (from < 9) {
            await _safeAddColumn(
              m,
              datalensConnections,
              datalensConnections.filePath,
            );
          }
          if (from < 10) {
            await m.createTable(userPreferencesTable);
          }
        },
      );

  /// Adds a column to a table, ignoring the error if the column already exists.
  ///
  /// SQLite does not support `ADD COLUMN IF NOT EXISTS`, so a partial migration
  /// that created the column but failed to bump `user_version` would crash on
  /// the next app launch. This wrapper makes `addColumn` idempotent.
  static Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await m.addColumn(table, column);
    } on Object catch (_) {
      // Column already exists — safe to ignore.
    }
  }

  /// Deletes all rows from every table.
  ///
  /// Used during logout to clear cached data.
  Future<void> clearAllTables() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

/// Lazy singleton instance of the database.
CodeOpsDatabase? _instance;

/// Returns the singleton [CodeOpsDatabase] instance.
CodeOpsDatabase get database => _instance ??= CodeOpsDatabase.defaults();

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'codeops.db'));
    return NativeDatabase.createInBackground(file);
  });
}
