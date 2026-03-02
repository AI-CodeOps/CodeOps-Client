/// Data models for the DataLens ER diagram feature.
///
/// Represents tables as nodes and foreign key relationships as edges in
/// an entity-relationship diagram. Supports Crow's Foot and IDEF1X
/// notations, interactive positioning, and export state.
library;

import 'dart:ui';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// Cardinality of a relationship between two tables.
enum ErCardinality {
  /// One-to-one relationship (FK with UNIQUE constraint on source).
  oneToOne,

  /// One-to-many relationship (standard FK, parent to child).
  oneToMany,

  /// Many-to-one relationship (child side of one-to-many).
  manyToOne,

  /// Many-to-many relationship (junction table with two FK+PK columns).
  manyToMany;

  /// Human-readable display label.
  String get displayName => switch (this) {
        ErCardinality.oneToOne => '1:1',
        ErCardinality.oneToMany => '1:N',
        ErCardinality.manyToOne => 'N:1',
        ErCardinality.manyToMany => 'M:N',
      };
}

/// ER diagram notation style.
enum ErNotation {
  /// Crow's Foot (IE) notation — crow's foot for many, bar for one.
  crowsFoot,

  /// IDEF1X notation — solid/dashed lines, rounded/square corners.
  idef1x;

  /// Human-readable display label.
  String get displayName => switch (this) {
        ErNotation.crowsFoot => "Crow's Foot",
        ErNotation.idef1x => 'IDEF1X',
      };
}

/// Scope of tables included in the diagram.
enum ErDiagramScope {
  /// All tables in the schema.
  fullSchema,

  /// One table plus all tables directly related via FK.
  singleTableRelated,

  /// User-selected subset of tables.
  customSelection;

  /// Human-readable display label.
  String get displayName => switch (this) {
        ErDiagramScope.fullSchema => 'Full Schema',
        ErDiagramScope.singleTableRelated => 'Table + Related',
        ErDiagramScope.customSelection => 'Custom Selection',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Model
// ─────────────────────────────────────────────────────────────────────────────

/// A column within an ER diagram table node.
class ErColumn {
  /// Column name.
  final String name;

  /// PostgreSQL data type (e.g., "integer", "text", "uuid").
  final String dataType;

  /// Whether this column is part of the primary key.
  final bool isPrimaryKey;

  /// Whether this column is a foreign key reference.
  final bool isForeignKey;

  /// Whether this column allows NULL values.
  final bool isNullable;

  /// Whether this column has a UNIQUE constraint.
  final bool isUnique;

  /// Referenced table name (if FK).
  final String? referencedTable;

  /// Referenced column name (if FK).
  final String? referencedColumn;

  /// Creates an [ErColumn].
  const ErColumn({
    required this.name,
    required this.dataType,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.isNullable = true,
    this.isUnique = false,
    this.referencedTable,
    this.referencedColumn,
  });

  @override
  String toString() => 'ErColumn($name $dataType'
      '${isPrimaryKey ? " PK" : ""}'
      '${isForeignKey ? " FK" : ""})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Node Model
// ─────────────────────────────────────────────────────────────────────────────

/// A table box in the ER diagram.
class ErTableNode {
  /// Schema name containing this table.
  final String schema;

  /// Table name.
  final String tableName;

  /// Column metadata for this table.
  final List<ErColumn> columns;

  /// Whether this is a view (vs. a regular table).
  final bool isView;

  /// Position on the canvas (mutable for drag).
  Offset position;

  /// Whether all columns are shown (expanded) or just PK/FK (collapsed).
  bool isExpanded;

  /// Creates an [ErTableNode].
  ErTableNode({
    required this.schema,
    required this.tableName,
    required this.columns,
    this.isView = false,
    this.position = Offset.zero,
    this.isExpanded = true,
  });

  /// Returns only PK and FK columns.
  List<ErColumn> get keyColumns =>
      columns.where((c) => c.isPrimaryKey || c.isForeignKey).toList();

  /// Returns the columns to display based on expansion state.
  List<ErColumn> get displayColumns => isExpanded ? columns : keyColumns;

  @override
  String toString() => 'ErTableNode($schema.$tableName, '
      '${columns.length} cols, pos=$position)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Relationship Model
// ─────────────────────────────────────────────────────────────────────────────

/// A relationship line between two tables in the ER diagram.
class ErRelationship {
  /// Source table name (FK owner / child).
  final String fromTable;

  /// Source column name (FK column).
  final String fromColumn;

  /// Target table name (referenced / parent).
  final String toTable;

  /// Target column name (referenced column).
  final String toColumn;

  /// Constraint name.
  final String? constraintName;

  /// Cardinality of the relationship.
  final ErCardinality cardinality;

  /// Whether the FK column is nullable (optional relationship).
  final bool isOptional;

  /// Creates an [ErRelationship].
  const ErRelationship({
    required this.fromTable,
    required this.fromColumn,
    required this.toTable,
    required this.toColumn,
    this.constraintName,
    required this.cardinality,
    this.isOptional = false,
  });

  @override
  String toString() => 'ErRelationship($fromTable.$fromColumn → '
      '$toTable.$toColumn ${cardinality.displayName})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Diagram State
// ─────────────────────────────────────────────────────────────────────────────

/// Complete state of an ER diagram.
class ErDiagramState {
  /// Connection ID this diagram was built from.
  final String connectionId;

  /// Schema name.
  final String schema;

  /// Table nodes in the diagram.
  final List<ErTableNode> tables;

  /// Relationship lines between tables.
  final List<ErRelationship> relationships;

  /// Current notation style.
  final ErNotation notation;

  /// Current zoom level (1.0 = 100%).
  final double zoom;

  /// Current pan offset.
  final Offset pan;

  /// Creates an [ErDiagramState].
  const ErDiagramState({
    required this.connectionId,
    required this.schema,
    required this.tables,
    required this.relationships,
    this.notation = ErNotation.crowsFoot,
    this.zoom = 1.0,
    this.pan = Offset.zero,
  });

  /// Creates a copy with the given overrides.
  ErDiagramState copyWith({
    String? connectionId,
    String? schema,
    List<ErTableNode>? tables,
    List<ErRelationship>? relationships,
    ErNotation? notation,
    double? zoom,
    Offset? pan,
  }) {
    return ErDiagramState(
      connectionId: connectionId ?? this.connectionId,
      schema: schema ?? this.schema,
      tables: tables ?? this.tables,
      relationships: relationships ?? this.relationships,
      notation: notation ?? this.notation,
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
    );
  }

  @override
  String toString() => 'ErDiagramState($schema, '
      '${tables.length} tables, ${relationships.length} rels)';
}
