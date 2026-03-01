/// Riverpod providers for the DataLens module.
///
/// Manages service singletons, UI state (selected connection/schema/table),
/// and reactive data providers that re-fetch when selections change.
/// Follows existing provider patterns: [Provider] for singletons,
/// [StateProvider] for mutable UI state, [FutureProvider] for async data,
/// [StreamProvider.family] for status streams.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/datalens_enums.dart';
import '../models/datalens_models.dart';
import '../services/datalens/database_connection_service.dart';
import '../services/datalens/query_execution_service.dart';
import '../services/datalens/query_history_service.dart';
import '../services/datalens/schema_introspection_service.dart';
import 'auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service Providers (singletons)
// ─────────────────────────────────────────────────────────────────────────────

/// Database connection service — manages all PostgreSQL connections.
final datalensConnectionServiceProvider =
    Provider<DatabaseConnectionService>((ref) {
  final db = ref.watch(databaseProvider);
  return DatabaseConnectionService(db);
});

/// Schema introspection service — queries PostgreSQL system catalogs.
final datalensSchemaServiceProvider =
    Provider<SchemaIntrospectionService>((ref) {
  final connectionService = ref.watch(datalensConnectionServiceProvider);
  return SchemaIntrospectionService(connectionService);
});

/// Query history service — persists query history and saved queries.
final datalensHistoryServiceProvider = Provider<QueryHistoryService>((ref) {
  final db = ref.watch(databaseProvider);
  return QueryHistoryService(db);
});

/// Query execution service — executes SQL and records results.
final datalensQueryServiceProvider = Provider<QueryExecutionService>((ref) {
  final connectionService = ref.watch(datalensConnectionServiceProvider);
  final historyService = ref.watch(datalensHistoryServiceProvider);
  return QueryExecutionService(connectionService, historyService);
});

// ─────────────────────────────────────────────────────────────────────────────
// UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected connection ID.
final selectedConnectionIdProvider = StateProvider<String?>((ref) => null);

/// Currently selected schema name.
final selectedSchemaProvider = StateProvider<String?>((ref) => null);

/// Currently selected table name.
final selectedTableProvider = StateProvider<String?>((ref) => null);

/// Currently active tab in table detail (Properties, Data, Diagram).
final selectedTableTabProvider = StateProvider<int>((ref) => 0);

/// Currently active sub-tab in Properties (Columns, Constraints, FK, etc.).
final selectedPropertiesTabProvider = StateProvider<int>((ref) => 0);

/// SQL editor content for the active query tab.
final sqlEditorContentProvider = StateProvider<String>((ref) => '');

/// Whether the SQL results panel is visible.
final sqlResultsPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// Active query result (set by SQL editor execution).
final datalensQueryResultProvider = StateProvider<QueryResult?>((ref) => null);

/// Data browser result (set by table data browsing).
final datalensDataBrowserResultProvider =
    StateProvider<QueryResult?>((ref) => null);

/// Data browser current page.
final datalensDataBrowserPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Data Providers — Connections
// ─────────────────────────────────────────────────────────────────────────────

/// All saved connections from the local Drift database.
final datalensConnectionsProvider =
    FutureProvider<List<DatabaseConnection>>((ref) {
  final service = ref.watch(datalensConnectionServiceProvider);
  return service.getAllConnections();
});

/// Connection status stream for a specific connection.
final connectionStatusProvider =
    StreamProvider.family<ConnectionStatus, String>((ref, connectionId) {
  final service = ref.watch(datalensConnectionServiceProvider);
  return service.statusStream
      .where((event) => event.$1 == connectionId)
      .map((event) => event.$2);
});

// ─────────────────────────────────────────────────────────────────────────────
// Data Providers — Schema Introspection
// ─────────────────────────────────────────────────────────────────────────────

/// Schemas for the selected connection.
final datalensSchemasProvider = FutureProvider<List<SchemaInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  if (connectionId == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getSchemas(connectionId);
});

/// Tables for the selected schema.
final datalensTablesProvider = FutureProvider<List<TableInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  if (connectionId == null || schema == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getTables(connectionId, schema);
});

/// Sequences for the selected schema.
final datalensSequencesProvider = FutureProvider<List<SequenceInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  if (connectionId == null || schema == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getSequences(connectionId, schema);
});

/// Columns for the selected table.
final datalensColumnsProvider = FutureProvider<List<ColumnInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getColumns(connectionId, schema, table);
});

/// Constraints for the selected table.
final datalensConstraintsProvider =
    FutureProvider<List<ConstraintInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getConstraints(connectionId, schema, table);
});

/// Foreign keys for the selected table.
final datalensForeignKeysProvider =
    FutureProvider<List<ForeignKeyInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getForeignKeys(connectionId, schema, table);
});

/// Incoming references for the selected table.
final datalensReferencesProvider =
    FutureProvider<List<ForeignKeyInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getIncomingReferences(connectionId, schema, table);
});

/// Indexes for the selected table.
final datalensIndexesProvider = FutureProvider<List<IndexInfo>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getIndexes(connectionId, schema, table);
});

/// Table dependencies for the selected table.
final datalensDependenciesProvider =
    FutureProvider<List<TableDependency>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return [];
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getTableDependencies(connectionId, schema, table);
});

/// Table statistics for the selected table.
final datalensStatisticsProvider = FutureProvider<TableStatistics?>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return null;
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getTableStatistics(connectionId, schema, table);
});

/// Table DDL for the selected table.
final datalensDdlProvider = FutureProvider<String?>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  final schema = ref.watch(selectedSchemaProvider);
  final table = ref.watch(selectedTableProvider);
  if (connectionId == null || schema == null || table == null) return null;
  final service = ref.watch(datalensSchemaServiceProvider);
  return service.getTableDdl(connectionId, schema, table);
});

// ─────────────────────────────────────────────────────────────────────────────
// Data Providers — Query History & Saved Queries
// ─────────────────────────────────────────────────────────────────────────────

/// Query history for the selected connection.
final datalensQueryHistoryProvider =
    FutureProvider<List<QueryHistoryEntry>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  if (connectionId == null) return [];
  final service = ref.watch(datalensHistoryServiceProvider);
  return service.getHistory(connectionId);
});

/// Saved queries for the selected connection.
final datalensSavedQueriesProvider = FutureProvider<List<SavedQuery>>((ref) {
  final connectionId = ref.watch(selectedConnectionIdProvider);
  if (connectionId == null) return [];
  final service = ref.watch(datalensHistoryServiceProvider);
  return service.getSavedQueries(connectionId);
});
