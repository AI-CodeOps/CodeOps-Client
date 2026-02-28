// Tests for DataLens model classes.
//
// Verifies const constructors, field assignment, JSON serialization
// round-trips, and nullable field handling for all 15 DataLens models.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';

void main() {
  // ══════════════════════════════════════════════════════════════
  //  CONNECTION CONFIGURATION
  // ══════════════════════════════════════════════════════════════

  group('DatabaseConnection', () {
    test('const constructor with all null optional fields', () {
      const instance = DatabaseConnection();
      expect(instance, isA<DatabaseConnection>());
    });

    test('constructor with populated fields', () {
      final instance = DatabaseConnection(
        id: 'conn-1',
        name: 'CodeOps Dev',
        driver: DatabaseDriver.postgresql,
        host: 'localhost',
        port: 5432,
        database: 'codeops',
        schema: 'public',
        username: 'codeops',
        password: 'codeops',
        useSsl: false,
        sslMode: 'disable',
        color: '#FF5733',
        connectionTimeout: 10,
        lastConnectedAt: DateTime.utc(2026),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(instance, isA<DatabaseConnection>());
      expect(instance.id, 'conn-1');
      expect(instance.name, 'CodeOps Dev');
      expect(instance.driver, DatabaseDriver.postgresql);
      expect(instance.host, 'localhost');
      expect(instance.port, 5432);
      expect(instance.database, 'codeops');
      expect(instance.schema, 'public');
      expect(instance.username, 'codeops');
      expect(instance.password, 'codeops');
      expect(instance.useSsl, false);
      expect(instance.sslMode, 'disable');
      expect(instance.color, '#FF5733');
      expect(instance.connectionTimeout, 10);
    });

    test('fromJson with all fields', () {
      final json = {
        'id': 'conn-1',
        'name': 'CodeOps Dev',
        'driver': 'POSTGRESQL',
        'host': 'localhost',
        'port': 5432,
        'database': 'codeops',
        'schema': 'public',
        'username': 'codeops',
        'password': 'codeops',
        'useSsl': false,
        'sslMode': 'disable',
        'color': '#FF5733',
        'connectionTimeout': 10,
        'lastConnectedAt': '2026-01-01T00:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final instance = DatabaseConnection.fromJson(json);
      expect(instance.id, 'conn-1');
      expect(instance.name, 'CodeOps Dev');
      expect(instance.driver, DatabaseDriver.postgresql);
      expect(instance.host, 'localhost');
      expect(instance.port, 5432);
      expect(instance.database, 'codeops');
      expect(instance.useSsl, false);
    });

    test('toJson round-trip', () {
      final original = DatabaseConnection(
        id: 'conn-1',
        name: 'Test DB',
        driver: DatabaseDriver.postgresql,
        host: '192.168.1.1',
        port: 5433,
        database: 'testdb',
        username: 'admin',
        useSsl: true,
        sslMode: 'require',
        connectionTimeout: 30,
        createdAt: DateTime.utc(2026),
      );
      final json = original.toJson();
      final restored = DatabaseConnection.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.driver, original.driver);
      expect(restored.host, original.host);
      expect(restored.port, original.port);
      expect(restored.database, original.database);
      expect(restored.useSsl, original.useSsl);
      expect(restored.sslMode, original.sslMode);
      expect(restored.connectionTimeout, original.connectionTimeout);
    });

    test('fromJson with nullable fields as null', () {
      final json = <String, dynamic>{
        'id': 'conn-1',
        'name': 'Minimal',
        'host': 'localhost',
        'port': 5432,
        'database': 'db',
        'username': 'user',
      };
      final instance = DatabaseConnection.fromJson(json);
      expect(instance.id, 'conn-1');
      expect(instance.password, isNull);
      expect(instance.schema, isNull);
      expect(instance.sslMode, isNull);
      expect(instance.color, isNull);
      expect(instance.lastConnectedAt, isNull);
      expect(instance.updatedAt, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  SCHEMA INTROSPECTION
  // ══════════════════════════════════════════════════════════════

  group('SchemaInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = SchemaInfo();
      expect(instance, isA<SchemaInfo>());
    });

    test('fromJson', () {
      final json = {
        'name': 'public',
        'owner': 'postgres',
        'tableCount': 15,
        'viewCount': 3,
        'sequenceCount': 10,
      };
      final instance = SchemaInfo.fromJson(json);
      expect(instance.name, 'public');
      expect(instance.owner, 'postgres');
      expect(instance.tableCount, 15);
      expect(instance.viewCount, 3);
      expect(instance.sequenceCount, 10);
    });
  });

  group('TableInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = TableInfo();
      expect(instance, isA<TableInfo>());
    });

    test('fromJson', () {
      final json = {
        'schemaName': 'public',
        'tableName': 'users',
        'tableComment': 'Application users',
        'objectType': 'TABLE',
        'rowEstimate': 1500,
        'tableSize': '256 kB',
        'totalSize': '512 kB',
        'owner': 'codeops',
        'hasRls': false,
        'isPartitioned': false,
        'partitionKey': null,
        'tablespace': null,
      };
      final instance = TableInfo.fromJson(json);
      expect(instance.schemaName, 'public');
      expect(instance.tableName, 'users');
      expect(instance.objectType, ObjectType.table);
      expect(instance.rowEstimate, 1500);
      expect(instance.tableSize, '256 kB');
      expect(instance.hasRls, false);
      expect(instance.isPartitioned, false);
    });
  });

  group('ColumnInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = ColumnInfo();
      expect(instance, isA<ColumnInfo>());
    });

    test('fromJson with all fields', () {
      final json = {
        'columnName': 'email',
        'ordinalPosition': 2,
        'dataType': 'character varying(255)',
        'udtName': 'varchar',
        'isNullable': false,
        'columnDefault': null,
        'isIdentity': false,
        'identityGeneration': null,
        'characterMaxLength': 255,
        'numericPrecision': null,
        'numericScale': null,
        'collation': 'en_US.UTF-8',
        'comment': 'User email address',
        'category': 'REGULAR',
      };
      final instance = ColumnInfo.fromJson(json);
      expect(instance.columnName, 'email');
      expect(instance.ordinalPosition, 2);
      expect(instance.dataType, 'character varying(255)');
      expect(instance.udtName, 'varchar');
      expect(instance.isNullable, false);
      expect(instance.characterMaxLength, 255);
      expect(instance.collation, 'en_US.UTF-8');
      expect(instance.comment, 'User email address');
      expect(instance.category, ColumnCategory.regular);
    });
  });

  group('ConstraintInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = ConstraintInfo();
      expect(instance, isA<ConstraintInfo>());
    });

    test('fromJson with FK references', () {
      final json = {
        'constraintName': 'fk_project_team',
        'constraintType': 'FOREIGN_KEY',
        'columns': ['team_id'],
        'checkExpression': null,
        'referencedTable': 'teams',
        'referencedColumns': ['id'],
        'onUpdate': 'NO ACTION',
        'onDelete': 'CASCADE',
        'isDeferrable': false,
        'isDeferred': false,
      };
      final instance = ConstraintInfo.fromJson(json);
      expect(instance.constraintName, 'fk_project_team');
      expect(instance.constraintType, ConstraintType.foreignKey);
      expect(instance.columns, ['team_id']);
      expect(instance.referencedTable, 'teams');
      expect(instance.referencedColumns, ['id']);
      expect(instance.onDelete, 'CASCADE');
      expect(instance.isDeferrable, false);
    });
  });

  group('IndexInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = IndexInfo();
      expect(instance, isA<IndexInfo>());
    });

    test('fromJson', () {
      final json = {
        'indexName': 'idx_users_email',
        'indexType': 'BTREE',
        'columns': ['email'],
        'isUnique': true,
        'isPrimary': false,
        'indexSize': '64 kB',
        'condition': null,
        'tablespace': null,
        'isValid': true,
      };
      final instance = IndexInfo.fromJson(json);
      expect(instance.indexName, 'idx_users_email');
      expect(instance.indexType, IndexType.btree);
      expect(instance.columns, ['email']);
      expect(instance.isUnique, true);
      expect(instance.isPrimary, false);
      expect(instance.indexSize, '64 kB');
      expect(instance.isValid, true);
    });
  });

  group('ForeignKeyInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = ForeignKeyInfo();
      expect(instance, isA<ForeignKeyInfo>());
    });

    test('fromJson', () {
      final json = {
        'constraintName': 'fk_project_team',
        'columns': ['team_id'],
        'referencedSchema': 'public',
        'referencedTable': 'teams',
        'referencedColumns': ['id'],
        'onUpdate': 'NO ACTION',
        'onDelete': 'CASCADE',
      };
      final instance = ForeignKeyInfo.fromJson(json);
      expect(instance.constraintName, 'fk_project_team');
      expect(instance.columns, ['team_id']);
      expect(instance.referencedSchema, 'public');
      expect(instance.referencedTable, 'teams');
      expect(instance.referencedColumns, ['id']);
      expect(instance.onUpdate, 'NO ACTION');
      expect(instance.onDelete, 'CASCADE');
    });
  });

  group('SequenceInfo', () {
    test('const constructor with all null optional fields', () {
      const instance = SequenceInfo();
      expect(instance, isA<SequenceInfo>());
    });

    test('fromJson', () {
      final json = {
        'sequenceName': 'users_id_seq',
        'schemaName': 'public',
        'dataType': 'bigint',
        'startValue': 1,
        'minValue': 1,
        'maxValue': 9223372036854775807,
        'increment': 1,
        'currentValue': 42,
        'isCycled': false,
        'ownedByTable': 'users',
        'ownedByColumn': 'id',
      };
      final instance = SequenceInfo.fromJson(json);
      expect(instance.sequenceName, 'users_id_seq');
      expect(instance.schemaName, 'public');
      expect(instance.dataType, 'bigint');
      expect(instance.startValue, 1);
      expect(instance.currentValue, 42);
      expect(instance.isCycled, false);
      expect(instance.ownedByTable, 'users');
      expect(instance.ownedByColumn, 'id');
    });
  });

  group('TableDependency', () {
    test('const constructor with all null optional fields', () {
      const instance = TableDependency();
      expect(instance, isA<TableDependency>());
    });

    test('fromJson', () {
      final json = {
        'sourceTable': 'projects',
        'sourceColumn': 'team_id',
        'targetTable': 'teams',
        'targetColumn': 'id',
        'constraintName': 'fk_project_team',
        'direction': 'outgoing',
      };
      final instance = TableDependency.fromJson(json);
      expect(instance.sourceTable, 'projects');
      expect(instance.sourceColumn, 'team_id');
      expect(instance.targetTable, 'teams');
      expect(instance.targetColumn, 'id');
      expect(instance.constraintName, 'fk_project_team');
      expect(instance.direction, 'outgoing');
    });
  });

  group('TableStatistics', () {
    test('const constructor with all null optional fields', () {
      const instance = TableStatistics();
      expect(instance, isA<TableStatistics>());
    });

    test('fromJson with nullable dates', () {
      final json = {
        'liveRowCount': 5000,
        'deadRowCount': 120,
        'lastVacuum': '2026-02-01T00:00:00.000Z',
        'lastAutoVacuum': '2026-02-15T00:00:00.000Z',
        'lastAnalyze': null,
        'lastAutoAnalyze': null,
        'seqScans': 350,
        'idxScans': 12000,
        'insertCount': 200,
        'updateCount': 150,
        'deleteCount': 30,
      };
      final instance = TableStatistics.fromJson(json);
      expect(instance.liveRowCount, 5000);
      expect(instance.deadRowCount, 120);
      expect(instance.lastVacuum, isNotNull);
      expect(instance.lastAutoVacuum, isNotNull);
      expect(instance.lastAnalyze, isNull);
      expect(instance.lastAutoAnalyze, isNull);
      expect(instance.seqScans, 350);
      expect(instance.idxScans, 12000);
      expect(instance.insertCount, 200);
      expect(instance.updateCount, 150);
      expect(instance.deleteCount, 30);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  QUERY EXECUTION
  // ══════════════════════════════════════════════════════════════

  group('QueryResult', () {
    test('const constructor with all null optional fields', () {
      const instance = QueryResult();
      expect(instance, isA<QueryResult>());
    });

    test('construction with columns and rows', () {
      const instance = QueryResult(
        columns: [
          QueryColumn(name: 'id', typeName: 'integer', typeOid: 23),
          QueryColumn(name: 'name', typeName: 'varchar', typeOid: 1043),
        ],
        rows: [
          [1, 'Alice'],
          [2, 'Bob'],
        ],
        rowCount: 2,
        totalRows: 100,
        executionTimeMs: 42,
        status: QueryStatus.completed,
        executedSql: 'SELECT id, name FROM users LIMIT 2',
      );
      expect(instance.columns!.length, 2);
      expect(instance.rows!.length, 2);
      expect(instance.rowCount, 2);
      expect(instance.totalRows, 100);
      expect(instance.executionTimeMs, 42);
      expect(instance.status, QueryStatus.completed);
      expect(instance.executedSql, 'SELECT id, name FROM users LIMIT 2');
    });
  });

  group('QueryColumn', () {
    test('const constructor with all null optional fields', () {
      const instance = QueryColumn();
      expect(instance, isA<QueryColumn>());
    });

    test('construction with type info', () {
      const instance = QueryColumn(
        name: 'email',
        typeName: 'varchar',
        typeOid: 1043,
      );
      expect(instance.name, 'email');
      expect(instance.typeName, 'varchar');
      expect(instance.typeOid, 1043);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  QUERY PERSISTENCE
  // ══════════════════════════════════════════════════════════════

  group('QueryHistoryEntry', () {
    test('const constructor with all null optional fields', () {
      const instance = QueryHistoryEntry();
      expect(instance, isA<QueryHistoryEntry>());
    });

    test('fromJson', () {
      final json = {
        'id': 'qh-1',
        'connectionId': 'conn-1',
        'sql': 'SELECT * FROM users',
        'status': 'COMPLETED',
        'rowCount': 50,
        'executionTimeMs': 120,
        'error': null,
        'executedAt': '2026-02-28T12:00:00.000Z',
      };
      final instance = QueryHistoryEntry.fromJson(json);
      expect(instance.id, 'qh-1');
      expect(instance.connectionId, 'conn-1');
      expect(instance.sql, 'SELECT * FROM users');
      expect(instance.status, QueryStatus.completed);
      expect(instance.rowCount, 50);
      expect(instance.executionTimeMs, 120);
      expect(instance.error, isNull);
      expect(instance.executedAt, isNotNull);
    });
  });

  group('SavedQuery', () {
    test('const constructor with all null optional fields', () {
      const instance = SavedQuery();
      expect(instance, isA<SavedQuery>());
    });

    test('fromJson', () {
      final json = {
        'id': 'sq-1',
        'connectionId': 'conn-1',
        'name': 'Active Users',
        'description': 'List all active users',
        'sql': 'SELECT * FROM users WHERE is_active = true',
        'folder': 'Reports',
        'createdAt': '2026-02-28T12:00:00.000Z',
        'updatedAt': '2026-02-28T13:00:00.000Z',
      };
      final instance = SavedQuery.fromJson(json);
      expect(instance.id, 'sq-1');
      expect(instance.connectionId, 'conn-1');
      expect(instance.name, 'Active Users');
      expect(instance.description, 'List all active users');
      expect(instance.sql, 'SELECT * FROM users WHERE is_active = true');
      expect(instance.folder, 'Reports');
      expect(instance.createdAt, isNotNull);
      expect(instance.updatedAt, isNotNull);
    });
  });
}
