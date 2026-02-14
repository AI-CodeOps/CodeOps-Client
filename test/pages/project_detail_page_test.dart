// Widget tests for ProjectDetailPage.
//
// Verifies header, metrics cards, health trend, jobs table,
// repo info, Jira mapping, and directives sections.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/directive.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/project.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/pages/project_detail_page.dart';
import 'package:codeops/providers/directive_providers.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/providers/health_providers.dart';
import 'package:codeops/providers/project_providers.dart';

final _testProject = Project(
  id: 'proj-1',
  teamId: 'team-1',
  name: 'Test Project',
  repoFullName: 'owner/test-project',
  techStack: 'Spring Boot',
  healthScore: 85,
  repoUrl: 'https://github.com/owner/test-project.git',
  defaultBranch: 'main',
  jiraProjectKey: 'TP',
  jiraDefaultIssueType: 'Bug',
  jiraLabels: ['backend', 'codeops'],
  jiraComponent: 'API',
  isArchived: false,
);

final _testMetrics = ProjectMetrics(
  projectId: 'proj-1',
  totalJobs: 12,
  totalFindings: 45,
  openCritical: 2,
  openHigh: 5,
  techDebtItemCount: 8,
  openVulnerabilities: 3,
);

void main() {
  Widget createWidget({
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/projects/proj-1',
      routes: [
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) => const ProjectDetailPage(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/jobs/:id',
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/directives',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        projectProvider('proj-1')
            .overrideWith((ref) => Future.value(_testProject)),
        projectMetricsProvider('proj-1')
            .overrideWith((ref) => Future.value(_testMetrics)),
        projectHealthTrendProvider('proj-1')
            .overrideWith((ref) => Future.value(<HealthSnapshot>[])),
        projectRecentJobsProvider('proj-1').overrideWith(
            (ref) => Future.value(PageResponse<JobSummary>.empty())),
        projectDirectivesProvider('proj-1')
            .overrideWith((ref) => Future.value(<ProjectDirective>[])),
        githubConnectionsProvider
            .overrideWith((ref) => Future.value(<GitHubConnection>[])),
        jiraConnectionsProvider
            .overrideWith((ref) => Future.value(<JiraConnection>[])),
        ...overrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ProjectDetailPage', () {
    testWidgets('shows project name in header', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('shows repo full name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Appears in header and repository info card.
      expect(find.text('owner/test-project'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows tech stack badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Spring Boot'), findsOneWidget);
    });

    testWidgets('shows health score gauge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('85'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows metrics cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Total Jobs'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Total Findings'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Open Critical'), findsOneWidget);
      expect(find.text('Open High'), findsOneWidget);
      expect(find.text('Tech Debt Items'), findsOneWidget);
      expect(find.text('Vulnerabilities'), findsOneWidget);
    });

    testWidgets('shows Health Trend section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Health Trend'), findsOneWidget);
    });

    testWidgets('shows empty health trend message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No health data yet'), findsOneWidget);
    });

    testWidgets('shows Recent Jobs section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Jobs'), findsOneWidget);
    });

    testWidgets('shows No jobs yet when empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No jobs yet'), findsOneWidget);
    });

    testWidgets('shows Repository section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Repository'), findsOneWidget);
    });

    testWidgets('shows repo URL', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('https://github.com/owner/test-project.git'),
        findsOneWidget,
      );
    });

    testWidgets('shows Jira Mapping section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Jira Mapping'), findsOneWidget);
      expect(find.text('TP'), findsOneWidget);
    });

    testWidgets('shows Directives section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Directives'), findsOneWidget);
      expect(find.text('Manage Directives'), findsOneWidget);
    });

    testWidgets('shows No directives when empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No directives assigned'), findsOneWidget);
    });

    testWidgets('shows action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('shows favorite star', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });
  });
}
