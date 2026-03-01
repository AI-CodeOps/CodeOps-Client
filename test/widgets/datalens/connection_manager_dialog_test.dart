// Widget tests for ConnectionManagerDialog.
//
// Verifies dialog structure, connection list, form fields, validation,
// color picker, and save/test button behavior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/connection_manager_dialog.dart';

Widget _createWidget({
  List<DatabaseConnection> connections = const [],
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      datalensConnectionsProvider.overrideWith(
        (ref) => Future.value(connections),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ProviderScope(
                    parent: ProviderScope.containerOf(context),
                    child: const ConnectionManagerDialog(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ConnectionManagerDialog', () {
    testWidgets('shows dialog title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Connection Manager'), findsOneWidget);
    });

    testWidgets('shows "New Connection" button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('New Connection'), findsOneWidget);
    });

    testWidgets('shows empty message when no connections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('No connections yet.\nClick "New Connection" to add one.'),
        findsOneWidget,
      );
    });

    testWidgets('shows select message when no connection selected',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Select or create a connection'),
        findsOneWidget,
      );
    });

    testWidgets('shows form when "New Connection" is tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Connection Name'), findsOneWidget);
      expect(find.text('Host'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('form shows validation errors for empty required fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Connection'));
      await tester.pumpAndSettle();

      // Clear host field (defaults to 'localhost').
      final hostField = find.widgetWithText(TextFormField, 'localhost');
      await tester.enterText(hostField, '');

      // Clear the name field.
      final nameField = find.widgetWithText(TextFormField, 'e.g., CodeOps Dev');
      await tester.enterText(nameField, '');

      // Scroll the form ListView to reveal the Save button.
      final formListView = find.descendant(
        of: find.byType(Form),
        matching: find.byType(ListView),
      );
      await tester.drag(formListView, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap Save to trigger validation.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Validation errors appear — they may be off-screen, but exist in tree.
      expect(
        find.text('Name is required', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('shows Test Connection and Save buttons in form',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Connection'));
      await tester.pumpAndSettle();

      // Scroll the form ListView to reveal the action buttons.
      final formListView = find.descendant(
        of: find.byType(Form),
        matching: find.byType(ListView),
      );
      await tester.drag(formListView, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows color picker in form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Color'), findsOneWidget);
      // 10 color options in the picker.
      final colorDots = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(GestureDetector),
      );
      expect(colorDots, findsNWidgets(10));
    });

    testWidgets('shows SSL toggle in form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Connection'));
      await tester.pumpAndSettle();

      expect(find.text('SSL'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('shows connection in list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        connections: const [
          DatabaseConnection(
            id: 'c1',
            name: 'My DB',
            host: 'db.example.com',
            port: 5432,
            database: 'mydb',
          ),
        ],
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('My DB'), findsOneWidget);
      expect(find.text('db.example.com:5432/mydb'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Connection Manager'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Connection Manager'), findsNothing);
    });
  });
}
