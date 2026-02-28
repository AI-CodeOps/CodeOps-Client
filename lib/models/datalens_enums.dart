/// Enum types for the DataLens module.
///
/// Each enum provides SCREAMING_SNAKE_CASE serialization for local persistence,
/// plus a companion [JsonConverter] for use with `json_serializable`.
library;

import 'package:json_annotation/json_annotation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConnectionStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Lifecycle state of a database connection.
enum ConnectionStatus {
  /// Connection is active and usable.
  connected,

  /// Connection is closed.
  disconnected,

  /// Connection is being established.
  connecting,

  /// Connection attempt failed or connection dropped.
  error;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ConnectionStatus.connected => 'CONNECTED',
        ConnectionStatus.disconnected => 'DISCONNECTED',
        ConnectionStatus.connecting => 'CONNECTING',
        ConnectionStatus.error => 'ERROR',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static ConnectionStatus fromJson(String json) => switch (json) {
        'CONNECTED' => ConnectionStatus.connected,
        'DISCONNECTED' => ConnectionStatus.disconnected,
        'CONNECTING' => ConnectionStatus.connecting,
        'ERROR' => ConnectionStatus.error,
        _ => throw ArgumentError('Unknown ConnectionStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ConnectionStatus.connected => 'Connected',
        ConnectionStatus.disconnected => 'Disconnected',
        ConnectionStatus.connecting => 'Connecting',
        ConnectionStatus.error => 'Error',
      };
}

/// JSON converter for [ConnectionStatus].
class ConnectionStatusConverter
    extends JsonConverter<ConnectionStatus, String> {
  /// Creates a [ConnectionStatusConverter].
  const ConnectionStatusConverter();

  @override
  ConnectionStatus fromJson(String json) => ConnectionStatus.fromJson(json);

  @override
  String toJson(ConnectionStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// DatabaseDriver
// ─────────────────────────────────────────────────────────────────────────────

/// Supported database drivers.
enum DatabaseDriver {
  /// PostgreSQL database.
  postgresql;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        DatabaseDriver.postgresql => 'POSTGRESQL',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static DatabaseDriver fromJson(String json) => switch (json) {
        'POSTGRESQL' => DatabaseDriver.postgresql,
        _ => throw ArgumentError('Unknown DatabaseDriver: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        DatabaseDriver.postgresql => 'PostgreSQL',
      };
}

/// JSON converter for [DatabaseDriver].
class DatabaseDriverConverter extends JsonConverter<DatabaseDriver, String> {
  /// Creates a [DatabaseDriverConverter].
  const DatabaseDriverConverter();

  @override
  DatabaseDriver fromJson(String json) => DatabaseDriver.fromJson(json);

  @override
  String toJson(DatabaseDriver object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// ConstraintType
// ─────────────────────────────────────────────────────────────────────────────

/// Type of table constraint in a database schema.
enum ConstraintType {
  /// Primary key constraint.
  primaryKey,

  /// Foreign key constraint.
  foreignKey,

  /// Unique constraint.
  unique,

  /// Check constraint.
  check,

  /// Exclusion constraint (PostgreSQL-specific).
  exclusion;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ConstraintType.primaryKey => 'PRIMARY_KEY',
        ConstraintType.foreignKey => 'FOREIGN_KEY',
        ConstraintType.unique => 'UNIQUE',
        ConstraintType.check => 'CHECK',
        ConstraintType.exclusion => 'EXCLUSION',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static ConstraintType fromJson(String json) => switch (json) {
        'PRIMARY_KEY' => ConstraintType.primaryKey,
        'FOREIGN_KEY' => ConstraintType.foreignKey,
        'UNIQUE' => ConstraintType.unique,
        'CHECK' => ConstraintType.check,
        'EXCLUSION' => ConstraintType.exclusion,
        _ => throw ArgumentError('Unknown ConstraintType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ConstraintType.primaryKey => 'Primary Key',
        ConstraintType.foreignKey => 'Foreign Key',
        ConstraintType.unique => 'Unique',
        ConstraintType.check => 'Check',
        ConstraintType.exclusion => 'Exclusion',
      };
}

/// JSON converter for [ConstraintType].
class ConstraintTypeConverter extends JsonConverter<ConstraintType, String> {
  /// Creates a [ConstraintTypeConverter].
  const ConstraintTypeConverter();

  @override
  ConstraintType fromJson(String json) => ConstraintType.fromJson(json);

  @override
  String toJson(ConstraintType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// IndexType
// ─────────────────────────────────────────────────────────────────────────────

/// PostgreSQL index access method.
enum IndexType {
  /// B-tree index (default).
  btree,

  /// Hash index.
  hash,

  /// Generalized Inverted Index (full-text, arrays, JSONB).
  gin,

  /// Generalized Search Tree (geometric, range types).
  gist,

  /// Space-partitioned GiST.
  spgist,

  /// Block Range Index (large sequential tables).
  brin;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        IndexType.btree => 'BTREE',
        IndexType.hash => 'HASH',
        IndexType.gin => 'GIN',
        IndexType.gist => 'GIST',
        IndexType.spgist => 'SPGIST',
        IndexType.brin => 'BRIN',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static IndexType fromJson(String json) => switch (json) {
        'BTREE' => IndexType.btree,
        'HASH' => IndexType.hash,
        'GIN' => IndexType.gin,
        'GIST' => IndexType.gist,
        'SPGIST' => IndexType.spgist,
        'BRIN' => IndexType.brin,
        _ => throw ArgumentError('Unknown IndexType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        IndexType.btree => 'B-Tree',
        IndexType.hash => 'Hash',
        IndexType.gin => 'GIN',
        IndexType.gist => 'GiST',
        IndexType.spgist => 'SP-GiST',
        IndexType.brin => 'BRIN',
      };
}

/// JSON converter for [IndexType].
class IndexTypeConverter extends JsonConverter<IndexType, String> {
  /// Creates an [IndexTypeConverter].
  const IndexTypeConverter();

  @override
  IndexType fromJson(String json) => IndexType.fromJson(json);

  @override
  String toJson(IndexType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// ColumnCategory
// ─────────────────────────────────────────────────────────────────────────────

/// Role of a column within a table.
enum ColumnCategory {
  /// Regular data column.
  regular,

  /// Part of the primary key.
  primaryKey,

  /// References another table via foreign key.
  foreignKey,

  /// Generated column (computed from other columns).
  generated,

  /// Auto-incrementing serial column.
  serial;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ColumnCategory.regular => 'REGULAR',
        ColumnCategory.primaryKey => 'PRIMARY_KEY',
        ColumnCategory.foreignKey => 'FOREIGN_KEY',
        ColumnCategory.generated => 'GENERATED',
        ColumnCategory.serial => 'SERIAL',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static ColumnCategory fromJson(String json) => switch (json) {
        'REGULAR' => ColumnCategory.regular,
        'PRIMARY_KEY' => ColumnCategory.primaryKey,
        'FOREIGN_KEY' => ColumnCategory.foreignKey,
        'GENERATED' => ColumnCategory.generated,
        'SERIAL' => ColumnCategory.serial,
        _ => throw ArgumentError('Unknown ColumnCategory: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ColumnCategory.regular => 'Regular',
        ColumnCategory.primaryKey => 'Primary Key',
        ColumnCategory.foreignKey => 'Foreign Key',
        ColumnCategory.generated => 'Generated',
        ColumnCategory.serial => 'Serial',
      };
}

/// JSON converter for [ColumnCategory].
class ColumnCategoryConverter extends JsonConverter<ColumnCategory, String> {
  /// Creates a [ColumnCategoryConverter].
  const ColumnCategoryConverter();

  @override
  ColumnCategory fromJson(String json) => ColumnCategory.fromJson(json);

  @override
  String toJson(ColumnCategory object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// QueryStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Execution state of a SQL query.
enum QueryStatus {
  /// Query is currently executing.
  running,

  /// Query completed successfully.
  completed,

  /// Query execution failed.
  failed,

  /// Query was cancelled by the user.
  cancelled;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        QueryStatus.running => 'RUNNING',
        QueryStatus.completed => 'COMPLETED',
        QueryStatus.failed => 'FAILED',
        QueryStatus.cancelled => 'CANCELLED',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static QueryStatus fromJson(String json) => switch (json) {
        'RUNNING' => QueryStatus.running,
        'COMPLETED' => QueryStatus.completed,
        'FAILED' => QueryStatus.failed,
        'CANCELLED' => QueryStatus.cancelled,
        _ => throw ArgumentError('Unknown QueryStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        QueryStatus.running => 'Running',
        QueryStatus.completed => 'Completed',
        QueryStatus.failed => 'Failed',
        QueryStatus.cancelled => 'Cancelled',
      };
}

/// JSON converter for [QueryStatus].
class QueryStatusConverter extends JsonConverter<QueryStatus, String> {
  /// Creates a [QueryStatusConverter].
  const QueryStatusConverter();

  @override
  QueryStatus fromJson(String json) => QueryStatus.fromJson(json);

  @override
  String toJson(QueryStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// SortDirection
// ─────────────────────────────────────────────────────────────────────────────

/// Column sort direction for query results.
enum SortDirection {
  /// Ascending order.
  asc,

  /// Descending order.
  desc;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        SortDirection.asc => 'ASC',
        SortDirection.desc => 'DESC',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static SortDirection fromJson(String json) => switch (json) {
        'ASC' => SortDirection.asc,
        'DESC' => SortDirection.desc,
        _ => throw ArgumentError('Unknown SortDirection: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        SortDirection.asc => 'Ascending',
        SortDirection.desc => 'Descending',
      };
}

/// JSON converter for [SortDirection].
class SortDirectionConverter extends JsonConverter<SortDirection, String> {
  /// Creates a [SortDirectionConverter].
  const SortDirectionConverter();

  @override
  SortDirection fromJson(String json) => SortDirection.fromJson(json);

  @override
  String toJson(SortDirection object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// ObjectType
// ─────────────────────────────────────────────────────────────────────────────

/// Type of database object in a schema.
enum ObjectType {
  /// Regular table.
  table,

  /// View.
  view,

  /// Materialized view.
  materializedView,

  /// Sequence.
  sequence,

  /// Enum type.
  enumType,

  /// Function or stored procedure.
  function;

  /// Serializes to SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ObjectType.table => 'TABLE',
        ObjectType.view => 'VIEW',
        ObjectType.materializedView => 'MATERIALIZED_VIEW',
        ObjectType.sequence => 'SEQUENCE',
        ObjectType.enumType => 'ENUM_TYPE',
        ObjectType.function => 'FUNCTION',
      };

  /// Deserializes from SCREAMING_SNAKE_CASE representation.
  static ObjectType fromJson(String json) => switch (json) {
        'TABLE' => ObjectType.table,
        'VIEW' => ObjectType.view,
        'MATERIALIZED_VIEW' => ObjectType.materializedView,
        'SEQUENCE' => ObjectType.sequence,
        'ENUM_TYPE' => ObjectType.enumType,
        'FUNCTION' => ObjectType.function,
        _ => throw ArgumentError('Unknown ObjectType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ObjectType.table => 'Table',
        ObjectType.view => 'View',
        ObjectType.materializedView => 'Materialized View',
        ObjectType.sequence => 'Sequence',
        ObjectType.enumType => 'Enum Type',
        ObjectType.function => 'Function',
      };
}

/// JSON converter for [ObjectType].
class ObjectTypeConverter extends JsonConverter<ObjectType, String> {
  /// Creates an [ObjectTypeConverter].
  const ObjectTypeConverter();

  @override
  ObjectType fromJson(String json) => ObjectType.fromJson(json);

  @override
  String toJson(ObjectType object) => object.toJson();
}
