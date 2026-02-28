/// Model classes for the DataLens module.
///
/// DataLens is a client-only database browser that connects directly to
/// PostgreSQL databases from the Flutter desktop app. These models represent
/// connection configurations, schema introspection results, and query state.
///
/// All classes use [JsonSerializable] with generated `fromJson` / `toJson`
/// methods via build_runner.
///
/// Organized by domain:
/// - Connection configuration (1 class)
/// - Schema introspection (8 classes)
/// - Query execution (3 classes)
/// - Query persistence (2 classes)
library;

import 'package:json_annotation/json_annotation.dart';

import 'datalens_enums.dart';

part 'datalens_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Connection Configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Saved database connection configuration.
@JsonSerializable()
class DatabaseConnection {
  /// UUID primary key.
  final String? id;

  /// Display name (e.g., "CodeOps Dev").
  final String? name;

  /// Database driver type.
  @DatabaseDriverConverter()
  final DatabaseDriver? driver;

  /// Database host address.
  final String? host;

  /// Database port number.
  final int? port;

  /// Database name.
  final String? database;

  /// Default schema (e.g., "public").
  final String? schema;

  /// Database username.
  final String? username;

  /// Database password (nullable — prompt if missing).
  final String? password;

  /// Whether to use SSL for the connection.
  final bool? useSsl;

  /// SSL mode (disable, require, verify-ca, verify-full).
  final String? sslMode;

  /// Hex color for visual identification.
  final String? color;

  /// Connection timeout in seconds.
  final int? connectionTimeout;

  /// Timestamp of last successful connection.
  final DateTime? lastConnectedAt;

  /// Timestamp when the connection config was created.
  final DateTime? createdAt;

  /// Timestamp when the connection config was last updated.
  final DateTime? updatedAt;

  /// Creates a [DatabaseConnection].
  const DatabaseConnection({
    this.id,
    this.name,
    this.driver,
    this.host,
    this.port,
    this.database,
    this.schema,
    this.username,
    this.password,
    this.useSsl,
    this.sslMode,
    this.color,
    this.connectionTimeout,
    this.lastConnectedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [DatabaseConnection] from a JSON map.
  factory DatabaseConnection.fromJson(Map<String, dynamic> json) =>
      _$DatabaseConnectionFromJson(json);

  /// Serializes this [DatabaseConnection] to a JSON map.
  Map<String, dynamic> toJson() => _$DatabaseConnectionToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Schema Introspection
// ─────────────────────────────────────────────────────────────────────────────

/// Database schema metadata.
@JsonSerializable()
class SchemaInfo {
  /// Schema name (e.g., "public", "forge").
  final String? name;

  /// Schema owner.
  final String? owner;

  /// Number of tables in the schema.
  final int? tableCount;

  /// Number of views in the schema.
  final int? viewCount;

  /// Number of sequences in the schema.
  final int? sequenceCount;

  /// Creates a [SchemaInfo].
  const SchemaInfo({
    this.name,
    this.owner,
    this.tableCount,
    this.viewCount,
    this.sequenceCount,
  });

  /// Deserializes a [SchemaInfo] from a JSON map.
  factory SchemaInfo.fromJson(Map<String, dynamic> json) =>
      _$SchemaInfoFromJson(json);

  /// Serializes this [SchemaInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$SchemaInfoToJson(this);
}

/// Database table metadata from introspection.
@JsonSerializable()
class TableInfo {
  /// Schema name containing this table.
  final String? schemaName;

  /// Table name.
  final String? tableName;

  /// Optional table comment.
  final String? tableComment;

  /// Object type (TABLE, VIEW, MATERIALIZED_VIEW).
  @ObjectTypeConverter()
  final ObjectType? objectType;

  /// Estimated row count from pg_class.reltuples.
  final int? rowEstimate;

  /// Human-readable table size from pg_size_pretty.
  final String? tableSize;

  /// Total size including indexes.
  final String? totalSize;

  /// Table owner.
  final String? owner;

  /// Whether row-level security is enabled.
  final bool? hasRls;

  /// Whether the table is partitioned.
  final bool? isPartitioned;

  /// Partition key expression.
  final String? partitionKey;

  /// Tablespace name.
  final String? tablespace;

  /// Creates a [TableInfo].
  const TableInfo({
    this.schemaName,
    this.tableName,
    this.tableComment,
    this.objectType,
    this.rowEstimate,
    this.tableSize,
    this.totalSize,
    this.owner,
    this.hasRls,
    this.isPartitioned,
    this.partitionKey,
    this.tablespace,
  });

  /// Deserializes a [TableInfo] from a JSON map.
  factory TableInfo.fromJson(Map<String, dynamic> json) =>
      _$TableInfoFromJson(json);

  /// Serializes this [TableInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$TableInfoToJson(this);
}

/// Column metadata from introspection.
@JsonSerializable()
class ColumnInfo {
  /// Column name.
  final String? columnName;

  /// Column ordinal position (1-based).
  final int? ordinalPosition;

  /// Full data type string (e.g., "character varying(255)").
  final String? dataType;

  /// Underlying type name (e.g., "varchar").
  final String? udtName;

  /// Whether the column allows NULL values.
  final bool? isNullable;

  /// Default value expression.
  final String? columnDefault;

  /// Whether this is an identity column.
  final bool? isIdentity;

  /// Identity generation type (ALWAYS, BY DEFAULT).
  final String? identityGeneration;

  /// Maximum character length.
  final int? characterMaxLength;

  /// Numeric precision.
  final int? numericPrecision;

  /// Numeric scale.
  final int? numericScale;

  /// Column collation.
  final String? collation;

  /// Column comment.
  final String? comment;

  /// Role of this column in the table.
  @ColumnCategoryConverter()
  final ColumnCategory? category;

  /// Creates a [ColumnInfo].
  const ColumnInfo({
    this.columnName,
    this.ordinalPosition,
    this.dataType,
    this.udtName,
    this.isNullable,
    this.columnDefault,
    this.isIdentity,
    this.identityGeneration,
    this.characterMaxLength,
    this.numericPrecision,
    this.numericScale,
    this.collation,
    this.comment,
    this.category,
  });

  /// Deserializes a [ColumnInfo] from a JSON map.
  factory ColumnInfo.fromJson(Map<String, dynamic> json) =>
      _$ColumnInfoFromJson(json);

  /// Serializes this [ColumnInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$ColumnInfoToJson(this);
}

/// Table constraint metadata.
@JsonSerializable()
class ConstraintInfo {
  /// Constraint name.
  final String? constraintName;

  /// Constraint type.
  @ConstraintTypeConverter()
  final ConstraintType? constraintType;

  /// Columns involved in this constraint.
  final List<String>? columns;

  /// CHECK constraint expression.
  final String? checkExpression;

  /// Referenced table (for foreign keys).
  final String? referencedTable;

  /// Referenced columns (for foreign keys).
  final List<String>? referencedColumns;

  /// ON UPDATE action (for foreign keys).
  final String? onUpdate;

  /// ON DELETE action (for foreign keys).
  final String? onDelete;

  /// Whether the constraint is deferrable.
  final bool? isDeferrable;

  /// Whether the constraint is initially deferred.
  final bool? isDeferred;

  /// Creates a [ConstraintInfo].
  const ConstraintInfo({
    this.constraintName,
    this.constraintType,
    this.columns,
    this.checkExpression,
    this.referencedTable,
    this.referencedColumns,
    this.onUpdate,
    this.onDelete,
    this.isDeferrable,
    this.isDeferred,
  });

  /// Deserializes a [ConstraintInfo] from a JSON map.
  factory ConstraintInfo.fromJson(Map<String, dynamic> json) =>
      _$ConstraintInfoFromJson(json);

  /// Serializes this [ConstraintInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$ConstraintInfoToJson(this);
}

/// Index metadata from introspection.
@JsonSerializable()
class IndexInfo {
  /// Index name.
  final String? indexName;

  /// Index access method type.
  @IndexTypeConverter()
  final IndexType? indexType;

  /// Columns included in this index.
  final List<String>? columns;

  /// Whether the index enforces uniqueness.
  final bool? isUnique;

  /// Whether this is the primary key index.
  final bool? isPrimary;

  /// Human-readable index size.
  final String? indexSize;

  /// Partial index WHERE clause condition.
  final String? condition;

  /// Tablespace for this index.
  final String? tablespace;

  /// Whether the index is valid (not in a failed build state).
  final bool? isValid;

  /// Creates an [IndexInfo].
  const IndexInfo({
    this.indexName,
    this.indexType,
    this.columns,
    this.isUnique,
    this.isPrimary,
    this.indexSize,
    this.condition,
    this.tablespace,
    this.isValid,
  });

  /// Deserializes an [IndexInfo] from a JSON map.
  factory IndexInfo.fromJson(Map<String, dynamic> json) =>
      _$IndexInfoFromJson(json);

  /// Serializes this [IndexInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$IndexInfoToJson(this);
}

/// Foreign key with resolved references.
@JsonSerializable()
class ForeignKeyInfo {
  /// Constraint name.
  final String? constraintName;

  /// Source columns.
  final List<String>? columns;

  /// Referenced schema name.
  final String? referencedSchema;

  /// Referenced table name.
  final String? referencedTable;

  /// Referenced column names.
  final List<String>? referencedColumns;

  /// ON UPDATE action.
  final String? onUpdate;

  /// ON DELETE action.
  final String? onDelete;

  /// Creates a [ForeignKeyInfo].
  const ForeignKeyInfo({
    this.constraintName,
    this.columns,
    this.referencedSchema,
    this.referencedTable,
    this.referencedColumns,
    this.onUpdate,
    this.onDelete,
  });

  /// Deserializes a [ForeignKeyInfo] from a JSON map.
  factory ForeignKeyInfo.fromJson(Map<String, dynamic> json) =>
      _$ForeignKeyInfoFromJson(json);

  /// Serializes this [ForeignKeyInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$ForeignKeyInfoToJson(this);
}

/// Sequence metadata from introspection.
@JsonSerializable()
class SequenceInfo {
  /// Sequence name.
  final String? sequenceName;

  /// Schema containing this sequence.
  final String? schemaName;

  /// Data type of the sequence values.
  final String? dataType;

  /// Start value.
  final int? startValue;

  /// Minimum value.
  final int? minValue;

  /// Maximum value.
  final int? maxValue;

  /// Increment step.
  final int? increment;

  /// Current value.
  final int? currentValue;

  /// Whether the sequence cycles on overflow.
  final bool? isCycled;

  /// Table that owns this sequence.
  final String? ownedByTable;

  /// Column that owns this sequence.
  final String? ownedByColumn;

  /// Creates a [SequenceInfo].
  const SequenceInfo({
    this.sequenceName,
    this.schemaName,
    this.dataType,
    this.startValue,
    this.minValue,
    this.maxValue,
    this.increment,
    this.currentValue,
    this.isCycled,
    this.ownedByTable,
    this.ownedByColumn,
  });

  /// Deserializes a [SequenceInfo] from a JSON map.
  factory SequenceInfo.fromJson(Map<String, dynamic> json) =>
      _$SequenceInfoFromJson(json);

  /// Serializes this [SequenceInfo] to a JSON map.
  Map<String, dynamic> toJson() => _$SequenceInfoToJson(this);
}

/// Table dependency or reference relationship.
@JsonSerializable()
class TableDependency {
  /// Source table name.
  final String? sourceTable;

  /// Source column name.
  final String? sourceColumn;

  /// Target table name.
  final String? targetTable;

  /// Target column name.
  final String? targetColumn;

  /// Constraint name.
  final String? constraintName;

  /// Relationship direction ("outgoing" or "incoming").
  final String? direction;

  /// Creates a [TableDependency].
  const TableDependency({
    this.sourceTable,
    this.sourceColumn,
    this.targetTable,
    this.targetColumn,
    this.constraintName,
    this.direction,
  });

  /// Deserializes a [TableDependency] from a JSON map.
  factory TableDependency.fromJson(Map<String, dynamic> json) =>
      _$TableDependencyFromJson(json);

  /// Serializes this [TableDependency] to a JSON map.
  Map<String, dynamic> toJson() => _$TableDependencyToJson(this);
}

/// Table statistics from pg_stat_user_tables.
@JsonSerializable()
class TableStatistics {
  /// Number of live rows.
  final int? liveRowCount;

  /// Number of dead (deleted but not vacuumed) rows.
  final int? deadRowCount;

  /// Last manual VACUUM timestamp.
  final DateTime? lastVacuum;

  /// Last auto-vacuum timestamp.
  final DateTime? lastAutoVacuum;

  /// Last manual ANALYZE timestamp.
  final DateTime? lastAnalyze;

  /// Last auto-analyze timestamp.
  final DateTime? lastAutoAnalyze;

  /// Sequential scan count.
  final int? seqScans;

  /// Index scan count.
  final int? idxScans;

  /// Insert count.
  final int? insertCount;

  /// Update count.
  final int? updateCount;

  /// Delete count.
  final int? deleteCount;

  /// Creates a [TableStatistics].
  const TableStatistics({
    this.liveRowCount,
    this.deadRowCount,
    this.lastVacuum,
    this.lastAutoVacuum,
    this.lastAnalyze,
    this.lastAutoAnalyze,
    this.seqScans,
    this.idxScans,
    this.insertCount,
    this.updateCount,
    this.deleteCount,
  });

  /// Deserializes a [TableStatistics] from a JSON map.
  factory TableStatistics.fromJson(Map<String, dynamic> json) =>
      _$TableStatisticsFromJson(json);

  /// Serializes this [TableStatistics] to a JSON map.
  Map<String, dynamic> toJson() => _$TableStatisticsToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Query Execution
// ─────────────────────────────────────────────────────────────────────────────

/// Result of executing a SQL query.
@JsonSerializable()
class QueryResult {
  /// Column metadata for the result set.
  final List<QueryColumn>? columns;

  /// Row data as a list of lists.
  final List<List<dynamic>>? rows;

  /// Number of rows returned.
  final int? rowCount;

  /// Total rows available (if known).
  final int? totalRows;

  /// Execution time in milliseconds.
  final int? executionTimeMs;

  /// Error message if the query failed.
  final String? error;

  /// Query execution status.
  @QueryStatusConverter()
  final QueryStatus? status;

  /// The SQL that was executed.
  final String? executedSql;

  /// Creates a [QueryResult].
  const QueryResult({
    this.columns,
    this.rows,
    this.rowCount,
    this.totalRows,
    this.executionTimeMs,
    this.error,
    this.status,
    this.executedSql,
  });

  /// Deserializes a [QueryResult] from a JSON map.
  factory QueryResult.fromJson(Map<String, dynamic> json) =>
      _$QueryResultFromJson(json);

  /// Serializes this [QueryResult] to a JSON map.
  Map<String, dynamic> toJson() => _$QueryResultToJson(this);
}

/// Column metadata in a query result.
@JsonSerializable()
class QueryColumn {
  /// Column name.
  final String? name;

  /// PostgreSQL type name.
  final String? typeName;

  /// PostgreSQL type OID.
  final int? typeOid;

  /// Creates a [QueryColumn].
  const QueryColumn({
    this.name,
    this.typeName,
    this.typeOid,
  });

  /// Deserializes a [QueryColumn] from a JSON map.
  factory QueryColumn.fromJson(Map<String, dynamic> json) =>
      _$QueryColumnFromJson(json);

  /// Serializes this [QueryColumn] to a JSON map.
  Map<String, dynamic> toJson() => _$QueryColumnToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Query Persistence
// ─────────────────────────────────────────────────────────────────────────────

/// Saved query history entry.
@JsonSerializable()
class QueryHistoryEntry {
  /// UUID primary key.
  final String? id;

  /// Connection UUID this query was run against.
  final String? connectionId;

  /// SQL that was executed.
  final String? sql;

  /// Query execution status.
  @QueryStatusConverter()
  final QueryStatus? status;

  /// Number of rows returned.
  final int? rowCount;

  /// Execution time in milliseconds.
  final int? executionTimeMs;

  /// Error message if the query failed.
  final String? error;

  /// Timestamp when the query was executed.
  final DateTime? executedAt;

  /// Creates a [QueryHistoryEntry].
  const QueryHistoryEntry({
    this.id,
    this.connectionId,
    this.sql,
    this.status,
    this.rowCount,
    this.executionTimeMs,
    this.error,
    this.executedAt,
  });

  /// Deserializes a [QueryHistoryEntry] from a JSON map.
  factory QueryHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$QueryHistoryEntryFromJson(json);

  /// Serializes this [QueryHistoryEntry] to a JSON map.
  Map<String, dynamic> toJson() => _$QueryHistoryEntryToJson(this);
}

/// User-saved query for reuse.
@JsonSerializable()
class SavedQuery {
  /// UUID primary key.
  final String? id;

  /// Connection UUID this query is associated with.
  final String? connectionId;

  /// Display name for the saved query.
  final String? name;

  /// Optional description.
  final String? description;

  /// SQL content.
  final String? sql;

  /// Optional grouping folder.
  final String? folder;

  /// Timestamp when the query was saved.
  final DateTime? createdAt;

  /// Timestamp when the query was last updated.
  final DateTime? updatedAt;

  /// Creates a [SavedQuery].
  const SavedQuery({
    this.id,
    this.connectionId,
    this.name,
    this.description,
    this.sql,
    this.folder,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [SavedQuery] from a JSON map.
  factory SavedQuery.fromJson(Map<String, dynamic> json) =>
      _$SavedQueryFromJson(json);

  /// Serializes this [SavedQuery] to a JSON map.
  Map<String, dynamic> toJson() => _$SavedQueryToJson(this);
}
