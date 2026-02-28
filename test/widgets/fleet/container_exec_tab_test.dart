// Widget tests for ContainerExecTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/fleet/container_exec_tab.dart';

void main() {
  Widget wrap({
    Future<String> Function(String)? onExec,
    bool isRunning = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerExecTab(
          onExec: onExec ?? (_) async => 'output',
          isRunning: isRunning,
        ),
      ),
    );
  }

  group('ContainerExecTab', () {
    testWidgets('shows prompt and empty state when running', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('\$'), findsOneWidget);
      expect(find.text('Enter a command below to execute in the container'),
          findsOneWidget);
    });

    testWidgets('shows not running message when stopped', (tester) async {
      await tester.pumpWidget(wrap(isRunning: false));

      expect(find.text('Container is not running'), findsOneWidget);
    });

    testWidgets('renders send button', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('renders command input field', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('executes command and shows output', (tester) async {
      await tester.pumpWidget(wrap(
        onExec: (_) async => 'hello from container',
      ));

      // Enter command
      await tester.enterText(find.byType(TextField), 'echo hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Command and output should appear in history
      expect(find.text('echo hello'), findsOneWidget);
      expect(find.text('hello from container'), findsOneWidget);
    });

    testWidgets('shows error output in red', (tester) async {
      await tester.pumpWidget(wrap(
        onExec: (_) async => throw Exception('command failed'),
      ));

      await tester.enterText(find.byType(TextField), 'bad-cmd');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('bad-cmd'), findsOneWidget);
      // Error text should be present
      expect(find.textContaining('command failed'), findsOneWidget);
    });
  });
}
