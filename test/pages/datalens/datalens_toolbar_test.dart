// Widget tests for DatalensToolbar.
//
// Verifies connection dropdown, connect/disconnect buttons, refresh,
// and connection manager button behavior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/pages/datalens/datalens_toolbar.dart';
import 'package:codeops/providers/datalens_providers.dart';

Widget _createWidget({
  String? selectedConnectionId,
  List<DatabaseConnection> connections = const [],
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => selectedConnectionId),
      datalensConnectionsProvider.overrideWith(
        (ref) => Future.value(connections),
      ),
      ...overrides,
    ],
    child: const MaterialApp(home: Scaffold(body: DatalensToolbar())),
  );
}

void main() {
  group('DatalensToolbar', () {
    testWidgets('shows connection dropdown hint when no connections',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select connection...'), findsOneWidget);
    });

    testWidgets('shows connection names in dropdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        connections: const [
          DatabaseConnection(id: 'c1', name: 'Dev DB'),
          DatabaseConnection(id: 'c2', name: 'Staging DB'),
        ],
      ));
      await tester.pumpAndSettle();

      // Open the dropdown.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Dev DB'), findsWidgets);
      expect(find.text('Staging DB'), findsWidgets);
    });

    testWidgets('shows Connections button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Connections'), findsOneWidget);
    });

    testWidgets('shows connect tooltip when disconnected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedConnectionId: 'c1',
        connections: const [
          DatabaseConnection(id: 'c1', name: 'Dev DB'),
        ],
      ));
      await tester.pumpAndSettle();

      // The connect button should be present with the link icon.
      expect(find.byIcon(Icons.link), findsOneWidget);
    });
  });
}
