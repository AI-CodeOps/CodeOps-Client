// Tests for ExecutiveSummaryCard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/widgets/reports/executive_summary_card.dart';

void main() {
  final testJob = QaJob(
    id: 'j1',
    projectId: 'p1',
    projectName: 'Test Project',
    mode: JobMode.audit,
    status: JobStatus.completed,
    name: 'Audit Run',
    healthScore: 85,
    totalFindings: 10,
    criticalCount: 1,
    highCount: 3,
    mediumCount: 4,
    lowCount: 2,
    overallResult: JobResult.pass,
  );

  final testAgentRuns = <AgentRun>[
    const AgentRun(
      id: 'ar1',
      jobId: 'j1',
      agentType: AgentType.security,
      status: AgentStatus.completed,
      result: AgentResult.pass,
      score: 90,
    ),
    const AgentRun(
      id: 'ar2',
      jobId: 'j1',
      agentType: AgentType.codeQuality,
      status: AgentStatus.completed,
      result: AgentResult.warn,
      score: 75,
    ),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('ExecutiveSummaryCard', () {
    testWidgets('renders job name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Audit Run'), findsOneWidget);
    });

    testWidgets('shows health score', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      // Allow gauge animation to complete.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('shows severity counts in bar chart', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      // SeverityChart in bar mode renders severity display names.
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('renders agent display names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Code Quality'), findsOneWidget);
    });

    testWidgets('shows project name meta chip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('shows overall result badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Pass'), findsOneWidget);
    });

    testWidgets('renders agent scores', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ExecutiveSummaryCard(job: testJob, agentRuns: testAgentRuns),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('90'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });
  });
}
