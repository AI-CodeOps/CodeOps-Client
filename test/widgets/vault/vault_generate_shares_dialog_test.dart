// Widget tests for VaultGenerateSharesDialog (CVF-007).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_generate_shares_dialog.dart';

void main() {
  Widget createWidget() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showGenerateSharesDialog(
              context,
              shares: [
                'c2hhcmUx',
                'c2hhcmUy',
                'c2hhcmUz',
                'c2hhcmU0',
                'c2hhcmU1',
              ],
              totalShares: 5,
              threshold: 3,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('VaultGenerateSharesDialog', () {
    testWidgets('displays all shares with indices', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Generated Key Shares'), findsOneWidget);
      expect(find.text('Share 1'), findsOneWidget);
      expect(find.text('Share 2'), findsOneWidget);
      expect(find.text('Share 3'), findsOneWidget);
      expect(find.text('Share 4'), findsOneWidget);
      expect(find.text('Share 5'), findsOneWidget);
    });

    testWidgets('shows warning banner', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('These shares will not be shown again'),
        findsOneWidget,
      );
    });

    testWidgets('shows Copy All and Download buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Copy All'), findsOneWidget);
      expect(find.text('Download as Text File'), findsOneWidget);
    });

    testWidgets('Done button disabled until checkbox checked', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Done button should be disabled
      final doneButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Done'),
      );
      expect(doneButton.onPressed, isNull);

      // Scroll down in the dialog to reveal the checkbox
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Check the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Done button should be enabled
      final doneButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Done'),
      );
      expect(doneButtonAfter.onPressed, isNotNull);
    });

    testWidgets('shows share info text', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Total Shares: 5'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Threshold: 3'),
        findsOneWidget,
      );
    });
  });
}
