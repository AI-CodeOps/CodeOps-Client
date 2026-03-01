// Widget tests for LogTrapsPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/log_traps_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final traps = [
    LogTrapResponse(
      id: 'trap-1',
      name: 'Error Spike Detector',
      description: 'Detects error spikes',
      trapType: TrapType.pattern,
      isActive: true,
      teamId: teamId,
      createdBy: 'user-1',
      triggerCount: 5,
      conditions: [
        TrapConditionResponse(
          id: 'cond-1',
          conditionType: ConditionType.keyword,
          field: 'message',
          pattern: 'OutOfMemoryError',
        ),
      ],
    ),
    LogTrapResponse(
      id: 'trap-2',
      name: 'Frequency Alert',
      trapType: TrapType.frequency,
      isActive: false,
      teamId: teamId,
      createdBy: 'user-1',
      triggerCount: 0,
      conditions: [
        TrapConditionResponse(
          id: 'cond-2',
          conditionType: ConditionType.frequencyThreshold,
          field: 'message',
          threshold: 100,
          windowSeconds: 60,
        ),
      ],
    ),
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<LogTrapResponse>? trapList,
    bool loading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/traps',
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
            child: Scaffold(body: LogTrapsPage()),
          ),
        ),
        GoRoute(
          path: '/logger/traps/:id/edit',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Center(child: Text('Edit ${state.pathParameters['id']}')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Alerts')),
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
        loggerTrapsProvider.overrideWith((ref) {
          if (loading) {
            return Completer<List<LogTrapResponse>>().future;
          }
          return Future.value(trapList ?? traps);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LogTrapsPage', () {
    testWidgets('renders toolbar and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Log Traps'), findsOneWidget);
      expect(find.text('LOGGER'), findsOneWidget);
      expect(find.text('Create Trap'), findsOneWidget);
    });

    testWidgets('shows traps in table', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Spike Detector'), findsOneWidget);
      expect(find.text('Frequency Alert'), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      // 'Pattern' also appears as a trap type badge.
      expect(find.text('Pattern'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows toggle switches', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Two traps = two switches.
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('shows empty state when no team selected', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('shows empty state when no traps', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(trapList: []));
      await tester.pumpAndSettle();

      expect(find.text('No traps configured'), findsOneWidget);
    });
  });
}
