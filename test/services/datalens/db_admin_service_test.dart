// Tests for DbAdminService.
//
// Mocks DatabaseConnectionService and DatabaseDriverAdapter to verify
// SQL generation for PostgreSQL, MySQL, SQLite, and SQL Server, result
// mapping to typed admin models, and error handling for missing connections.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:codeops/services/datalens/drivers/database_driver.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockDatabaseDriverAdapter extends Mock
    implements DatabaseDriverAdapter {}

void main() {
  late MockDatabaseConnectionService mockConnService;
  late MockDatabaseDriverAdapter mockDriver;
  late DbAdminService service;

  setUp(() {
    mockConnService = MockDatabaseConnectionService();
    mockDriver = MockDatabaseDriverAdapter();
    service = DbAdminService(mockConnService);

    when(() => mockConnService.getDriver('conn-1')).thenReturn(mockDriver);
    when(() => mockDriver.dialect).thenReturn(SqlDialect.postgresql);
  });

  // -------------------------------------------------------------------------
  // Active Sessions
  // -------------------------------------------------------------------------

  group('getActiveSessions', () {
    test('returns sessions from pg_stat_activity', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'pid', 'datname', 'usename', 'application_name', 'client_addr',
            'backend_start', 'query_start', 'state', 'wait_duration_sec',
            'query', 'backend_type',
          ],
          rows: [
            [123, 'mydb', 'admin', 'psql', '127.0.0.1', null, null,
             'active', 1.5, 'SELECT 1', 'client backend'],
          ],
        ),
      );

      final sessions = await service.getActiveSessions('conn-1');

      expect(sessions, hasLength(1));
      expect(sessions.first.pid, 123);
      expect(sessions.first.database, 'mydb');
      expect(sessions.first.username, 'admin');
      expect(sessions.first.state, 'active');
      expect(sessions.first.waitDurationSec, 1.5);
      expect(sessions.first.query, 'SELECT 1');
    });

    test('returns empty for SQLite', () async {
      when(() => mockDriver.dialect).thenReturn(SqlDialect.sqlite);

      final sessions = await service.getActiveSessions('conn-1');
      expect(sessions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Terminate / Cancel
  // -------------------------------------------------------------------------

  group('terminateSession', () {
    test('calls pg_terminate_backend', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => const DriverQueryResult(
          columnNames: ['pg_terminate_backend'],
          rows: [[true]],
        ),
      );

      final result = await service.terminateSession('conn-1', 456);
      expect(result, isTrue);

      final captured =
          verify(() => mockDriver.execute(captureAny())).captured;
      expect(captured.first, contains('pg_terminate_backend(456)'));
    });
  });

  group('cancelSessionQuery', () {
    test('calls pg_cancel_backend', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => const DriverQueryResult(
          columnNames: ['pg_cancel_backend'],
          rows: [[true]],
        ),
      );

      final result = await service.cancelSessionQuery('conn-1', 789);
      expect(result, isTrue);

      final captured =
          verify(() => mockDriver.execute(captureAny())).captured;
      expect(captured.first, contains('pg_cancel_backend(789)'));
    });
  });

  // -------------------------------------------------------------------------
  // Database / Table Sizes
  // -------------------------------------------------------------------------

  group('getDatabaseSizes', () {
    test('returns database sizes', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: ['datname', 'total_size', 'size_bytes'],
          rows: [
            ['mydb', '100 MB', 104857600],
            ['testdb', '50 MB', 52428800],
          ],
        ),
      );

      final sizes = await service.getDatabaseSizes('conn-1');

      expect(sizes, hasLength(2));
      expect(sizes.first.name, 'mydb');
      expect(sizes.first.totalSize, '100 MB');
      expect(sizes.first.sizeBytes, 104857600);
    });
  });

  group('getTableSizes', () {
    test('returns table sizes for a schema', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'schemaname', 'tablename', 'table_size', 'index_size',
            'total_size', 'total_size_bytes', 'row_estimate',
          ],
          rows: [
            ['public', 'users', '8 kB', '16 kB', '24 kB', 24576, 100],
          ],
        ),
      );

      final sizes = await service.getTableSizes('conn-1', 'public');

      expect(sizes, hasLength(1));
      expect(sizes.first.tableName, 'users');
      expect(sizes.first.tableSize, '8 kB');
      expect(sizes.first.totalSizeBytes, 24576);
    });
  });

  // -------------------------------------------------------------------------
  // Locks
  // -------------------------------------------------------------------------

  group('getLocks', () {
    test('returns lock info', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'pid', 'mode', 'locktype', 'relation', 'granted',
            'datname', 'usename', 'query', 'duration_sec',
          ],
          rows: [
            [100, 'AccessShareLock', 'relation', 'users', true,
             'mydb', 'admin', 'SELECT * FROM users', 2.0],
          ],
        ),
      );

      final locks = await service.getLocks('conn-1');

      expect(locks, hasLength(1));
      expect(locks.first.pid, 100);
      expect(locks.first.lockMode, 'AccessShareLock');
      expect(locks.first.granted, isTrue);
      expect(locks.first.relation, 'users');
    });
  });

  group('getLockConflicts', () {
    test('returns blocking relationships', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'blocked_pid', 'blocked_query', 'blocked_user',
            'blocking_pid', 'blocking_query', 'blocking_user', 'lock_mode',
          ],
          rows: [
            [200, 'UPDATE users SET name = ?', 'app',
             100, 'ALTER TABLE users ADD COLUMN x int', 'admin',
             'AccessExclusiveLock'],
          ],
        ),
      );

      final conflicts = await service.getLockConflicts('conn-1');

      expect(conflicts, hasLength(1));
      expect(conflicts.first.blockedPid, 200);
      expect(conflicts.first.blockingPid, 100);
      expect(conflicts.first.lockMode, 'AccessExclusiveLock');
    });

    test('returns empty for non-PostgreSQL', () async {
      when(() => mockDriver.dialect).thenReturn(SqlDialect.mysql);

      final conflicts = await service.getLockConflicts('conn-1');
      expect(conflicts, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Index Usage
  // -------------------------------------------------------------------------

  group('getIndexUsage', () {
    test('returns index usage stats', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'schemaname', 'tablename', 'indexname', 'idx_scan',
            'index_size', 'index_size_bytes', 'idx_tup_read', 'idx_tup_fetch',
          ],
          rows: [
            ['public', 'users', 'users_pkey', 500,
             '16 kB', 16384, 1000, 500],
            ['public', 'users', 'users_email_idx', 0,
             '8 kB', 8192, 0, 0],
          ],
        ),
      );

      final indexes = await service.getIndexUsage('conn-1', 'public');

      expect(indexes, hasLength(2));
      expect(indexes.first.indexScans, 500);
      expect(indexes.last.indexScans, 0);
    });
  });

  group('getUnusedIndexes', () {
    test('returns only zero-scan indexes', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'schemaname', 'tablename', 'indexname', 'idx_scan',
            'index_size', 'index_size_bytes', 'idx_tup_read', 'idx_tup_fetch',
          ],
          rows: [
            ['public', 'users', 'users_pkey', 500,
             '16 kB', 16384, 1000, 500],
            ['public', 'users', 'users_email_idx', 0,
             '8 kB', 8192, 0, 0],
          ],
        ),
      );

      final unused = await service.getUnusedIndexes('conn-1', 'public');

      expect(unused, hasLength(1));
      expect(unused.first.indexName, 'users_email_idx');
    });
  });

  // -------------------------------------------------------------------------
  // Table Stats
  // -------------------------------------------------------------------------

  group('getTableStats', () {
    test('returns table statistics', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'schemaname', 'relname', 'n_live_tup', 'n_dead_tup',
            'seq_scan', 'seq_tup_read', 'idx_scan', 'idx_tup_fetch',
            'n_tup_ins', 'n_tup_upd', 'n_tup_del',
            'last_vacuum', 'last_autovacuum', 'last_analyze',
            'last_autoanalyze', 'table_size',
          ],
          rows: [
            ['public', 'users', 1000, 50, 200, 50000, 800, 3000,
             500, 200, 100, null, null, null, null, '1 MB'],
          ],
        ),
      );

      final stats = await service.getTableStats('conn-1', 'public');

      expect(stats, hasLength(1));
      expect(stats.first.tableName, 'users');
      expect(stats.first.liveRows, 1000);
      expect(stats.first.deadRows, 50);
      expect(stats.first.tableSize, '1 MB');
    });
  });

  // -------------------------------------------------------------------------
  // Vacuum
  // -------------------------------------------------------------------------

  group('getVacuumStatus', () {
    test('returns vacuum info', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'schemaname', 'relname', 'last_vacuum', 'last_autovacuum',
            'last_analyze', 'last_autoanalyze', 'n_dead_tup', 'n_live_tup',
          ],
          rows: [
            ['public', 'users', null, null, null, null, 200, 1000],
          ],
        ),
      );

      final vacuum = await service.getVacuumStatus('conn-1', 'public');

      expect(vacuum, hasLength(1));
      expect(vacuum.first.deadTuples, 200);
      expect(vacuum.first.liveTuples, 1000);
    });

    test('returns empty for non-PostgreSQL', () async {
      when(() => mockDriver.dialect).thenReturn(SqlDialect.mysql);

      final vacuum = await service.getVacuumStatus('conn-1', 'public');
      expect(vacuum, isEmpty);
    });
  });

  group('vacuumTable', () {
    test('executes VACUUM command', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => const DriverQueryResult(affectedRows: 0),
      );

      await service.vacuumTable('conn-1', 'public', 'users');

      final captured =
          verify(() => mockDriver.execute(captureAny())).captured;
      expect(captured.first, 'VACUUM "public"."users"');
    });
  });

  group('analyzeTable', () {
    test('executes ANALYZE command', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => const DriverQueryResult(affectedRows: 0),
      );

      await service.analyzeTable('conn-1', 'public', 'users');

      final captured =
          verify(() => mockDriver.execute(captureAny())).captured;
      expect(captured.first, 'ANALYZE "public"."users"');
    });
  });

  // -------------------------------------------------------------------------
  // Server Info
  // -------------------------------------------------------------------------

  group('getServerInfo', () {
    test('returns server info from PostgreSQL', () async {
      when(() => mockDriver.getServerVersion())
          .thenAnswer((_) async => 'PostgreSQL 16.1');
      when(() => mockDriver.getCurrentDatabase())
          .thenAnswer((_) async => 'mydb');
      when(() => mockDriver.getCurrentUser())
          .thenAnswer((_) async => 'admin');
      when(() => mockDriver.getDatabaseSize())
          .thenAnswer((_) async => '100 MB');
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: ['result'],
          rows: [['100']],
        ),
      );

      final info = await service.getServerInfo('conn-1');

      expect(info.version, 'PostgreSQL 16.1');
      expect(info.currentDatabase, 'mydb');
      expect(info.currentUser, 'admin');
      expect(info.databaseSize, '100 MB');
    });
  });

  group('getServerParameters', () {
    test('returns server parameters', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: ['name', 'setting', 'unit', 'category', 'short_desc', 'source'],
          rows: [
            ['max_connections', '100', null, 'Connections', 'Max connections', 'configuration file'],
            ['shared_buffers', '128MB', 'kB', 'Memory', 'Shared buffers', 'configuration file'],
          ],
        ),
      );

      final params = await service.getServerParameters('conn-1');

      expect(params, hasLength(2));
      expect(params.first.name, 'max_connections');
      expect(params.first.value, '100');
      expect(params.last.name, 'shared_buffers');
    });

    test('returns empty for SQLite', () async {
      when(() => mockDriver.dialect).thenReturn(SqlDialect.sqlite);

      final params = await service.getServerParameters('conn-1');
      expect(params, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Replication
  // -------------------------------------------------------------------------

  group('getReplicationStatus', () {
    test('returns replication info', () async {
      when(() => mockDriver.execute(any())).thenAnswer(
        (_) async => DriverQueryResult(
          columnNames: [
            'pid', 'usename', 'application_name', 'client_addr', 'state',
            'sent_lsn', 'write_lsn', 'flush_lsn', 'replay_lsn', 'replay_lag',
          ],
          rows: [
            [300, 'replicator', 'standby1', '10.0.0.2', 'streaming',
             '0/3000028', '0/3000028', '0/3000028', '0/3000028', '00:00:01'],
          ],
        ),
      );

      final replication = await service.getReplicationStatus('conn-1');

      expect(replication, hasLength(1));
      expect(replication.first.pid, 300);
      expect(replication.first.state, 'streaming');
    });

    test('returns empty for non-PostgreSQL', () async {
      when(() => mockDriver.dialect).thenReturn(SqlDialect.mysql);

      final replication = await service.getReplicationStatus('conn-1');
      expect(replication, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Error Handling
  // -------------------------------------------------------------------------

  group('error handling', () {
    test('throws when no active connection', () {
      when(() => mockConnService.getDriver('bad-conn')).thenReturn(null);

      expect(
        () => service.getActiveSessions('bad-conn'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
