// Widget tests for ModuleHealthCard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/providers/dashboard_providers.dart';
import 'package:codeops/widgets/home/module_health_card.dart';

void main() {
  Widget createWidget(ModuleHealth health, {String? navigatedTo}) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              body: Center(child: ModuleHealthCard(health: health)),
            ),
          ),
        ),
        GoRoute(
          path: '/registry',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Registry Page'))),
          ),
        ),
        GoRoute(
          path: '/fleet',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Fleet Page'))),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  const healthyModule = ModuleHealth(
    name: 'Registry',
    icon: Icons.app_registration_outlined,
    route: '/registry',
    status: ModuleHealthStatus.healthy,
    metric: '5 services',
  );

  const degradedModule = ModuleHealth(
    name: 'Fleet',
    icon: Icons.dns_outlined,
    route: '/fleet',
    status: ModuleHealthStatus.degraded,
    metric: '3/5 running',
  );

  const downModule = ModuleHealth(
    name: 'Logger',
    icon: Icons.receipt_long_outlined,
    route: '/logger',
    status: ModuleHealthStatus.down,
    metric: '0 sources',
  );

  const unknownModule = ModuleHealth(
    name: 'DataLens',
    icon: Icons.storage_outlined,
    route: '/datalens',
    status: ModuleHealthStatus.unknown,
    metric: '0 connections',
  );

  group('ModuleHealthCard', () {
    testWidgets('renders module name and metric', (tester) async {
      await tester.pumpWidget(createWidget(healthyModule));
      await tester.pumpAndSettle();

      expect(find.text('Registry'), findsOneWidget);
      expect(find.text('5 services'), findsOneWidget);
    });

    testWidgets('renders Healthy status badge', (tester) async {
      await tester.pumpWidget(createWidget(healthyModule));
      await tester.pumpAndSettle();

      expect(find.text('Healthy'), findsOneWidget);
    });

    testWidgets('renders Degraded status badge', (tester) async {
      await tester.pumpWidget(createWidget(degradedModule));
      await tester.pumpAndSettle();

      expect(find.text('Degraded'), findsOneWidget);
      expect(find.text('3/5 running'), findsOneWidget);
    });

    testWidgets('renders Down status badge', (tester) async {
      await tester.pumpWidget(createWidget(downModule));
      await tester.pumpAndSettle();

      expect(find.text('Down'), findsOneWidget);
    });

    testWidgets('renders Unknown status badge', (tester) async {
      await tester.pumpWidget(createWidget(unknownModule));
      await tester.pumpAndSettle();

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('renders module icon', (tester) async {
      await tester.pumpWidget(createWidget(healthyModule));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.app_registration_outlined), findsOneWidget);
    });

    testWidgets('navigates to module route on tap', (tester) async {
      await tester.pumpWidget(createWidget(healthyModule));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registry'));
      await tester.pumpAndSettle();

      expect(find.text('Registry Page'), findsOneWidget);
    });
  });
}
