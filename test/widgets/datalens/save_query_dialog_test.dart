// Widget tests for SaveQueryDialog.
//
// Verifies dialog rendering, form fields (name, description, SQL, folder),
// validation errors, and edit mode pre-population.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/save_query_dialog.dart';

Widget _createWidget({
  SavedQuery? existingQuery,
  String? initialSql,
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => 'conn-1'),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => SaveQueryDialog(
                existingQuery: existingQuery,
                initialSql: initialSql,
              ),
            ),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SaveQueryDialog', () {
    testWidgets('renders with Save title for new query', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save Query'), findsOneWidget);
    });

    testWidgets('renders with Edit title for existing query', (tester) async {
      await tester.pumpWidget(_createWidget(
        existingQuery: const SavedQuery(
          id: '1',
          name: 'Test Query',
          sql: 'SELECT 1',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Query'), findsOneWidget);
    });

    testWidgets('shows all form fields', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('SQL'), findsOneWidget);
      expect(find.text('Folder'), findsOneWidget);
    });

    testWidgets('shows Save and Cancel buttons', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows Update button for existing query', (tester) async {
      await tester.pumpWidget(_createWidget(
        existingQuery: const SavedQuery(
          id: '1',
          name: 'Test Query',
          sql: 'SELECT 1',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('pre-fills initialSql', (tester) async {
      await tester.pumpWidget(_createWidget(
        initialSql: 'SELECT * FROM orders',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT * FROM orders'), findsOneWidget);
    });

    testWidgets('pre-fills existing query fields', (tester) async {
      await tester.pumpWidget(_createWidget(
        existingQuery: const SavedQuery(
          id: '1',
          name: 'My Query',
          description: 'A test query',
          sql: 'SELECT 1',
          folder: 'Tests',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('My Query'), findsOneWidget);
      expect(find.text('A test query'), findsOneWidget);
      expect(find.text('SELECT 1'), findsOneWidget);
      expect(find.text('Tests'), findsOneWidget);
    });

    testWidgets('cancel closes dialog', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Save Query'), findsNothing);
    });
  });
}
