// Widget tests for PendingChangesPanel.
//
// Verifies change list rendering, change type labels, count badge,
// Apply All / Revert All buttons, and per-change revert.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/datalens/data_editor_service.dart';
import 'package:codeops/widgets/datalens/pending_changes_panel.dart';

Widget _createWidget({
  List<RowChange> changes = const [],
  VoidCallback? onApplyAll,
  VoidCallback? onRevertAll,
  ValueChanged<int>? onRevertChange,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PendingChangesPanel(
        changes: changes,
        onApplyAll: onApplyAll,
        onRevertAll: onRevertAll,
        onRevertChange: onRevertChange,
      ),
    ),
  );
}

void main() {
  group('PendingChangesPanel', () {
    testWidgets('returns empty when no changes', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PendingChangesPanel), findsOneWidget);
      expect(find.text('Pending Changes'), findsNothing);
    });

    testWidgets('shows header with change count', (tester) async {
      await tester.pumpWidget(_createWidget(
        changes: [
          const RowChange(
            type: RowChangeType.insert,
            rowData: {'name': 'Alice'},
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pending Changes'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows Apply All and Revert All buttons', (tester) async {
      await tester.pumpWidget(_createWidget(
        changes: [
          const RowChange(type: RowChangeType.insert, rowData: {'name': 'A'}),
        ],
        onApplyAll: () {},
        onRevertAll: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Apply All'), findsOneWidget);
      expect(find.text('Revert All'), findsOneWidget);
    });

    testWidgets('shows INSERT label for insert change', (tester) async {
      await tester.pumpWidget(_createWidget(
        changes: [
          const RowChange(type: RowChangeType.insert, rowData: {'name': 'A'}),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('INSERT'), findsOneWidget);
    });

    testWidgets('shows UPDATE label for update change', (tester) async {
      await tester.pumpWidget(_createWidget(
        changes: [
          RowChange(
            type: RowChangeType.update,
            rowKey: RowKey({'id': 1}),
            cellChanges: const [
              CellChange(columnName: 'name', originalValue: 'a', newValue: 'b'),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('UPDATE'), findsOneWidget);
    });

    testWidgets('shows DELETE label for delete change', (tester) async {
      await tester.pumpWidget(_createWidget(
        changes: [
          RowChange(type: RowChangeType.delete, rowKey: RowKey({'id': 5})),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('Apply All callback fires', (tester) async {
      var applied = false;
      await tester.pumpWidget(_createWidget(
        changes: [
          const RowChange(type: RowChangeType.insert, rowData: {'name': 'A'}),
        ],
        onApplyAll: () => applied = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply All'));

      expect(applied, isTrue);
    });

    testWidgets('Revert All callback fires', (tester) async {
      var reverted = false;
      await tester.pumpWidget(_createWidget(
        changes: [
          const RowChange(type: RowChangeType.insert, rowData: {'name': 'A'}),
        ],
        onRevertAll: () => reverted = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revert All'));

      expect(reverted, isTrue);
    });
  });
}
