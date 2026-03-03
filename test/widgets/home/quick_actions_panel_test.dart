// Widget tests for QuickActionsPanel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/providers/dashboard_providers.dart';
import 'package:codeops/widgets/home/quick_actions_panel.dart';

void main() {
  Widget createWidget({List<QuickAction>? actions}) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ProviderScope(
              overrides: [
                if (actions != null)
                  quickActionsProvider.overrideWithValue(actions),
              ],
              child: const Scaffold(body: QuickActionsPanel()),
            ),
          ),
        ),
        GoRoute(
          path: '/audit',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Audit Page'))),
          ),
        ),
        GoRoute(
          path: '/courier',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Courier Page'))),
          ),
        ),
        GoRoute(
          path: '/relay',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Relay Page'))),
          ),
        ),
        GoRoute(
          path: '/datalens',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('DataLens Page'))),
          ),
        ),
        GoRoute(
          path: '/courier/import',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Import Page'))),
          ),
        ),
        GoRoute(
          path: '/fleet/workstation-profiles',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Workstation Page'))),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('QuickActionsPanel', () {
    testWidgets('renders Quick Actions title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('renders all default actions', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Start Workstation'), findsOneWidget);
      expect(find.text('Run Audit'), findsOneWidget);
      expect(find.text('New Request'), findsOneWidget);
      expect(find.text('Open Relay'), findsOneWidget);
      expect(find.text('Open DataLens'), findsOneWidget);
      expect(find.text('New Collection'), findsOneWidget);
    });

    testWidgets('navigates to audit on tap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Run Audit'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Page'), findsOneWidget);
    });

    testWidgets('navigates to courier on New Request tap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Request'));
      await tester.pumpAndSettle();

      expect(find.text('Courier Page'), findsOneWidget);
    });

    testWidgets('navigates to relay on Open Relay tap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Relay'));
      await tester.pumpAndSettle();

      expect(find.text('Relay Page'), findsOneWidget);
    });

    testWidgets('navigates to datalens on Open DataLens tap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open DataLens'));
      await tester.pumpAndSettle();

      expect(find.text('DataLens Page'), findsOneWidget);
    });
  });
}
