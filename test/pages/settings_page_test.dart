// Widget tests for SettingsPage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/team.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/pages/settings_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/providers/health_providers.dart';
import 'package:codeops/providers/jira_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/utils/constants.dart';

void main() {
  Widget createWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => const User(
            id: 'u1',
            email: 'alice@test.com',
            displayName: 'Alice',
          ),
        ),
        selectedTeamProvider.overrideWith((ref) => Future.value(null)),
        teamMembersProvider.overrideWith(
          (ref) => Future.value(<TeamMember>[]),
        ),
        githubConnectionsProvider.overrideWith(
          (ref) => Future.value(<GitHubConnection>[]),
        ),
        jiraConnectionsProvider.overrideWith(
          (ref) => Future.value(<JiraConnection>[]),
        ),
        teamMetricsProvider.overrideWith((ref) => Future.value(null)),
        ...overrides,
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsPage())),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders section tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('Integrations'), findsOneWidget);
      expect(find.text('Agent Config'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('shows profile section by default', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Profile section content
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Change Password'), findsWidgets);
    });

    testWidgets('switches to agent config section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agent Config'));
      await tester.pumpAndSettle();

      expect(find.text('Agent Configuration'), findsOneWidget);
      expect(find.text('Claude Model'), findsOneWidget);
    });

    testWidgets('agent config section has sliders', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agent Config'));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('switches to about section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('App Version'), findsOneWidget);
      expect(find.text(AppConstants.appVersion), findsOneWidget);
      expect(find.text('Server URL'), findsOneWidget);
    });

    testWidgets('switches to appearance section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      expect(find.text('Font Density'), findsOneWidget);
      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Comfortable'), findsOneWidget);
    });

    testWidgets('switches to notifications section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Notifications'), findsWidgets);
      expect(find.text('In-App'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
