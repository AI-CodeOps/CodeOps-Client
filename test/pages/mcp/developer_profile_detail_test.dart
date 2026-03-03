// Widget tests for DeveloperProfileDetailPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/pages/mcp/developer_profile_detail_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/mcp_profile_providers.dart';

void main() {
  const profileId = 'dev-1';

  final profile = DeveloperProfile(
    id: profileId,
    displayName: 'Adam',
    bio: 'Full stack dev',
    timezone: 'America/Chicago',
    isActive: true,
    defaultEnvironment: McpEnvironment.local,
    userId: 'user-1',
    preferencesJson: '{"theme":"dark","editor":"vim"}',
  );

  final currentUser = User(id: 'user-1', email: 'adam@allard.com', displayName: 'Adam');

  Widget createWidget({
    bool isMyProfile = true,
    bool loading = false,
    bool notFound = false,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => isMyProfile ? currentUser : null),
        profileDetailProvider.overrideWith((ref, id) {
          if (loading) return Completer<DeveloperProfile?>().future;
          if (notFound) return Future.value(null);
          return Future.value(profile);
        }),
        profileSessionsProvider.overrideWith((ref, id) {
          return Future.value([
            McpSession(
              id: 'sess-1',
              status: SessionStatus.completed,
              projectName: 'CodeOps-Server',
              totalToolCalls: 15,
              startedAt: DateTime(2026, 3, 1, 10, 30),
            ),
            McpSession(
              id: 'sess-2',
              status: SessionStatus.failed,
              projectName: 'CodeOps-Client',
              totalToolCalls: 3,
              startedAt: DateTime(2026, 3, 2, 14, 0),
            ),
          ]);
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: DeveloperProfileDetailPage(profileId: profileId),
        ),
      ),
    );
  }

  group('DeveloperProfileDetailPage', () {
    testWidgets('renders profile name in header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Adam'), findsWidgets);
    });

    testWidgets('renders My Profile badge when own profile',
        (tester) async {
      await tester.pumpWidget(createWidget(isMyProfile: true));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('does not render My Profile badge for others',
        (tester) async {
      await tester.pumpWidget(createWidget(isMyProfile: false));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsNothing);
    });

    testWidgets('renders profile info fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profile Information'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Bio'), findsOneWidget);
      expect(find.text('Timezone'), findsOneWidget);
    });

    testWidgets('renders preferences editor', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('IDE Preferences'), findsOneWidget);
    });

    testWidgets('renders session history section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
      expect(find.text('CodeOps-Server'), findsOneWidget);
      expect(find.text('CodeOps-Client'), findsOneWidget);
    });

    testWidgets('renders token management link', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('API Tokens'), findsOneWidget);
      expect(find.text('Manage Tokens'), findsOneWidget);
    });
  });
}
