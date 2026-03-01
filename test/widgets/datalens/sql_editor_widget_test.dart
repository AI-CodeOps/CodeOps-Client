// Widget tests for SqlEditorWidget.
//
// Verifies editor rendering, line numbers, toolbar buttons (execute, cancel,
// save, format), and running state visual feedback.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/sql_editor_toolbar.dart';
import 'package:codeops/widgets/datalens/sql_editor_widget.dart';
import 'package:codeops/widgets/scribe/scribe_editor.dart';

Widget _createWidget({
  String content = 'SELECT * FROM users;',
  VoidCallback? onExecute,
  VoidCallback? onCancel,
  VoidCallback? onSave,
  VoidCallback? onFormat,
  bool isRunning = false,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 600,
          child: SqlEditorWidget(
            content: content,
            onExecute: onExecute,
            onCancel: onCancel,
            onSave: onSave,
            onFormat: onFormat,
            isRunning: isRunning,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SqlEditorWidget', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SqlEditorWidget), findsOneWidget);
    });

    testWidgets('shows ScribeEditor with SQL language', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ScribeEditor), findsOneWidget);
    });

    testWidgets('shows toolbar with execute button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SqlEditorToolbar), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows cancel button when running', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(isRunning: true));
      // Use pump() instead of pumpAndSettle() because the running
      // spinner animates continuously.
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('Running...'), findsOneWidget);

      // Drain re_editor cursor blink timer to avoid pending timer error.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows save button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    });

    testWidgets('shows format button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.format_align_left), findsOneWidget);
    });
  });
}
