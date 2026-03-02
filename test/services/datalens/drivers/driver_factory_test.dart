// Tests for DriverFactory.
//
// Verifies that the factory creates the correct concrete driver adapter
// for each DatabaseDriver enum value and that dialectFor returns the
// matching SqlDialect.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/services/datalens/drivers/database_driver.dart';
import 'package:codeops/services/datalens/drivers/driver_factory.dart';
import 'package:codeops/services/datalens/drivers/mysql_driver.dart';
import 'package:codeops/services/datalens/drivers/postgresql_driver.dart';
import 'package:codeops/services/datalens/drivers/sqlite_driver.dart';
import 'package:codeops/services/datalens/drivers/sql_server_driver.dart';

void main() {
  // ---------------------------------------------------------------------------
  // create
  // ---------------------------------------------------------------------------
  group('DriverFactory.create', () {
    test('creates PostgresqlDriver for postgresql', () {
      final driver = DriverFactory.create(DatabaseDriver.postgresql);
      expect(driver, isA<PostgresqlDriver>());
      expect(driver.driverType, DatabaseDriver.postgresql);
      expect(driver.dialect, SqlDialect.postgresql);
    });

    test('creates MysqlDriver for mysql', () {
      final driver = DriverFactory.create(DatabaseDriver.mysql);
      expect(driver, isA<MysqlDriver>());
      expect(driver.driverType, DatabaseDriver.mysql);
      expect(driver.dialect, SqlDialect.mysql);
    });

    test('creates MysqlDriver for mariadb', () {
      final driver = DriverFactory.create(DatabaseDriver.mariadb);
      expect(driver, isA<MysqlDriver>());
      expect(driver.driverType, DatabaseDriver.mariadb);
      expect(driver.dialect, SqlDialect.mariadb);
    });

    test('creates SqliteDriver for sqlite', () {
      final driver = DriverFactory.create(DatabaseDriver.sqlite);
      expect(driver, isA<SqliteDriver>());
      expect(driver.driverType, DatabaseDriver.sqlite);
      expect(driver.dialect, SqlDialect.sqlite);
    });

    test('creates SqlServerDriver for sqlServer', () {
      final driver = DriverFactory.create(DatabaseDriver.sqlServer);
      expect(driver, isA<SqlServerDriver>());
      expect(driver.driverType, DatabaseDriver.sqlServer);
      expect(driver.dialect, SqlDialect.sqlServer);
    });

    test('returns a new instance each call', () {
      final a = DriverFactory.create(DatabaseDriver.postgresql);
      final b = DriverFactory.create(DatabaseDriver.postgresql);
      expect(identical(a, b), isFalse);
    });

    test('created drivers are not connected', () {
      for (final driverType in DatabaseDriver.values) {
        final driver = DriverFactory.create(driverType);
        expect(driver.isOpen, isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // dialectFor
  // ---------------------------------------------------------------------------
  group('DriverFactory.dialectFor', () {
    test('returns correct dialect for each driver type', () {
      expect(DriverFactory.dialectFor(DatabaseDriver.postgresql),
          SqlDialect.postgresql);
      expect(DriverFactory.dialectFor(DatabaseDriver.mysql), SqlDialect.mysql);
      expect(
          DriverFactory.dialectFor(DatabaseDriver.mariadb), SqlDialect.mariadb);
      expect(
          DriverFactory.dialectFor(DatabaseDriver.sqlite), SqlDialect.sqlite);
      expect(DriverFactory.dialectFor(DatabaseDriver.sqlServer),
          SqlDialect.sqlServer);
    });
  });
}
