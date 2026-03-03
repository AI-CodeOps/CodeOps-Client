// Widget tests for the unified HomePage dashboard.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/pages/home_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/dashboard_providers.dart';
import 'package:codeops/providers/fleet_providers.dart' hide selectedTeamIdProvider;
import 'package:codeops/providers/mcp_activity_providers.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/providers/team_providers.dart';

void main() {
  Widget createWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => const User(
            id: 'u1',
            email: 'test@test.com',
            displayName: 'Alice',
          ),
        ),
        selectedTeamIdProvider.overrideWith((ref) => 'team-1'),
        moduleHealthProvider.overrideWith((ref) => Future.value([
              const ModuleHealth(
                name: 'Registry',
                icon: Icons.app_registration_outlined,
                route: '/registry',
                status: ModuleHealthStatus.healthy,
                metric: '5 services',
              ),
              const ModuleHealth(
                name: 'Fleet',
                icon: Icons.dns_outlined,
                route: '/fleet',
                status: ModuleHealthStatus.degraded,
                metric: '3/5 running',
              ),
            ])),
        quickActionsProvider.overrideWithValue(const [
          QuickAction(
            label: 'Run Audit',
            icon: Icons.search_outlined,
            route: '/audit',
          ),
          QuickAction(
            label: 'New Request',
            icon: Icons.send_outlined,
            route: '/courier',
          ),
        ]),
        fleetHealthSummaryProvider('team-1').overrideWith(
          (ref) => Future.value(const FleetHealthSummary(
            totalContainers: 5,
            runningContainers: 3,
            stoppedContainers: 1,
            unhealthyContainers: 1,
            totalCpuPercent: 42.5,
            totalMemoryBytes: 1073741824,
          )),
        ),
        unreadCountsProvider('team-1').overrideWith(
          (ref) => Future.value(<UnreadCountResponse>[]),
        ),
        mcpActivityFeedProvider.overrideWith(
          (ref) => Future.value(PageResponse<ActivityFeedEntry>.empty()),
        ),
        ...overrides,
      ],
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    );
  }

  group('HomePage', () {
    testWidgets('shows greeting with user name', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Alice'), findsOneWidget);
    });

    testWidgets('shows time-based greeting', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Good '), findsOneWidget);
    });

    testWidgets('renders Module Health section', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Module Health'), findsOneWidget);
      expect(find.text('Registry'), findsOneWidget);
      expect(find.text('Fleet'), findsOneWidget);
    });

    testWidgets('renders Recent Activity section', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('renders Quick Actions panel', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Run Audit'), findsOneWidget);
      expect(find.text('New Request'), findsOneWidget);
    });

    testWidgets('renders Fleet Status section', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fleet Status'), findsOneWidget);
    });

    testWidgets('renders Relay Unread section', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Relay Unread'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byTooltip('Refresh dashboard'), findsOneWidget);
    });
  });
}
