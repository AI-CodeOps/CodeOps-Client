/// Factory for creating database driver adapters.
///
/// Returns the appropriate [DatabaseDriverAdapter] implementation based on
/// the [DatabaseDriver] enum value. This is the single point of driver
/// instantiation — all services should use this factory rather than
/// constructing drivers directly.
library;

import '../../../models/datalens_enums.dart';
import 'database_driver.dart';
import 'mysql_driver.dart';
import 'postgresql_driver.dart';
import 'sqlite_driver.dart';
import 'sql_server_driver.dart';

/// Creates [DatabaseDriverAdapter] instances based on [DatabaseDriver] type.
///
/// Usage:
/// ```dart
/// final driver = DriverFactory.create(DatabaseDriver.postgresql);
/// await driver.connect(config);
/// ```
class DriverFactory {
  /// Private constructor — all methods are static.
  const DriverFactory._();

  /// Creates a [DatabaseDriverAdapter] for the given [driver] type.
  ///
  /// Returns a new, unconnected adapter instance. Call [connect] on the
  /// returned adapter to establish a connection.
  static DatabaseDriverAdapter create(DatabaseDriver driver) {
    return switch (driver) {
      DatabaseDriver.postgresql => PostgresqlDriver(),
      DatabaseDriver.mysql => MysqlDriver(driverType: DatabaseDriver.mysql),
      DatabaseDriver.mariadb => MysqlDriver(driverType: DatabaseDriver.mariadb),
      DatabaseDriver.sqlite => SqliteDriver(),
      DatabaseDriver.sqlServer => SqlServerDriver(),
    };
  }

  /// Returns the [SqlDialect] for the given [driver] type.
  ///
  /// Convenience method that avoids creating an adapter instance when only
  /// the dialect is needed (e.g., for SQL generation).
  static SqlDialect dialectFor(DatabaseDriver driver) =>
      SqlDialect.forDriver(driver);
}
