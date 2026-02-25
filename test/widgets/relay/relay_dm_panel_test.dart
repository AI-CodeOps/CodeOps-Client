/// Tests for [RelayDmPanel] — direct message center panel.
///
/// Verifies header rendering, message list display, empty state,
/// loading/error states, composer hint text, send button states,
/// and API integration for sending DMs.
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
import 'package:codeops/services/cloud/relay_api.dart';
import 'package:codeops/widgets/relay/relay_dm_panel.dart';

class MockRelayApiService extends Mock implements RelayApiService {}

class FakeSendDirectMessageRequest extends Fake
    implements SendDirectMessageRequest {}

const _conversationId = 'convo-1';

const _conversationDetail = DirectConversationResponse(
  id: _conversationId,
  teamId: 'team-1',
  name: 'Alice, Bob',
);

final _dmMessages = [
  DirectMessageResponse(
    id: 'dm-1',
    conversationId: _conversationId,
    senderId: 'user-2',
    senderDisplayName: 'Bob',
    content: 'Hey Alice!',
    messageType: MessageType.text,
    createdAt: DateTime.now(),
  ),
  DirectMessageResponse(
    id: 'dm-2',
    conversationId: _conversationId,
    senderId: 'user-1',
    senderDisplayName: 'Alice',
    content: 'Hi Bob!',
    messageType: MessageType.text,
    createdAt: DateTime.now(),
  ),
];

final _sentDm = DirectMessageResponse(
  id: 'dm-new',
  conversationId: _conversationId,
  senderId: 'user-1',
  senderDisplayName: 'Alice',
  content: 'New message',
  messageType: MessageType.text,
  createdAt: DateTime.now(),
);

Widget _createPanel({
  MockRelayApiService? mockApi,
  bool errorMessages = false,
  List<Override> overrides = const [],
}) {
  final api = mockApi ?? MockRelayApiService();

  // Only set up default stubs when no custom mock was provided.
  if (mockApi == null) {
    when(() => api.getConversation(any()))
        .thenAnswer((_) async => _conversationDetail);

    if (errorMessages) {
      when(() => api.getDirectMessages(any(),
              page: any(named: 'page'), size: any(named: 'size')))
          .thenThrow(Exception('network error'));
    } else {
      when(() => api.getDirectMessages(any(),
              page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer((_) async => PageResponse<DirectMessageResponse>(
                content: _dmMessages,
                page: 0,
                size: 50,
                totalElements: 2,
                totalPages: 1,
                isLast: true,
              ));
    }

    when(() => api.markConversationRead(any()))
        .thenAnswer((_) async => {});
  }

  return ProviderScope(
    overrides: [
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
          width: 600,
          height: 800,
          child: RelayDmPanel(conversationId: _conversationId),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSendDirectMessageRequest());
  });

  group('RelayDmPanel', () {
    testWidgets('renders header with conversation name', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Alice, Bob'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching messages',
        (tester) async {
      final api = MockRelayApiService();
      when(() => api.getConversation(any()))
          .thenAnswer((_) => Completer<DirectConversationResponse>().future);
      when(() => api.getDirectMessages(any(),
              page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer(
              (_) => Completer<PageResponse<DirectMessageResponse>>().future);

      await tester.pumpWidget(_createPanel(mockApi: api));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('renders DM messages', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Hey Alice!'), findsOneWidget);
      expect(find.text('Hi Bob!'), findsOneWidget);
    });

    testWidgets('shows empty state when no messages', (tester) async {
      final api = MockRelayApiService();
      when(() => api.getConversation(any()))
          .thenAnswer((_) async => _conversationDetail);
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
      when(() => api.markConversationRead(any()))
          .thenAnswer((_) async => {});

      await tester.pumpWidget(_createPanel(mockApi: api));
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('composer has hint text', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Message...'), findsOneWidget);
    });

    testWidgets('send button disabled when composer is empty',
        (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      final sendButton = tester.widgetList<IconButton>(
        find.byType(IconButton),
      ).last;
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('send button enabled when text entered', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello!');
      await tester.pump();

      final sendButton = tester.widgetList<IconButton>(
        find.byType(IconButton),
      ).last;
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('sends DM via API on submit', (tester) async {
      final api = MockRelayApiService();
      when(() => api.getConversation(any()))
          .thenAnswer((_) async => _conversationDetail);
      when(() => api.getDirectMessages(any(),
              page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer((_) async => PageResponse<DirectMessageResponse>(
                content: _dmMessages,
                page: 0,
                size: 50,
                totalElements: 2,
                totalPages: 1,
                isLast: true,
              ));
      when(() => api.markConversationRead(any()))
          .thenAnswer((_) async => {});
      when(() => api.sendDirectMessage(any(), any()))
          .thenAnswer((_) async => _sentDm);

      await tester.pumpWidget(_createPanel(mockApi: api));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New message');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final captured = verify(
        () => api.sendDirectMessage(_conversationId, captureAny()),
      ).captured;

      expect(captured, isNotEmpty);
      final request = captured.first as SendDirectMessageRequest;
      expect(request.content, 'New message');
    });

    testWidgets('shows error state for failed messages', (tester) async {
      await tester.pumpWidget(_createPanel(errorMessages: true));
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
    });

    testWidgets('renders person icon in header', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });
}
