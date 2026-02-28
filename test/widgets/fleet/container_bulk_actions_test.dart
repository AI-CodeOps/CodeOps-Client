// Widget tests for ContainerBulkActions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/fleet/container_bulk_actions.dart';

void main() {
  Widget wrap({
    int selectedCount = 3,
    VoidCallback? onStart,
    VoidCallback? onStop,
    VoidCallback? onRemove,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerBulkActions(
          selectedCount: selectedCount,
          onStart: onStart ?? () {},
          onStop: onStop ?? () {},
          onRemove: onRemove ?? () {},
        ),
      ),
    );
  }

  group('ContainerBulkActions', () {
    testWidgets('shows selected count', (tester) async {
      await tester.pumpWidget(wrap(selectedCount: 5));
      expect(find.text('5 selected'), findsOneWidget);
    });

    testWidgets('shows Start, Stop, Remove buttons', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('calls onStart when Start tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(onStart: () => called = true));

      await tester.tap(find.text('Start'));
      expect(called, isTrue);
    });

    testWidgets('calls onStop when Stop tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(onStop: () => called = true));

      await tester.tap(find.text('Stop'));
      expect(called, isTrue);
    });

    testWidgets('calls onRemove when Remove tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(onRemove: () => called = true));

      await tester.tap(find.text('Remove'));
      expect(called, isTrue);
    });

    testWidgets('shows icons for each action', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
