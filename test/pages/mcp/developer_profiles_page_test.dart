// Widget tests for DeveloperProfilesPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/pages/mcp/developer_profiles_page.dart';
import 'package:codeops/providers/mcp_profile_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final profiles = [
    DeveloperProfile(
      id: 'dev-1',
      displayName: 'Adam',
      bio: 'Full stack developer specializing in Flutter and Spring Boot.',
      timezone: 'America/Chicago',
      isActive: true,
      defaultEnvironment: McpEnvironment.local,
      userId: 'user-1',
    ),
    DeveloperProfile(
      id: 'dev-2',
      displayName: 'Claude',
      bio: 'AI assistant',
      timezone: 'UTC',
      isActive: false,
      userId: 'user-2',
    ),
    DeveloperProfile(
      id: 'dev-3',
      userDisplayName: 'Bob',
      isActive: true,
      userId: 'user-3',
    ),
  ];

  Widget createWidget({
    bool hasTeam = true,
    bool loading = false,
    bool empty = false,
  }) {
    return ProviderScope(
      overrides: [
        if (hasTeam)
          selectedTeamIdProvider.overrideWith((ref) => teamId),
        if (!hasTeam)
          selectedTeamIdProvider.overrideWith((ref) => null),
        profileListProvider.overrideWith((ref) {
          if (loading) return Completer<List<DeveloperProfile>>().future;
          if (empty) return Future.value([]);
          return Future.value(profiles);
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DeveloperProfilesPage()),
      ),
    );
  }

  group('DeveloperProfilesPage', () {
    testWidgets('renders header with breadcrumb', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Developer Profiles'), findsOneWidget);
    });

    testWidgets('renders profile cards for all profiles', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Adam'), findsOneWidget);
      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('renders active and inactive badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsWidgets);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('renders bio preview', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Full stack developer specializing in Flutter and Spring Boot.'),
        findsOneWidget,
      );
    });

    testWidgets('renders no team state', (tester) async {
      await tester.pumpWidget(createWidget(hasTeam: false));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });
  });
}
