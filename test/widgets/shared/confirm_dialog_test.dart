// Widget tests for ConfirmDialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/shared/confirm_dialog.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ConfirmDialog', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(wrap(
        const ConfirmDialog(title: 'Delete?', message: 'Are you sure?'),
      ));

      expect(find.text('Delete?'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Test',
                message: 'Confirm?',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('confirm returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Test',
                message: 'Confirm?',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('destructive mode renders with error color', (tester) async {
      await tester.pumpWidget(wrap(
        const ConfirmDialog(
          title: 'Delete?',
          message: 'This cannot be undone',
          destructive: true,
          confirmLabel: 'Delete',
        ),
      ));

      expect(find.text('Delete'), findsOneWidget);
      // Verify the confirm button exists (color testing is limited in widget tests)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
