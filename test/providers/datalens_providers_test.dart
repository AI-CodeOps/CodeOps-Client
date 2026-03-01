// Tests for DataLens Riverpod providers.
//
// Verifies service provider creation, UI state default values, and
// state mutation for all DataLens providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/query_execution_service.dart';
import 'package:codeops/services/datalens/query_history_service.dart';
import 'package:codeops/services/datalens/schema_introspection_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Service Providers
  // ---------------------------------------------------------------------------
  group('Service providers', () {
    test('connectionServiceProvider returns DatabaseConnectionService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(datalensConnectionServiceProvider);

      expect(service, isA<DatabaseConnectionService>());
    });

    test('schemaServiceProvider returns SchemaIntrospectionService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(datalensSchemaServiceProvider);

      expect(service, isA<SchemaIntrospectionService>());
    });

    test('queryServiceProvider returns QueryExecutionService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(datalensQueryServiceProvider);

      expect(service, isA<QueryExecutionService>());
    });

    test('historyServiceProvider returns QueryHistoryService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(datalensHistoryServiceProvider);

      expect(service, isA<QueryHistoryService>());
    });
  });

  // ---------------------------------------------------------------------------
  // UI State Defaults
  // ---------------------------------------------------------------------------
  group('UI state defaults', () {
    test('selectedConnectionIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedConnectionIdProvider), isNull);
    });

    test('selectedSchemaProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedSchemaProvider), isNull);
    });

    test('selectedTableProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedTableProvider), isNull);
    });

    test('selectedTableTabProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedTableTabProvider), 0);
    });

    test('selectedPropertiesTabProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedPropertiesTabProvider), 0);
    });

    test('sqlEditorContentProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sqlEditorContentProvider), '');
    });

    test('sqlResultsPanelVisibleProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sqlResultsPanelVisibleProvider), false);
    });

    test('datalensQueryResultProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(datalensQueryResultProvider), isNull);
    });

    test('datalensDataBrowserResultProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(datalensDataBrowserResultProvider), isNull);
    });

    test('datalensDataBrowserPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(datalensDataBrowserPageProvider), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // State Mutation
  // ---------------------------------------------------------------------------
  group('State mutation', () {
    test('selectedConnectionIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedConnectionIdProvider.notifier).state = 'conn-1';

      expect(container.read(selectedConnectionIdProvider), 'conn-1');
    });

    test('selectedSchemaProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedSchemaProvider.notifier).state = 'public';

      expect(container.read(selectedSchemaProvider), 'public');
    });

    test('selectedTableProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedTableProvider.notifier).state = 'users';

      expect(container.read(selectedTableProvider), 'users');
    });

    test('sqlEditorContentProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sqlEditorContentProvider.notifier).state = 'SELECT 1';

      expect(container.read(sqlEditorContentProvider), 'SELECT 1');
    });

    test('sqlResultsPanelVisibleProvider can be toggled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sqlResultsPanelVisibleProvider.notifier).state = true;

      expect(container.read(sqlResultsPanelVisibleProvider), true);
    });

    test('datalensQueryResultProvider can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const result = QueryResult(rowCount: 5, executedSql: 'SELECT 1');
      container.read(datalensQueryResultProvider.notifier).state = result;

      final stored = container.read(datalensQueryResultProvider);
      expect(stored, isNotNull);
      expect(stored!.rowCount, 5);
      expect(stored.executedSql, 'SELECT 1');
    });

    test('datalensDataBrowserPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(datalensDataBrowserPageProvider.notifier).state = 3;

      expect(container.read(datalensDataBrowserPageProvider), 3);
    });
  });
}
