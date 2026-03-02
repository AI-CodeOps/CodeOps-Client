// Tests for database driver abstraction classes.
//
// Verifies SqlDialect, DriverResultRow, and DriverQueryResult behavior
// including identifier quoting, table qualification, and per-engine dialect
// instances.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/services/datalens/drivers/database_driver.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SqlDialect — static instances
  // ---------------------------------------------------------------------------
  group('SqlDialect', () {
    test('postgresql dialect has correct properties', () {
      const d = SqlDialect.postgresql;
      expect(d.driver, DatabaseDriver.postgresql);
      expect(d.identifierQuote, '"');
      expect(d.identifierQuoteClose, '"');
      expect(d.supportsLimitOffset, true);
      expect(d.supportsExplain, true);
      expect(d.supportsReturning, true);
      expect(d.parameterStyle, r'$');
    });

    test('mysql dialect has correct properties', () {
      const d = SqlDialect.mysql;
      expect(d.driver, DatabaseDriver.mysql);
      expect(d.identifierQuote, '`');
      expect(d.identifierQuoteClose, '`');
      expect(d.supportsLimitOffset, true);
      expect(d.supportsExplain, true);
      expect(d.supportsReturning, false);
      expect(d.parameterStyle, '?');
    });

    test('mariadb dialect has correct properties', () {
      const d = SqlDialect.mariadb;
      expect(d.driver, DatabaseDriver.mariadb);
      expect(d.identifierQuote, '`');
      expect(d.identifierQuoteClose, '`');
      expect(d.supportsLimitOffset, true);
      expect(d.supportsExplain, true);
      expect(d.supportsReturning, false);
      expect(d.parameterStyle, '?');
    });

    test('sqlite dialect has correct properties', () {
      const d = SqlDialect.sqlite;
      expect(d.driver, DatabaseDriver.sqlite);
      expect(d.identifierQuote, '"');
      expect(d.identifierQuoteClose, '"');
      expect(d.supportsLimitOffset, true);
      expect(d.supportsExplain, true);
      expect(d.supportsReturning, true);
      expect(d.parameterStyle, '?');
    });

    test('sqlServer dialect has correct properties', () {
      const d = SqlDialect.sqlServer;
      expect(d.driver, DatabaseDriver.sqlServer);
      expect(d.identifierQuote, '[');
      expect(d.identifierQuoteClose, ']');
      expect(d.supportsLimitOffset, false);
      expect(d.supportsExplain, false);
      expect(d.supportsReturning, false);
      expect(d.parameterStyle, '@');
    });

    group('forDriver', () {
      test('returns postgresql for postgresql', () {
        expect(SqlDialect.forDriver(DatabaseDriver.postgresql),
            SqlDialect.postgresql);
      });

      test('returns mysql for mysql', () {
        expect(SqlDialect.forDriver(DatabaseDriver.mysql), SqlDialect.mysql);
      });

      test('returns mariadb for mariadb', () {
        expect(
            SqlDialect.forDriver(DatabaseDriver.mariadb), SqlDialect.mariadb);
      });

      test('returns sqlite for sqlite', () {
        expect(SqlDialect.forDriver(DatabaseDriver.sqlite), SqlDialect.sqlite);
      });

      test('returns sqlServer for sqlServer', () {
        expect(SqlDialect.forDriver(DatabaseDriver.sqlServer),
            SqlDialect.sqlServer);
      });
    });

    group('quoteIdentifier', () {
      test('postgresql wraps with double quotes', () {
        expect(SqlDialect.postgresql.quoteIdentifier('users'), '"users"');
      });

      test('mysql wraps with backticks', () {
        expect(SqlDialect.mysql.quoteIdentifier('users'), '`users`');
      });

      test('sqlServer wraps with brackets', () {
        expect(SqlDialect.sqlServer.quoteIdentifier('users'), '[users]');
      });

      test('sqlite wraps with double quotes', () {
        expect(SqlDialect.sqlite.quoteIdentifier('users'), '"users"');
      });
    });

    group('qualifyTable', () {
      test('postgresql qualifies schema.table', () {
        expect(
          SqlDialect.postgresql.qualifyTable('public', 'users'),
          '"public"."users"',
        );
      });

      test('mysql qualifies schema.table with backticks', () {
        expect(
          SqlDialect.mysql.qualifyTable('mydb', 'users'),
          '`mydb`.`users`',
        );
      });

      test('sqlServer qualifies schema.table with brackets', () {
        expect(
          SqlDialect.sqlServer.qualifyTable('dbo', 'users'),
          '[dbo].[users]',
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // DriverResultRow
  // ---------------------------------------------------------------------------
  group('DriverResultRow', () {
    test('stores column values by name', () {
      final row = DriverResultRow({'id': 1, 'name': 'Alice'});
      expect(row['id'], 1);
      expect(row['name'], 'Alice');
    });

    test('returns null for missing keys', () {
      final row = DriverResultRow({'id': 1});
      expect(row['missing'], isNull);
    });

    test('columns map is accessible', () {
      final row = DriverResultRow({'a': 1, 'b': 2});
      expect(row.columns, {'a': 1, 'b': 2});
    });
  });

  // ---------------------------------------------------------------------------
  // DriverQueryResult
  // ---------------------------------------------------------------------------
  group('DriverQueryResult', () {
    test('default constructor has empty values', () {
      const result = DriverQueryResult();
      expect(result.columnNames, isEmpty);
      expect(result.columnTypes, isEmpty);
      expect(result.rows, isEmpty);
      expect(result.affectedRows, 0);
    });

    test('stores column names, types, and rows', () {
      final result = DriverQueryResult(
        columnNames: ['id', 'name'],
        columnTypes: ['int4', 'text'],
        rows: [
          [1, 'Alice'],
          [2, 'Bob'],
        ],
        affectedRows: 2,
      );

      expect(result.columnNames, ['id', 'name']);
      expect(result.columnTypes, ['int4', 'text']);
      expect(result.rows.length, 2);
      expect(result.rows[0], [1, 'Alice']);
      expect(result.rows[1], [2, 'Bob']);
      expect(result.affectedRows, 2);
    });

    test('DML result has affectedRows only', () {
      const result = DriverQueryResult(affectedRows: 5);
      expect(result.columnNames, isEmpty);
      expect(result.rows, isEmpty);
      expect(result.affectedRows, 5);
    });
  });
}
