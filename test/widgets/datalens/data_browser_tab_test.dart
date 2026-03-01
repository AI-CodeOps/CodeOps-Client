// Widget tests for DataBrowserTab.
//
// Verifies data browser tab rendering, toolbar presence, grid display,
// empty state when no table is selected, and loading state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/data_browser_tab.dart';
import 'package:codeops/widgets/datalens/data_browser_toolbar.dart';

Widget _createWidget({
  String? selectedTable,
  String? selectedSchema,
  String? selectedConnectionId,
  QueryResult? browserResult,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      selectedTableProvider.overrideWith((ref) => selectedTable),
      selectedSchemaProvider.overrideWith((ref) => selectedSchema),
      selectedConnectionIdProvider
          .overrideWith((ref) => selectedConnectionId),
      datalensDataBrowserResultProvider
          .overrideWith((ref) => browserResult),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(body: DataBrowserTab()),
    ),
  );
}

void main() {
  group('DataBrowserTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedTable: 'users',
        selectedSchema: 'public',
        selectedConnectionId: 'conn-1',
      ));
      await tester.pump();

      expect(find.byType(DataBrowserTab), findsOneWidget);
    });

    testWidgets('shows toolbar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedTable: 'users',
        selectedSchema: 'public',
        selectedConnectionId: 'conn-1',
      ));
      await tester.pump();

      expect(find.byType(DataBrowserToolbar), findsOneWidget);
    });

    testWidgets('shows error when query service fails', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedTable: 'users',
        selectedSchema: 'public',
        selectedConnectionId: 'conn-1',
      ));
      // Pump to let _loadData() run and fail.
      await tester.pump();

      // The service has no active connection, so an error message is shown.
      expect(find.textContaining('No active connection'), findsOneWidget);
    });

    testWidgets('shows empty state when no table selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pump();

      expect(find.text('No table selected'), findsOneWidget);
    });

    testWidgets('shows status bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedTable: 'users',
        selectedSchema: 'public',
        selectedConnectionId: 'conn-1',
      ));
      await tester.pump();

      // Both toolbar and status bar show "0 rows" when no data loaded.
      expect(find.text('0 rows'), findsNWidgets(2));
    });
  });
}
