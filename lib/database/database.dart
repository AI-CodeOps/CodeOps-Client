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
])
class CodeOpsDatabase extends _$CodeOpsDatabase {
  /// Creates a [CodeOpsDatabase] with the given [QueryExecutor].
  CodeOpsDatabase(super.e);

  /// Creates a [CodeOpsDatabase] using the platform-specific default location.
  factory CodeOpsDatabase.defaults() {
    return CodeOpsDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(clonedRepos);
          }
          if (from < 3) {
            await m.addColumn(qaJobs, qaJobs.configJson);
          }
        },
      );

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
