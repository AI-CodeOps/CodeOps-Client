// Widget tests for BodyGraphqlEditor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/body_graphql_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildGraphqlEditor({
  String query = '',
  String variables = '',
  ValueChanged<String>? onQueryChanged,
  ValueChanged<String>? onVariablesChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: BodyGraphqlEditor(
          query: query,
          variables: variables,
          onQueryChanged: onQueryChanged ?? (_) {},
          onVariablesChanged: onVariablesChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BodyGraphqlEditor', () {
    testWidgets('renders two-panel layout', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildGraphqlEditor());
      await tester.pumpAndSettle();

      expect(find.byType(BodyGraphqlEditor), findsOneWidget);
      expect(
          find.byKey(const Key('graphql_query_header')), findsOneWidget);
      expect(find.byKey(const Key('graphql_variables_header')),
          findsOneWidget);
    });

    testWidgets('shows Query and Variables labels', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildGraphqlEditor());
      await tester.pumpAndSettle();

      expect(find.text('Query'), findsOneWidget);
      expect(find.text('Variables'), findsOneWidget);
    });

    testWidgets('shows beautify button for variables', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildGraphqlEditor());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('graphql_beautify_vars_button')),
          findsOneWidget);
    });

    testWidgets('renders query editor', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildGraphqlEditor(
        query: 'query { users { id name } }',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('graphql_query_editor')), findsOneWidget);
    });

    testWidgets('renders variables editor', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildGraphqlEditor(
        variables: '{"id": "123"}',
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('graphql_variables_editor')), findsOneWidget);
    });
  });
}
