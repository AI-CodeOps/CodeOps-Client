import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/progress/agent_output_terminal.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AgentOutputTerminal', () {
    testWidgets('shows waiting text when lines are empty', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentOutputTerminal(lines: []),
      ));

      expect(find.text('Waiting for output...'), findsOneWidget);
    });

    testWidgets('renders output lines', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentOutputTerminal(
          lines: ['line 1', 'line 2', 'line 3'],
        ),
      ));

      expect(find.text('line 1'), findsOneWidget);
      expect(find.text('line 2'), findsOneWidget);
      expect(find.text('line 3'), findsOneWidget);
    });

    testWidgets('updates when lines change', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentOutputTerminal(lines: ['line 1']),
      ));

      expect(find.text('line 1'), findsOneWidget);

      await tester.pumpWidget(wrap(
        const AgentOutputTerminal(lines: ['line 1', 'line 2']),
      ));

      expect(find.text('line 2'), findsOneWidget);
    });

    testWidgets('respects maxHeight constraint', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentOutputTerminal(
          lines: ['a', 'b', 'c'],
          maxHeight: 100,
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxHeight, 100);
    });
  });
}
