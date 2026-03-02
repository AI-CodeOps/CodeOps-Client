// Tests for QueryExecutionService.
//
// Mocks DatabaseConnectionService, QueryHistoryService, and
// DatabaseDriverAdapter to verify SQL execution, result building,
// pagination, table browsing, EXPLAIN plans, row counting, cancellation,
// transaction control, and error handling without a real database server.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/drivers/database_driver.dart';
import 'package:codeops/services/datalens/query_execution_service.dart';
import 'package:codeops/services/datalens/query_history_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockQueryHistoryService extends Mock implements QueryHistoryService {}

class MockDatabaseDriverAdapter extends Mock
    implements DatabaseDriverAdapter {}

void main() {
  late MockDatabaseConnectionService mockConnService;
  late MockQueryHistoryService mockHistoryService;
  late MockDatabaseDriverAdapter mockDriver;
  late QueryExecutionService service;

  setUpAll(() {
    registerFallbackValue(QueryStatus.completed);
  });

  setUp(() {
    mockConnService = MockDatabaseConnectionService();
    mockHistoryService = MockQueryHistoryService();
    mockDriver = MockDatabaseDriverAdapter();
    service = QueryExecutionService(mockConnService, mockHistoryService);

    when(() => mockConnService.getDriver('conn-1')).thenReturn(mockDriver);
    when(() => mockDriver.dialect).thenReturn(SqlDialect.postgresql);

    // Default stub for recordExecution — always succeeds.
    when(() => mockHistoryService.recordExecution(
          connectionId: any(named: 'connectionId'),
          sql: any(named: 'sql'),
          status: any(named: 'status'),
          rowCount: any(named: 'rowCount'),
          executionTimeMs: any(named: 'executionTimeMs'),
          error: any(named: 'error'),
        )).thenAnswer((_) async {});
  });

  // ---------------------------------------------------------------------------
  // executeQuery — SELECT
  // ---------------------------------------------------------------------------
  group('executeQuery', () {
    test('executes a SELECT and returns columns + rows', () async {
      when(() => mockDriver.execute('SELECT id, name FROM users'))
          .thenAnswer((_) async => DriverQueryResult(
                columnNames: ['id', 'name'],
                columnTypes: ['int4', 'text'],
                rows: [
                  [1, 'Alice'],
                  [2, 'Bob'],
                ],
                affectedRows: 2,
              ));

      final result =
          await service.executeQuery('conn-1', 'SELECT id, name FROM users');

      expect(result.status, QueryStatus.completed);
      expect(result.columns, hasLength(2));
      expect(result.columns!.first.name, 'id');
      expect(result.columns!.last.name, 'name');
      expect(result.rows, hasLength(2));
      expect(result.rows!.first, [1, 'Alice']);
      expect(result.rowCount, 2);
      expect(result.executionTimeMs, isNotNull);
      expect(result.executedSql, 'SELECT id, name FROM users');

      // Verify history was recorded.
      verify(() => mockHistoryService.recordExecution(
            connectionId: 'conn-1',
            sql: 'SELECT id, name FROM users',
            status: QueryStatus.completed,
            rowCount: 2,
            executionTimeMs: any(named: 'executionTimeMs'),
          )).called(1);
    });

    test('executes a DML and returns affected rows', () async {
      when(() => mockDriver.execute('UPDATE users SET active = true'))
          .thenAnswer((_) async => const DriverQueryResult(affectedRows: 5));

      final result = await service.executeQuery(
          'conn-1', 'UPDATE users SET active = true');

      expect(result.status, QueryStatus.completed);
      expect(result.rowCount, 5);
      expect(result.columns, isNull);
      expect(result.rows, isNull);
    });

    test('returns failed result on exception', () async {
      when(() => mockDriver.execute('INVALID SQL'))
          .thenThrow(Exception('syntax error'));

      final result =
          await service.executeQuery('conn-1', 'INVALID SQL');

      expect(result.status, QueryStatus.failed);
      expect(result.error, contains('syntax error'));
      expect(result.executedSql, 'INVALID SQL');

      // Verify failure was recorded.
      verify(() => mockHistoryService.recordExecution(
            connectionId: 'conn-1',
            sql: 'INVALID SQL',
            status: QueryStatus.failed,
            executionTimeMs: any(named: 'executionTimeMs'),
            error: any(named: 'error'),
          )).called(1);
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getDriver('unknown')).thenReturn(null);

      expect(
        () => service.executeQuery('unknown', 'SELECT 1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // executePagedQuery
  // ---------------------------------------------------------------------------
  group('executePagedQuery', () {
    test('wraps SQL with pagination and returns totalRows', () async {
      // COUNT query.
      when(() => mockDriver.execute(any())).thenAnswer((_) async =>
          DriverQueryResult(
            columnNames: ['count'],
            columnTypes: ['int8'],
            rows: [[42]],
            affectedRows: 1,
          ));
      // Paged query.
      when(() => mockDriver.executePaged(
            any(),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => DriverQueryResult(
                columnNames: ['id', 'name'],
                columnTypes: ['int4', 'text'],
                rows: [
                  [1, 'Alice'],
                  [2, 'Bob'],
                ],
                affectedRows: 2,
              ));

      final result = await service.executePagedQuery(
        'conn-1',
        'SELECT id, name FROM users',
        limit: 10,
        offset: 0,
      );

      expect(result.status, QueryStatus.completed);
      expect(result.totalRows, 42);
      expect(result.rows, hasLength(2));
      expect(result.rowCount, 2);
    });

    test('returns failed result on exception', () async {
      when(() => mockDriver.execute(any()))
          .thenThrow(Exception('timeout'));

      final result = await service.executePagedQuery(
        'conn-1',
        'SELECT * FROM big_table',
      );

      expect(result.status, QueryStatus.failed);
      expect(result.error, contains('timeout'));
    });
  });

  // ---------------------------------------------------------------------------
  // browseTable
  // ---------------------------------------------------------------------------
  group('browseTable', () {
    test('builds SELECT * with ORDER BY and WHERE', () async {
      when(() => mockDriver.execute(any())).thenAnswer((_) async =>
          DriverQueryResult(
            columnNames: ['count'],
            columnTypes: ['int8'],
            rows: [[100]],
            affectedRows: 1,
          ));
      when(() => mockDriver.executePaged(
            any(),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => DriverQueryResult(
                columnNames: ['id', 'name'],
                columnTypes: ['int4', 'text'],
                rows: [[1, 'Alice']],
                affectedRows: 1,
              ));

      final result = await service.browseTable(
        'conn-1',
        'public',
        'users',
        limit: 50,
        offset: 10,
        orderBy: 'name',
        sortDirection: SortDirection.asc,
        whereClause: 'active = true',
      );

      expect(result.status, QueryStatus.completed);
      expect(result.totalRows, 100);

      // Verify the base SQL was recorded in history.
      verify(() => mockHistoryService.recordExecution(
            connectionId: 'conn-1',
            sql: 'SELECT * FROM "public"."users" WHERE active = true ORDER BY "name" ASC',
            status: QueryStatus.completed,
            rowCount: any(named: 'rowCount'),
            executionTimeMs: any(named: 'executionTimeMs'),
          )).called(1);
    });

    test('builds SELECT * without optional clauses', () async {
      when(() => mockDriver.execute(any())).thenAnswer((_) async =>
          DriverQueryResult(
            columnNames: ['count'],
            columnTypes: ['int8'],
            rows: [[5]],
            affectedRows: 1,
          ));
      when(() => mockDriver.executePaged(
            any(),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => DriverQueryResult(
                columnNames: ['id'],
                columnTypes: ['int4'],
                rows: [[1]],
                affectedRows: 1,
              ));

      final result = await service.browseTable(
        'conn-1',
        'public',
        'users',
      );

      expect(result.status, QueryStatus.completed);

      verify(() => mockHistoryService.recordExecution(
            connectionId: 'conn-1',
            sql: 'SELECT * FROM "public"."users"',
            status: QueryStatus.completed,
            rowCount: any(named: 'rowCount'),
            executionTimeMs: any(named: 'executionTimeMs'),
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // cancelQuery
  // ---------------------------------------------------------------------------
  group('cancelQuery', () {
    test('delegates to driver and returns result', () async {
      when(() => mockDriver.cancelQuery()).thenAnswer((_) async => true);

      final cancelled = await service.cancelQuery('conn-1');
      expect(cancelled, isTrue);
      verify(() => mockDriver.cancelQuery()).called(1);
    });

    test('returns false when driver returns false', () async {
      when(() => mockDriver.cancelQuery()).thenAnswer((_) async => false);

      final cancelled = await service.cancelQuery('conn-1');
      expect(cancelled, isFalse);
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getDriver('unknown')).thenReturn(null);

      expect(
        () => service.cancelQuery('unknown'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // explainQuery
  // ---------------------------------------------------------------------------
  group('explainQuery', () {
    test('delegates to driver without analyze', () async {
      when(() => mockDriver.explainQuery('SELECT * FROM users', analyze: false))
          .thenAnswer((_) async =>
              'Seq Scan on users  (cost=0.00..1.05 rows=5 width=36)');

      final plan = await service.explainQuery(
        'conn-1',
        'SELECT * FROM users',
      );

      expect(plan, contains('Seq Scan'));
      verify(() =>
              mockDriver.explainQuery('SELECT * FROM users', analyze: false))
          .called(1);
    });

    test('delegates to driver with analyze=true', () async {
      when(() => mockDriver.explainQuery('SELECT * FROM users', analyze: true))
          .thenAnswer((_) async => 'Seq Scan (actual time=0.01..0.02)');

      final plan = await service.explainQuery(
        'conn-1',
        'SELECT * FROM users',
        analyze: true,
      );

      expect(plan, contains('actual time'));
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getDriver('unknown')).thenReturn(null);

      expect(
        () => service.explainQuery('unknown', 'SELECT 1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // countRows
  // ---------------------------------------------------------------------------
  group('countRows', () {
    test('returns the row count for a table', () async {
      when(() => mockDriver.execute(any())).thenAnswer((_) async =>
          DriverQueryResult(
            columnNames: ['count'],
            columnTypes: ['int8'],
            rows: [[42]],
            affectedRows: 1,
          ));

      final count = await service.countRows('conn-1', 'public', 'users');
      expect(count, 42);
    });

    test('applies WHERE clause when provided', () async {
      when(() => mockDriver.execute(
          'SELECT COUNT(*) FROM "public"."users" WHERE active = true'))
          .thenAnswer((_) async => DriverQueryResult(
                columnNames: ['count'],
                columnTypes: ['int8'],
                rows: [[10]],
                affectedRows: 1,
              ));

      final count = await service.countRows(
        'conn-1',
        'public',
        'users',
        whereClause: 'active = true',
      );

      expect(count, 10);
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getDriver('unknown')).thenReturn(null);

      expect(
        () => service.countRows('unknown', 'public', 'users'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Transaction Control
  // ---------------------------------------------------------------------------
  group('Transaction control', () {
    test('beginTransaction executes BEGIN and marks active', () async {
      when(() => mockDriver.execute('BEGIN'))
          .thenAnswer((_) async => const DriverQueryResult());

      expect(service.isTransactionActive('conn-1'), isFalse);

      await service.beginTransaction('conn-1');

      expect(service.isTransactionActive('conn-1'), isTrue);
      verify(() => mockDriver.execute('BEGIN')).called(1);
    });

    test('beginTransaction is no-op if transaction already active', () async {
      when(() => mockDriver.execute('BEGIN'))
          .thenAnswer((_) async => const DriverQueryResult());

      await service.beginTransaction('conn-1');
      await service.beginTransaction('conn-1');

      verify(() => mockDriver.execute('BEGIN')).called(1);
    });

    test('commit executes COMMIT and clears active flag', () async {
      when(() => mockDriver.execute(any()))
          .thenAnswer((_) async => const DriverQueryResult());

      await service.beginTransaction('conn-1');
      expect(service.isTransactionActive('conn-1'), isTrue);

      await service.commit('conn-1');
      expect(service.isTransactionActive('conn-1'), isFalse);

      verify(() => mockDriver.execute('COMMIT')).called(1);
    });

    test('commit throws StateError when no active transaction', () {
      expect(
        () => service.commit('conn-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('rollback executes ROLLBACK and clears active flag', () async {
      when(() => mockDriver.execute(any()))
          .thenAnswer((_) async => const DriverQueryResult());

      await service.beginTransaction('conn-1');
      expect(service.isTransactionActive('conn-1'), isTrue);

      await service.rollback('conn-1');
      expect(service.isTransactionActive('conn-1'), isFalse);

      verify(() => mockDriver.execute('ROLLBACK')).called(1);
    });

    test('rollback throws StateError when no active transaction', () {
      expect(
        () => service.rollback('conn-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('autoRollbackOnDisconnect rolls back active transaction', () async {
      when(() => mockDriver.execute(any()))
          .thenAnswer((_) async => const DriverQueryResult());

      await service.beginTransaction('conn-1');
      expect(service.isTransactionActive('conn-1'), isTrue);

      await service.autoRollbackOnDisconnect('conn-1');
      expect(service.isTransactionActive('conn-1'), isFalse);

      verify(() => mockDriver.execute('ROLLBACK')).called(1);
    });

    test('autoRollbackOnDisconnect is no-op without active transaction',
        () async {
      await service.autoRollbackOnDisconnect('conn-1');

      verifyNever(() => mockDriver.execute(any()));
    });

    test('isTransactionActive returns false for unknown connectionId', () {
      expect(service.isTransactionActive('unknown'), isFalse);
    });
  });
}
