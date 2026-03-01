/// Service for persisting query history and saved queries in DataLens.
///
/// Provides Drift-backed CRUD operations for [DatalensQueryHistory] and
/// [DatalensSavedQueries] tables. Records every query execution, supports
/// search and cleanup, and lets users bookmark queries for reuse.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/database.dart';
import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../logging/log_service.dart';

/// Persists query history and user-saved queries to the local database.
///
/// Each method operates on the Drift [DatalensQueryHistory] or
/// [DatalensSavedQueries] table through the injected [CodeOpsDatabase].
class QueryHistoryService {
  static const String _tag = 'QueryHistoryService';
  static const _uuid = Uuid();

  /// The local Drift database.
  final CodeOpsDatabase _db;

  /// Creates a [QueryHistoryService] with the given [database].
  QueryHistoryService(CodeOpsDatabase database) : _db = database;

  // ---------------------------------------------------------------------------
  // Query History — Record & Read
  // ---------------------------------------------------------------------------

  /// Records a query execution in the history table.
  ///
  /// Generates a UUID v4 primary key and timestamps the entry with the
  /// current time.
  Future<void> recordExecution({
    required String connectionId,
    required String sql,
    required QueryStatus status,
    int? rowCount,
    required int executionTimeMs,
    String? error,
  }) async {
    log.d(_tag, 'Recording query execution for $connectionId');
    await _db.into(_db.datalensQueryHistory).insert(
          DatalensQueryHistoryCompanion(
            id: Value(_uuid.v4()),
            connectionId: Value(connectionId),
            sql: Value(sql),
            status: Value(status.toJson()),
            rowCount: Value(rowCount),
            executionTimeMs: Value(executionTimeMs),
            error: Value(error),
            executedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Returns query history for [connectionId], ordered newest-first.
  ///
  /// Optionally limits the number of entries returned via [limit].
  Future<List<QueryHistoryEntry>> getHistory(
    String connectionId, {
    int? limit,
  }) async {
    log.d(_tag, 'getHistory($connectionId, limit=$limit)');
    final query = _db.select(_db.datalensQueryHistory)
      ..where((t) => t.connectionId.equals(connectionId))
      ..orderBy([(t) => OrderingTerm.desc(t.executedAt)]);
    if (limit != null) {
      query.limit(limit);
    }
    final rows = await query.get();
    return rows.map(_historyRowToModel).toList();
  }

  /// Searches query history for [connectionId] where the SQL contains
  /// [searchTerm] (case-insensitive).
  ///
  /// Results are ordered newest-first.
  Future<List<QueryHistoryEntry>> searchHistory(
    String connectionId,
    String searchTerm,
  ) async {
    log.d(_tag, 'searchHistory($connectionId, "$searchTerm")');
    final query = _db.select(_db.datalensQueryHistory)
      ..where((t) =>
          t.connectionId.equals(connectionId) &
          t.sql.like('%$searchTerm%'))
      ..orderBy([(t) => OrderingTerm.desc(t.executedAt)]);
    final rows = await query.get();
    return rows.map(_historyRowToModel).toList();
  }

  // ---------------------------------------------------------------------------
  // Query History — Cleanup
  // ---------------------------------------------------------------------------

  /// Deletes all history entries for [connectionId].
  Future<void> clearHistory(String connectionId) async {
    log.i(_tag, 'Clearing history for $connectionId');
    await (_db.delete(_db.datalensQueryHistory)
          ..where((t) => t.connectionId.equals(connectionId)))
        .go();
  }

  /// Deletes history entries executed before [cutoff].
  Future<void> clearHistoryBefore(DateTime cutoff) async {
    log.i(_tag, 'Clearing history before $cutoff');
    await (_db.delete(_db.datalensQueryHistory)
          ..where((t) => t.executedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Returns the number of history entries for [connectionId].
  Future<int> getHistoryCount(String connectionId) async {
    final count = _db.datalensQueryHistory.id.count();
    final query = _db.selectOnly(_db.datalensQueryHistory)
      ..addColumns([count])
      ..where(_db.datalensQueryHistory.connectionId.equals(connectionId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Saved Queries — CRUD
  // ---------------------------------------------------------------------------

  /// Saves a new query and returns it as read back from the database.
  ///
  /// Generates a UUID v4 primary key and sets [createdAt] to now.
  Future<SavedQuery> saveQuery({
    required String connectionId,
    required String name,
    required String sql,
    String? description,
    String? folder,
  }) async {
    log.i(_tag, 'Saving query "$name" for $connectionId');
    final id = _uuid.v4();
    await _db.into(_db.datalensSavedQueries).insert(
          DatalensSavedQueriesCompanion(
            id: Value(id),
            connectionId: Value(connectionId),
            name: Value(name),
            description: Value(description),
            sql: Value(sql),
            folder: Value(folder),
            createdAt: Value(DateTime.now()),
          ),
        );
    return (await _getSavedQueryById(id))!;
  }

  /// Updates an existing saved query and returns the updated record.
  ///
  /// Sets [updatedAt] to now.
  Future<SavedQuery> updateSavedQuery(SavedQuery query) async {
    log.i(_tag, 'Updating saved query "${query.name}" (${query.id})');
    await (_db.update(_db.datalensSavedQueries)
          ..where((t) => t.id.equals(query.id!)))
        .write(
      DatalensSavedQueriesCompanion(
        name: Value(query.name ?? ''),
        description: Value(query.description),
        sql: Value(query.sql ?? ''),
        folder: Value(query.folder),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (await _getSavedQueryById(query.id!))!;
  }

  /// Deletes the saved query identified by [queryId].
  Future<void> deleteSavedQuery(String queryId) async {
    log.i(_tag, 'Deleting saved query $queryId');
    await (_db.delete(_db.datalensSavedQueries)
          ..where((t) => t.id.equals(queryId)))
        .go();
  }

  /// Returns all saved queries for [connectionId], ordered by name.
  Future<List<SavedQuery>> getSavedQueries(String connectionId) async {
    log.d(_tag, 'getSavedQueries($connectionId)');
    final query = _db.select(_db.datalensSavedQueries)
      ..where((t) => t.connectionId.equals(connectionId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await query.get();
    return rows.map(_savedQueryRowToModel).toList();
  }

  /// Returns saved queries for [connectionId] within a specific [folder].
  Future<List<SavedQuery>> getSavedQueriesByFolder(
    String connectionId,
    String folder,
  ) async {
    log.d(_tag, 'getSavedQueriesByFolder($connectionId, "$folder")');
    final query = _db.select(_db.datalensSavedQueries)
      ..where((t) =>
          t.connectionId.equals(connectionId) & t.folder.equals(folder))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await query.get();
    return rows.map(_savedQueryRowToModel).toList();
  }

  /// Returns the distinct folder names used by saved queries for
  /// [connectionId], sorted alphabetically.
  Future<List<String>> getFolders(String connectionId) async {
    log.d(_tag, 'getFolders($connectionId)');
    final folderCol = _db.datalensSavedQueries.folder;
    final query = _db.selectOnly(_db.datalensSavedQueries, distinct: true)
      ..addColumns([folderCol])
      ..where(_db.datalensSavedQueries.connectionId.equals(connectionId) &
          folderCol.isNotNull())
      ..orderBy([OrderingTerm.asc(folderCol)]);
    final rows = await query.get();
    return rows.map((row) => row.read(folderCol)!).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Fetches a single saved query by [id].
  Future<SavedQuery?> _getSavedQueryById(String id) async {
    final row = await (_db.select(_db.datalensSavedQueries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _savedQueryRowToModel(row);
  }

  /// Converts a Drift [DatalensQueryHistoryData] row to a
  /// [QueryHistoryEntry] model.
  QueryHistoryEntry _historyRowToModel(DatalensQueryHistoryData row) {
    return QueryHistoryEntry(
      id: row.id,
      connectionId: row.connectionId,
      sql: row.sql,
      status: QueryStatus.fromJson(row.status),
      rowCount: row.rowCount,
      executionTimeMs: row.executionTimeMs,
      error: row.error,
      executedAt: row.executedAt,
    );
  }

  /// Converts a Drift [DatalensSavedQuery] row to a [SavedQuery] model.
  SavedQuery _savedQueryRowToModel(DatalensSavedQuery row) {
    return SavedQuery(
      id: row.id,
      connectionId: row.connectionId,
      name: row.name,
      description: row.description,
      sql: row.sql,
      folder: row.folder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
