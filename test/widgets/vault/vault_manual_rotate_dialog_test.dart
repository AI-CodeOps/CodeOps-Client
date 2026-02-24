// Widget tests for VaultManualRotateDialog (CVF-005).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_manual_rotate_dialog.dart';

void main() {
  Widget createWidget() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const VaultManualRotateDialog(
                secretName: 'db-password',
                secretPath: '/services/app/db-password',
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('VaultManualRotateDialog', () {
    testWidgets('shows Rotate Secret title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Rotate Secret'), findsOneWidget);
    });

    testWidgets('shows secret name and path', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('db-password'), findsOneWidget);
      expect(find.text('/services/app/db-password'), findsOneWidget);
    });

    testWidgets('shows warning message', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('generate a new secret value'),
        findsOneWidget,
      );
    });

    testWidgets('shows Rotate Now and Cancel buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Rotate Now'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel closes dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Rotate Secret'), findsNothing);
    });
  });
}
