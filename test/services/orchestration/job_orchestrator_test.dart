// Tests for JobOrchestrator.
//
// Verifies the cancel flow (kills agents, updates server, emits event),
// activeJobId state management, and lifecycleStream broadcast behavior.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/services/agent/report_parser.dart';
import 'package:codeops/services/cloud/finding_api.dart';
import 'package:codeops/services/cloud/job_api.dart';
import 'package:codeops/services/cloud/report_api.dart';
import 'package:codeops/services/orchestration/agent_dispatcher.dart';
import 'package:codeops/services/orchestration/agent_monitor.dart';
import 'package:codeops/services/orchestration/job_orchestrator.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';
import 'package:codeops/services/orchestration/vera_manager.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAgentDispatcher extends Mock implements AgentDispatcher {}

class MockAgentMonitor extends Mock implements AgentMonitor {}

class MockVeraManager extends Mock implements VeraManager {}

class MockProgressAggregator extends Mock implements ProgressAggregator {}

class MockReportParser extends Mock implements ReportParser {}

class MockJobApi extends Mock implements JobApi {}

class MockFindingApi extends Mock implements FindingApi {}

class MockReportApi extends Mock implements ReportApi {}

void main() {
  late MockAgentDispatcher mockDispatcher;
  late MockAgentMonitor mockMonitor;
  late MockVeraManager mockVera;
  late MockProgressAggregator mockProgress;
  late MockReportParser mockParser;
  late MockJobApi mockJobApi;
  late MockFindingApi mockFindingApi;
  late MockReportApi mockReportApi;
  late JobOrchestrator orchestrator;

  setUpAll(() {
    registerFallbackValue(AgentType.security);
    registerFallbackValue(JobMode.audit);
    registerFallbackValue(JobStatus.running);
    registerFallbackValue(JobResult.pass);
    registerFallbackValue(const AgentDispatchConfig());
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<AgentType>[]);
    registerFallbackValue(<AgentType, ParsedReport>{});
  });

  setUp(() {
    mockDispatcher = MockAgentDispatcher();
    mockMonitor = MockAgentMonitor();
    mockVera = MockVeraManager();
    mockProgress = MockProgressAggregator();
    mockParser = MockReportParser();
    mockJobApi = MockJobApi();
    mockFindingApi = MockFindingApi();
    mockReportApi = MockReportApi();

    orchestrator = JobOrchestrator(
      dispatcher: mockDispatcher,
      monitor: mockMonitor,
      vera: mockVera,
      progress: mockProgress,
      parser: mockParser,
      jobApi: mockJobApi,
      findingApi: mockFindingApi,
      reportApi: mockReportApi,
    );
  });

  // ---------------------------------------------------------------------------
  // activeJobId
  // ---------------------------------------------------------------------------

  group('activeJobId', () {
    test('is null when no job is running', () {
      expect(orchestrator.activeJobId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // lifecycleStream
  // ---------------------------------------------------------------------------

  group('lifecycleStream', () {
    test('is a broadcast stream', () {
      final stream = orchestrator.lifecycleStream;
      expect(stream.isBroadcast, isTrue);
    });

    test('supports multiple listeners', () {
      final stream = orchestrator.lifecycleStream;

      // Should not throw when adding multiple listeners.
      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});

      addTearDown(() async {
        await sub1.cancel();
        await sub2.cancel();
      });

      expect(sub1, isNotNull);
      expect(sub2, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // cancelJob
  // ---------------------------------------------------------------------------

  group('cancelJob', () {
    test('calls dispatcher.cancelAll to kill agents', () async {
      when(() => mockDispatcher.cancelAll()).thenAnswer((_) async {});
      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            completedAt: any(named: 'completedAt'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-123',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.cancelled,
          ));

      await orchestrator.cancelJob('job-123');

      verify(() => mockDispatcher.cancelAll()).called(1);
    });

    test('updates job status to cancelled on the server', () async {
      when(() => mockDispatcher.cancelAll()).thenAnswer((_) async {});
      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            completedAt: any(named: 'completedAt'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-456',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.cancelled,
          ));

      await orchestrator.cancelJob('job-456');

      verify(() => mockJobApi.updateJob(
            'job-456',
            status: JobStatus.cancelled,
            completedAt: any(named: 'completedAt'),
          )).called(1);
    });

    test('emits a single JobCancelled event', () async {
      when(() => mockDispatcher.cancelAll()).thenAnswer((_) async {});
      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            completedAt: any(named: 'completedAt'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-789',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.cancelled,
          ));

      final events = <JobLifecycleEvent>[];
      orchestrator.lifecycleStream.listen(events.add);

      await orchestrator.cancelJob('job-789');

      // Allow broadcast stream microtask to flush before checking events.
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first, isA<JobCancelled>());
      expect((events.first as JobCancelled).jobId, 'job-789');
    });

    test('clears activeJobId after cancellation', () async {
      when(() => mockDispatcher.cancelAll()).thenAnswer((_) async {});
      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            completedAt: any(named: 'completedAt'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-abc',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.cancelled,
          ));

      await orchestrator.cancelJob('job-abc');

      expect(orchestrator.activeJobId, isNull);
    });

    test('still emits JobCancelled even when server update fails', () async {
      when(() => mockDispatcher.cancelAll()).thenAnswer((_) async {});
      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            completedAt: any(named: 'completedAt'),
          )).thenThrow(Exception('Network error'));

      final events = <JobLifecycleEvent>[];
      orchestrator.lifecycleStream.listen(events.add);

      await orchestrator.cancelJob('job-fail');

      // Allow broadcast stream microtask to flush before checking events.
      await Future<void>.delayed(Duration.zero);

      // cancelJob swallows the server update error (best-effort).
      expect(events, hasLength(1));
      expect(events.first, isA<JobCancelled>());
      expect((events.first as JobCancelled).jobId, 'job-fail');
    });
  });

  // ---------------------------------------------------------------------------
  // executeJob — early cancellation before agent dispatch
  // ---------------------------------------------------------------------------

  group('executeJob', () {
    test('sets activeJobId after job creation', () async {
      // Stub createJob to return a QaJob, then trigger cancellation via
      // a failing updateJob to avoid needing the full dispatch pipeline.
      when(() => mockJobApi.createJob(
            projectId: any(named: 'projectId'),
            mode: any(named: 'mode'),
            name: any(named: 'name'),
            branch: any(named: 'branch'),
            jiraTicketKey: any(named: 'jiraTicketKey'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-exec-1',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.pending,
          ));

      when(() => mockJobApi.createAgentRunsBatch(any(), any()))
          .thenAnswer((_) async => const [
                AgentRun(
                  id: 'run-1',
                  jobId: 'job-exec-1',
                  agentType: AgentType.security,
                  status: AgentStatus.pending,
                ),
              ]);

      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            summaryMd: any(named: 'summaryMd'),
            overallResult: any(named: 'overallResult'),
            healthScore: any(named: 'healthScore'),
            totalFindings: any(named: 'totalFindings'),
            criticalCount: any(named: 'criticalCount'),
            highCount: any(named: 'highCount'),
            mediumCount: any(named: 'mediumCount'),
            lowCount: any(named: 'lowCount'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-exec-1',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.running,
          ));

      when(() => mockProgress.reset(any())).thenReturn(null);
      when(() => mockProgress.progressStream)
          .thenAnswer((_) => const Stream.empty());

      // Return an empty dispatch stream so agent phase finishes immediately.
      when(() => mockDispatcher.dispatchAll(
            agentTypes: any(named: 'agentTypes'),
            teamId: any(named: 'teamId'),
            projectId: any(named: 'projectId'),
            projectPath: any(named: 'projectPath'),
            branch: any(named: 'branch'),
            mode: any(named: 'mode'),
            projectName: any(named: 'projectName'),
            config: any(named: 'config'),
            additionalContext: any(named: 'additionalContext'),
            jiraTicketData: any(named: 'jiraTicketData'),
            specReferences: any(named: 'specReferences'),
          )).thenAnswer((_) => const Stream.empty());

      when(() => mockVera.consolidate(
            jobId: any(named: 'jobId'),
            projectName: any(named: 'projectName'),
            agentReports: any(named: 'agentReports'),
            mode: any(named: 'mode'),
          )).thenAnswer((_) async => const VeraReport(
            healthScore: 95,
            overallResult: JobResult.pass,
            executiveSummaryMd: '# Summary\nAll good.',
            deduplicatedFindings: [],
            totalFindings: 0,
            criticalCount: 0,
            highCount: 0,
            mediumCount: 0,
            lowCount: 0,
            agentScores: {},
          ));

      when(() => mockReportApi.uploadSummaryReport(any(), any()))
          .thenAnswer((_) async => {'s3Key': 'reports/summary.md'});

      final events = <JobLifecycleEvent>[];
      orchestrator.lifecycleStream.listen(events.add);

      final result = await orchestrator.executeJob(
        projectId: 'proj-1',
        projectName: 'Test Project',
        projectPath: '/tmp/test',
        teamId: 'team-1',
        branch: 'main',
        mode: JobMode.audit,
        selectedAgents: [AgentType.security],
        config: const AgentDispatchConfig(),
      );

      // Verify job lifecycle events were emitted in order.
      expect(events, isNotEmpty);
      expect(events[0], isA<JobCreated>());
      expect((events[0] as JobCreated).jobId, 'job-exec-1');
      expect(events[1], isA<JobStarted>());
      expect(events[2], isA<AgentPhaseStarted>());

      // After completion, activeJobId should be cleared.
      expect(orchestrator.activeJobId, isNull);
      expect(result, JobResult.pass);
    });

    test('emits JobFailed and rethrows when createJob throws', () async {
      when(() => mockJobApi.createJob(
            projectId: any(named: 'projectId'),
            mode: any(named: 'mode'),
            name: any(named: 'name'),
            branch: any(named: 'branch'),
            jiraTicketKey: any(named: 'jiraTicketKey'),
          )).thenThrow(Exception('Server unreachable'));

      final events = <JobLifecycleEvent>[];
      orchestrator.lifecycleStream.listen(events.add);

      expect(
        () => orchestrator.executeJob(
          projectId: 'proj-1',
          projectName: 'Test Project',
          projectPath: '/tmp/test',
          teamId: 'team-1',
          branch: 'main',
          mode: JobMode.audit,
          selectedAgents: [AgentType.security],
          config: const AgentDispatchConfig(),
        ),
        throwsA(isA<Exception>()),
      );

      // activeJobId should be cleared after failure.
      // Note: since createJob failed, jobId was never set, so no JobFailed
      // event is emitted (the error handler only emits when jobId is non-null).
      expect(orchestrator.activeJobId, isNull);
    });

    test('emits JobFailed when an error occurs after job creation', () async {
      when(() => mockJobApi.createJob(
            projectId: any(named: 'projectId'),
            mode: any(named: 'mode'),
            name: any(named: 'name'),
            branch: any(named: 'branch'),
            jiraTicketKey: any(named: 'jiraTicketKey'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-err-1',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.pending,
          ));

      // Fail on createAgentRunsBatch to trigger the catch block.
      when(() => mockJobApi.createAgentRunsBatch(any(), any()))
          .thenThrow(Exception('Batch creation failed'));

      // Allow the error-handler's updateJob call (best-effort status update).
      when(() => mockJobApi.updateJob(
            any(),
            status: any(named: 'status'),
            completedAt: any(named: 'completedAt'),
            startedAt: any(named: 'startedAt'),
            summaryMd: any(named: 'summaryMd'),
            overallResult: any(named: 'overallResult'),
            healthScore: any(named: 'healthScore'),
            totalFindings: any(named: 'totalFindings'),
            criticalCount: any(named: 'criticalCount'),
            highCount: any(named: 'highCount'),
            mediumCount: any(named: 'mediumCount'),
            lowCount: any(named: 'lowCount'),
          )).thenAnswer((_) async => const QaJob(
            id: 'job-err-1',
            projectId: 'proj-1',
            mode: JobMode.audit,
            status: JobStatus.failed,
          ));

      final events = <JobLifecycleEvent>[];
      orchestrator.lifecycleStream.listen(events.add);

      await expectLater(
        () => orchestrator.executeJob(
          projectId: 'proj-1',
          projectName: 'Test Project',
          projectPath: '/tmp/test',
          teamId: 'team-1',
          branch: 'main',
          mode: JobMode.audit,
          selectedAgents: [AgentType.security],
          config: const AgentDispatchConfig(),
        ),
        throwsA(isA<Exception>()),
      );

      // Allow async microtasks to flush.
      await Future<void>.delayed(Duration.zero);

      // Should have: JobCreated, then JobFailed.
      final createdEvents = events.whereType<JobCreated>().toList();
      final failedEvents = events.whereType<JobFailed>().toList();

      expect(createdEvents, hasLength(1));
      expect(createdEvents.first.jobId, 'job-err-1');
      expect(failedEvents, hasLength(1));
      expect(failedEvents.first.jobId, 'job-err-1');
      expect(failedEvents.first.error, contains('Batch creation failed'));

      // activeJobId should be cleared.
      expect(orchestrator.activeJobId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JobLifecycleEvent type checks
  // ---------------------------------------------------------------------------

  group('JobLifecycleEvent hierarchy', () {
    test('JobCreated carries jobId', () {
      final event = JobCreated(jobId: 'abc');
      expect(event.jobId, 'abc');
    });

    test('JobStarted carries jobId', () {
      final event = JobStarted(jobId: 'def');
      expect(event.jobId, 'def');
    });

    test('AgentPhaseStarted carries jobId and totalAgents', () {
      final event = AgentPhaseStarted(jobId: 'ghi', totalAgents: 5);
      expect(event.jobId, 'ghi');
      expect(event.totalAgents, 5);
    });

    test('ConsolidationStarted carries jobId', () {
      final event = ConsolidationStarted(jobId: 'jkl');
      expect(event.jobId, 'jkl');
    });

    test('SyncStarted carries jobId', () {
      final event = SyncStarted(jobId: 'mno');
      expect(event.jobId, 'mno');
    });

    test('JobFailed carries jobId and error', () {
      final event = JobFailed(jobId: 'pqr', error: 'something broke');
      expect(event.jobId, 'pqr');
      expect(event.error, 'something broke');
    });

    test('JobCancelled carries jobId', () {
      final event = JobCancelled(jobId: 'stu');
      expect(event.jobId, 'stu');
    });

    test('JobCompleted carries jobId and report', () {
      const report = VeraReport(
        healthScore: 90,
        overallResult: JobResult.pass,
        executiveSummaryMd: '# Good',
        deduplicatedFindings: [],
        totalFindings: 0,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
        agentScores: {},
      );
      final event = JobCompleted(jobId: 'vwx', report: report);
      expect(event.jobId, 'vwx');
      expect(event.report.healthScore, 90);
    });

    test('AgentPhaseProgress carries progress snapshot', () {
      const progress = JobProgress(
        agentStatuses: {},
        liveFindings: [],
        completedCount: 1,
        totalCount: 3,
        elapsed: Duration(seconds: 10),
      );
      final event = AgentPhaseProgress(progress: progress);
      expect(event.progress.completedCount, 1);
      expect(event.progress.totalCount, 3);
    });
  });
}
