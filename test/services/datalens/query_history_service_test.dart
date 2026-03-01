// Tests for QueryHistoryService.
//
// Uses a real in-memory Drift database to verify Drift CRUD operations on
// DatalensQueryHistory and DatalensSavedQueries tables. No mocks needed —
// all operations are against the local SQLite database.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/database/database.dart';
import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/services/datalens/query_history_service.dart';

void main() {
  late CodeOpsDatabase db;
  late QueryHistoryService service;

  setUp(() {
    db = CodeOpsDatabase(NativeDatabase.memory());
    service = QueryHistoryService(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // recordExecution
  // ---------------------------------------------------------------------------
  group('recordExecution', () {
    test('records a completed query execution', () async {
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'SELECT 1',
        status: QueryStatus.completed,
        rowCount: 1,
        executionTimeMs: 42,
      );

      final history = await service.getHistory('conn-1');
      expect(history, hasLength(1));
      expect(history.first.connectionId, 'conn-1');
      expect(history.first.sql, 'SELECT 1');
      expect(history.first.status, QueryStatus.completed);
      expect(history.first.rowCount, 1);
      expect(history.first.executionTimeMs, 42);
      expect(history.first.error, isNull);
      expect(history.first.id, isNotNull);
      expect(history.first.executedAt, isNotNull);
    });

    test('records a failed query execution with error', () async {
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'INVALID SQL',
        status: QueryStatus.failed,
        executionTimeMs: 5,
        error: 'syntax error',
      );

      final history = await service.getHistory('conn-1');
      expect(history, hasLength(1));
      expect(history.first.status, QueryStatus.failed);
      expect(history.first.error, 'syntax error');
    });
  });

  // ---------------------------------------------------------------------------
  // getHistory
  // ---------------------------------------------------------------------------
  group('getHistory', () {
    test('returns empty list when no history exists', () async {
      final history = await service.getHistory('conn-1');
      expect(history, isEmpty);
    });

    test('returns entries ordered newest-first', () async {
      // Insert directly with controlled timestamps to avoid same-second
      // collisions (Drift stores DateTime as integer seconds).
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion(
              id: const Value('h-1'),
              connectionId: const Value('conn-1'),
              sql: const Value('SELECT 1'),
              status: const Value('COMPLETED'),
              executionTimeMs: const Value(10),
              executedAt: Value(DateTime.utc(2025)),
            ),
          );
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion(
              id: const Value('h-2'),
              connectionId: const Value('conn-1'),
              sql: const Value('SELECT 2'),
              status: const Value('COMPLETED'),
              executionTimeMs: const Value(20),
              executedAt: Value(DateTime.utc(2026)),
            ),
          );

      final history = await service.getHistory('conn-1');
      expect(history, hasLength(2));
      expect(history.first.sql, 'SELECT 2');
      expect(history.last.sql, 'SELECT 1');
    });

    test('limits the number of entries returned', () async {
      for (var i = 0; i < 5; i++) {
        await service.recordExecution(
          connectionId: 'conn-1',
          sql: 'SELECT $i',
          status: QueryStatus.completed,
          executionTimeMs: i,
        );
      }

      final history = await service.getHistory('conn-1', limit: 3);
      expect(history, hasLength(3));
    });

    test('only returns history for the specified connection', () async {
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'SELECT 1',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );
      await service.recordExecution(
        connectionId: 'conn-2',
        sql: 'SELECT 2',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );

      final history = await service.getHistory('conn-1');
      expect(history, hasLength(1));
      expect(history.first.sql, 'SELECT 1');
    });
  });

  // ---------------------------------------------------------------------------
  // searchHistory
  // ---------------------------------------------------------------------------
  group('searchHistory', () {
    test('finds entries matching the search term', () async {
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'SELECT * FROM users',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'SELECT * FROM orders',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );

      final results = await service.searchHistory('conn-1', 'users');
      expect(results, hasLength(1));
      expect(results.first.sql, 'SELECT * FROM users');
    });

    test('returns empty list when no entries match', () async {
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'SELECT 1',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );

      final results = await service.searchHistory('conn-1', 'nonexistent');
      expect(results, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // clearHistory
  // ---------------------------------------------------------------------------
  group('clearHistory', () {
    test('deletes all history for the specified connection', () async {
      await service.recordExecution(
        connectionId: 'conn-1',
        sql: 'SELECT 1',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );
      await service.recordExecution(
        connectionId: 'conn-2',
        sql: 'SELECT 2',
        status: QueryStatus.completed,
        executionTimeMs: 10,
      );

      await service.clearHistory('conn-1');

      final conn1History = await service.getHistory('conn-1');
      final conn2History = await service.getHistory('conn-2');
      expect(conn1History, isEmpty);
      expect(conn2History, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // clearHistoryBefore
  // ---------------------------------------------------------------------------
  group('clearHistoryBefore', () {
    test('deletes entries before the cutoff date', () async {
      // Insert records with specific timestamps via raw SQL to avoid
      // relying on wall-clock delays (Drift stores DateTime as integer
      // seconds, so sub-second delays produce identical stored values).
      final oldTime = DateTime.utc(2025);
      final newTime = DateTime.utc(2026);
      final cutoff = DateTime.utc(2025, 7);

      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion(
              id: const Value('old-1'),
              connectionId: const Value('conn-1'),
              sql: const Value('SELECT old'),
              status: const Value('COMPLETED'),
              executionTimeMs: const Value(10),
              executedAt: Value(oldTime),
            ),
          );
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion(
              id: const Value('new-1'),
              connectionId: const Value('conn-1'),
              sql: const Value('SELECT new'),
              status: const Value('COMPLETED'),
              executionTimeMs: const Value(10),
              executedAt: Value(newTime),
            ),
          );

      await service.clearHistoryBefore(cutoff);

      final history = await service.getHistory('conn-1');
      expect(history, hasLength(1));
      expect(history.first.sql, 'SELECT new');
    });
  });

  // ---------------------------------------------------------------------------
  // getHistoryCount
  // ---------------------------------------------------------------------------
  group('getHistoryCount', () {
    test('returns zero when no history exists', () async {
      final count = await service.getHistoryCount('conn-1');
      expect(count, 0);
    });

    test('returns the correct count', () async {
      for (var i = 0; i < 4; i++) {
        await service.recordExecution(
          connectionId: 'conn-1',
          sql: 'SELECT $i',
          status: QueryStatus.completed,
          executionTimeMs: i,
        );
      }

      final count = await service.getHistoryCount('conn-1');
      expect(count, 4);
    });
  });

  // ---------------------------------------------------------------------------
  // saveQuery
  // ---------------------------------------------------------------------------
  group('saveQuery', () {
    test('saves a query and returns it', () async {
      final saved = await service.saveQuery(
        connectionId: 'conn-1',
        name: 'User Count',
        sql: 'SELECT COUNT(*) FROM users',
        description: 'Counts all users',
        folder: 'Analytics',
      );

      expect(saved.id, isNotNull);
      expect(saved.connectionId, 'conn-1');
      expect(saved.name, 'User Count');
      expect(saved.sql, 'SELECT COUNT(*) FROM users');
      expect(saved.description, 'Counts all users');
      expect(saved.folder, 'Analytics');
      expect(saved.createdAt, isNotNull);
    });

    test('saves a query without optional fields', () async {
      final saved = await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Simple',
        sql: 'SELECT 1',
      );

      expect(saved.description, isNull);
      expect(saved.folder, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // updateSavedQuery
  // ---------------------------------------------------------------------------
  group('updateSavedQuery', () {
    test('updates name and SQL and sets updatedAt', () async {
      final saved = await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Old Name',
        sql: 'SELECT 1',
      );

      final updated = await service.updateSavedQuery(SavedQuery(
        id: saved.id,
        connectionId: saved.connectionId,
        name: 'New Name',
        sql: 'SELECT 2',
      ));

      expect(updated.name, 'New Name');
      expect(updated.sql, 'SELECT 2');
      expect(updated.updatedAt, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteSavedQuery
  // ---------------------------------------------------------------------------
  group('deleteSavedQuery', () {
    test('removes the saved query', () async {
      final saved = await service.saveQuery(
        connectionId: 'conn-1',
        name: 'To Delete',
        sql: 'SELECT 1',
      );

      await service.deleteSavedQuery(saved.id!);

      final queries = await service.getSavedQueries('conn-1');
      expect(queries, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getSavedQueries
  // ---------------------------------------------------------------------------
  group('getSavedQueries', () {
    test('returns empty list when no saved queries exist', () async {
      final queries = await service.getSavedQueries('conn-1');
      expect(queries, isEmpty);
    });

    test('returns queries ordered by name', () async {
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Zulu',
        sql: 'SELECT 3',
      );
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Alpha',
        sql: 'SELECT 1',
      );
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Mike',
        sql: 'SELECT 2',
      );

      final queries = await service.getSavedQueries('conn-1');
      expect(queries.map((q) => q.name).toList(), ['Alpha', 'Mike', 'Zulu']);
    });
  });

  // ---------------------------------------------------------------------------
  // getSavedQueriesByFolder
  // ---------------------------------------------------------------------------
  group('getSavedQueriesByFolder', () {
    test('filters by folder', () async {
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q1',
        sql: 'SELECT 1',
        folder: 'Reports',
      );
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q2',
        sql: 'SELECT 2',
        folder: 'Admin',
      );
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q3',
        sql: 'SELECT 3',
        folder: 'Reports',
      );

      final reports =
          await service.getSavedQueriesByFolder('conn-1', 'Reports');
      expect(reports, hasLength(2));
      expect(reports.every((q) => q.folder == 'Reports'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // getFolders
  // ---------------------------------------------------------------------------
  group('getFolders', () {
    test('returns empty list when no folders exist', () async {
      final folders = await service.getFolders('conn-1');
      expect(folders, isEmpty);
    });

    test('returns distinct folder names sorted alphabetically', () async {
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q1',
        sql: 'SELECT 1',
        folder: 'Zulu',
      );
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q2',
        sql: 'SELECT 2',
        folder: 'Alpha',
      );
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q3',
        sql: 'SELECT 3',
        folder: 'Zulu',
      );
      // Query with no folder — should not appear.
      await service.saveQuery(
        connectionId: 'conn-1',
        name: 'Q4',
        sql: 'SELECT 4',
      );

      final folders = await service.getFolders('conn-1');
      expect(folders, ['Alpha', 'Zulu']);
    });
  });
}
