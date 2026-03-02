// Tests for DataLens enum types.
//
// Verifies serialization (toJson), deserialization (fromJson),
// invalid value handling, and display names for all DataLens enums.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ConnectionStatus
  // ---------------------------------------------------------------------------
  group('ConnectionStatus', () {
    test('has 4 values', () {
      expect(ConnectionStatus.values.length, 4);
    });

    group('toJson', () {
      test('maps connected to CONNECTED', () {
        expect(ConnectionStatus.connected.toJson(), 'CONNECTED');
      });

      test('maps disconnected to DISCONNECTED', () {
        expect(ConnectionStatus.disconnected.toJson(), 'DISCONNECTED');
      });

      test('maps connecting to CONNECTING', () {
        expect(ConnectionStatus.connecting.toJson(), 'CONNECTING');
      });

      test('maps error to ERROR', () {
        expect(ConnectionStatus.error.toJson(), 'ERROR');
      });
    });

    group('fromJson', () {
      test('maps CONNECTED to connected', () {
        expect(
          ConnectionStatus.fromJson('CONNECTED'),
          ConnectionStatus.connected,
        );
      });

      test('maps DISCONNECTED to disconnected', () {
        expect(
          ConnectionStatus.fromJson('DISCONNECTED'),
          ConnectionStatus.disconnected,
        );
      });

      test('maps CONNECTING to connecting', () {
        expect(
          ConnectionStatus.fromJson('CONNECTING'),
          ConnectionStatus.connecting,
        );
      });

      test('maps ERROR to error', () {
        expect(
          ConnectionStatus.fromJson('ERROR'),
          ConnectionStatus.error,
        );
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => ConnectionStatus.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('connected returns Connected', () {
        expect(ConnectionStatus.connected.displayName, 'Connected');
      });

      test('disconnected returns Disconnected', () {
        expect(ConnectionStatus.disconnected.displayName, 'Disconnected');
      });

      test('connecting returns Connecting', () {
        expect(ConnectionStatus.connecting.displayName, 'Connecting');
      });

      test('error returns Error', () {
        expect(ConnectionStatus.error.displayName, 'Error');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in ConnectionStatus.values) {
        expect(ConnectionStatus.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // DatabaseDriver
  // ---------------------------------------------------------------------------
  group('DatabaseDriver', () {
    test('has 5 values', () {
      expect(DatabaseDriver.values.length, 5);
    });

    group('toJson', () {
      test('maps postgresql to POSTGRESQL', () {
        expect(DatabaseDriver.postgresql.toJson(), 'POSTGRESQL');
      });

      test('maps mysql to MYSQL', () {
        expect(DatabaseDriver.mysql.toJson(), 'MYSQL');
      });

      test('maps mariadb to MARIADB', () {
        expect(DatabaseDriver.mariadb.toJson(), 'MARIADB');
      });

      test('maps sqlite to SQLITE', () {
        expect(DatabaseDriver.sqlite.toJson(), 'SQLITE');
      });

      test('maps sqlServer to SQL_SERVER', () {
        expect(DatabaseDriver.sqlServer.toJson(), 'SQL_SERVER');
      });
    });

    group('fromJson', () {
      test('maps POSTGRESQL to postgresql', () {
        expect(
          DatabaseDriver.fromJson('POSTGRESQL'),
          DatabaseDriver.postgresql,
        );
      });

      test('maps MYSQL to mysql', () {
        expect(DatabaseDriver.fromJson('MYSQL'), DatabaseDriver.mysql);
      });

      test('maps MARIADB to mariadb', () {
        expect(DatabaseDriver.fromJson('MARIADB'), DatabaseDriver.mariadb);
      });

      test('maps SQLITE to sqlite', () {
        expect(DatabaseDriver.fromJson('SQLITE'), DatabaseDriver.sqlite);
      });

      test('maps SQL_SERVER to sqlServer', () {
        expect(
          DatabaseDriver.fromJson('SQL_SERVER'),
          DatabaseDriver.sqlServer,
        );
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => DatabaseDriver.fromJson('ORACLE'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('postgresql returns PostgreSQL', () {
        expect(DatabaseDriver.postgresql.displayName, 'PostgreSQL');
      });

      test('mysql returns MySQL', () {
        expect(DatabaseDriver.mysql.displayName, 'MySQL');
      });

      test('mariadb returns MariaDB', () {
        expect(DatabaseDriver.mariadb.displayName, 'MariaDB');
      });

      test('sqlite returns SQLite', () {
        expect(DatabaseDriver.sqlite.displayName, 'SQLite');
      });

      test('sqlServer returns SQL Server', () {
        expect(DatabaseDriver.sqlServer.displayName, 'SQL Server');
      });
    });

    group('defaultPort', () {
      test('postgresql returns 5432', () {
        expect(DatabaseDriver.postgresql.defaultPort, 5432);
      });

      test('mysql returns 3306', () {
        expect(DatabaseDriver.mysql.defaultPort, 3306);
      });

      test('mariadb returns 3306', () {
        expect(DatabaseDriver.mariadb.defaultPort, 3306);
      });

      test('sqlite returns null', () {
        expect(DatabaseDriver.sqlite.defaultPort, isNull);
      });

      test('sqlServer returns 1433', () {
        expect(DatabaseDriver.sqlServer.defaultPort, 1433);
      });
    });

    group('isNetworkBased', () {
      test('postgresql is network-based', () {
        expect(DatabaseDriver.postgresql.isNetworkBased, true);
      });

      test('mysql is network-based', () {
        expect(DatabaseDriver.mysql.isNetworkBased, true);
      });

      test('mariadb is network-based', () {
        expect(DatabaseDriver.mariadb.isNetworkBased, true);
      });

      test('sqlite is NOT network-based', () {
        expect(DatabaseDriver.sqlite.isNetworkBased, false);
      });

      test('sqlServer is network-based', () {
        expect(DatabaseDriver.sqlServer.isNetworkBased, true);
      });
    });

    group('defaultSchema', () {
      test('postgresql returns public', () {
        expect(DatabaseDriver.postgresql.defaultSchema, 'public');
      });

      test('mysql returns null', () {
        expect(DatabaseDriver.mysql.defaultSchema, isNull);
      });

      test('mariadb returns null', () {
        expect(DatabaseDriver.mariadb.defaultSchema, isNull);
      });

      test('sqlite returns main', () {
        expect(DatabaseDriver.sqlite.defaultSchema, 'main');
      });

      test('sqlServer returns dbo', () {
        expect(DatabaseDriver.sqlServer.defaultSchema, 'dbo');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in DatabaseDriver.values) {
        expect(DatabaseDriver.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConstraintType
  // ---------------------------------------------------------------------------
  group('ConstraintType', () {
    test('has 5 values', () {
      expect(ConstraintType.values.length, 5);
    });

    group('toJson', () {
      test('maps primaryKey to PRIMARY_KEY', () {
        expect(ConstraintType.primaryKey.toJson(), 'PRIMARY_KEY');
      });

      test('maps foreignKey to FOREIGN_KEY', () {
        expect(ConstraintType.foreignKey.toJson(), 'FOREIGN_KEY');
      });

      test('maps unique to UNIQUE', () {
        expect(ConstraintType.unique.toJson(), 'UNIQUE');
      });

      test('maps check to CHECK', () {
        expect(ConstraintType.check.toJson(), 'CHECK');
      });

      test('maps exclusion to EXCLUSION', () {
        expect(ConstraintType.exclusion.toJson(), 'EXCLUSION');
      });
    });

    group('fromJson', () {
      test('maps PRIMARY_KEY to primaryKey', () {
        expect(
          ConstraintType.fromJson('PRIMARY_KEY'),
          ConstraintType.primaryKey,
        );
      });

      test('maps FOREIGN_KEY to foreignKey', () {
        expect(
          ConstraintType.fromJson('FOREIGN_KEY'),
          ConstraintType.foreignKey,
        );
      });

      test('maps UNIQUE to unique', () {
        expect(ConstraintType.fromJson('UNIQUE'), ConstraintType.unique);
      });

      test('maps CHECK to check', () {
        expect(ConstraintType.fromJson('CHECK'), ConstraintType.check);
      });

      test('maps EXCLUSION to exclusion', () {
        expect(
          ConstraintType.fromJson('EXCLUSION'),
          ConstraintType.exclusion,
        );
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => ConstraintType.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('primaryKey returns Primary Key', () {
        expect(ConstraintType.primaryKey.displayName, 'Primary Key');
      });

      test('foreignKey returns Foreign Key', () {
        expect(ConstraintType.foreignKey.displayName, 'Foreign Key');
      });

      test('unique returns Unique', () {
        expect(ConstraintType.unique.displayName, 'Unique');
      });

      test('check returns Check', () {
        expect(ConstraintType.check.displayName, 'Check');
      });

      test('exclusion returns Exclusion', () {
        expect(ConstraintType.exclusion.displayName, 'Exclusion');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in ConstraintType.values) {
        expect(ConstraintType.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // IndexType
  // ---------------------------------------------------------------------------
  group('IndexType', () {
    test('has 11 values', () {
      expect(IndexType.values.length, 11);
    });

    group('toJson', () {
      test('maps btree to BTREE', () {
        expect(IndexType.btree.toJson(), 'BTREE');
      });

      test('maps hash to HASH', () {
        expect(IndexType.hash.toJson(), 'HASH');
      });

      test('maps gin to GIN', () {
        expect(IndexType.gin.toJson(), 'GIN');
      });

      test('maps gist to GIST', () {
        expect(IndexType.gist.toJson(), 'GIST');
      });

      test('maps spgist to SPGIST', () {
        expect(IndexType.spgist.toJson(), 'SPGIST');
      });

      test('maps brin to BRIN', () {
        expect(IndexType.brin.toJson(), 'BRIN');
      });

      test('maps fulltext to FULLTEXT', () {
        expect(IndexType.fulltext.toJson(), 'FULLTEXT');
      });

      test('maps rtree to RTREE', () {
        expect(IndexType.rtree.toJson(), 'RTREE');
      });

      test('maps clustered to CLUSTERED', () {
        expect(IndexType.clustered.toJson(), 'CLUSTERED');
      });

      test('maps nonclustered to NONCLUSTERED', () {
        expect(IndexType.nonclustered.toJson(), 'NONCLUSTERED');
      });

      test('maps other to OTHER', () {
        expect(IndexType.other.toJson(), 'OTHER');
      });
    });

    group('fromJson', () {
      test('maps BTREE to btree', () {
        expect(IndexType.fromJson('BTREE'), IndexType.btree);
      });

      test('maps HASH to hash', () {
        expect(IndexType.fromJson('HASH'), IndexType.hash);
      });

      test('maps GIN to gin', () {
        expect(IndexType.fromJson('GIN'), IndexType.gin);
      });

      test('maps GIST to gist', () {
        expect(IndexType.fromJson('GIST'), IndexType.gist);
      });

      test('maps SPGIST to spgist', () {
        expect(IndexType.fromJson('SPGIST'), IndexType.spgist);
      });

      test('maps BRIN to brin', () {
        expect(IndexType.fromJson('BRIN'), IndexType.brin);
      });

      test('maps FULLTEXT to fulltext', () {
        expect(IndexType.fromJson('FULLTEXT'), IndexType.fulltext);
      });

      test('maps RTREE to rtree', () {
        expect(IndexType.fromJson('RTREE'), IndexType.rtree);
      });

      test('maps CLUSTERED to clustered', () {
        expect(IndexType.fromJson('CLUSTERED'), IndexType.clustered);
      });

      test('maps NONCLUSTERED to nonclustered', () {
        expect(IndexType.fromJson('NONCLUSTERED'), IndexType.nonclustered);
      });

      test('maps OTHER to other', () {
        expect(IndexType.fromJson('OTHER'), IndexType.other);
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => IndexType.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('btree returns B-Tree', () {
        expect(IndexType.btree.displayName, 'B-Tree');
      });

      test('hash returns Hash', () {
        expect(IndexType.hash.displayName, 'Hash');
      });

      test('gin returns GIN', () {
        expect(IndexType.gin.displayName, 'GIN');
      });

      test('gist returns GiST', () {
        expect(IndexType.gist.displayName, 'GiST');
      });

      test('spgist returns SP-GiST', () {
        expect(IndexType.spgist.displayName, 'SP-GiST');
      });

      test('brin returns BRIN', () {
        expect(IndexType.brin.displayName, 'BRIN');
      });

      test('fulltext returns Full-Text', () {
        expect(IndexType.fulltext.displayName, 'Full-Text');
      });

      test('rtree returns R-Tree', () {
        expect(IndexType.rtree.displayName, 'R-Tree');
      });

      test('clustered returns Clustered', () {
        expect(IndexType.clustered.displayName, 'Clustered');
      });

      test('nonclustered returns Non-Clustered', () {
        expect(IndexType.nonclustered.displayName, 'Non-Clustered');
      });

      test('other returns Other', () {
        expect(IndexType.other.displayName, 'Other');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in IndexType.values) {
        expect(IndexType.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ColumnCategory
  // ---------------------------------------------------------------------------
  group('ColumnCategory', () {
    test('has 5 values', () {
      expect(ColumnCategory.values.length, 5);
    });

    group('toJson', () {
      test('maps regular to REGULAR', () {
        expect(ColumnCategory.regular.toJson(), 'REGULAR');
      });

      test('maps primaryKey to PRIMARY_KEY', () {
        expect(ColumnCategory.primaryKey.toJson(), 'PRIMARY_KEY');
      });

      test('maps foreignKey to FOREIGN_KEY', () {
        expect(ColumnCategory.foreignKey.toJson(), 'FOREIGN_KEY');
      });

      test('maps generated to GENERATED', () {
        expect(ColumnCategory.generated.toJson(), 'GENERATED');
      });

      test('maps serial to SERIAL', () {
        expect(ColumnCategory.serial.toJson(), 'SERIAL');
      });
    });

    group('fromJson', () {
      test('maps REGULAR to regular', () {
        expect(ColumnCategory.fromJson('REGULAR'), ColumnCategory.regular);
      });

      test('maps PRIMARY_KEY to primaryKey', () {
        expect(
          ColumnCategory.fromJson('PRIMARY_KEY'),
          ColumnCategory.primaryKey,
        );
      });

      test('maps FOREIGN_KEY to foreignKey', () {
        expect(
          ColumnCategory.fromJson('FOREIGN_KEY'),
          ColumnCategory.foreignKey,
        );
      });

      test('maps GENERATED to generated', () {
        expect(
          ColumnCategory.fromJson('GENERATED'),
          ColumnCategory.generated,
        );
      });

      test('maps SERIAL to serial', () {
        expect(ColumnCategory.fromJson('SERIAL'), ColumnCategory.serial);
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => ColumnCategory.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('regular returns Regular', () {
        expect(ColumnCategory.regular.displayName, 'Regular');
      });

      test('primaryKey returns Primary Key', () {
        expect(ColumnCategory.primaryKey.displayName, 'Primary Key');
      });

      test('foreignKey returns Foreign Key', () {
        expect(ColumnCategory.foreignKey.displayName, 'Foreign Key');
      });

      test('generated returns Generated', () {
        expect(ColumnCategory.generated.displayName, 'Generated');
      });

      test('serial returns Serial', () {
        expect(ColumnCategory.serial.displayName, 'Serial');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in ColumnCategory.values) {
        expect(ColumnCategory.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // QueryStatus
  // ---------------------------------------------------------------------------
  group('QueryStatus', () {
    test('has 4 values', () {
      expect(QueryStatus.values.length, 4);
    });

    group('toJson', () {
      test('maps running to RUNNING', () {
        expect(QueryStatus.running.toJson(), 'RUNNING');
      });

      test('maps completed to COMPLETED', () {
        expect(QueryStatus.completed.toJson(), 'COMPLETED');
      });

      test('maps failed to FAILED', () {
        expect(QueryStatus.failed.toJson(), 'FAILED');
      });

      test('maps cancelled to CANCELLED', () {
        expect(QueryStatus.cancelled.toJson(), 'CANCELLED');
      });
    });

    group('fromJson', () {
      test('maps RUNNING to running', () {
        expect(QueryStatus.fromJson('RUNNING'), QueryStatus.running);
      });

      test('maps COMPLETED to completed', () {
        expect(QueryStatus.fromJson('COMPLETED'), QueryStatus.completed);
      });

      test('maps FAILED to failed', () {
        expect(QueryStatus.fromJson('FAILED'), QueryStatus.failed);
      });

      test('maps CANCELLED to cancelled', () {
        expect(QueryStatus.fromJson('CANCELLED'), QueryStatus.cancelled);
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => QueryStatus.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('running returns Running', () {
        expect(QueryStatus.running.displayName, 'Running');
      });

      test('completed returns Completed', () {
        expect(QueryStatus.completed.displayName, 'Completed');
      });

      test('failed returns Failed', () {
        expect(QueryStatus.failed.displayName, 'Failed');
      });

      test('cancelled returns Cancelled', () {
        expect(QueryStatus.cancelled.displayName, 'Cancelled');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in QueryStatus.values) {
        expect(QueryStatus.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SortDirection
  // ---------------------------------------------------------------------------
  group('SortDirection', () {
    test('has 2 values', () {
      expect(SortDirection.values.length, 2);
    });

    group('toJson', () {
      test('maps asc to ASC', () {
        expect(SortDirection.asc.toJson(), 'ASC');
      });

      test('maps desc to DESC', () {
        expect(SortDirection.desc.toJson(), 'DESC');
      });
    });

    group('fromJson', () {
      test('maps ASC to asc', () {
        expect(SortDirection.fromJson('ASC'), SortDirection.asc);
      });

      test('maps DESC to desc', () {
        expect(SortDirection.fromJson('DESC'), SortDirection.desc);
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => SortDirection.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('asc returns Ascending', () {
        expect(SortDirection.asc.displayName, 'Ascending');
      });

      test('desc returns Descending', () {
        expect(SortDirection.desc.displayName, 'Descending');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in SortDirection.values) {
        expect(SortDirection.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ObjectType
  // ---------------------------------------------------------------------------
  group('ObjectType', () {
    test('has 6 values', () {
      expect(ObjectType.values.length, 6);
    });

    group('toJson', () {
      test('maps table to TABLE', () {
        expect(ObjectType.table.toJson(), 'TABLE');
      });

      test('maps view to VIEW', () {
        expect(ObjectType.view.toJson(), 'VIEW');
      });

      test('maps materializedView to MATERIALIZED_VIEW', () {
        expect(ObjectType.materializedView.toJson(), 'MATERIALIZED_VIEW');
      });

      test('maps sequence to SEQUENCE', () {
        expect(ObjectType.sequence.toJson(), 'SEQUENCE');
      });

      test('maps enumType to ENUM_TYPE', () {
        expect(ObjectType.enumType.toJson(), 'ENUM_TYPE');
      });

      test('maps function to FUNCTION', () {
        expect(ObjectType.function.toJson(), 'FUNCTION');
      });
    });

    group('fromJson', () {
      test('maps TABLE to table', () {
        expect(ObjectType.fromJson('TABLE'), ObjectType.table);
      });

      test('maps VIEW to view', () {
        expect(ObjectType.fromJson('VIEW'), ObjectType.view);
      });

      test('maps MATERIALIZED_VIEW to materializedView', () {
        expect(
          ObjectType.fromJson('MATERIALIZED_VIEW'),
          ObjectType.materializedView,
        );
      });

      test('maps SEQUENCE to sequence', () {
        expect(ObjectType.fromJson('SEQUENCE'), ObjectType.sequence);
      });

      test('maps ENUM_TYPE to enumType', () {
        expect(ObjectType.fromJson('ENUM_TYPE'), ObjectType.enumType);
      });

      test('maps FUNCTION to function', () {
        expect(ObjectType.fromJson('FUNCTION'), ObjectType.function);
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => ObjectType.fromJson('INVALID'),
          throwsArgumentError,
        );
      });
    });

    group('displayName', () {
      test('table returns Table', () {
        expect(ObjectType.table.displayName, 'Table');
      });

      test('view returns View', () {
        expect(ObjectType.view.displayName, 'View');
      });

      test('materializedView returns Materialized View', () {
        expect(ObjectType.materializedView.displayName, 'Materialized View');
      });

      test('sequence returns Sequence', () {
        expect(ObjectType.sequence.displayName, 'Sequence');
      });

      test('enumType returns Enum Type', () {
        expect(ObjectType.enumType.displayName, 'Enum Type');
      });

      test('function returns Function', () {
        expect(ObjectType.function.displayName, 'Function');
      });
    });

    test('round-trip all values through toJson and fromJson', () {
      for (final value in ObjectType.values) {
        expect(ObjectType.fromJson(value.toJson()), value);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Cross-enum: unknown fromJson
  // ---------------------------------------------------------------------------
  group('allEnums fromJson unknown fallback', () {
    test('ConnectionStatus throws for unknown', () {
      expect(
        () => ConnectionStatus.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('DatabaseDriver throws for unknown', () {
      expect(
        () => DatabaseDriver.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('ConstraintType throws for unknown', () {
      expect(
        () => ConstraintType.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('IndexType throws for unknown', () {
      expect(
        () => IndexType.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('ColumnCategory throws for unknown', () {
      expect(
        () => ColumnCategory.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('QueryStatus throws for unknown', () {
      expect(
        () => QueryStatus.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('SortDirection throws for unknown', () {
      expect(
        () => SortDirection.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('ObjectType throws for unknown', () {
      expect(
        () => ObjectType.fromJson('UNKNOWN'),
        throwsArgumentError,
      );
    });
  });
}
