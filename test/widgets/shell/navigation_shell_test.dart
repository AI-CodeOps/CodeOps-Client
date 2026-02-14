// Widget tests for NavigationShell.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/team.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/settings_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/widgets/shell/navigation_shell.dart';

Widget _createShell({
  TeamRole userRole = TeamRole.owner,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Center(child: Text('Home Content')),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Center(child: Text('Settings Content')),
            ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Center(child: Text('Admin Content')),
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      sidebarCollapsedProvider.overrideWith((ref) => false),
      currentUserProvider.overrideWith(
        (ref) => const User(
          id: 'u1',
          email: 'test@test.com',
          displayName: 'Test User',
        ),
      ),
      teamMembersProvider.overrideWith(
        (ref) => Future.value([
          TeamMember(
            id: 'm1',
            userId: 'u1',
            displayName: 'Test User',
            role: userRole,
          ),
        ]),
      ),
      teamsProvider.overrideWith((ref) => Future.value(<Team>[])),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('NavigationShell', () {
    Future<void> setupSize(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
    }

    tearDown(() {
      // Reset is handled per test via addTearDown
    });

    testWidgets('renders sidebar section headers', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell());
      await tester.pumpAndSettle();

      expect(find.text('NAVIGATE'), findsOneWidget);
      expect(find.text('SOURCE'), findsOneWidget);
      expect(find.text('ANALYZE'), findsOneWidget);
      expect(find.text('MAINTAIN'), findsOneWidget);
      expect(find.text('MONITOR'), findsOneWidget);
      expect(find.text('TEAM'), findsOneWidget);
    });

    testWidgets('renders nav items', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Audit'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders CodeOps logo text', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell());
      await tester.pumpAndSettle();

      expect(find.text('CodeOps'), findsOneWidget);
    });

    testWidgets('renders child content', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell());
      await tester.pumpAndSettle();

      expect(find.text('Home Content'), findsOneWidget);
    });

    testWidgets('shows Admin link for OWNER role', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell(userRole: TeamRole.owner));
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('hides Admin link for MEMBER role', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell(userRole: TeamRole.member));
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsNothing);
    });

    testWidgets('shows user display name', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell());
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('collapse toggle exists', (tester) async {
      await setupSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_createShell());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });
  });
}
