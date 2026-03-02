// Tests for QueryExecutionService.
//
// Mocks DatabaseConnectionService, QueryHistoryService, and pg.Connection
// to verify SQL execution, result building, pagination, table browsing,
// EXPLAIN plans, row counting, cancellation, and error handling without
// requiring a real PostgreSQL server.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart' as pg;

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/query_execution_service.dart';
import 'package:codeops/services/datalens/query_history_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockQueryHistoryService extends Mock implements QueryHistoryService {}

class MockPgConnection extends Mock implements pg.Connection {}

// ---------------------------------------------------------------------------
// Fakes for registerFallbackValue
// ---------------------------------------------------------------------------

class FakeSql extends Fake implements pg.Sql {}

// ---------------------------------------------------------------------------
// Test helpers — construct postgres Result objects
// ---------------------------------------------------------------------------

pg.ResultSchema _schema(List<String> columnNames) {
  return pg.ResultSchema(
    columnNames
        .map((name) => pg.ResultSchemaColumn(
              typeOid: 25, // text
              type: pg.Type.text,
              columnName: name,
            ))
        .toList(),
  );
}

pg.ResultRow _row(pg.ResultSchema schema, List<Object?> values) {
  return pg.ResultRow(values: values, schema: schema);
}

pg.Result _result(List<String> columns, List<List<Object?>> rows,
    {int? affectedRows}) {
  final schema = _schema(columns);
  return pg.Result(
    rows: rows.map((vals) => _row(schema, vals)).toList(),
    affectedRows: affectedRows ?? rows.length,
    schema: schema,
  );
}

void main() {
  late MockDatabaseConnectionService mockConnService;
  late MockQueryHistoryService mockHistoryService;
  late MockPgConnection mockConn;
  late QueryExecutionService service;

  setUpAll(() {
    registerFallbackValue(FakeSql());
    registerFallbackValue(QueryStatus.completed);
  });

  setUp(() {
    mockConnService = MockDatabaseConnectionService();
    mockHistoryService = MockQueryHistoryService();
    mockConn = MockPgConnection();
    service = QueryExecutionService(mockConnService, mockHistoryService);

    when(() => mockConnService.getConnection('conn-1')).thenReturn(mockConn);

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

  /// Stub for conn.execute — matches any SQL and optional parameters.
  void stubExecute(pg.Result result) {
    when(() => mockConn.execute(
          any(),
          parameters: any(named: 'parameters'),
          ignoreRows: any(named: 'ignoreRows'),
          queryMode: any(named: 'queryMode'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => result);
  }

  /// Stubs sequential execute calls.
  void stubExecuteSequence(List<pg.Result> results) {
    var index = 0;
    when(() => mockConn.execute(
          any(),
          parameters: any(named: 'parameters'),
          ignoreRows: any(named: 'ignoreRows'),
          queryMode: any(named: 'queryMode'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async {
      final r = results[index];
      if (index < results.length - 1) index++;
      return r;
    });
  }

  /// Stub for conn.execute that matches a specific SQL string.
  void stubExecuteForSql(String sql, pg.Result result) {
    when(() => mockConn.execute(
          sql,
          parameters: any(named: 'parameters'),
          ignoreRows: any(named: 'ignoreRows'),
          queryMode: any(named: 'queryMode'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => result);
  }

  // ---------------------------------------------------------------------------
  // executeQuery — SELECT
  // ---------------------------------------------------------------------------
  group('executeQuery', () {
    test('executes a SELECT and returns columns + rows', () async {
      stubExecute(_result(['id', 'name'], [
        [1, 'Alice'],
        [2, 'Bob'],
      ]));

      final result = await service.executeQuery('conn-1', 'SELECT id, name FROM users');

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
      stubExecute(_result([], [], affectedRows: 5));

      final result =
          await service.executeQuery('conn-1', 'UPDATE users SET active = true');

      expect(result.status, QueryStatus.completed);
      expect(result.rowCount, 5);
      expect(result.columns, isNull);
      expect(result.rows, isNull);
    });

    test('returns failed result on exception', () async {
      when(() => mockConn.execute(
            any(),
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).thenThrow(pg.PgException('syntax error'));

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
      when(() => mockConnService.getConnection('unknown')).thenReturn(null);

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
    test('wraps SQL with LIMIT/OFFSET and returns totalRows', () async {
      // First call: COUNT(*), second call: paged SELECT.
      stubExecuteSequence([
        _result(['count'], [
          [42]
        ]),
        _result(['id', 'name'], [
          [1, 'Alice'],
          [2, 'Bob'],
        ]),
      ]);

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
      when(() => mockConn.execute(
            any(),
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).thenThrow(pg.PgException('timeout'));

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
      stubExecuteSequence([
        _result(['count'], [
          [100]
        ]),
        _result(['id', 'name'], [
          [1, 'Alice'],
        ]),
      ]);

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
      stubExecuteSequence([
        _result(['count'], [
          [5]
        ]),
        _result(['id'], [
          [1],
        ]),
      ]);

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
    test('sends pg_cancel_backend and returns true', () async {
      stubExecuteSequence([
        _result(['pg_backend_pid'], [
          [12345]
        ]),
        _result(['pg_cancel_backend'], [
          [true]
        ]),
      ]);

      final cancelled = await service.cancelQuery('conn-1');
      expect(cancelled, isTrue);
    });

    test('returns false on exception', () async {
      when(() => mockConn.execute(
            any(),
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).thenThrow(pg.PgException('connection closed'));

      final cancelled = await service.cancelQuery('conn-1');
      expect(cancelled, isFalse);
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getConnection('unknown')).thenReturn(null);

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
    test('returns EXPLAIN plan as a single string', () async {
      stubExecute(_result(['QUERY PLAN'], [
        ['Seq Scan on users  (cost=0.00..1.05 rows=5 width=36)'],
      ]));

      final plan = await service.explainQuery(
        'conn-1',
        'SELECT * FROM users',
      );

      expect(plan, 'Seq Scan on users  (cost=0.00..1.05 rows=5 width=36)');
    });

    test('returns EXPLAIN ANALYZE plan when analyze is true', () async {
      stubExecute(_result(['QUERY PLAN'], [
        ['Seq Scan on users  (cost=0.00..1.05 rows=5) (actual time=0.01..0.02 rows=5 loops=1)'],
        ['Planning Time: 0.05 ms'],
        ['Execution Time: 0.08 ms'],
      ]));

      final plan = await service.explainQuery(
        'conn-1',
        'SELECT * FROM users',
        analyze: true,
      );

      expect(plan, contains('actual time'));
      expect(plan, contains('Planning Time'));
      expect(plan, contains('Execution Time'));
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getConnection('unknown')).thenReturn(null);

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
      stubExecute(_result(['count'], [
        [42]
      ]));

      final count = await service.countRows('conn-1', 'public', 'users');
      expect(count, 42);
    });

    test('applies WHERE clause when provided', () async {
      stubExecuteForSql(
        'SELECT COUNT(*) FROM "public"."users" WHERE active = true',
        _result(['count'], [
          [10]
        ]),
      );

      final count = await service.countRows(
        'conn-1',
        'public',
        'users',
        whereClause: 'active = true',
      );

      expect(count, 10);
    });

    test('throws StateError when no active connection', () {
      when(() => mockConnService.getConnection('unknown')).thenReturn(null);

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
      stubExecute(_result([], []));

      expect(service.isTransactionActive('conn-1'), isFalse);

      await service.beginTransaction('conn-1');

      expect(service.isTransactionActive('conn-1'), isTrue);
      verify(() => mockConn.execute(
            'BEGIN',
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('beginTransaction is no-op if transaction already active', () async {
      stubExecute(_result([], []));

      await service.beginTransaction('conn-1');
      await service.beginTransaction('conn-1');

      // Should only call BEGIN once.
      verify(() => mockConn.execute(
            'BEGIN',
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('commit executes COMMIT and clears active flag', () async {
      stubExecute(_result([], []));

      await service.beginTransaction('conn-1');
      expect(service.isTransactionActive('conn-1'), isTrue);

      await service.commit('conn-1');
      expect(service.isTransactionActive('conn-1'), isFalse);

      verify(() => mockConn.execute(
            'COMMIT',
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('commit throws StateError when no active transaction', () {
      expect(
        () => service.commit('conn-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('rollback executes ROLLBACK and clears active flag', () async {
      stubExecute(_result([], []));

      await service.beginTransaction('conn-1');
      expect(service.isTransactionActive('conn-1'), isTrue);

      await service.rollback('conn-1');
      expect(service.isTransactionActive('conn-1'), isFalse);

      verify(() => mockConn.execute(
            'ROLLBACK',
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('rollback throws StateError when no active transaction', () {
      expect(
        () => service.rollback('conn-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('autoRollbackOnDisconnect rolls back active transaction', () async {
      stubExecute(_result([], []));

      await service.beginTransaction('conn-1');
      expect(service.isTransactionActive('conn-1'), isTrue);

      await service.autoRollbackOnDisconnect('conn-1');
      expect(service.isTransactionActive('conn-1'), isFalse);

      verify(() => mockConn.execute(
            'ROLLBACK',
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          )).called(1);
    });

    test('autoRollbackOnDisconnect is no-op without active transaction',
        () async {
      await service.autoRollbackOnDisconnect('conn-1');

      verifyNever(() => mockConn.execute(
            any(),
            parameters: any(named: 'parameters'),
            ignoreRows: any(named: 'ignoreRows'),
            queryMode: any(named: 'queryMode'),
            timeout: any(named: 'timeout'),
          ));
    });

    test('isTransactionActive returns false for unknown connectionId', () {
      expect(service.isTransactionActive('unknown'), isFalse);
    });
  });
}
