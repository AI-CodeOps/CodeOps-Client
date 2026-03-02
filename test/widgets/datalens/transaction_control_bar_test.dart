// Widget tests for TransactionControlBar.
//
// Verifies auto-commit toggle, COMMIT/ROLLBACK button visibility,
// transaction status indicator, and callback wiring.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/transaction_control_bar.dart';

Widget _createWidget({
  bool autoCommit = true,
  ValueChanged<bool>? onAutoCommitChanged,
  bool transactionActive = false,
  VoidCallback? onCommit,
  VoidCallback? onRollback,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TransactionControlBar(
        autoCommit: autoCommit,
        onAutoCommitChanged: onAutoCommitChanged,
        transactionActive: transactionActive,
        onCommit: onCommit,
        onRollback: onRollback,
      ),
    ),
  );
}

void main() {
  group('TransactionControlBar', () {
    testWidgets('shows auto-commit label', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Auto-commit'), findsOneWidget);
    });

    testWidgets('shows auto-commit toggle switch', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('hides COMMIT/ROLLBACK when auto-commit ON', (tester) async {
      await tester.pumpWidget(_createWidget(autoCommit: true));
      await tester.pumpAndSettle();

      expect(find.text('COMMIT'), findsNothing);
      expect(find.text('ROLLBACK'), findsNothing);
    });

    testWidgets('shows COMMIT/ROLLBACK when auto-commit OFF', (tester) async {
      await tester.pumpWidget(_createWidget(
        autoCommit: false,
        onCommit: () {},
        onRollback: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('COMMIT'), findsOneWidget);
      expect(find.text('ROLLBACK'), findsOneWidget);
    });

    testWidgets('shows "No transaction" status when inactive',
        (tester) async {
      await tester.pumpWidget(_createWidget(
        autoCommit: false,
        transactionActive: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No transaction'), findsOneWidget);
    });

    testWidgets('shows "Transaction active" status when active',
        (tester) async {
      await tester.pumpWidget(_createWidget(
        autoCommit: false,
        transactionActive: true,
        onCommit: () {},
        onRollback: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Transaction active'), findsOneWidget);
    });

    testWidgets('hides status indicator when auto-commit ON', (tester) async {
      await tester.pumpWidget(_createWidget(autoCommit: true));
      await tester.pumpAndSettle();

      expect(find.text('No transaction'), findsNothing);
      expect(find.text('Transaction active'), findsNothing);
    });

    testWidgets('COMMIT callback fires on tap when transaction active',
        (tester) async {
      var committed = false;
      await tester.pumpWidget(_createWidget(
        autoCommit: false,
        transactionActive: true,
        onCommit: () => committed = true,
        onRollback: () {},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('COMMIT'));
      expect(committed, isTrue);
    });

    testWidgets('ROLLBACK callback fires on tap when transaction active',
        (tester) async {
      var rolledBack = false;
      await tester.pumpWidget(_createWidget(
        autoCommit: false,
        transactionActive: true,
        onCommit: () {},
        onRollback: () => rolledBack = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ROLLBACK'));
      expect(rolledBack, isTrue);
    });
  });
}
