// Widget tests for JsonColumnViewer.
//
// Verifies dialog rendering, title, JSON badge, raw/tree toggle,
// toolbar buttons, and footer size display.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/json_column_viewer.dart';

Widget _createWidget({
  String jsonString = '{"name": "Alice", "age": 30}',
  String columnName = 'metadata',
  bool editable = false,
  ValueChanged<String>? onSave,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => JsonColumnViewer(
              jsonString: jsonString,
              columnName: columnName,
              editable: editable,
              onSave: onSave,
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  group('JsonColumnViewer', () {
    testWidgets('renders dialog with column name and JSON badge',
        (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('metadata'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
    });

    testWidgets('shows Raw and Tree toggle chips', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Raw'), findsOneWidget);
      expect(find.text('Tree'), findsOneWidget);
    });

    testWidgets('shows Close button in footer', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('shows size info in footer', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('bytes'), findsOneWidget);
    });

    testWidgets('shows formatted JSON content', (tester) async {
      await tester.pumpWidget(_createWidget(
        jsonString: '{"key":"value"}',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The formatted JSON should contain the key.
      expect(find.textContaining('key'), findsWidgets);
    });

    testWidgets('shows edit icon when editable', (tester) async {
      await tester.pumpWidget(_createWidget(editable: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('hides edit icon when not editable', (tester) async {
      await tester.pumpWidget(_createWidget(editable: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });
}
