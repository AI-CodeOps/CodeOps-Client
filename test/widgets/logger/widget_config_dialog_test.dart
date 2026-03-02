// Widget tests for WidgetConfigDialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/logger/widget_config_dialog.dart';

void main() {
  Widget createWidget({
    String? initialTitle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => WidgetConfigDialog(
                initialTitle: initialTitle,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('WidgetConfigDialog', () {
    testWidgets('renders add dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add Widget'), findsOneWidget);
    });

    testWidgets('shows type selector', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Widget Type'), findsOneWidget);
      // Default type should be Counter.
      expect(find.text('Counter'), findsOneWidget);
    });

    testWidgets('shows title field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Widget Title'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
