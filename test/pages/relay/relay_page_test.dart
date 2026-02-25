/// Tests for [RelayPage] — the main Relay messaging shell.
///
/// Verifies three-column layout rendering, route parameter processing,
/// thread panel visibility, and channel/DM selection behavior.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/pages/relay/relay_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/services/cloud/relay_api.dart';
import 'package:codeops/widgets/relay/relay_dm_panel.dart';
import 'package:codeops/widgets/relay/relay_empty_state.dart';
import 'package:codeops/widgets/relay/relay_message_feed.dart';
import 'package:codeops/widgets/relay/relay_sidebar.dart';
import 'package:codeops/widgets/relay/relay_thread_panel.dart';

class MockRelayApiService extends Mock implements RelayApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => null;
}

/// Stub secure storage that provides a null token.
class SecureStorageService {
  Future<String?> getAuthToken() async => null;
}

Widget _createPage({
  String initialLocation = '/relay',
  MockRelayApiService? mockApi,
  List<Override> overrides = const [],
}) {
  final api = mockApi ?? MockRelayApiService();

  // Default stubs for providers the real widgets depend on
  when(() => api.getConversation(any()))
      .thenAnswer((_) async => const DirectConversationResponse(
            id: 'convo',
            name: 'Test DM',
          ));
  when(() => api.getDirectMessages(any(),
          page: any(named: 'page'), size: any(named: 'size')))
      .thenAnswer((_) async => PageResponse<DirectMessageResponse>(
            content: [],
            page: 0,
            size: 50,
            totalElements: 0,
            totalPages: 1,
            isLast: true,
          ));
  when(() => api.markConversationRead(any())).thenAnswer((_) async => {});
  when(() => api.getChannelMessages(any(), any(),
          page: any(named: 'page'), size: any(named: 'size')))
      .thenAnswer((_) async => PageResponse<MessageResponse>(
            content: [],
            page: 0,
            size: 50,
            totalElements: 0,
            totalPages: 1,
            isLast: true,
          ));
  when(() => api.getMessage(any(), any()))
      .thenAnswer((_) async => const MessageResponse(
            id: 'msg-1',
            content: 'Root',
          ));
  when(() => api.getThreadReplies(any(), any()))
      .thenAnswer((_) async => <MessageResponse>[]);

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
              final conversationId =
                  state.pathParameters['conversationId']!;
              return RelayPage(initialConversationId: conversationId);
            },
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      relayApiProvider.overrideWithValue(api),
      currentUserProvider.overrideWith(
        (ref) => const User(
          id: 'user-1',
          email: 'test@test.com',
          displayName: 'Test User',
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

      expect(find.byType(RelayMessageFeed), findsOneWidget);
      expect(find.byType(RelayEmptyState), findsNothing);
    });

    testWidgets('processes initialConversationId route param',
        (tester) async {
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

      expect(find.byType(RelayMessageFeed), findsOneWidget);
      expect(find.byType(RelayThreadPanel), findsOneWidget);
    });

    testWidgets('hides thread panel by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage());
      await tester.pumpAndSettle();

      expect(find.byType(RelayThreadPanel), findsNothing);
    });

    testWidgets('shows thread panel when showThreadPanelProvider is true',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createPage(
        overrides: [
          showThreadPanelProvider.overrideWith((ref) => true),
          selectedChannelIdProvider.overrideWith((ref) => 'ch-123'),
          threadRootMessageIdProvider.overrideWith((ref) => 'msg-123'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RelayThreadPanel), findsOneWidget);
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

      expect(find.byType(RelayMessageFeed), findsOneWidget);
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
      expect(find.byType(RelayMessageFeed), findsOneWidget);
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
      expect(find.byType(RelayMessageFeed), findsNothing);
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
