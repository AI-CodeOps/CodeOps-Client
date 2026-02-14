import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/pages/job_report_page.dart';
import 'package:codeops/providers/job_providers.dart';
import 'package:codeops/providers/report_providers.dart';

void main() {
  final job = QaJob(
    id: 'job-1',
    projectId: 'p1',
    projectName: 'Test App',
    mode: JobMode.audit,
    status: JobStatus.completed,
    name: 'Audit Run #1',
    branch: 'main',
    overallResult: JobResult.pass,
    healthScore: 85,
    totalFindings: 5,
    criticalCount: 0,
    highCount: 1,
    mediumCount: 2,
    lowCount: 2,
  );

  final agentRun = AgentRun(
    id: 'r1',
    jobId: 'job-1',
    agentType: AgentType.security,
    status: AgentStatus.completed,
    result: AgentResult.pass,
    score: 92,
    findingsCount: 3,
    reportS3Key: 'reports/r1.md',
  );

  Widget createWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        jobDetailProvider(job.id).overrideWith((ref) => Future.value(job)),
        agentRunsByJobProvider(job.id)
            .overrideWith((ref) => Future.value([agentRun])),
        jobFindingsProvider((jobId: job.id, page: 0)).overrideWith(
            (ref) => Future.value(PageResponse<Finding>.empty())),
        projectTrendProvider((projectId: job.projectId, days: 30))
            .overrideWith(
                (ref) => Future.value(<HealthSnapshot>[])),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: JobReportPage(jobId: job.id),
        ),
      ),
    );
  }

  group('JobReportPage', () {
    testWidgets('shows report title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Report: Audit Run #1'), findsOneWidget);
    });

    testWidgets('shows Overview tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('shows agent tab names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The completed agent run is Security, so its tab should appear.
      expect(find.text('Security'), findsAtLeast(1));
    });
  });
}
