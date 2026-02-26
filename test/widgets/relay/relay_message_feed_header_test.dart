/// Tests for [RelayMessageFeedHeader] — channel header bar.
///
/// Verifies channel name, topic, member count, channel type icon,
/// settings button, and loading/error states.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/relay_enums.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/widgets/relay/relay_message_feed_header.dart';

const _testChannel = ChannelResponse(
  id: 'ch-1',
  name: 'engineering',
  slug: 'engineering',
  description: 'Engineering discussions',
  topic: 'Sprint 42 planning',
  channelType: ChannelType.public,
  teamId: 'team-1',
  isArchived: false,
  memberCount: 12,
);

Widget _createHeader({
  String channelId = 'ch-1',
  String teamId = 'team-1',
  ChannelResponse? channel,
  List<Override> overrides = const [],
}) {
  final ch = channel ?? _testChannel;
  return ProviderScope(
    overrides: [
      channelDetailProvider((channelId: channelId, teamId: teamId))
          .overrideWith((ref) async => ch),
      undeliveredEventsProvider(teamId)
          .overrideWith((ref) async => <PlatformEventResponse>[]),
      ...overrides,
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RelayMessageFeedHeader(channelId: channelId, teamId: teamId),
      ),
    ),
  );
}

void main() {
  group('RelayMessageFeedHeader', () {
    testWidgets('renders channel name', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.text('engineering'), findsOneWidget);
    });

    testWidgets('renders topic text', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.text('Sprint 42 planning'), findsOneWidget);
    });

    testWidgets('renders member count', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('renders hash icon for public channel', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tag), findsOneWidget);
    });

    testWidgets('renders lock icon for private channel', (tester) async {
      const privateChannel = ChannelResponse(
        id: 'ch-2',
        name: 'secret',
        channelType: ChannelType.private,
        memberCount: 3,
      );
      await tester.pumpWidget(_createHeader(channel: privateChannel));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders settings icon button', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('renders pins icon button', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    });

    testWidgets('shows loading spinner initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelDetailProvider((channelId: 'ch-1', teamId: 'team-1'))
                .overrideWith(
                    (ref) => Completer<ChannelResponse>().future),
            undeliveredEventsProvider('team-1')
                .overrideWith((ref) async => <PlatformEventResponse>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RelayMessageFeedHeader(
                  channelId: 'ch-1', teamId: 'team-1'),
            ),
          ),
        ),
      );
      // Don't pump to settle — just check loading state
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelDetailProvider((channelId: 'ch-1', teamId: 'team-1'))
                .overrideWith(
                    (ref) async => throw Exception('channel not found')),
            undeliveredEventsProvider('team-1')
                .overrideWith((ref) async => <PlatformEventResponse>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RelayMessageFeedHeader(
                  channelId: 'ch-1', teamId: 'team-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load channel'), findsOneWidget);
    });

    testWidgets('renders search icon button', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(_createHeader());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('notification bell shows badge when undelivered events exist',
        (tester) async {
      await tester.pumpWidget(_createHeader(
        overrides: [
          undeliveredEventsProvider('team-1').overrideWith(
            (ref) async => const [
              PlatformEventResponse(id: 'evt-1', isDelivered: false),
              PlatformEventResponse(id: 'evt-2', isDelivered: false),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('does not show topic when null', (tester) async {
      const noTopicChannel = ChannelResponse(
        id: 'ch-3',
        name: 'general',
        channelType: ChannelType.public,
        memberCount: 5,
      );
      await tester.pumpWidget(_createHeader(channel: noTopicChannel));
      await tester.pumpAndSettle();

      expect(find.text('general'), findsOneWidget);
      // Pipe separator should not appear
      expect(find.text('|'), findsNothing);
    });
  });
}
