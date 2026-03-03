// Widget tests for BodyFormDataEditor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/body_form_data_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildFormDataEditor({
  List<FormDataEntry>? entries,
  ValueChanged<List<FormDataEntry>>? onChanged,
  bool allowFiles = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: BodyFormDataEditor(
          entries: entries ?? [],
          onChanged: onChanged ?? (_) {},
          allowFiles: allowFiles,
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
  group('BodyFormDataEditor', () {
    testWidgets('renders without error', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildFormDataEditor());
      await tester.pumpAndSettle();

      expect(find.byType(BodyFormDataEditor), findsOneWidget);
    });

    testWidgets('shows header row with Key/Value/Type/Content-Type labels',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildFormDataEditor());
      await tester.pumpAndSettle();

      expect(find.text('Key'), findsAtLeastNWidgets(1));
      expect(find.text('Value'), findsAtLeastNWidgets(1));
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Content-Type'), findsAtLeastNWidgets(1));
    });

    testWidgets('hides Type column when allowFiles is false',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildFormDataEditor(allowFiles: false));
      await tester.pumpAndSettle();

      expect(find.text('Type'), findsNothing);
    });

    testWidgets('displays existing entries', (tester) async {
      setSize(tester);
      final entries = [
        const FormDataEntry(id: '1', key: 'name', value: 'John'),
        const FormDataEntry(id: '2', key: 'email', value: 'john@test.com'),
      ];
      await tester.pumpWidget(buildFormDataEditor(entries: entries));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'John'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'email'), findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'john@test.com'), findsOneWidget);
    });

    testWidgets('delete entry emits updated list', (tester) async {
      setSize(tester);
      final entries = [
        const FormDataEntry(id: '1', key: 'key1', value: 'val1'),
        const FormDataEntry(id: '2', key: 'key2', value: 'val2'),
      ];
      List<FormDataEntry>? emitted;
      await tester.pumpWidget(buildFormDataEditor(
        entries: entries,
        onChanged: (updated) => emitted = updated,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('form_data_delete_0')));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      final nonEmpty = emitted!.where((e) => !e.isEmpty).toList();
      expect(nonEmpty.length, 1);
      expect(nonEmpty.first.key, 'key2');
    });

    testWidgets('toggle enable/disable on entry', (tester) async {
      setSize(tester);
      final entries = [
        const FormDataEntry(
            id: '1', key: 'k1', value: 'v1', enabled: true),
      ];
      List<FormDataEntry>? emitted;
      await tester.pumpWidget(buildFormDataEditor(
        entries: entries,
        onChanged: (updated) => emitted = updated,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('form_data_enable_0')));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      final first = emitted!.firstWhere((e) => e.key == 'k1');
      expect(first.enabled, false);
    });

    testWidgets('file type entry shows file picker button', (tester) async {
      setSize(tester);
      final entries = [
        const FormDataEntry(
          id: '1',
          key: 'avatar',
          value: '',
          valueType: FormDataValueType.file,
        ),
      ];
      await tester.pumpWidget(buildFormDataEditor(entries: entries));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('form_data_file_pick_0')), findsOneWidget);
      expect(find.text('No file selected'), findsOneWidget);
    });

    testWidgets('FormDataEntry.toKeyValuePair converts correctly',
        (_) async {
      const entry = FormDataEntry(
        id: '1',
        key: 'name',
        value: 'John',
        description: 'User name',
        enabled: true,
      );
      final pair = entry.toKeyValuePair();
      expect(pair.id, '1');
      expect(pair.key, 'name');
      expect(pair.value, 'John');
      expect(pair.description, 'User name');
      expect(pair.enabled, true);
    });
  });
}
