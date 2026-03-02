// Widget tests for DataCellEditor.
//
// Verifies type-aware editor rendering, null toggle, OK/Cancel buttons,
// and value commitment for different data types.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/data_cell_editor.dart';

Widget _createWidget({
  dynamic value = 'test',
  String dataType = 'text',
  bool isNullable = true,
  void Function(dynamic)? onCommit,
  VoidCallback? onCancel,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: DataCellEditor(
          value: value,
          dataType: dataType,
          isNullable: isNullable,
          onCommit: onCommit,
          onCancel: onCancel,
        ),
      ),
    ),
  );
}

void main() {
  group('DataCellEditor', () {
    testWidgets('renders with text editor for text type', (tester) async {
      await tester.pumpWidget(_createWidget(dataType: 'text'));
      await tester.pumpAndSettle();

      expect(find.byType(DataCellEditor), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows NULL toggle when nullable', (tester) async {
      await tester.pumpWidget(_createWidget(isNullable: true));
      await tester.pumpAndSettle();

      expect(find.text('NULL'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('hides NULL toggle when not nullable', (tester) async {
      await tester.pumpWidget(_createWidget(isNullable: false));
      await tester.pumpAndSettle();

      expect(find.text('NULL'), findsNothing);
    });

    testWidgets('shows OK and Cancel buttons', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders checkbox editor for boolean type', (tester) async {
      await tester.pumpWidget(_createWidget(
        value: true,
        dataType: 'boolean',
        isNullable: false,
      ));
      await tester.pumpAndSettle();

      // Boolean editor has a Checkbox.
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('renders binary indicator for bytea type', (tester) async {
      await tester.pumpWidget(_createWidget(
        value: 'binary',
        dataType: 'bytea',
        isNullable: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('(binary data)'), findsOneWidget);
    });

    testWidgets('renders date picker icon for date type', (tester) async {
      await tester.pumpWidget(_createWidget(
        value: '2026-01-15',
        dataType: 'date',
        isNullable: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('commits null when null checkbox is checked', (tester) async {
      dynamic committedValue = 'not-null';
      await tester.pumpWidget(_createWidget(
        value: 'test',
        isNullable: true,
        onCommit: (v) => committedValue = v,
      ));
      await tester.pumpAndSettle();

      // Tap the NULL checkbox.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap OK.
      await tester.tap(find.text('OK'));

      expect(committedValue, isNull);
    });

    testWidgets('Cancel callback fires on tap', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(_createWidget(
        onCancel: () => cancelled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));

      expect(cancelled, isTrue);
    });
  });
}
