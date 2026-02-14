// Tests for TaskGenerator.
//
// Verifies finding grouping, priority calculation, prompt generation,
// and batch task creation via IntegrationApi.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/models/remediation_task.dart';
import 'package:codeops/services/agent/task_generator.dart';
import 'package:codeops/services/cloud/integration_api.dart';

class MockIntegrationApi extends Mock implements IntegrationApi {}

void main() {
  late MockIntegrationApi mockIntegrationApi;
  late TaskGenerator taskGenerator;

  final securityFinding = const Finding(
    id: 'f1',
    jobId: 'job-1',
    agentType: AgentType.security,
    severity: Severity.high,
    title: 'SQL Injection',
    status: FindingStatus.open,
    filePath: 'src/main.dart',
    lineNumber: 42,
  );

  final mediumFinding = const Finding(
    id: 'f2',
    jobId: 'job-1',
    agentType: AgentType.security,
    severity: Severity.medium,
    title: 'Missing Input Validation',
    status: FindingStatus.open,
    filePath: 'src/main.dart',
    lineNumber: 100,
  );

  final criticalFinding = const Finding(
    id: 'f3',
    jobId: 'job-1',
    agentType: AgentType.security,
    severity: Severity.critical,
    title: 'Hardcoded Credentials',
    status: FindingStatus.open,
    filePath: 'src/config.dart',
    lineNumber: 10,
  );

  final lowFinding = const Finding(
    id: 'f4',
    jobId: 'job-1',
    agentType: AgentType.codeQuality,
    severity: Severity.low,
    title: 'Unused Import',
    status: FindingStatus.open,
    filePath: 'src/utils.dart',
    lineNumber: 5,
  );

  final noFileFinding = const Finding(
    id: 'f5',
    jobId: 'job-1',
    agentType: AgentType.documentation,
    severity: Severity.low,
    title: 'Missing README',
    status: FindingStatus.open,
  );

  setUp(() {
    mockIntegrationApi = MockIntegrationApi();
    taskGenerator = TaskGenerator(mockIntegrationApi);
  });

  group('TaskGenerator', () {
    // ---------------------------------------------------------------------
    // groupByFile
    // ---------------------------------------------------------------------

    group('groupByFile', () {
      test('groups findings with the same file path together', () {
        final groups = taskGenerator.groupByFile([
          securityFinding,
          mediumFinding,
        ]);

        expect(groups, hasLength(1));
        expect(groups.first.filePath, 'src/main.dart');
        expect(groups.first.findings, hasLength(2));
      });

      test('creates separate groups for different file paths', () {
        final groups = taskGenerator.groupByFile([
          securityFinding,
          criticalFinding,
          lowFinding,
        ]);

        expect(groups, hasLength(3));
        final paths = groups.map((g) => g.filePath).toSet();
        expect(paths, contains('src/main.dart'));
        expect(paths, contains('src/config.dart'));
        expect(paths, contains('src/utils.dart'));
      });

      test('groups findings without filePath under (no file)', () {
        final groups = taskGenerator.groupByFile([noFileFinding]);

        expect(groups, hasLength(1));
        expect(groups.first.filePath, '(no file)');
        expect(groups.first.findings, hasLength(1));
      });

      test('returns empty list for empty findings', () {
        final groups = taskGenerator.groupByFile([]);

        expect(groups, isEmpty);
      });

      test('mixes findings with and without file paths', () {
        final groups = taskGenerator.groupByFile([
          securityFinding,
          noFileFinding,
        ]);

        expect(groups, hasLength(2));
        final paths = groups.map((g) => g.filePath).toSet();
        expect(paths, contains('src/main.dart'));
        expect(paths, contains('(no file)'));
      });
    });

    // ---------------------------------------------------------------------
    // calculatePriority
    // ---------------------------------------------------------------------

    group('calculatePriority', () {
      test('returns P0 for critical severity findings', () {
        final priority = taskGenerator.calculatePriority([criticalFinding]);

        expect(priority, Priority.p0);
      });

      test('returns P1 for high severity findings', () {
        final priority = taskGenerator.calculatePriority([securityFinding]);

        expect(priority, Priority.p1);
      });

      test('returns P2 for medium severity findings', () {
        final priority = taskGenerator.calculatePriority([mediumFinding]);

        expect(priority, Priority.p2);
      });

      test('returns P3 for low severity findings', () {
        final priority = taskGenerator.calculatePriority([lowFinding]);

        expect(priority, Priority.p3);
      });

      test('returns highest priority when mixed severities', () {
        final priority = taskGenerator.calculatePriority([
          securityFinding,
          mediumFinding,
          lowFinding,
        ]);

        expect(priority, Priority.p1);
      });

      test('returns P0 when critical is among mixed severities', () {
        final priority = taskGenerator.calculatePriority([
          lowFinding,
          criticalFinding,
          mediumFinding,
        ]);

        expect(priority, Priority.p0);
      });
    });

    // ---------------------------------------------------------------------
    // generatePrompt
    // ---------------------------------------------------------------------

    group('generatePrompt', () {
      test('includes file path in prompt header', () {
        final group = FindingGroup(
          filePath: 'src/main.dart',
          findings: [securityFinding],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('# Remediation Task: src/main.dart'));
        expect(prompt, contains('`src/main.dart`'));
      });

      test('includes finding title and severity', () {
        final group = FindingGroup(
          filePath: 'src/main.dart',
          findings: [securityFinding],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('SQL Injection'));
        expect(prompt, contains('High'));
      });

      test('includes line number when present', () {
        final group = FindingGroup(
          filePath: 'src/main.dart',
          findings: [securityFinding],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('**Line:** 42'));
      });

      test('includes agent type display name', () {
        final group = FindingGroup(
          filePath: 'src/main.dart',
          findings: [securityFinding],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('Security'));
      });

      test('includes instructions section', () {
        final group = FindingGroup(
          filePath: 'src/main.dart',
          findings: [securityFinding],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('## Instructions'));
        expect(prompt, contains('recommended fixes'));
      });

      test('numbers multiple findings', () {
        final group = FindingGroup(
          filePath: 'src/main.dart',
          findings: [securityFinding, mediumFinding],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('### 1. SQL Injection'));
        expect(prompt, contains('### 2. Missing Input Validation'));
      });

      test('includes description when present', () {
        final findingWithDesc = const Finding(
          id: 'f10',
          jobId: 'job-1',
          agentType: AgentType.security,
          severity: Severity.high,
          title: 'Test Finding',
          description: 'Detailed description of the issue',
          status: FindingStatus.open,
          filePath: 'src/test.dart',
        );
        final group = FindingGroup(
          filePath: 'src/test.dart',
          findings: [findingWithDesc],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('Detailed description of the issue'));
      });

      test('includes recommendation when present', () {
        final findingWithRec = const Finding(
          id: 'f11',
          jobId: 'job-1',
          agentType: AgentType.security,
          severity: Severity.high,
          title: 'Test Finding',
          recommendation: 'Use parameterized queries',
          status: FindingStatus.open,
          filePath: 'src/test.dart',
        );
        final group = FindingGroup(
          filePath: 'src/test.dart',
          findings: [findingWithRec],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('Use parameterized queries'));
      });

      test('includes evidence when present', () {
        final findingWithEvidence = const Finding(
          id: 'f12',
          jobId: 'job-1',
          agentType: AgentType.security,
          severity: Severity.high,
          title: 'Test Finding',
          evidence: 'db.query("SELECT * FROM users WHERE id=" + userId)',
          status: FindingStatus.open,
          filePath: 'src/test.dart',
        );
        final group = FindingGroup(
          filePath: 'src/test.dart',
          findings: [findingWithEvidence],
        );

        final prompt = taskGenerator.generatePrompt(group);

        expect(prompt, contains('db.query'));
      });
    });

    // ---------------------------------------------------------------------
    // generateTasks
    // ---------------------------------------------------------------------

    group('generateTasks', () {
      test('returns empty list for empty findings', () async {
        final tasks = await taskGenerator.generateTasks(
          jobId: 'job-1',
          findings: [],
        );

        expect(tasks, isEmpty);
        verifyNever(() => mockIntegrationApi.createTasksBatch(any()));
      });

      test('calls createTasksBatch and returns created tasks', () async {
        when(() => mockIntegrationApi.createTasksBatch(any()))
            .thenAnswer((_) async => [
                  const RemediationTask(
                    id: 'task-1',
                    jobId: 'job-1',
                    taskNumber: 1,
                    title: 'Fix 1 finding in main.dart',
                    status: TaskStatus.pending,
                    priority: Priority.p1,
                    findingIds: ['f1'],
                  ),
                ]);

        final tasks = await taskGenerator.generateTasks(
          jobId: 'job-1',
          findings: [securityFinding],
        );

        expect(tasks, hasLength(1));
        expect(tasks.first.id, 'task-1');
        expect(tasks.first.priority, Priority.p1);

        verify(() => mockIntegrationApi.createTasksBatch(any())).called(1);
      });

      test('creates one task per file group', () async {
        when(() => mockIntegrationApi.createTasksBatch(any()))
            .thenAnswer((invocation) async {
          final payloads = invocation.positionalArguments[0]
              as List<Map<String, dynamic>>;
          return payloads
              .map((p) => RemediationTask(
                    id: 'task-${p['taskNumber']}',
                    jobId: p['jobId'] as String,
                    taskNumber: p['taskNumber'] as int,
                    title: p['title'] as String,
                    status: TaskStatus.pending,
                    priority: Priority.fromJson(p['priority'] as String),
                    findingIds: (p['findingIds'] as List<dynamic>)
                        .cast<String>(),
                  ))
              .toList();
        });

        final tasks = await taskGenerator.generateTasks(
          jobId: 'job-1',
          findings: [
            securityFinding,
            mediumFinding,
            criticalFinding,
          ],
        );

        // securityFinding & mediumFinding share src/main.dart,
        // criticalFinding is in src/config.dart
        expect(tasks, hasLength(2));
      });

      test('includes finding IDs in task payloads', () async {
        final capturedPayloads = <List<Map<String, dynamic>>>[];

        when(() => mockIntegrationApi.createTasksBatch(any()))
            .thenAnswer((invocation) async {
          final payloads = invocation.positionalArguments[0]
              as List<Map<String, dynamic>>;
          capturedPayloads.add(payloads);
          return [
            const RemediationTask(
              id: 'task-1',
              jobId: 'job-1',
              taskNumber: 1,
              title: 'Fix 2 findings in main.dart',
              status: TaskStatus.pending,
              findingIds: ['f1', 'f2'],
            ),
          ];
        });

        await taskGenerator.generateTasks(
          jobId: 'job-1',
          findings: [securityFinding, mediumFinding],
        );

        expect(capturedPayloads, hasLength(1));
        final payload = capturedPayloads.first.first;
        expect(payload['findingIds'], contains('f1'));
        expect(payload['findingIds'], contains('f2'));
      });

      test('assigns sequential task numbers', () async {
        final capturedPayloads = <List<Map<String, dynamic>>>[];

        when(() => mockIntegrationApi.createTasksBatch(any()))
            .thenAnswer((invocation) async {
          final payloads = invocation.positionalArguments[0]
              as List<Map<String, dynamic>>;
          capturedPayloads.add(payloads);
          return payloads
              .map((p) => RemediationTask(
                    id: 'task-${p['taskNumber']}',
                    jobId: p['jobId'] as String,
                    taskNumber: p['taskNumber'] as int,
                    title: p['title'] as String,
                    status: TaskStatus.pending,
                  ))
              .toList();
        });

        await taskGenerator.generateTasks(
          jobId: 'job-1',
          findings: [securityFinding, criticalFinding, lowFinding],
        );

        expect(capturedPayloads, hasLength(1));
        final numbers =
            capturedPayloads.first.map((p) => p['taskNumber']).toList();
        expect(numbers, contains(1));
        expect(numbers, contains(2));
        expect(numbers, contains(3));
      });
    });

    // ---------------------------------------------------------------------
    // FindingGroup
    // ---------------------------------------------------------------------

    group('FindingGroup', () {
      test('can be constructed with required fields', () {
        final group = FindingGroup(
          filePath: 'src/test.dart',
          findings: [securityFinding],
        );

        expect(group.filePath, 'src/test.dart');
        expect(group.findings, hasLength(1));
      });
    });
  });
}
