import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/pages/findings_explorer_page.dart';
import 'package:codeops/providers/finding_providers.dart';
import 'package:codeops/providers/job_providers.dart' show jobDetailProvider;

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

  final finding = Finding(
    id: 'f1',
    jobId: 'job-1',
    agentType: AgentType.security,
    severity: Severity.high,
    title: 'SQL Injection Risk',
    status: FindingStatus.open,
    filePath: 'src/main.dart',
    lineNumber: 42,
  );

  Widget createWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        jobDetailProvider(job.id).overrideWith((ref) => Future.value(job)),
        jobFindingsProvider((jobId: job.id, page: 0)).overrideWith(
          (ref) => Future.value(PageResponse<Finding>(
            content: [finding],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            isLast: true,
          )),
        ),
        findingSeverityCountsProvider(job.id).overrideWith(
          (ref) => Future.value(<String, dynamic>{
            'CRITICAL': 0,
            'HIGH': 1,
            'MEDIUM': 0,
            'LOW': 0,
          }),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FindingsExplorerPage(jobId: job.id),
        ),
      ),
    );
  }

  group('FindingsExplorerPage', () {
    testWidgets('shows Findings title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Findings: Audit Run #1'), findsOneWidget);
    });

    testWidgets('renders findings table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The finding title should appear in the table.
      expect(find.text('SQL Injection Risk'), findsOneWidget);
    });

    testWidgets('shows filter bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The severity filter bar renders severity chip labels with counts.
      expect(find.text('Critical (0)'), findsOneWidget);
      expect(find.text('High (1)'), findsOneWidget);
    });
  });
}
