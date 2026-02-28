// Widget tests for ContainerRowActions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_enums.dart';
import 'package:codeops/widgets/fleet/container_row_actions.dart';

void main() {
  Widget wrap(ContainerStatus status, ContainerActionCallbacks callbacks) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerRowActions(status: status, callbacks: callbacks),
      ),
    );
  }

  group('ContainerRowActions', () {
    testWidgets('shows Stop button when running', (tester) async {
      var stopCalled = false;
      await tester.pumpWidget(wrap(
        ContainerStatus.running,
        (
          onStop: () => stopCalled = true,
          onStart: null,
          onRestart: () {},
          onRemove: () {},
          onViewLogs: () {},
        ),
      ));

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.tap(find.byIcon(Icons.stop));
      expect(stopCalled, isTrue);
    });

    testWidgets('shows Start button when stopped', (tester) async {
      var startCalled = false;
      await tester.pumpWidget(wrap(
        ContainerStatus.stopped,
        (
          onStop: null,
          onStart: () => startCalled = true,
          onRestart: () {},
          onRemove: () {},
          onViewLogs: () {},
        ),
      ));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);

      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(startCalled, isTrue);
    });

    testWidgets('shows Start button when exited', (tester) async {
      await tester.pumpWidget(wrap(
        ContainerStatus.exited,
        (
          onStop: null,
          onStart: () {},
          onRestart: () {},
          onRemove: () {},
          onViewLogs: () {},
        ),
      ));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('shows Start button when created', (tester) async {
      await tester.pumpWidget(wrap(
        ContainerStatus.created,
        (
          onStop: null,
          onStart: () {},
          onRestart: () {},
          onRemove: () {},
          onViewLogs: () {},
        ),
      ));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('always shows Restart, Remove, and View Logs', (tester) async {
      await tester.pumpWidget(wrap(
        ContainerStatus.running,
        (
          onStop: () {},
          onStart: null,
          onRestart: () {},
          onRemove: () {},
          onViewLogs: () {},
        ),
      ));

      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('calls onRestart when Restart button tapped', (tester) async {
      var restartCalled = false;
      await tester.pumpWidget(wrap(
        ContainerStatus.running,
        (
          onStop: () {},
          onStart: null,
          onRestart: () => restartCalled = true,
          onRemove: () {},
          onViewLogs: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.restart_alt));
      expect(restartCalled, isTrue);
    });

    testWidgets('calls onRemove when Remove button tapped', (tester) async {
      var removeCalled = false;
      await tester.pumpWidget(wrap(
        ContainerStatus.running,
        (
          onStop: () {},
          onStart: null,
          onRestart: () {},
          onRemove: () => removeCalled = true,
          onViewLogs: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(removeCalled, isTrue);
    });

    testWidgets('calls onViewLogs when View Logs button tapped',
        (tester) async {
      var logsCalled = false;
      await tester.pumpWidget(wrap(
        ContainerStatus.running,
        (
          onStop: () {},
          onStart: null,
          onRestart: () {},
          onRemove: () {},
          onViewLogs: () => logsCalled = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.article_outlined));
      expect(logsCalled, isTrue);
    });
  });
}
