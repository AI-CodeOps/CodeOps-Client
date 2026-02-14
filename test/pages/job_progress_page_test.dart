import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/pages/job_progress_page.dart';
import 'package:codeops/providers/agent_providers.dart';
import 'package:codeops/providers/job_providers.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';

void main() {
  final completedJob = QaJob(
    id: 'job-1',
    projectId: 'p1',
    projectName: 'Frontend App',
    mode: JobMode.audit,
    status: JobStatus.completed,
    name: 'Audit Run #1',
    branch: 'main',
    overallResult: JobResult.pass,
    healthScore: 92,
    totalFindings: 5,
    criticalCount: 0,
    highCount: 1,
    mediumCount: 2,
    lowCount: 2,
    startedAt: DateTime(2026, 1, 1, 10, 0),
    completedAt: DateTime(2026, 1, 1, 10, 15),
    createdAt: DateTime(2026, 1, 1, 10, 0),
  );

  final runningJob = QaJob(
    id: 'job-2',
    projectId: 'p1',
    projectName: 'Frontend App',
    mode: JobMode.audit,
    status: JobStatus.running,
    name: 'Audit Run #2',
    branch: 'develop',
    startedAt: DateTime(2026, 1, 1, 10, 0),
    createdAt: DateTime(2026, 1, 1, 10, 0),
  );

  const emptyProgress = JobProgress(
    agentStatuses: {},
    liveFindings: [],
    completedCount: 0,
    totalCount: 0,
    elapsed: Duration.zero,
  );

  Widget createWidget({
    required QaJob job,
    JobProgress progress = emptyProgress,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        jobDetailProvider(job.id).overrideWith((ref) => Future.value(job)),
        jobProgressProvider.overrideWith((ref) {
          final controller = StreamController<JobProgress>();
          controller.add(progress);
          ref.onDispose(() => controller.close());
          return controller.stream;
        }),
        jobLifecycleProvider.overrideWith((ref) {
          // Return a stream that never emits, so lifecycle doesn't interfere.
          final controller = StreamController<Never>();
          ref.onDispose(() => controller.close());
          return controller.stream;
        }),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: JobProgressPage(jobId: job.id),
        ),
      ),
    );
  }

  group('JobProgressPage', () {
    testWidgets('shows job name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: completedJob));
      // Use pump() instead of pumpAndSettle() because the page has Timer.periodic.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Audit Run #1'), findsOneWidget);
    });

    testWidgets('shows mode badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: completedJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Audit'), findsAtLeast(1));
    });

    testWidgets('shows branch name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: completedJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('shows health score for completed job', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: completedJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('92'), findsOneWidget);
    });

    testWidgets('shows Pass result for completed job', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: completedJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pass'), findsOneWidget);
    });

    testWidgets('shows View Report and View Findings buttons for completed job',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: completedJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('View Report'), findsOneWidget);
      expect(find.text('View Findings'), findsOneWidget);
    });

    testWidgets('shows Cancel button for running job', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: runningJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows PhaseIndicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(job: runningJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Phase indicator shows phase labels like 'Creating', 'Dispatching', etc.
      expect(find.text('Creating'), findsOneWidget);
    });
  });
}
