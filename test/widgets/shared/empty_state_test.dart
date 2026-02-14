// Widget tests for EmptyState.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/shared/empty_state.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(icon: Icons.inbox, title: 'Nothing here'),
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(
          icon: Icons.inbox,
          title: 'Empty',
          subtitle: 'Try creating one',
        ),
      ));

      expect(find.text('Try creating one'), findsOneWidget);
    });

    testWidgets('hides subtitle when not provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(icon: Icons.inbox, title: 'Empty'),
      ));

      // Only title text + icon
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('shows action button and fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EmptyState(
          icon: Icons.inbox,
          title: 'Empty',
          actionLabel: 'Create',
          onAction: () => tapped = true,
        ),
      ));

      expect(find.text('Create'), findsOneWidget);
      await tester.tap(find.text('Create'));
      expect(tapped, isTrue);
    });

    testWidgets('hides action button when no label', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(icon: Icons.inbox, title: 'Empty'),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
