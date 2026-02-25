/// Tests for [RelayMessageBubble] — individual message rendering.
///
/// Verifies text messages, system messages, platform events, file messages,
/// reactions, thread indicators, edited/deleted states, avatar rendering,
/// and the [showThreadIndicator] parameter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/relay_enums.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/widgets/relay/relay_message_bubble.dart';

Widget _createBubble(
  MessageResponse message, {
  bool isOwnMessage = false,
  bool showThreadIndicator = true,
  VoidCallback? onThreadTap,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RelayMessageBubble(
            message: message,
            isOwnMessage: isOwnMessage,
            showThreadIndicator: showThreadIndicator,
            onThreadTap: onThreadTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('RelayMessageBubble — TEXT', () {
    testWidgets('renders sender name', (tester) async {
      const msg = MessageResponse(
        id: 'msg-1',
        senderDisplayName: 'Alice',
        content: 'Hello world',
        messageType: MessageType.text,
        createdAt: null,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders message content', (tester) async {
      const msg = MessageResponse(
        id: 'msg-2',
        senderDisplayName: 'Bob',
        content: 'This is a test message',
        messageType: MessageType.text,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('This is a test message'), findsOneWidget);
    });

    testWidgets('renders avatar with first letter of name', (tester) async {
      const msg = MessageResponse(
        id: 'msg-3',
        senderDisplayName: 'Charlie',
        content: 'Hey',
        messageType: MessageType.text,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('C'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows (edited) indicator when message is edited',
        (tester) async {
      const msg = MessageResponse(
        id: 'msg-4',
        senderDisplayName: 'Dave',
        content: 'Edited message',
        messageType: MessageType.text,
        isEdited: true,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('(edited)'), findsOneWidget);
    });

    testWidgets('does not show (edited) when not edited', (tester) async {
      const msg = MessageResponse(
        id: 'msg-5',
        senderDisplayName: 'Eve',
        content: 'Normal message',
        messageType: MessageType.text,
        isEdited: false,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('(edited)'), findsNothing);
    });

    testWidgets('shows deleted placeholder when message is deleted',
        (tester) async {
      const msg = MessageResponse(
        id: 'msg-6',
        senderDisplayName: 'Frank',
        content: 'Secret message',
        messageType: MessageType.text,
        isDeleted: true,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('This message was deleted'), findsOneWidget);
      expect(find.text('Secret message'), findsNothing);
    });

    testWidgets('renders reactions when present', (tester) async {
      const msg = MessageResponse(
        id: 'msg-7',
        senderDisplayName: 'Grace',
        content: 'React to this!',
        messageType: MessageType.text,
        reactions: [
          ReactionSummaryResponse(
            emoji: '\u{1F44D}',
            count: 3,
            currentUserReacted: false,
          ),
          ReactionSummaryResponse(
            emoji: '\u{2764}',
            count: 1,
            currentUserReacted: true,
          ),
        ],
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.textContaining('3'), findsOneWidget);
      expect(find.textContaining('1'), findsOneWidget);
    });

    testWidgets('renders thread indicator when replies exist',
        (tester) async {
      var threadTapped = false;
      const msg = MessageResponse(
        id: 'msg-8',
        senderDisplayName: 'Heidi',
        content: 'Thread root',
        messageType: MessageType.text,
        replyCount: 5,
      );
      await tester.pumpWidget(
        _createBubble(msg, onThreadTap: () => threadTapped = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 replies'), findsOneWidget);

      await tester.tap(find.text('5 replies'));
      expect(threadTapped, isTrue);
    });

    testWidgets('renders "1 reply" for single reply', (tester) async {
      const msg = MessageResponse(
        id: 'msg-9',
        senderDisplayName: 'Ivan',
        content: 'One reply message',
        messageType: MessageType.text,
        replyCount: 1,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('1 reply'), findsOneWidget);
    });

    testWidgets('hides thread indicator when showThreadIndicator is false',
        (tester) async {
      const msg = MessageResponse(
        id: 'msg-thread-hidden',
        senderDisplayName: 'Jack',
        content: 'Thread root hidden',
        messageType: MessageType.text,
        replyCount: 5,
      );
      await tester.pumpWidget(
        _createBubble(msg, showThreadIndicator: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 replies'), findsNothing);
    });

    testWidgets('renders file attachments', (tester) async {
      const msg = MessageResponse(
        id: 'msg-10',
        senderDisplayName: 'Judy',
        content: 'Here is the file',
        messageType: MessageType.text,
        attachments: [
          FileAttachmentResponse(
            id: 'att-1',
            fileName: 'report.pdf',
            fileSizeBytes: 2048,
          ),
        ],
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.textContaining('KB'), findsOneWidget);
    });

    testWidgets('highlights own message sender name', (tester) async {
      const msg = MessageResponse(
        id: 'msg-11',
        senderDisplayName: 'Me',
        content: 'My message',
        messageType: MessageType.text,
      );
      await tester.pumpWidget(_createBubble(msg, isOwnMessage: true));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Me'));
      expect(textWidget.style?.color, const Color(0xFF6C63FF));
    });
  });

  group('RelayMessageBubble — SYSTEM', () {
    testWidgets('renders centered system message', (tester) async {
      const msg = MessageResponse(
        id: 'sys-1',
        content: 'Alice joined the channel',
        messageType: MessageType.system,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('Alice joined the channel'), findsOneWidget);
    });

    testWidgets('system message does not show avatar', (tester) async {
      const msg = MessageResponse(
        id: 'sys-2',
        content: 'Topic changed',
        messageType: MessageType.system,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsNothing);
    });
  });

  group('RelayMessageBubble — PLATFORM_EVENT', () {
    testWidgets('renders platform event card', (tester) async {
      const msg = MessageResponse(
        id: 'pe-1',
        content: 'Audit completed for project-x',
        messageType: MessageType.platformEvent,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('Platform Event'), findsOneWidget);
      expect(
          find.text('Audit completed for project-x'), findsOneWidget);
    });

    testWidgets('platform event shows bolt icon', (tester) async {
      const msg = MessageResponse(
        id: 'pe-2',
        content: 'Alert fired for service-y',
        messageType: MessageType.platformEvent,
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });

  group('RelayMessageBubble — FILE', () {
    testWidgets('renders file message with attachment card', (tester) async {
      const msg = MessageResponse(
        id: 'file-1',
        senderDisplayName: 'Karl',
        content: '',
        messageType: MessageType.file,
        attachments: [
          FileAttachmentResponse(
            id: 'att-2',
            fileName: 'design.png',
            fileSizeBytes: 5120,
          ),
        ],
      );
      await tester.pumpWidget(_createBubble(msg));
      await tester.pumpAndSettle();

      expect(find.text('Karl'), findsOneWidget);
      expect(find.text('design.png'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });
}
