/// Service for building ER diagrams from database schema metadata.
///
/// Uses [SchemaIntrospectionService] to fetch tables, columns, constraints,
/// and foreign keys, then assembles them into an [ErDiagramState] with
/// auto-layout positioning. Supports full-schema, single-table-related,
/// and filtered-table scopes.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../../models/datalens_enums.dart';
import '../../models/datalens_er_models.dart';
import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'schema_introspection_service.dart';

/// Builds ER diagram state from database schema metadata.
///
/// Determines relationship cardinality from constraint metadata and applies
/// a force-directed layout algorithm to position tables automatically.
class ErDiagramService {
  static const String _tag = 'ErDiagramService';

  /// Schema introspection service for fetching metadata.
  final SchemaIntrospectionService _schemaService;

  /// Creates an [ErDiagramService] with the given [schemaService].
  ErDiagramService(this._schemaService);

  // ─────────────────────────────────────────────────────────────────────────
  // Diagram Building
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds a full ER diagram for all tables in the schema.
  ///
  /// When [tableFilter] is provided, only those tables are included (plus
  /// any tables they reference via FK that are also in the schema).
  Future<ErDiagramState> buildDiagram(
    String connectionId,
    String schema, {
    List<String>? tableFilter,
  }) async {
    log.d(_tag, 'buildDiagram($connectionId, $schema, '
        'filter=${tableFilter?.length ?? "all"})');

    // Fetch all tables in the schema.
    final allTables = await _schemaService.getTables(connectionId, schema);

    // Determine which tables to include.
    final tableNames = tableFilter ?? allTables.map((t) => t.tableName!).toList();

    // Build table nodes with columns.
    final nodes = <ErTableNode>[];
    final relationships = <ErRelationship>[];

    for (final tableName in tableNames) {
      final tableInfo = allTables.firstWhere(
        (t) => t.tableName == tableName,
        orElse: () => TableInfo(schemaName: schema, tableName: tableName),
      );

      final columns = await _schemaService.getColumns(
        connectionId, schema, tableName,
      );
      final fks = await _schemaService.getForeignKeys(
        connectionId, schema, tableName,
      );
      final constraints = await _schemaService.getConstraints(
        connectionId, schema, tableName,
      );

      // Build unique column set from constraints.
      final uniqueColumns = <String>{};
      for (final c in constraints) {
        if (c.constraintType == ConstraintType.unique && c.columns != null) {
          if (c.columns!.length == 1) uniqueColumns.add(c.columns!.first);
        }
      }

      // Map FK columns to their referenced tables.
      final fkMap = <String, ForeignKeyInfo>{};
      for (final fk in fks) {
        if (fk.columns != null) {
          for (var i = 0; i < fk.columns!.length; i++) {
            fkMap[fk.columns![i]] = fk;
          }
        }
      }

      // Build ErColumn list.
      final erColumns = columns.map((col) {
        final colName = col.columnName ?? '';
        final fk = fkMap[colName];
        String? refTable;
        String? refColumn;
        if (fk != null && fk.columns != null) {
          final idx = fk.columns!.indexOf(colName);
          refTable = fk.referencedTable;
          refColumn = (fk.referencedColumns != null && idx < fk.referencedColumns!.length)
              ? fk.referencedColumns![idx]
              : null;
        }

        return ErColumn(
          name: colName,
          dataType: col.udtName ?? col.dataType ?? 'unknown',
          isPrimaryKey: col.category == ColumnCategory.primaryKey,
          isForeignKey: col.category == ColumnCategory.foreignKey,
          isNullable: col.isNullable ?? true,
          isUnique: uniqueColumns.contains(colName),
          referencedTable: refTable,
          referencedColumn: refColumn,
        );
      }).toList();

      nodes.add(ErTableNode(
        schema: schema,
        tableName: tableName,
        columns: erColumns,
        isView: tableInfo.objectType == ObjectType.view ||
            tableInfo.objectType == ObjectType.materializedView,
      ));

      // Build relationships from FKs.
      for (final fk in fks) {
        if (fk.columns == null || fk.referencedTable == null) continue;
        for (var i = 0; i < fk.columns!.length; i++) {
          final fromCol = fk.columns![i];
          final toCol = (fk.referencedColumns != null && i < fk.referencedColumns!.length)
              ? fk.referencedColumns![i]
              : '?';

          // Only add relationship if target table is in the diagram.
          if (!tableNames.contains(fk.referencedTable)) continue;

          final srcColumn = columns.firstWhere(
            (c) => c.columnName == fromCol,
            orElse: () => const ColumnInfo(),
          );

          relationships.add(ErRelationship(
            fromTable: tableName,
            fromColumn: fromCol,
            toTable: fk.referencedTable!,
            toColumn: toCol,
            constraintName: fk.constraintName,
            cardinality: _detectCardinality(
              fromCol, erColumns, uniqueColumns, fk, constraints,
            ),
            isOptional: srcColumn.isNullable ?? true,
          ));
        }
      }
    }

    // Apply auto-layout.
    _applyForceDirectedLayout(nodes, relationships);

    return ErDiagramState(
      connectionId: connectionId,
      schema: schema,
      tables: nodes,
      relationships: relationships,
    );
  }

  /// Builds a diagram for a single table and all directly related tables.
  Future<ErDiagramState> buildSingleTableDiagram(
    String connectionId,
    String schema,
    String tableName,
  ) async {
    log.d(_tag, 'buildSingleTableDiagram($connectionId, $schema.$tableName)');

    final fks = await _schemaService.getForeignKeys(
      connectionId, schema, tableName,
    );
    final refs = await _schemaService.getIncomingReferences(
      connectionId, schema, tableName,
    );

    // Collect related table names.
    final relatedTables = <String>{tableName};
    for (final fk in fks) {
      if (fk.referencedTable != null) relatedTables.add(fk.referencedTable!);
    }
    for (final ref in refs) {
      if (ref.referencedTable != null) relatedTables.add(ref.referencedTable!);
    }

    return buildDiagram(
      connectionId,
      schema,
      tableFilter: relatedTables.toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cardinality Detection
  // ─────────────────────────────────────────────────────────────────────────

  /// Determines the cardinality of a foreign key relationship.
  ///
  /// - FK column with UNIQUE constraint → ONE_TO_ONE
  /// - FK column that is part of composite PK with another FK → MANY_TO_MANY
  /// - Standard FK → MANY_TO_ONE
  ErCardinality _detectCardinality(
    String fromColumn,
    List<ErColumn> allColumns,
    Set<String> uniqueColumns,
    ForeignKeyInfo fk,
    List<ConstraintInfo> constraints,
  ) {
    // Check if FK column has UNIQUE constraint → one-to-one.
    if (uniqueColumns.contains(fromColumn)) {
      return ErCardinality.oneToOne;
    }

    // Check if FK column is part of PK → potential junction table.
    final pkConstraint = constraints.where(
      (c) => c.constraintType == ConstraintType.primaryKey,
    );
    if (pkConstraint.isNotEmpty) {
      final pkCols = pkConstraint.first.columns ?? [];
      final fkCols = allColumns.where((c) => c.isForeignKey).map((c) => c.name).toSet();

      // Junction table: PK consists entirely of FK columns.
      if (pkCols.length >= 2 &&
          pkCols.every((pk) => fkCols.contains(pk)) &&
          pkCols.contains(fromColumn)) {
        return ErCardinality.manyToMany;
      }
    }

    // Default: many-to-one (child references parent).
    return ErCardinality.manyToOne;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Layout Algorithm
  // ─────────────────────────────────────────────────────────────────────────

  /// Applies a simple force-directed layout to position table nodes.
  ///
  /// Uses repulsive forces between all nodes and attractive forces along
  /// relationship edges to produce a readable layout.
  void _applyForceDirectedLayout(
    List<ErTableNode> nodes,
    List<ErRelationship> relationships,
  ) {
    if (nodes.isEmpty) return;

    // Initial grid placement.
    final cols = math.max(1, math.sqrt(nodes.length).ceil());
    const spacing = 280.0;
    for (var i = 0; i < nodes.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      nodes[i].position = Offset(col * spacing + 50, row * spacing + 50);
    }

    // Build lookup.
    final nodeMap = <String, ErTableNode>{};
    for (final node in nodes) {
      nodeMap[node.tableName] = node;
    }

    // Force-directed iterations.
    const iterations = 50;
    const repulsion = 50000.0;
    const attraction = 0.01;
    const damping = 0.9;

    final velocities = List.generate(nodes.length, (_) => Offset.zero);

    for (var iter = 0; iter < iterations; iter++) {
      final forces = List.generate(nodes.length, (_) => Offset.zero);

      // Repulsive forces between all pairs.
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final delta = nodes[i].position - nodes[j].position;
          final dist = math.max(delta.distance, 1.0);
          final force = delta / dist * (repulsion / (dist * dist));
          forces[i] = forces[i] + force;
          forces[j] = forces[j] - force;
        }
      }

      // Attractive forces along edges.
      for (final rel in relationships) {
        final fromIdx = nodes.indexWhere((n) => n.tableName == rel.fromTable);
        final toIdx = nodes.indexWhere((n) => n.tableName == rel.toTable);
        if (fromIdx < 0 || toIdx < 0) continue;

        final delta = nodes[toIdx].position - nodes[fromIdx].position;
        final dist = math.max(delta.distance, 1.0);
        final force = delta * attraction * dist;
        forces[fromIdx] = forces[fromIdx] + force;
        forces[toIdx] = forces[toIdx] - force;
      }

      // Apply forces with damping.
      for (var i = 0; i < nodes.length; i++) {
        velocities[i] = (velocities[i] + forces[i]) * damping;
        nodes[i].position = nodes[i].position + velocities[i];
      }
    }

    // Normalize: shift so minimum position is at (50, 50).
    var minX = double.infinity;
    var minY = double.infinity;
    for (final node in nodes) {
      if (node.position.dx < minX) minX = node.position.dx;
      if (node.position.dy < minY) minY = node.position.dy;
    }
    final shift = Offset(50 - minX, 50 - minY);
    for (final node in nodes) {
      node.position = node.position + shift;
    }
  }

  /// Re-applies auto-layout to an existing diagram state.
  ErDiagramState autoLayout(ErDiagramState state) {
    final tables = List<ErTableNode>.of(state.tables);
    _applyForceDirectedLayout(tables, state.relationships);
    return state.copyWith(tables: tables);
  }
}
