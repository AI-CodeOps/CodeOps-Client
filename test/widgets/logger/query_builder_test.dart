// Widget tests for QueryBuilder.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/logger/query_builder.dart';

void main() {
  Widget createWidget({
    void Function(Map<String, dynamic>)? onSearch,
    void Function(String)? onSearchDsl,
    VoidCallback? onSave,
    List<QueryCondition>? initialConditions,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: QueryBuilder(
          onSearch: onSearch ?? (_) {},
          onSearchDsl: onSearchDsl,
          onSave: onSave,
          initialConditions: initialConditions,
        ),
      ),
    );
  }

  group('QueryBuilder', () {
    testWidgets('renders with header and default condition', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Query Builder'), findsOneWidget);
      expect(find.text('Visual Mode'), findsOneWidget);
      // Default field is 'message'.
      expect(find.text('message'), findsAtLeastNWidgets(1));
      // Default operator is 'contains'.
      expect(find.text('contains'), findsAtLeastNWidgets(1));
    });

    testWidgets('add condition button adds a new row', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Start with 1 condition — no remove buttons visible.
      expect(find.byIcon(Icons.close), findsNothing);

      // Add a condition.
      await tester.tap(find.text('Add Condition'));
      await tester.pumpAndSettle();

      // Now 2 conditions — remove buttons visible.
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('remove condition button removes a row', (tester) async {
      await tester.pumpWidget(createWidget(
        initialConditions: [
          QueryCondition(field: 'message', operator: 'contains', value: 'err'),
          QueryCondition(field: 'level', operator: 'equals', value: 'ERROR'),
        ],
      ));
      await tester.pumpAndSettle();

      // 2 conditions, 2 remove buttons.
      expect(find.byIcon(Icons.close), findsNWidgets(2));

      // Remove the first condition.
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Now 1 condition, no remove buttons.
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('field dropdown shows all search fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap the field dropdown to open it.
      await tester.tap(find.text('message').first);
      await tester.pumpAndSettle();

      // Check some key fields are present.
      expect(find.text('level'), findsAtLeastNWidgets(1));
      expect(find.text('serviceName'), findsAtLeastNWidgets(1));
      expect(find.text('correlationId'), findsAtLeastNWidgets(1));
    });

    testWidgets('operator dropdown shows operators when tapped', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // The operator dropdown should show the default value 'contains'.
      expect(find.text('contains'), findsAtLeastNWidgets(1));

      // Tap the operator dropdown to open it.
      await tester.tap(find.text('contains').first);
      await tester.pumpAndSettle();

      // Verify at least one other operator item is visible.
      // 'not_contains' is right near 'contains' so should be visible.
      expect(find.text('not_contains'), findsAtLeastNWidgets(1));
    });

    testWidgets('raw mode toggle switches to DSL input', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Visual Mode'), findsOneWidget);

      // Toggle to raw mode.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('DSL Mode'), findsOneWidget);
      // Should show the DSL text input with hint.
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.maxLines == null,
        ),
        findsOneWidget,
      );
    });

    testWidgets('AND/OR combiner toggles on tap', (tester) async {
      await tester.pumpWidget(createWidget(
        initialConditions: [
          QueryCondition(field: 'message', operator: 'contains', value: 'err'),
          QueryCondition(field: 'level', operator: 'equals', value: 'ERROR'),
        ],
      ));
      await tester.pumpAndSettle();

      // Default combiner is AND.
      expect(find.text('AND'), findsOneWidget);

      // Toggle to OR.
      await tester.tap(find.text('AND'));
      await tester.pumpAndSettle();

      expect(find.text('OR'), findsOneWidget);
    });
  });
}
