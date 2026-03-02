// Widget tests for AlertChannelsPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/alert_channels_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final channels = [
    AlertChannelResponse(
      id: 'ch-1',
      name: 'Ops Email',
      channelType: AlertChannelType.email,
      configuration: '{"recipients":"ops@example.com","subject":"Alert"}',
      isActive: true,
      teamId: teamId,
      createdBy: 'user-1',
    ),
    AlertChannelResponse(
      id: 'ch-2',
      name: 'Slack Alerts',
      channelType: AlertChannelType.slack,
      configuration: '{"url":"https://hooks.slack.com/x","channel":"#alerts"}',
      isActive: false,
      teamId: teamId,
      createdBy: 'user-1',
    ),
    AlertChannelResponse(
      id: 'ch-3',
      name: 'PagerDuty Webhook',
      channelType: AlertChannelType.webhook,
      configuration: '{"url":"https://pd.example.com/hook","method":"POST"}',
      isActive: true,
      teamId: teamId,
      createdBy: 'user-1',
    ),
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<AlertChannelResponse>? channelList,
    bool loading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/alerts/channels',
      routes: [
        GoRoute(
          path: '/logger',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Dashboard'))),
          ),
        ),
        GoRoute(
          path: '/logger/viewer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Viewer')),
          ),
        ),
        GoRoute(
          path: '/logger/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Search')),
          ),
        ),
        GoRoute(
          path: '/logger/traps',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Traps')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Alerts')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts/channels',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: AlertChannelsPage()),
          ),
        ),
        GoRoute(
          path: '/logger/dashboards',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Dashboards')),
          ),
        ),
        GoRoute(
          path: '/logger/metrics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Metrics')),
          ),
        ),
        GoRoute(
          path: '/logger/traces',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Traces')),
          ),
        ),
        GoRoute(
          path: '/logger/traces/:correlationId',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Trace Detail')),
          ),
        ),
        GoRoute(
          path: '/logger/retention',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Retention')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        loggerAlertChannelsProvider.overrideWith((ref) {
          if (loading) {
            return Completer<List<AlertChannelResponse>>().future;
          }
          return Future.value(channelList ?? channels);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AlertChannelsPage', () {
    testWidgets('renders toolbar and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alert Channels'), findsOneWidget);
      expect(find.text('LOGGER'), findsOneWidget);
    });

    testWidgets('shows channel list', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ops Email'), findsOneWidget);
      expect(find.text('Slack Alerts'), findsOneWidget);
      expect(find.text('PagerDuty Webhook'), findsOneWidget);
    });

    testWidgets('shows create button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Channel'), findsOneWidget);
    });

    testWidgets('shows type icons', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Email, Slack, Webhook icons.
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tag), findsOneWidget);
      expect(find.byIcon(Icons.webhook_outlined), findsOneWidget);
    });

    testWidgets('shows active toggles', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 3 channels = 3 switches.
      expect(find.byType(Switch), findsNWidgets(3));
    });

    testWidgets('opens create dialog on button tap', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Channel'));
      await tester.pumpAndSettle();

      expect(find.text('Create Channel'), findsAtLeastNWidgets(1));
      expect(find.text('Channel Name'), findsOneWidget);
    });

    testWidgets('shows empty state when no channels', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(channelList: []));
      await tester.pumpAndSettle();

      expect(find.text('No channels configured'), findsOneWidget);
    });
  });
}
