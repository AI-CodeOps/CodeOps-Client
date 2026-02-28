// Tests for DataLens Drift table operations.
//
// Verifies CRUD operations, filtering, and ordering for all three
// DataLens tables: DatalensConnections, DatalensQueryHistory,
// DatalensSavedQueries.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/database/database.dart';

void main() {
  late CodeOpsDatabase db;

  setUp(() {
    db = CodeOpsDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // DatalensConnections
  // ---------------------------------------------------------------------------
  group('DatalensConnections', () {
    test('insert and query', () async {
      await db.into(db.datalensConnections).insert(
            DatalensConnectionsCompanion.insert(
              id: 'conn-1',
              name: 'CodeOps Dev',
              host: 'localhost',
              database: 'codeops',
              username: 'codeops',
              createdAt: DateTime.utc(2026),
            ),
          );

      final rows = await db.select(db.datalensConnections).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'conn-1');
      expect(rows.first.name, 'CodeOps Dev');
      expect(rows.first.host, 'localhost');
      expect(rows.first.database, 'codeops');
      expect(rows.first.username, 'codeops');
      expect(rows.first.port, 5432);
      expect(rows.first.driver, 'POSTGRESQL');
      expect(rows.first.useSsl, false);
      expect(rows.first.connectionTimeout, 10);
    });

    test('update lastConnectedAt', () async {
      await db.into(db.datalensConnections).insert(
            DatalensConnectionsCompanion.insert(
              id: 'conn-1',
              name: 'Dev DB',
              host: 'localhost',
              database: 'devdb',
              username: 'admin',
              createdAt: DateTime.utc(2026),
            ),
          );

      final now = DateTime.utc(2026, 2, 28, 12, 0);
      await (db.update(db.datalensConnections)
            ..where((t) => t.id.equals('conn-1')))
          .write(
        DatalensConnectionsCompanion(
          lastConnectedAt: Value(now),
        ),
      );

      final rows = await db.select(db.datalensConnections).get();
      expect(rows.first.lastConnectedAt?.toUtc(), now);
    });

    test('delete by id', () async {
      await db.into(db.datalensConnections).insert(
            DatalensConnectionsCompanion.insert(
              id: 'conn-1',
              name: 'To Delete',
              host: 'localhost',
              database: 'db',
              username: 'user',
              createdAt: DateTime.utc(2026),
            ),
          );

      await (db.delete(db.datalensConnections)
            ..where((t) => t.id.equals('conn-1')))
          .go();

      final rows = await db.select(db.datalensConnections).get();
      expect(rows, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // DatalensQueryHistory
  // ---------------------------------------------------------------------------
  group('DatalensQueryHistory', () {
    test('insert and query', () async {
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion.insert(
              id: 'qh-1',
              connectionId: 'conn-1',
              sql: 'SELECT * FROM users',
              status: 'COMPLETED',
              executionTimeMs: 120,
              executedAt: DateTime.utc(2026, 2, 28, 12, 0),
            ),
          );

      final rows = await db.select(db.datalensQueryHistory).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'qh-1');
      expect(rows.first.connectionId, 'conn-1');
      expect(rows.first.sql, 'SELECT * FROM users');
      expect(rows.first.status, 'COMPLETED');
      expect(rows.first.executionTimeMs, 120);
    });

    test('query by connectionId', () async {
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion.insert(
              id: 'qh-1',
              connectionId: 'conn-1',
              sql: 'SELECT 1',
              status: 'COMPLETED',
              executionTimeMs: 5,
              executedAt: DateTime.utc(2026, 2, 28, 12, 0),
            ),
          );
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion.insert(
              id: 'qh-2',
              connectionId: 'conn-2',
              sql: 'SELECT 2',
              status: 'COMPLETED',
              executionTimeMs: 10,
              executedAt: DateTime.utc(2026, 2, 28, 12, 1),
            ),
          );
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion.insert(
              id: 'qh-3',
              connectionId: 'conn-1',
              sql: 'SELECT 3',
              status: 'FAILED',
              executionTimeMs: 2,
              executedAt: DateTime.utc(2026, 2, 28, 12, 2),
            ),
          );

      final rows = await (db.select(db.datalensQueryHistory)
            ..where((t) => t.connectionId.equals('conn-1')))
          .get();
      expect(rows.length, 2);
      expect(rows.every((r) => r.connectionId == 'conn-1'), true);
    });

    test('order by executedAt', () async {
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion.insert(
              id: 'qh-old',
              connectionId: 'conn-1',
              sql: 'SELECT old',
              status: 'COMPLETED',
              executionTimeMs: 5,
              executedAt: DateTime.utc(2026, 1, 1),
            ),
          );
      await db.into(db.datalensQueryHistory).insert(
            DatalensQueryHistoryCompanion.insert(
              id: 'qh-new',
              connectionId: 'conn-1',
              sql: 'SELECT new',
              status: 'COMPLETED',
              executionTimeMs: 5,
              executedAt: DateTime.utc(2026, 2, 28),
            ),
          );

      final rows = await (db.select(db.datalensQueryHistory)
            ..orderBy([
              (t) => OrderingTerm.desc(t.executedAt),
            ]))
          .get();
      expect(rows.first.id, 'qh-new');
      expect(rows.last.id, 'qh-old');
    });
  });

  // ---------------------------------------------------------------------------
  // DatalensSavedQueries
  // ---------------------------------------------------------------------------
  group('DatalensSavedQueries', () {
    test('insert and query', () async {
      await db.into(db.datalensSavedQueries).insert(
            DatalensSavedQueriesCompanion.insert(
              id: 'sq-1',
              connectionId: 'conn-1',
              name: 'Active Users',
              sql: 'SELECT * FROM users WHERE is_active = true',
              createdAt: DateTime.utc(2026),
            ),
          );

      final rows = await db.select(db.datalensSavedQueries).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'sq-1');
      expect(rows.first.name, 'Active Users');
      expect(rows.first.sql, 'SELECT * FROM users WHERE is_active = true');
    });

    test('update sql', () async {
      await db.into(db.datalensSavedQueries).insert(
            DatalensSavedQueriesCompanion.insert(
              id: 'sq-1',
              connectionId: 'conn-1',
              name: 'My Query',
              sql: 'SELECT 1',
              createdAt: DateTime.utc(2026),
            ),
          );

      await (db.update(db.datalensSavedQueries)
            ..where((t) => t.id.equals('sq-1')))
          .write(
        const DatalensSavedQueriesCompanion(
          sql: Value('SELECT * FROM projects'),
          updatedAt: Value(null),
        ),
      );

      final rows = await db.select(db.datalensSavedQueries).get();
      expect(rows.first.sql, 'SELECT * FROM projects');
    });

    test('query by folder', () async {
      await db.into(db.datalensSavedQueries).insert(
            DatalensSavedQueriesCompanion.insert(
              id: 'sq-1',
              connectionId: 'conn-1',
              name: 'Report 1',
              sql: 'SELECT 1',
              folder: const Value('Reports'),
              createdAt: DateTime.utc(2026),
            ),
          );
      await db.into(db.datalensSavedQueries).insert(
            DatalensSavedQueriesCompanion.insert(
              id: 'sq-2',
              connectionId: 'conn-1',
              name: 'Debug Query',
              sql: 'SELECT 2',
              folder: const Value('Debug'),
              createdAt: DateTime.utc(2026),
            ),
          );
      await db.into(db.datalensSavedQueries).insert(
            DatalensSavedQueriesCompanion.insert(
              id: 'sq-3',
              connectionId: 'conn-1',
              name: 'Report 2',
              sql: 'SELECT 3',
              folder: const Value('Reports'),
              createdAt: DateTime.utc(2026),
            ),
          );

      final rows = await (db.select(db.datalensSavedQueries)
            ..where((t) => t.folder.equals('Reports')))
          .get();
      expect(rows.length, 2);
      expect(rows.every((r) => r.folder == 'Reports'), true);
    });
  });
}
