// Widget tests for HomePage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/project.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/pages/home_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/health_providers.dart';
import 'package:codeops/providers/job_providers.dart';
import 'package:codeops/providers/project_providers.dart';

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
        myJobsProvider.overrideWith((ref) => Future.value(<JobSummary>[])),
        teamProjectsProvider.overrideWith((ref) => Future.value(<Project>[])),
        teamMetricsProvider.overrideWith((ref) => Future.value(null)),
        ...overrides,
      ],
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    );
  }

  group('HomePage', () {
    testWidgets('shows greeting with user name', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should contain the user's name in the greeting
      expect(find.textContaining('Alice'), findsOneWidget);
    });

    testWidgets('shows time-based greeting', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should have one of Good morning/afternoon/evening
      final hasGreeting = find.textContaining('Good ');
      expect(hasGreeting, findsOneWidget);
    });

    testWidgets('renders quick start cards section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Run Audit'), findsOneWidget);
      expect(find.text('Investigate Bug'), findsOneWidget);
      expect(find.text('Compliance Check'), findsOneWidget);
      expect(find.text('Scan Dependencies'), findsOneWidget);
    });

    testWidgets('shows Recent Activity header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('shows Project Health header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Project Health'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.text('No projects yet'), findsOneWidget);
    });
  });
}
