// Widget tests for TablePropertiesPanel.
//
// Verifies panel rendering, tab bar, empty state, and default tab selection.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/table_properties_panel.dart';

Widget _createWidget({
  List<TableInfo> tables = const [],
  List<ColumnInfo> columns = const [],
  String? selectedTable,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      selectedTableProvider.overrideWith((ref) => selectedTable),
      datalensTablesProvider.overrideWith(
        (ref) => Future.value(tables),
      ),
      datalensColumnsProvider.overrideWith(
        (ref) => Future.value(columns),
      ),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(body: TablePropertiesPanel()),
    ),
  );
}

void main() {
  group('TablePropertiesPanel', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TablePropertiesPanel), findsOneWidget);
    });

    testWidgets('shows tab bar with Properties, Data, Diagram', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('Diagram'), findsOneWidget);
    });

    testWidgets('shows Properties tab by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedTable: 'users',
        tables: const [
          TableInfo(
            tableName: 'users',
            objectType: ObjectType.table,
            owner: 'admin',
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Properties sidebar items should be visible.
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Constraints'), findsOneWidget);
      expect(find.text('Foreign Keys'), findsOneWidget);
    });

    testWidgets('shows data browser when Data tab is tapped',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data'));
      await tester.pump();

      // DataBrowserTab shows "No table selected" when no table is selected.
      expect(find.text('No table selected'), findsOneWidget);
    });
  });
}
