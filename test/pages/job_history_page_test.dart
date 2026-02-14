import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/pages/job_history_page.dart';
import 'package:codeops/providers/wizard_providers.dart';

void main() {
  final sampleJobs = [
    JobSummary(
      id: 'job-1',
      projectName: 'Frontend App',
      mode: JobMode.audit,
      status: JobStatus.completed,
      name: 'Audit #1',
      overallResult: JobResult.pass,
      healthScore: 92,
      totalFindings: 5,
      createdAt: DateTime(2026, 1, 15),
    ),
    JobSummary(
      id: 'job-2',
      projectName: 'Backend API',
      mode: JobMode.audit,
      status: JobStatus.running,
      name: 'Audit #2',
      healthScore: null,
      totalFindings: null,
      createdAt: DateTime(2026, 1, 16),
    ),
  ];

  Widget createWidget({
    List<JobSummary> jobs = const [],
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (_, __) => const Scaffold(body: JobHistoryPage()),
        ),
        GoRoute(
          path: '/audit',
          builder: (_, __) => const Scaffold(body: Text('Audit')),
        ),
        GoRoute(
          path: '/jobs/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Job ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        jobHistoryProvider.overrideWith((ref) => Future.value(jobs)),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('JobHistoryPage', () {
    testWidgets('shows page title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Job History'), findsOneWidget);
    });

    testWidgets('shows New Audit button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Audit'), findsOneWidget);
    });

    testWidgets('shows empty state when no jobs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(jobs: []));
      await tester.pumpAndSettle();

      expect(find.text('No jobs yet'), findsOneWidget);
    });

    testWidgets('shows job names in table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(jobs: sampleJobs));
      await tester.pumpAndSettle();

      expect(find.text('Audit #1'), findsOneWidget);
      expect(find.text('Audit #2'), findsOneWidget);
    });

    testWidgets('shows project names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(jobs: sampleJobs));
      await tester.pumpAndSettle();

      expect(find.text('Frontend App'), findsOneWidget);
      expect(find.text('Backend API'), findsOneWidget);
    });

    testWidgets('shows table headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(jobs: sampleJobs));
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Mode'), findsWidgets); // header + filter chip
      expect(find.text('Result'), findsWidgets); // header + filter chip
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Findings'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('shows health score for completed job', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(jobs: sampleJobs));
      await tester.pumpAndSettle();

      expect(find.text('92'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(jobs: sampleJobs));
      await tester.pumpAndSettle();

      // Filter chips for Mode, Status, Result
      expect(find.byType(Chip), findsAtLeast(3));
    });
  });
}
