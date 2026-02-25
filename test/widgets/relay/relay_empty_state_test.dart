/// Tests for [RelayEmptyState] — empty center panel.
///
/// Verifies icon, instructional text, and placeholder action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/relay/relay_empty_state.dart';

Widget _createEmptyState() {
  return const MaterialApp(
    home: Scaffold(
      body: RelayEmptyState(),
    ),
  );
}

void main() {
  group('RelayEmptyState', () {
    testWidgets('renders messaging icon', (tester) async {
      await tester.pumpWidget(_createEmptyState());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('renders instructional text', (tester) async {
      await tester.pumpWidget(_createEmptyState());
      await tester.pumpAndSettle();

      expect(
        find.text('Select a channel or conversation to start messaging'),
        findsOneWidget,
      );
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(_createEmptyState());
      await tester.pumpAndSettle();

      expect(find.text('Browse Channels'), findsOneWidget);
      expect(find.text('Start a DM'), findsOneWidget);
    });
  });
}
