import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/ci_status_badge.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CiStatusBadge', () {
    testWidgets('shows success text for conclusion=success', (tester) async {
      await tester.pumpWidget(wrap(
        const CiStatusBadge(
          run: WorkflowRun(
            id: 1,
            name: 'CI',
            status: 'completed',
            conclusion: 'success',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('success'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows failure text for conclusion=failure', (tester) async {
      await tester.pumpWidget(wrap(
        const CiStatusBadge(
          run: WorkflowRun(
            id: 2,
            name: 'CI',
            status: 'completed',
            conclusion: 'failure',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('failure'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows in_progress for status=in_progress', (tester) async {
      await tester.pumpWidget(wrap(
        const CiStatusBadge(
          run: WorkflowRun(
            id: 3,
            name: 'CI',
            status: 'in_progress',
            conclusion: null,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('in_progress'), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);
    });
  });
}
