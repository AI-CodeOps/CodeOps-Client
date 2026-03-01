// Widget tests for DatalensPage.
//
// Verifies page structure, empty state when no connection, toolbar presence,
// status bar presence, and navigator panel with schema/table selection.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/pages/datalens/datalens_page.dart';
import 'package:codeops/pages/datalens/datalens_status_bar.dart';
import 'package:codeops/pages/datalens/datalens_toolbar.dart';
import 'package:codeops/providers/datalens_providers.dart';

Widget _createWidget({
  String? selectedConnectionId,
  List<DatabaseConnection> connections = const [],
  List<SchemaInfo> schemas = const [],
  List<TableInfo> tables = const [],
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => selectedConnectionId),
      datalensConnectionsProvider.overrideWith(
        (ref) => Future.value(connections),
      ),
      datalensSchemasProvider.overrideWith(
        (ref) => Future.value(schemas),
      ),
      datalensTablesProvider.overrideWith(
        (ref) => Future.value(tables),
      ),
      ...overrides,
    ],
    child: const MaterialApp(home: Scaffold(body: DatalensPage())),
  );
}

void main() {
  group('DatalensPage', () {
    testWidgets('shows empty state when no connection selected',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pump();

      expect(find.text('No connection selected'), findsOneWidget);
      expect(
        find.text(
          'Select or create a connection to start browsing your database.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('contains toolbar and status bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pump();

      expect(find.byType(DatalensToolbar), findsOneWidget);
      expect(find.byType(DatalensStatusBar), findsOneWidget);
    });

    testWidgets('shows navigator panel when connection is selected',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedConnectionId: 'conn-1',
        schemas: const [SchemaInfo(name: 'public', tableCount: 3)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Database Navigator'), findsOneWidget);
      expect(find.text('public'), findsOneWidget);
    });

    testWidgets('shows schema tables when schema is selected',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedConnectionId: 'conn-1',
        schemas: const [SchemaInfo(name: 'public', tableCount: 2)],
        tables: const [
          TableInfo(tableName: 'users', schemaName: 'public'),
          TableInfo(tableName: 'orders', schemaName: 'public'),
        ],
        overrides: [
          selectedSchemaProvider.overrideWith((ref) => 'public'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('users'), findsOneWidget);
      expect(find.text('orders'), findsOneWidget);
    });

    testWidgets('shows content placeholder when table is selected',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedConnectionId: 'conn-1',
        schemas: const [SchemaInfo(name: 'public')],
        tables: const [
          TableInfo(tableName: 'users', schemaName: 'public'),
        ],
        overrides: [
          selectedSchemaProvider.overrideWith((ref) => 'public'),
          selectedTableProvider.overrideWith((ref) => 'users'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('public.users'), findsOneWidget);
    });
  });
}
