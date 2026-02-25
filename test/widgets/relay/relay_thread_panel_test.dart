/// Tests for [RelayThreadPanel] — thread right panel.
///
/// Verifies header rendering, close button, root message display,
/// reply list, reply composer, "Also send to channel" checkbox,
/// loading/error states, and API integration for sending replies.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/relay_enums.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/services/cloud/relay_api.dart';
import 'package:codeops/widgets/relay/relay_thread_panel.dart';

class MockRelayApiService extends Mock implements RelayApiService {}

class FakeSendMessageRequest extends Fake implements SendMessageRequest {}

const _channelId = 'ch-1';
const _teamId = 'team-1';
const _rootMessageId = 'msg-root-1';

final _rootMessage = MessageResponse(
  id: _rootMessageId,
  channelId: _channelId,
  senderId: 'user-1',
  senderDisplayName: 'Alice',
  content: 'This is the root message',
  messageType: MessageType.text,
  replyCount: 2,
  createdAt: DateTime.now(),
);

final _replies = [
  MessageResponse(
    id: 'reply-1',
    channelId: _channelId,
    senderId: 'user-2',
    senderDisplayName: 'Bob',
    content: 'First reply',
    messageType: MessageType.text,
    parentId: _rootMessageId,
    createdAt: DateTime.now(),
  ),
  MessageResponse(
    id: 'reply-2',
    channelId: _channelId,
    senderId: 'user-3',
    senderDisplayName: 'Carol',
    content: 'Second reply',
    messageType: MessageType.text,
    parentId: _rootMessageId,
    createdAt: DateTime.now(),
  ),
];

final _sentReply = MessageResponse(
  id: 'reply-new',
  channelId: _channelId,
  senderId: 'user-1',
  senderDisplayName: 'Alice',
  content: 'New reply',
  messageType: MessageType.text,
  parentId: _rootMessageId,
  createdAt: DateTime.now(),
);

Widget _createPanel({
  MockRelayApiService? mockApi,
  bool errorReplies = false,
  VoidCallback? onClose,
  List<Override> overrides = const [],
}) {
  final api = mockApi ?? MockRelayApiService();

  // Only set up default stubs when no custom mock was provided.
  // Custom mocks bring their own stubs that must not be overridden.
  if (mockApi == null) {
    when(() => api.getMessage(any(), any()))
        .thenAnswer((_) async => _rootMessage);

    if (errorReplies) {
      when(() => api.getThreadReplies(any(), any()))
          .thenThrow(Exception('network error'));
    } else {
      when(() => api.getThreadReplies(any(), any()))
          .thenAnswer((_) async => _replies);
    }

    // Stub for channel messages (required by accumulated messages provider)
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
  }

  return ProviderScope(
    overrides: [
      selectedTeamIdProvider.overrideWith((ref) => _teamId),
      relayApiProvider.overrideWithValue(api),
      currentUserProvider.overrideWith(
        (ref) => const User(
          id: 'user-1',
          email: 'alice@test.com',
          displayName: 'Alice',
        ),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 340,
          height: 600,
          child: RelayThreadPanel(
            channelId: _channelId,
            rootMessageId: _rootMessageId,
            onClose: onClose ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSendMessageRequest());
  });

  group('RelayThreadPanel', () {
    testWidgets('renders header with Thread title', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Thread'), findsOneWidget);
    });

    testWidgets('close button calls onClose callback', (tester) async {
      bool closed = false;
      await tester.pumpWidget(_createPanel(onClose: () => closed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('shows loading indicator while fetching root message',
        (tester) async {
      final api = MockRelayApiService();
      when(() => api.getMessage(any(), any()))
          .thenAnswer((_) => Completer<MessageResponse>().future);
      when(() => api.getThreadReplies(any(), any()))
          .thenAnswer((_) => Completer<List<MessageResponse>>().future);
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

      await tester.pumpWidget(_createPanel(mockApi: api));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('renders root message content', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('This is the root message'), findsOneWidget);
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders reply count separator', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('2 replies'), findsOneWidget);
    });

    testWidgets('renders thread replies', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('First reply'), findsOneWidget);
      expect(find.text('Second reply'), findsOneWidget);
    });

    testWidgets('shows "No replies yet" when no replies', (tester) async {
      final api = MockRelayApiService();
      when(() => api.getMessage(any(), any()))
          .thenAnswer((_) async => _rootMessage);
      when(() => api.getThreadReplies(any(), any()))
          .thenAnswer((_) async => <MessageResponse>[]);
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

      await tester.pumpWidget(_createPanel(mockApi: api));
      await tester.pumpAndSettle();

      expect(find.text('No replies yet'), findsOneWidget);
    });

    testWidgets('reply composer has hint text', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Reply...'), findsOneWidget);
    });

    testWidgets('send button disabled when reply field is empty',
        (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      final sendButton = tester.widgetList<IconButton>(
        find.byType(IconButton),
      ).last;
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('send button enabled when reply text entered',
        (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My reply');
      await tester.pump();

      final sendButton = tester.widgetList<IconButton>(
        find.byType(IconButton),
      ).last;
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('"Also send to channel" checkbox is present',
        (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Also send to channel'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('"Also send to channel" checkbox toggles', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final updated = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(updated.value, isTrue);
    });

    testWidgets('sends reply with parentId on submit', (tester) async {
      final api = MockRelayApiService();
      when(() => api.getMessage(any(), any()))
          .thenAnswer((_) async => _rootMessage);
      when(() => api.getThreadReplies(any(), any()))
          .thenAnswer((_) async => _replies);
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
      when(() => api.sendMessage(any(), any(), any()))
          .thenAnswer((_) async => _sentReply);

      await tester.pumpWidget(_createPanel(mockApi: api));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New reply');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final captured = verify(
        () => api.sendMessage(_channelId, captureAny(), _teamId),
      ).captured;

      expect(captured, isNotEmpty);
      final request = captured.first as SendMessageRequest;
      expect(request.parentId, _rootMessageId);
      expect(request.content, 'New reply');
    });

    testWidgets('shows error state for failed replies', (tester) async {
      await tester.pumpWidget(_createPanel(errorReplies: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load replies'), findsOneWidget);
    });

    testWidgets('root message hides thread indicator', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      // The root message has replyCount: 2 but showThreadIndicator is false
      // so "2 replies" from the thread indicator should NOT appear as a
      // tappable link (only as the separator label)
      // The separator shows "2 replies" but the bubble should not.
      // Verify there is exactly one "2 replies" text (the separator, not bubble)
      expect(find.text('2 replies'), findsOneWidget);
    });
  });
}
