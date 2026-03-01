// Widget tests for LoggerSidebar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/widgets/logger/logger_sidebar.dart';

void main() {
  Widget createSidebar({String initialLocation = '/logger'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/logger',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Row(
              children: [
                const LoggerSidebar(),
                const Expanded(child: Center(child: Text('Dashboard Content'))),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/logger/viewer',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Row(
              children: [
                const LoggerSidebar(),
                const Expanded(child: Center(child: Text('Viewer Content'))),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/logger/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
        GoRoute(
          path: '/logger/traps',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
        GoRoute(
          path: '/logger/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
        GoRoute(
          path: '/logger/dashboards',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
        GoRoute(
          path: '/logger/metrics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
        GoRoute(
          path: '/logger/traces',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
        GoRoute(
          path: '/logger/retention',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoggerSidebar(),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('LoggerSidebar', () {
    testWidgets('renders sidebar with section header', (tester) async {
      await tester.pumpWidget(createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('LOGGER'), findsOneWidget);
    });

    testWidgets('shows all 9 nav items', (tester) async {
      await tester.pumpWidget(createSidebar());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Log Viewer'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Traps'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Dashboards'), findsOneWidget);
      expect(find.text('Metrics'), findsOneWidget);
      expect(find.text('Traces'), findsOneWidget);
      expect(find.text('Retention'), findsOneWidget);
    });

    testWidgets('Dashboard item highlighted when on /logger', (tester) async {
      await tester.pumpWidget(createSidebar(initialLocation: '/logger'));
      await tester.pumpAndSettle();

      // Dashboard should be highlighted — find its text widget and verify
      // it is inside a container with the active decoration.
      final dashboardText = find.text('Dashboard');
      expect(dashboardText, findsOneWidget);

      // The active nav item has font weight w500.
      final textWidget = tester.widget<Text>(dashboardText);
      expect(textWidget.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('tapping nav item navigates to correct path', (tester) async {
      await tester.pumpWidget(createSidebar(initialLocation: '/logger'));
      await tester.pumpAndSettle();

      // Tap "Log Viewer" nav item
      await tester.tap(find.text('Log Viewer'));
      await tester.pumpAndSettle();

      // Should now show viewer content
      expect(find.text('Viewer Content'), findsOneWidget);
    });
  });
}
