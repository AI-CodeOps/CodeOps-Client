// Widget tests for SqlEditorPanel.
//
// Verifies panel rendering, split view presence, tab bar with + button,
// adding new tabs, and closing tabs.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_view/split_view.dart';

import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/sql_editor_panel.dart';
import 'package:codeops/widgets/datalens/sql_editor_widget.dart';
import 'package:codeops/widgets/datalens/sql_results_panel.dart';

Widget _createWidget({
  String? selectedConnectionId,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider
          .overrideWith((ref) => selectedConnectionId),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(body: SqlEditorPanel()),
    ),
  );
}

void main() {
  group('SqlEditorPanel', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SqlEditorPanel), findsOneWidget);
    });

    testWidgets('shows split view with editor and results', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SplitView), findsOneWidget);
      expect(find.byType(SqlEditorWidget), findsOneWidget);
      expect(find.byType(SqlResultsPanel), findsOneWidget);
    });

    testWidgets('shows tab bar with + button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Initial tab is "Script 1".
      expect(find.text('Script 1'), findsOneWidget);
      // + button is present.
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('add tab creates new tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Tap the + button.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Now two tabs should exist.
      expect(find.text('Script 1'), findsOneWidget);
      expect(find.text('Script 2'), findsOneWidget);
    });

    testWidgets('close tab removes tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Add a second tab.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Script 1'), findsOneWidget);
      expect(find.text('Script 2'), findsOneWidget);

      // Close the first tab (first close icon).
      final closeButtons = find.byIcon(Icons.close);
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      // Only Script 2 remains.
      expect(find.text('Script 1'), findsNothing);
      expect(find.text('Script 2'), findsOneWidget);
    });
  });
}
