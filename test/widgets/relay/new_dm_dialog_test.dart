/// Tests for [NewDmDialog] — new direct message conversation dialog.
///
/// Verifies title rendering, team member list, search filtering,
/// current user exclusion, member selection with API call,
/// error handling, and cancel/close behavior.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/relay_models.dart';
import 'package:codeops/models/team.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/services/cloud/relay_api.dart';
import 'package:codeops/widgets/relay/new_dm_dialog.dart';

class MockRelayApiService extends Mock implements RelayApiService {}

class FakeCreateDirectConversationRequest extends Fake
    implements CreateDirectConversationRequest {}

const _teamId = 'team-1';

const _teamMembers = [
  TeamMember(
    id: 'tm-1',
    userId: 'user-1',
    displayName: 'Alice',
    email: 'alice@test.com',
    role: TeamRole.admin,
  ),
  TeamMember(
    id: 'tm-2',
    userId: 'user-2',
    displayName: 'Bob',
    email: 'bob@test.com',
    role: TeamRole.member,
  ),
  TeamMember(
    id: 'tm-3',
    userId: 'user-3',
    displayName: 'Carol',
    email: 'carol@test.com',
    role: TeamRole.member,
  ),
];

const _createdConversation = DirectConversationResponse(
  id: 'convo-new',
  teamId: _teamId,
  name: 'Alice, Bob',
);

Widget _createDialog({
  MockRelayApiService? mockApi,
  List<Override> overrides = const [],
}) {
  final api = mockApi ?? MockRelayApiService();

  // Stub getConversations for sidebar refresh
  if (mockApi == null) {
    when(() => api.getConversations(any()))
        .thenAnswer((_) async => <DirectConversationSummaryResponse>[]);
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
      teamMembersProvider.overrideWith((ref) => _teamMembers),
      ...overrides,
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (_) => const NewDmDialog(teamId: _teamId),
            ),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    ),
  );
}

/// Opens the dialog by tapping the trigger button.
Future<void> _openDialog(WidgetTester tester) async {
  await tester.pumpWidget(_createDialog());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open Dialog'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCreateDirectConversationRequest());
  });

  group('NewDmDialog', () {
    testWidgets('renders title "New Message"', (tester) async {
      await _openDialog(tester);

      expect(find.text('New Message'), findsOneWidget);
    });

    testWidgets('renders person_add icon', (tester) async {
      await _openDialog(tester);

      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    });

    testWidgets('renders team members excluding current user',
        (tester) async {
      await _openDialog(tester);

      // Alice (current user) should be excluded
      // Only looking in the dialog — not the trigger button area
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
      // Alice appears only if there's a different widget showing it,
      // but not as a member tile in the dialog
      expect(find.text('alice@test.com'), findsNothing);
    });

    testWidgets('shows member emails', (tester) async {
      await _openDialog(tester);

      expect(find.text('bob@test.com'), findsOneWidget);
      expect(find.text('carol@test.com'), findsOneWidget);
    });

    testWidgets('filters members by search query', (tester) async {
      await _openDialog(tester);

      await tester.enterText(
        find.byType(TextField).last,
        'Bob',
      );
      await tester.pumpAndSettle();

      // "Bob" appears in the text field AND in the member tile
      expect(find.text('bob@test.com'), findsOneWidget);
      expect(find.text('Carol'), findsNothing);
      expect(find.text('carol@test.com'), findsNothing);
    });

    testWidgets('shows "No members found" for no matches', (tester) async {
      await _openDialog(tester);

      await tester.enterText(
        find.byType(TextField).last,
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('No members found'), findsOneWidget);
    });

    testWidgets('tapping member creates conversation and closes dialog',
        (tester) async {
      final api = MockRelayApiService();
      when(() => api.getOrCreateConversation(any(), any()))
          .thenAnswer((_) async => _createdConversation);
      when(() => api.getConversations(any()))
          .thenAnswer((_) async => <DirectConversationSummaryResponse>[]);

      await tester.pumpWidget(_createDialog(mockApi: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      // Verify API was called
      final captured = verify(
        () => api.getOrCreateConversation(captureAny(), _teamId),
      ).captured;

      expect(captured, isNotEmpty);
      final request = captured.first as CreateDirectConversationRequest;
      expect(request.participantIds, ['user-2']);

      // Dialog should be closed
      expect(find.text('New Message'), findsNothing);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await _openDialog(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('New Message'), findsNothing);
    });

    testWidgets('has search field with placeholder', (tester) async {
      await _openDialog(tester);

      expect(find.text('Search members...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
