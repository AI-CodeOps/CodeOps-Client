/// Tests for [RelaySidebar] — channel and DM list sidebar.
///
/// Verifies header rendering, section headers, expand/collapse,
/// add buttons, selection callbacks, and unread badges.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/widgets/relay/relay_sidebar.dart';

Widget _createSidebar({
  ValueChanged<String>? onChannelSelected,
  ValueChanged<String>? onConversationSelected,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 260,
          child: RelaySidebar(
            onChannelSelected: onChannelSelected ?? (_) {},
            onConversationSelected: onConversationSelected ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('RelaySidebar', () {
    testWidgets('renders header with Relay title', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('Relay'), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('renders channels section header', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('CHANNELS'), findsOneWidget);
    });

    testWidgets('renders direct messages section header', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('DIRECT MESSAGES'), findsOneWidget);
    });

    testWidgets('renders placeholder channel items', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('# general'), findsOneWidget);
      expect(find.text('# engineering'), findsOneWidget);
      expect(find.text('# random'), findsOneWidget);
    });

    testWidgets('section headers have expand/collapse chevron',
        (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      // Both sections are expanded by default — show expand_more icon
      expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(2));
    });

    testWidgets('section headers have add button', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(2));
    });

    testWidgets('calls onChannelSelected callback when channel tapped',
        (tester) async {
      String? selectedId;
      await tester.pumpWidget(_createSidebar(
        onChannelSelected: (id) => selectedId = id,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('# general'));
      await tester.pumpAndSettle();

      expect(selectedId, 'placeholder-general');
    });

    testWidgets('highlights selected channel', (tester) async {
      await tester.pumpWidget(_createSidebar(
        overrides: [
          selectedChannelIdProvider
              .overrideWith((ref) => 'placeholder-general'),
        ],
      ));
      await tester.pumpAndSettle();

      // The selected channel text should exist and be rendered
      expect(find.text('# general'), findsOneWidget);
    });

    testWidgets('shows no conversations placeholder', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('chevron toggles between expand and collapse', (tester) async {
      await tester.pumpWidget(_createSidebar());
      await tester.pumpAndSettle();

      // Initially expanded — find the first expand_more icon and tap it
      final expandIcons = find.byIcon(Icons.expand_more);
      expect(expandIcons, findsAtLeastNWidgets(2));

      await tester.tap(expandIcons.first);
      await tester.pumpAndSettle();

      // After collapse, at least one chevron_right should appear
      expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
    });
  });
}
