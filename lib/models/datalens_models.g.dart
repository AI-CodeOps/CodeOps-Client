// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datalens_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DatabaseConnection _$DatabaseConnectionFromJson(Map<String, dynamic> json) =>
    DatabaseConnection(
      id: json['id'] as String?,
      name: json['name'] as String?,
      driver: _$JsonConverterFromJson<String, DatabaseDriver>(
          json['driver'], const DatabaseDriverConverter().fromJson),
      host: json['host'] as String?,
      port: (json['port'] as num?)?.toInt(),
      database: json['database'] as String?,
      schema: json['schema'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      useSsl: json['useSsl'] as bool?,
      sslMode: json['sslMode'] as String?,
      color: json['color'] as String?,
      connectionTimeout: (json['connectionTimeout'] as num?)?.toInt(),
      lastConnectedAt: json['lastConnectedAt'] == null
          ? null
          : DateTime.parse(json['lastConnectedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DatabaseConnectionToJson(DatabaseConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'driver': _$JsonConverterToJson<String, DatabaseDriver>(
          instance.driver, const DatabaseDriverConverter().toJson),
      'host': instance.host,
      'port': instance.port,
      'database': instance.database,
      'schema': instance.schema,
      'username': instance.username,
      'password': instance.password,
      'useSsl': instance.useSsl,
      'sslMode': instance.sslMode,
      'color': instance.color,
      'connectionTimeout': instance.connectionTimeout,
      'lastConnectedAt': instance.lastConnectedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

SchemaInfo _$SchemaInfoFromJson(Map<String, dynamic> json) => SchemaInfo(
      name: json['name'] as String?,
      owner: json['owner'] as String?,
      tableCount: (json['tableCount'] as num?)?.toInt(),
      viewCount: (json['viewCount'] as num?)?.toInt(),
      sequenceCount: (json['sequenceCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SchemaInfoToJson(SchemaInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'owner': instance.owner,
      'tableCount': instance.tableCount,
      'viewCount': instance.viewCount,
      'sequenceCount': instance.sequenceCount,
    };

TableInfo _$TableInfoFromJson(Map<String, dynamic> json) => TableInfo(
      schemaName: json['schemaName'] as String?,
      tableName: json['tableName'] as String?,
      tableComment: json['tableComment'] as String?,
      objectType: _$JsonConverterFromJson<String, ObjectType>(
          json['objectType'], const ObjectTypeConverter().fromJson),
      rowEstimate: (json['rowEstimate'] as num?)?.toInt(),
      tableSize: json['tableSize'] as String?,
      totalSize: json['totalSize'] as String?,
      owner: json['owner'] as String?,
      hasRls: json['hasRls'] as bool?,
      isPartitioned: json['isPartitioned'] as bool?,
      partitionKey: json['partitionKey'] as String?,
      tablespace: json['tablespace'] as String?,
    );

Map<String, dynamic> _$TableInfoToJson(TableInfo instance) => <String, dynamic>{
      'schemaName': instance.schemaName,
      'tableName': instance.tableName,
      'tableComment': instance.tableComment,
      'objectType': _$JsonConverterToJson<String, ObjectType>(
          instance.objectType, const ObjectTypeConverter().toJson),
      'rowEstimate': instance.rowEstimate,
      'tableSize': instance.tableSize,
      'totalSize': instance.totalSize,
      'owner': instance.owner,
      'hasRls': instance.hasRls,
      'isPartitioned': instance.isPartitioned,
      'partitionKey': instance.partitionKey,
      'tablespace': instance.tablespace,
    };

ColumnInfo _$ColumnInfoFromJson(Map<String, dynamic> json) => ColumnInfo(
      columnName: json['columnName'] as String?,
      ordinalPosition: (json['ordinalPosition'] as num?)?.toInt(),
      dataType: json['dataType'] as String?,
      udtName: json['udtName'] as String?,
      isNullable: json['isNullable'] as bool?,
      columnDefault: json['columnDefault'] as String?,
      isIdentity: json['isIdentity'] as bool?,
      identityGeneration: json['identityGeneration'] as String?,
      characterMaxLength: (json['characterMaxLength'] as num?)?.toInt(),
      numericPrecision: (json['numericPrecision'] as num?)?.toInt(),
      numericScale: (json['numericScale'] as num?)?.toInt(),
      collation: json['collation'] as String?,
      comment: json['comment'] as String?,
      category: _$JsonConverterFromJson<String, ColumnCategory>(
          json['category'], const ColumnCategoryConverter().fromJson),
    );

Map<String, dynamic> _$ColumnInfoToJson(ColumnInfo instance) =>
    <String, dynamic>{
      'columnName': instance.columnName,
      'ordinalPosition': instance.ordinalPosition,
      'dataType': instance.dataType,
      'udtName': instance.udtName,
      'isNullable': instance.isNullable,
      'columnDefault': instance.columnDefault,
      'isIdentity': instance.isIdentity,
      'identityGeneration': instance.identityGeneration,
      'characterMaxLength': instance.characterMaxLength,
      'numericPrecision': instance.numericPrecision,
      'numericScale': instance.numericScale,
      'collation': instance.collation,
      'comment': instance.comment,
      'category': _$JsonConverterToJson<String, ColumnCategory>(
          instance.category, const ColumnCategoryConverter().toJson),
    };

ConstraintInfo _$ConstraintInfoFromJson(Map<String, dynamic> json) =>
    ConstraintInfo(
      constraintName: json['constraintName'] as String?,
      constraintType: _$JsonConverterFromJson<String, ConstraintType>(
          json['constraintType'], const ConstraintTypeConverter().fromJson),
      columns:
          (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList(),
      checkExpression: json['checkExpression'] as String?,
      referencedTable: json['referencedTable'] as String?,
      referencedColumns: (json['referencedColumns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      onUpdate: json['onUpdate'] as String?,
      onDelete: json['onDelete'] as String?,
      isDeferrable: json['isDeferrable'] as bool?,
      isDeferred: json['isDeferred'] as bool?,
    );

Map<String, dynamic> _$ConstraintInfoToJson(ConstraintInfo instance) =>
    <String, dynamic>{
      'constraintName': instance.constraintName,
      'constraintType': _$JsonConverterToJson<String, ConstraintType>(
          instance.constraintType, const ConstraintTypeConverter().toJson),
      'columns': instance.columns,
      'checkExpression': instance.checkExpression,
      'referencedTable': instance.referencedTable,
      'referencedColumns': instance.referencedColumns,
      'onUpdate': instance.onUpdate,
      'onDelete': instance.onDelete,
      'isDeferrable': instance.isDeferrable,
      'isDeferred': instance.isDeferred,
    };

IndexInfo _$IndexInfoFromJson(Map<String, dynamic> json) => IndexInfo(
      indexName: json['indexName'] as String?,
      indexType: _$JsonConverterFromJson<String, IndexType>(
          json['indexType'], const IndexTypeConverter().fromJson),
      columns:
          (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isUnique: json['isUnique'] as bool?,
      isPrimary: json['isPrimary'] as bool?,
      indexSize: json['indexSize'] as String?,
      condition: json['condition'] as String?,
      tablespace: json['tablespace'] as String?,
      isValid: json['isValid'] as bool?,
    );

Map<String, dynamic> _$IndexInfoToJson(IndexInfo instance) => <String, dynamic>{
      'indexName': instance.indexName,
      'indexType': _$JsonConverterToJson<String, IndexType>(
          instance.indexType, const IndexTypeConverter().toJson),
      'columns': instance.columns,
      'isUnique': instance.isUnique,
      'isPrimary': instance.isPrimary,
      'indexSize': instance.indexSize,
      'condition': instance.condition,
      'tablespace': instance.tablespace,
      'isValid': instance.isValid,
    };

ForeignKeyInfo _$ForeignKeyInfoFromJson(Map<String, dynamic> json) =>
    ForeignKeyInfo(
      constraintName: json['constraintName'] as String?,
      columns:
          (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList(),
      referencedSchema: json['referencedSchema'] as String?,
      referencedTable: json['referencedTable'] as String?,
      referencedColumns: (json['referencedColumns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      onUpdate: json['onUpdate'] as String?,
      onDelete: json['onDelete'] as String?,
    );

Map<String, dynamic> _$ForeignKeyInfoToJson(ForeignKeyInfo instance) =>
    <String, dynamic>{
      'constraintName': instance.constraintName,
      'columns': instance.columns,
      'referencedSchema': instance.referencedSchema,
      'referencedTable': instance.referencedTable,
      'referencedColumns': instance.referencedColumns,
      'onUpdate': instance.onUpdate,
      'onDelete': instance.onDelete,
    };

SequenceInfo _$SequenceInfoFromJson(Map<String, dynamic> json) => SequenceInfo(
      sequenceName: json['sequenceName'] as String?,
      schemaName: json['schemaName'] as String?,
      dataType: json['dataType'] as String?,
      startValue: (json['startValue'] as num?)?.toInt(),
      minValue: (json['minValue'] as num?)?.toInt(),
      maxValue: (json['maxValue'] as num?)?.toInt(),
      increment: (json['increment'] as num?)?.toInt(),
      currentValue: (json['currentValue'] as num?)?.toInt(),
      isCycled: json['isCycled'] as bool?,
      ownedByTable: json['ownedByTable'] as String?,
      ownedByColumn: json['ownedByColumn'] as String?,
    );

Map<String, dynamic> _$SequenceInfoToJson(SequenceInfo instance) =>
    <String, dynamic>{
      'sequenceName': instance.sequenceName,
      'schemaName': instance.schemaName,
      'dataType': instance.dataType,
      'startValue': instance.startValue,
      'minValue': instance.minValue,
      'maxValue': instance.maxValue,
      'increment': instance.increment,
      'currentValue': instance.currentValue,
      'isCycled': instance.isCycled,
      'ownedByTable': instance.ownedByTable,
      'ownedByColumn': instance.ownedByColumn,
    };

TableDependency _$TableDependencyFromJson(Map<String, dynamic> json) =>
    TableDependency(
      sourceTable: json['sourceTable'] as String?,
      sourceColumn: json['sourceColumn'] as String?,
      targetTable: json['targetTable'] as String?,
      targetColumn: json['targetColumn'] as String?,
      constraintName: json['constraintName'] as String?,
      direction: json['direction'] as String?,
    );

Map<String, dynamic> _$TableDependencyToJson(TableDependency instance) =>
    <String, dynamic>{
      'sourceTable': instance.sourceTable,
      'sourceColumn': instance.sourceColumn,
      'targetTable': instance.targetTable,
      'targetColumn': instance.targetColumn,
      'constraintName': instance.constraintName,
      'direction': instance.direction,
    };

TableStatistics _$TableStatisticsFromJson(Map<String, dynamic> json) =>
    TableStatistics(
      liveRowCount: (json['liveRowCount'] as num?)?.toInt(),
      deadRowCount: (json['deadRowCount'] as num?)?.toInt(),
      lastVacuum: json['lastVacuum'] == null
          ? null
          : DateTime.parse(json['lastVacuum'] as String),
      lastAutoVacuum: json['lastAutoVacuum'] == null
          ? null
          : DateTime.parse(json['lastAutoVacuum'] as String),
      lastAnalyze: json['lastAnalyze'] == null
          ? null
          : DateTime.parse(json['lastAnalyze'] as String),
      lastAutoAnalyze: json['lastAutoAnalyze'] == null
          ? null
          : DateTime.parse(json['lastAutoAnalyze'] as String),
      seqScans: (json['seqScans'] as num?)?.toInt(),
      idxScans: (json['idxScans'] as num?)?.toInt(),
      insertCount: (json['insertCount'] as num?)?.toInt(),
      updateCount: (json['updateCount'] as num?)?.toInt(),
      deleteCount: (json['deleteCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TableStatisticsToJson(TableStatistics instance) =>
    <String, dynamic>{
      'liveRowCount': instance.liveRowCount,
      'deadRowCount': instance.deadRowCount,
      'lastVacuum': instance.lastVacuum?.toIso8601String(),
      'lastAutoVacuum': instance.lastAutoVacuum?.toIso8601String(),
      'lastAnalyze': instance.lastAnalyze?.toIso8601String(),
      'lastAutoAnalyze': instance.lastAutoAnalyze?.toIso8601String(),
      'seqScans': instance.seqScans,
      'idxScans': instance.idxScans,
      'insertCount': instance.insertCount,
      'updateCount': instance.updateCount,
      'deleteCount': instance.deleteCount,
    };

QueryResult _$QueryResultFromJson(Map<String, dynamic> json) => QueryResult(
      columns: (json['columns'] as List<dynamic>?)
          ?.map((e) => QueryColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList(),
      rowCount: (json['rowCount'] as num?)?.toInt(),
      totalRows: (json['totalRows'] as num?)?.toInt(),
      executionTimeMs: (json['executionTimeMs'] as num?)?.toInt(),
      error: json['error'] as String?,
      status: _$JsonConverterFromJson<String, QueryStatus>(
          json['status'], const QueryStatusConverter().fromJson),
      executedSql: json['executedSql'] as String?,
    );

Map<String, dynamic> _$QueryResultToJson(QueryResult instance) =>
    <String, dynamic>{
      'columns': instance.columns,
      'rows': instance.rows,
      'rowCount': instance.rowCount,
      'totalRows': instance.totalRows,
      'executionTimeMs': instance.executionTimeMs,
      'error': instance.error,
      'status': _$JsonConverterToJson<String, QueryStatus>(
          instance.status, const QueryStatusConverter().toJson),
      'executedSql': instance.executedSql,
    };

QueryColumn _$QueryColumnFromJson(Map<String, dynamic> json) => QueryColumn(
      name: json['name'] as String?,
      typeName: json['typeName'] as String?,
      typeOid: (json['typeOid'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QueryColumnToJson(QueryColumn instance) =>
    <String, dynamic>{
      'name': instance.name,
      'typeName': instance.typeName,
      'typeOid': instance.typeOid,
    };

QueryHistoryEntry _$QueryHistoryEntryFromJson(Map<String, dynamic> json) =>
    QueryHistoryEntry(
      id: json['id'] as String?,
      connectionId: json['connectionId'] as String?,
      sql: json['sql'] as String?,
      status: _$JsonConverterFromJson<String, QueryStatus>(
          json['status'], const QueryStatusConverter().fromJson),
      rowCount: (json['rowCount'] as num?)?.toInt(),
      executionTimeMs: (json['executionTimeMs'] as num?)?.toInt(),
      error: json['error'] as String?,
      executedAt: json['executedAt'] == null
          ? null
          : DateTime.parse(json['executedAt'] as String),
    );

Map<String, dynamic> _$QueryHistoryEntryToJson(QueryHistoryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'connectionId': instance.connectionId,
      'sql': instance.sql,
      'status': _$JsonConverterToJson<String, QueryStatus>(
          instance.status, const QueryStatusConverter().toJson),
      'rowCount': instance.rowCount,
      'executionTimeMs': instance.executionTimeMs,
      'error': instance.error,
      'executedAt': instance.executedAt?.toIso8601String(),
    };

SavedQuery _$SavedQueryFromJson(Map<String, dynamic> json) => SavedQuery(
      id: json['id'] as String?,
      connectionId: json['connectionId'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      sql: json['sql'] as String?,
      folder: json['folder'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SavedQueryToJson(SavedQuery instance) =>
    <String, dynamic>{
      'id': instance.id,
      'connectionId': instance.connectionId,
      'name': instance.name,
      'description': instance.description,
      'sql': instance.sql,
      'folder': instance.folder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
