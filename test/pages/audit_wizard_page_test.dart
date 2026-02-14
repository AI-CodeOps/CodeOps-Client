import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/pages/audit_wizard_page.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/widgets/wizard/wizard_scaffold.dart';

void main() {
  Widget createWidget({List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: '/audit',
      routes: [
        GoRoute(
          path: '/audit',
          builder: (_, __) => const Scaffold(body: AuditWizardPage()),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/jobs/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Job ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/history',
          builder: (_, __) => const Scaffold(body: Text('History')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        teamProjectsProvider.overrideWith((ref) => Future.value([])),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('AuditWizardPage', () {
    testWidgets('shows Audit Wizard title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Audit Wizard'), findsOneWidget);
    });

    testWidgets('shows WizardScaffold', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(WizardScaffold), findsOneWidget);
    });

    testWidgets('shows 4 step titles in sidebar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Configuration'), findsWidgets);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('starts on first step (Source)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Source'), findsOneWidget);
    });

    testWidgets('shows Cancel button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
