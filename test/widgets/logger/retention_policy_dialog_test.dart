// Widget tests for RetentionPolicyDialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/retention_policy_dialog.dart';

void main() {
  Widget createWidget({RetentionPolicyResponse? existing}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => RetentionPolicyDialog(existing: existing),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('RetentionPolicyDialog', () {
    testWidgets('renders create dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create Retention Policy'), findsOneWidget);
    });

    testWidgets('shows name field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Policy Name'), findsOneWidget);
    });

    testWidgets('shows source filter field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Source Filter (optional)'), findsOneWidget);
    });

    testWidgets('shows retention days field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Retention Days'), findsOneWidget);
    });

    testWidgets('shows action dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Purge'), findsOneWidget);
    });

    testWidgets('shows create button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
    });
  });
}
