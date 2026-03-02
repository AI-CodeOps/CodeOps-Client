/// Service for managing inline data editing and pending changes in DataLens.
///
/// Tracks cell edits, row insertions, row deletions, and row duplications
/// as pending changes. Changes accumulate locally until the user explicitly
/// applies them, at which point the service generates and executes the
/// appropriate SQL (INSERT, UPDATE, DELETE) statements.
///
/// Design mirrors DBeaver's data editor: changes are staged in memory,
/// visually indicated in the grid, and applied as a batch.
library;

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'query_execution_service.dart';
import 'schema_introspection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies a row by its primary key column values.
///
/// For tables without a primary key, uses the row index as a fallback.
class RowKey {
  /// Primary key column-value pairs (e.g., `{'id': 42}`).
  final Map<String, dynamic> values;

  /// Creates a [RowKey] with the given primary key [values].
  const RowKey(this.values);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RowKey &&
          runtimeType == other.runtimeType &&
          _mapEquals(values, other.values);

  @override
  int get hashCode => Object.hashAll(values.entries.map((e) => Object.hash(e.key, e.value)));

  @override
  String toString() => 'RowKey($values)';

  /// Deep-equality check for maps.
  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// A single cell value change.
class CellChange {
  /// Column name that was changed.
  final String columnName;

  /// Original value before the edit.
  final dynamic originalValue;

  /// New value after the edit.
  final dynamic newValue;

  /// Creates a [CellChange].
  const CellChange({
    required this.columnName,
    required this.originalValue,
    required this.newValue,
  });

  @override
  String toString() => 'CellChange($columnName: $originalValue -> $newValue)';
}

/// The type of change applied to a row.
enum RowChangeType {
  /// An existing row was modified.
  update,

  /// A new row was inserted.
  insert,

  /// An existing row was deleted.
  delete,

  /// An existing row was duplicated (creates a new insert).
  duplicate,
}

/// A pending change to a single row.
class RowChange {
  /// The type of change.
  final RowChangeType type;

  /// The row key identifying the target row. Null for new inserts.
  final RowKey? rowKey;

  /// Cell-level changes for updates. Empty for delete/insert.
  final List<CellChange> cellChanges;

  /// Full row data for inserts and duplicates.
  final Map<String, dynamic>? rowData;

  /// Creates a [RowChange].
  const RowChange({
    required this.type,
    this.rowKey,
    this.cellChanges = const [],
    this.rowData,
  });

  @override
  String toString() => 'RowChange($type, key=$rowKey, '
      'cells=${cellChanges.length}, data=${rowData != null})';
}

/// Result of applying pending changes to the database.
class ApplyResult {
  /// Number of statements that succeeded.
  final int successCount;

  /// Number of statements that failed.
  final int failureCount;

  /// Error messages for failed statements.
  final List<String> errors;

  /// The SQL statements that were generated and executed.
  final List<String> executedSql;

  /// Creates an [ApplyResult].
  const ApplyResult({
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
    this.executedSql = const [],
  });

  /// Whether all changes were applied successfully.
  bool get isSuccess => failureCount == 0;

  @override
  String toString() => 'ApplyResult(success=$successCount, '
      'failures=$failureCount)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Manages pending data changes for inline editing in the DataLens data grid.
///
/// Changes accumulate in memory per connection+schema+table and are applied
/// as a batch when the user commits. The service generates parameterized SQL
/// for safety and delegates execution to [QueryExecutionService].
class DataEditorService {
  static const String _tag = 'DataEditorService';

  /// Query execution service for applying changes.
  final QueryExecutionService _queryService;

  /// Schema introspection service for resolving primary keys.
  final SchemaIntrospectionService _schemaService;

  /// Pending changes keyed by `connectionId:schema.table`.
  final Map<String, List<RowChange>> _pendingChanges = {};

  /// Cached primary key columns keyed by `connectionId:schema.table`.
  final Map<String, List<String>> _pkCache = {};

  /// Creates a [DataEditorService] with the given dependencies.
  DataEditorService(this._queryService, this._schemaService);

  // ─────────────────────────────────────────────────────────────────────────
  // Pending Changes Access
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the list of pending changes for the given table.
  List<RowChange> getPendingChanges(
    String connectionId,
    String schemaName,
    String tableName,
  ) {
    final key = _tableKey(connectionId, schemaName, tableName);
    return List.unmodifiable(_pendingChanges[key] ?? []);
  }

  /// Returns the total number of pending changes for the given table.
  int getPendingChangeCount(
    String connectionId,
    String schemaName,
    String tableName,
  ) {
    final key = _tableKey(connectionId, schemaName, tableName);
    return _pendingChanges[key]?.length ?? 0;
  }

  /// Returns `true` if there are any pending changes for the given table.
  bool hasPendingChanges(
    String connectionId,
    String schemaName,
    String tableName,
  ) {
    return getPendingChangeCount(connectionId, schemaName, tableName) > 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stage Changes
  // ─────────────────────────────────────────────────────────────────────────

  /// Stages a cell edit on an existing row.
  ///
  /// If the same cell on the same row has already been edited, the existing
  /// change is updated with the new value. If the new value equals the
  /// original value, the change is removed.
  void stageEdit(
    String connectionId,
    String schemaName,
    String tableName,
    RowKey rowKey,
    CellChange change,
  ) {
    log.d(_tag, 'stageEdit: $schemaName.$tableName $rowKey ${change.columnName}');
    final key = _tableKey(connectionId, schemaName, tableName);
    final changes = _pendingChanges.putIfAbsent(key, () => []);

    // Find existing update for this row.
    final existingIdx = changes.indexWhere(
      (c) => c.type == RowChangeType.update && c.rowKey == rowKey,
    );

    if (existingIdx >= 0) {
      final existing = changes[existingIdx];
      final cellList = List<CellChange>.from(existing.cellChanges);

      // Replace or add the cell change.
      final cellIdx = cellList.indexWhere(
        (c) => c.columnName == change.columnName,
      );

      if (change.newValue == change.originalValue) {
        // Revert — remove this cell change.
        if (cellIdx >= 0) cellList.removeAt(cellIdx);
        if (cellList.isEmpty) {
          changes.removeAt(existingIdx);
        } else {
          changes[existingIdx] = RowChange(
            type: RowChangeType.update,
            rowKey: rowKey,
            cellChanges: cellList,
          );
        }
      } else {
        if (cellIdx >= 0) {
          cellList[cellIdx] = change;
        } else {
          cellList.add(change);
        }
        changes[existingIdx] = RowChange(
          type: RowChangeType.update,
          rowKey: rowKey,
          cellChanges: cellList,
        );
      }
    } else if (change.newValue != change.originalValue) {
      changes.add(RowChange(
        type: RowChangeType.update,
        rowKey: rowKey,
        cellChanges: [change],
      ));
    }
  }

  /// Stages a new row insertion.
  void stageInsert(
    String connectionId,
    String schemaName,
    String tableName,
    Map<String, dynamic> rowData,
  ) {
    log.d(_tag, 'stageInsert: $schemaName.$tableName');
    final key = _tableKey(connectionId, schemaName, tableName);
    final changes = _pendingChanges.putIfAbsent(key, () => []);
    changes.add(RowChange(
      type: RowChangeType.insert,
      rowData: rowData,
    ));
  }

  /// Stages deletion of an existing row.
  void stageDelete(
    String connectionId,
    String schemaName,
    String tableName,
    RowKey rowKey,
  ) {
    log.d(_tag, 'stageDelete: $schemaName.$tableName $rowKey');
    final key = _tableKey(connectionId, schemaName, tableName);
    final changes = _pendingChanges.putIfAbsent(key, () => []);

    // If the row was inserted in this session, just remove the insert.
    final insertIdx = changes.indexWhere(
      (c) => c.type == RowChangeType.insert && c.rowKey == rowKey,
    );
    if (insertIdx >= 0) {
      changes.removeAt(insertIdx);
      return;
    }

    // Remove any pending updates for this row.
    changes.removeWhere(
      (c) => c.type == RowChangeType.update && c.rowKey == rowKey,
    );

    // Add the delete change.
    changes.add(RowChange(
      type: RowChangeType.delete,
      rowKey: rowKey,
    ));
  }

  /// Stages duplication of an existing row (creates an insert).
  void stageDuplicate(
    String connectionId,
    String schemaName,
    String tableName,
    Map<String, dynamic> rowData,
  ) {
    log.d(_tag, 'stageDuplicate: $schemaName.$tableName');
    final key = _tableKey(connectionId, schemaName, tableName);
    final changes = _pendingChanges.putIfAbsent(key, () => []);
    changes.add(RowChange(
      type: RowChangeType.duplicate,
      rowData: rowData,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Revert
  // ─────────────────────────────────────────────────────────────────────────

  /// Reverts a specific pending change by index.
  void revertChange(
    String connectionId,
    String schemaName,
    String tableName,
    int index,
  ) {
    final key = _tableKey(connectionId, schemaName, tableName);
    final changes = _pendingChanges[key];
    if (changes != null && index >= 0 && index < changes.length) {
      log.d(_tag, 'revertChange: $schemaName.$tableName index=$index');
      changes.removeAt(index);
      if (changes.isEmpty) _pendingChanges.remove(key);
    }
  }

  /// Reverts all pending changes for the given table.
  void revertAll(
    String connectionId,
    String schemaName,
    String tableName,
  ) {
    final key = _tableKey(connectionId, schemaName, tableName);
    log.d(_tag, 'revertAll: $schemaName.$tableName');
    _pendingChanges.remove(key);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SQL Generation
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates SQL statements for all pending changes on the given table.
  ///
  /// Returns a list of SQL strings ready for execution. Does NOT execute
  /// them — use [applyAll] for that.
  List<String> generateSql(
    String connectionId,
    String schemaName,
    String tableName,
  ) {
    final key = _tableKey(connectionId, schemaName, tableName);
    final changes = _pendingChanges[key] ?? [];
    final qualifiedTable = '"$schemaName"."$tableName"';
    final statements = <String>[];

    for (final change in changes) {
      switch (change.type) {
        case RowChangeType.update:
          if (change.rowKey != null && change.cellChanges.isNotEmpty) {
            statements.add(_generateUpdate(
              qualifiedTable,
              change.rowKey!,
              change.cellChanges,
            ));
          }
        case RowChangeType.insert:
        case RowChangeType.duplicate:
          if (change.rowData != null && change.rowData!.isNotEmpty) {
            statements.add(_generateInsert(qualifiedTable, change.rowData!));
          }
        case RowChangeType.delete:
          if (change.rowKey != null) {
            statements.add(_generateDelete(qualifiedTable, change.rowKey!));
          }
      }
    }

    return statements;
  }

  /// Generates an UPDATE statement.
  String _generateUpdate(
    String qualifiedTable,
    RowKey rowKey,
    List<CellChange> cellChanges,
  ) {
    final setClauses = cellChanges
        .map((c) => '"${c.columnName}" = ${_sqlLiteral(c.newValue)}')
        .join(', ');
    final whereClauses = rowKey.values.entries
        .map((e) => '"${e.key}" = ${_sqlLiteral(e.value)}')
        .join(' AND ');
    return 'UPDATE $qualifiedTable SET $setClauses WHERE $whereClauses';
  }

  /// Generates an INSERT statement.
  String _generateInsert(
    String qualifiedTable,
    Map<String, dynamic> rowData,
  ) {
    final columns = rowData.keys.map((c) => '"$c"').join(', ');
    final values = rowData.values.map(_sqlLiteral).join(', ');
    return 'INSERT INTO $qualifiedTable ($columns) VALUES ($values)';
  }

  /// Generates a DELETE statement.
  String _generateDelete(String qualifiedTable, RowKey rowKey) {
    final whereClauses = rowKey.values.entries
        .map((e) => '"${e.key}" = ${_sqlLiteral(e.value)}')
        .join(' AND ');
    return 'DELETE FROM $qualifiedTable WHERE $whereClauses';
  }

  /// Converts a Dart value to a SQL literal string.
  String _sqlLiteral(dynamic value) {
    if (value == null) return 'NULL';
    if (value is bool) return value ? 'TRUE' : 'FALSE';
    if (value is num) return value.toString();
    if (value is DateTime) return "'${value.toIso8601String()}'";
    // Escape single quotes in strings.
    final escaped = value.toString().replaceAll("'", "''");
    return "'$escaped'";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Apply
  // ─────────────────────────────────────────────────────────────────────────

  /// Applies all pending changes to the database.
  ///
  /// Generates SQL for each change and executes them sequentially via
  /// [QueryExecutionService]. Returns an [ApplyResult] with success/failure
  /// counts.
  Future<ApplyResult> applyAll(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.i(_tag, 'applyAll: $schemaName.$tableName');
    final statements = generateSql(connectionId, schemaName, tableName);

    if (statements.isEmpty) {
      return const ApplyResult();
    }

    var successCount = 0;
    var failureCount = 0;
    final errors = <String>[];
    final executedSql = <String>[];

    for (final sql in statements) {
      executedSql.add(sql);
      final result = await _queryService.executeQuery(connectionId, sql);
      if (result.error != null) {
        failureCount++;
        errors.add('${result.error}');
      } else {
        successCount++;
      }
    }

    // Clear pending changes on full success.
    if (failureCount == 0) {
      final key = _tableKey(connectionId, schemaName, tableName);
      _pendingChanges.remove(key);
    }

    return ApplyResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      executedSql: executedSql,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Primary Key Resolution
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the primary key columns for a table.
  ///
  /// Results are cached per table to avoid repeated introspection queries.
  Future<List<String>> getPrimaryKeyColumns(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    final key = _tableKey(connectionId, schemaName, tableName);
    if (_pkCache.containsKey(key)) return _pkCache[key]!;

    final columns = await _schemaService.getColumns(
      connectionId,
      schemaName,
      tableName,
    );
    final pkColumns = columns
        .where((c) => c.category == ColumnCategory.primaryKey)
        .map((c) => c.columnName!)
        .toList();

    _pkCache[key] = pkColumns;
    return pkColumns;
  }

  /// Builds a [RowKey] from a row of data and the table's primary key columns.
  RowKey buildRowKey(
    List<String> pkColumns,
    List<QueryColumn> resultColumns,
    List<dynamic> rowData,
  ) {
    final keyValues = <String, dynamic>{};
    for (final pkCol in pkColumns) {
      final colIdx = resultColumns.indexWhere((c) => c.name == pkCol);
      if (colIdx >= 0 && colIdx < rowData.length) {
        keyValues[pkCol] = rowData[colIdx];
      }
    }
    return RowKey(keyValues);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Clears all pending changes and cached data.
  void clearAll() {
    _pendingChanges.clear();
    _pkCache.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a composite key for the pending changes map.
  String _tableKey(String connectionId, String schemaName, String tableName) {
    return '$connectionId:$schemaName.$tableName';
  }
}
