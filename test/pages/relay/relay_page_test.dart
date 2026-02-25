/// Tests for [RelayPage] — the main Relay messaging shell.
///
/// Verifies three-column layout rendering, route parameter processing,
/// thread panel visibility, and channel/DM selection behavior.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/pages/relay/relay_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/widgets/relay/relay_detail_panel.dart';
import 'package:codeops/widgets/relay/relay_dm_panel.dart';
import 'package:codeops/widgets/relay/relay_empty_state.dart';
import 'package:codeops/widgets/relay/relay_message_panel.dart';
import 'package:codeops/widgets/relay/relay_sidebar.dart';
import 'package:codeops/services/auth/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _createPage({
  String initialLocation = '/relay',
  List<Override> overrides = const [],
}) {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/relay',
        builder: (context, state) => const RelayPage(),
        routes: [
          GoRoute(
            path: 'channel/:channelId',
            builder: (context, state) {
              final channelId = state.pathParameters['channelId']!;
              return RelayPage(initialChannelId: channelId);
            },
            routes: [
              GoRoute(
                path: 'thread/:messageId',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  final messageId = state.pathParameters['messageId']!;
                  return RelayPage(
                    initialChannelId: channelId,
                    initialThreadMessageId: messageId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'dm/:conversationId',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return RelayPage(initialConversationId: conversationId);
            },
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWith(
        (ref) => SecureStorageService(
          prefs: SharedPreferences.getInstance() as SharedPreferences?,
        ),
      ),
      ...overrides,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('RelayPage', () {
    testWidgets('renders three-column layout with sidebar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage());
      await tester.pumpAndSettle();

      expect(find.byType(RelaySidebar), findsOneWidget);
      expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no channel selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage());
      await tester.pumpAndSettle();

      expect(find.byType(RelayEmptyState), findsOneWidget);
      expect(find.text('Select a channel or conversation to start messaging'),
          findsOneWidget);
    });

    testWidgets('processes initialChannelId route param', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        initialLocation: '/relay/channel/ch-123',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayMessagePanel), findsOneWidget);
      expect(find.byType(RelayEmptyState), findsNothing);
    });

    testWidgets('processes initialConversationId route param', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        initialLocation: '/relay/dm/dm-456',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayDmPanel), findsOneWidget);
      expect(find.byType(RelayEmptyState), findsNothing);
    });

    testWidgets('processes initialThreadMessageId and shows thread panel',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        initialLocation: '/relay/channel/ch-123/thread/msg-789',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayMessagePanel), findsOneWidget);
      expect(find.byType(RelayDetailPanel), findsOneWidget);
    });

    testWidgets('hides thread panel by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage());
      await tester.pumpAndSettle();

      expect(find.byType(RelayDetailPanel), findsNothing);
    });

    testWidgets('shows thread panel when showThreadPanelProvider is true',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        overrides: [
          showThreadPanelProvider.overrideWith((ref) => true),
          selectedChannelIdProvider.overrideWith((ref) => 'ch-123'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayDetailPanel), findsOneWidget);
    });

    testWidgets('channel selection shows message panel', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        overrides: [
          selectedChannelIdProvider.overrideWith((ref) => 'ch-abc'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayMessagePanel), findsOneWidget);
    });

    testWidgets('DM selection shows DM panel', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        overrides: [
          selectedConversationIdProvider.overrideWith((ref) => 'dm-xyz'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayDmPanel), findsOneWidget);
    });

    testWidgets('channel selection clears DM selection via route',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        initialLocation: '/relay/channel/ch-123',
      ));
      await tester.pumpAndSettle();

      // Channel panel is showing, not DM
      expect(find.byType(RelayMessagePanel), findsOneWidget);
      expect(find.byType(RelayDmPanel), findsNothing);
    });

    testWidgets('DM selection clears channel selection via route',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        initialLocation: '/relay/dm/dm-456',
      ));
      await tester.pumpAndSettle();

      // DM panel is showing, not channel
      expect(find.byType(RelayDmPanel), findsOneWidget);
      expect(find.byType(RelayMessagePanel), findsNothing);
    });

    testWidgets('sidebar is present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage());
      await tester.pumpAndSettle();

      expect(find.byType(RelaySidebar), findsOneWidget);
    });

    testWidgets('sidebar width is 260', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage());
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(RelaySidebar),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 260);
    });
  });
}
