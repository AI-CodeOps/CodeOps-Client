// Tests that key model classes serialize/deserialize correctly
// with field names matching the server's OpenAPI spec.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/project.dart';
import 'package:codeops/models/qa_job.dart';

void main() {
  group('Model serialization', () {
    group('Project', () {
      final projectJson = <String, dynamic>{
        'id': 'proj-1',
        'teamId': 'team-1',
        'name': 'My Project',
        'description': 'A test project',
        'githubConnectionId': 'gh-1',
        'repoUrl': 'https://github.com/test/repo.git',
        'repoFullName': 'test/repo',
        'defaultBranch': 'main',
        'jiraConnectionId': 'jira-1',
        'jiraProjectKey': 'PROJ',
        'jiraDefaultIssueType': 'Bug',
        'jiraLabels': ['codeops', 'auto'],
        'jiraComponent': 'Backend',
        'techStack': 'Spring Boot, Java',
        'healthScore': 85,
        'lastAuditAt': '2025-01-15T12:00:00.000Z',
        'isArchived': false,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-15T12:00:00.000Z',
      };

      test('fromJson deserializes all fields correctly', () {
        final project = Project.fromJson(projectJson);

        expect(project.id, 'proj-1');
        expect(project.teamId, 'team-1');
        expect(project.name, 'My Project');
        expect(project.description, 'A test project');
        expect(project.githubConnectionId, 'gh-1');
        expect(project.repoUrl, 'https://github.com/test/repo.git');
        expect(project.repoFullName, 'test/repo');
        expect(project.defaultBranch, 'main');
        expect(project.jiraConnectionId, 'jira-1');
        expect(project.jiraProjectKey, 'PROJ');
        expect(project.jiraDefaultIssueType, 'Bug');
        expect(project.jiraLabels, ['codeops', 'auto']);
        expect(project.jiraComponent, 'Backend');
        expect(project.techStack, 'Spring Boot, Java');
        expect(project.healthScore, 85);
        expect(project.isArchived, false);
        expect(project.createdAt, isNotNull);
        expect(project.updatedAt, isNotNull);
      });

      test('toJson produces correct field names', () {
        final project = Project.fromJson(projectJson);
        final json = project.toJson();

        expect(json['id'], 'proj-1');
        expect(json['teamId'], 'team-1');
        expect(json['name'], 'My Project');
        expect(json.containsKey('githubConnectionId'), isTrue);
        expect(json.containsKey('repoFullName'), isTrue);
        expect(json.containsKey('jiraProjectKey'), isTrue);
      });

      test('does not contain removed fields (settingsJson, createdBy)', () {
        final project = Project.fromJson(projectJson);
        final json = project.toJson();

        expect(json.containsKey('settingsJson'), isFalse);
        expect(json.containsKey('createdBy'), isFalse);
      });

      test('handles null optional fields', () {
        final minimalJson = <String, dynamic>{
          'id': 'proj-2',
          'teamId': 'team-1',
          'name': 'Minimal',
        };

        final project = Project.fromJson(minimalJson);

        expect(project.id, 'proj-2');
        expect(project.description, isNull);
        expect(project.githubConnectionId, isNull);
        expect(project.healthScore, isNull);
      });
    });

    group('QaJob', () {
      final jobJson = <String, dynamic>{
        'id': 'job-1',
        'projectId': 'proj-1',
        'projectName': 'My Project',
        'mode': 'AUDIT',
        'status': 'COMPLETED',
        'name': 'Full Audit',
        'branch': 'main',
        'configJson': '{"agents":["SECURITY"]}',
        'summaryMd': '# Summary\nAll good.',
        'overallResult': 'PASS',
        'healthScore': 92,
        'totalFindings': 5,
        'criticalCount': 0,
        'highCount': 1,
        'mediumCount': 2,
        'lowCount': 2,
        'jiraTicketKey': 'PROJ-123',
        'startedBy': 'user-1',
        'startedByName': 'Adam',
        'startedAt': '2025-01-15T10:00:00.000Z',
        'completedAt': '2025-01-15T10:30:00.000Z',
        'createdAt': '2025-01-15T09:59:00.000Z',
      };

      test('fromJson deserializes all fields correctly', () {
        final job = QaJob.fromJson(jobJson);

        expect(job.id, 'job-1');
        expect(job.projectId, 'proj-1');
        expect(job.projectName, 'My Project');
        expect(job.mode, JobMode.audit);
        expect(job.status, JobStatus.completed);
        expect(job.configJson, '{"agents":["SECURITY"]}');
        expect(job.summaryMd, '# Summary\nAll good.');
        expect(job.overallResult, JobResult.pass);
        expect(job.healthScore, 92);
        expect(job.startedBy, 'user-1');
        expect(job.startedByName, 'Adam');
      });

      test('toJson produces correct field names', () {
        final job = QaJob.fromJson(jobJson);
        final json = job.toJson();

        expect(json['configJson'], '{"agents":["SECURITY"]}');
        expect(json['summaryMd'], '# Summary\nAll good.');
        expect(json['startedBy'], 'user-1');
        expect(json['startedByName'], 'Adam');
        expect(json['mode'], 'AUDIT');
        expect(json['status'], 'COMPLETED');
      });

      test('does not contain removed fields (summaryReportS3Key)', () {
        final job = QaJob.fromJson(jobJson);
        final json = job.toJson();

        expect(json.containsKey('summaryReportS3Key'), isFalse);
      });
    });

    group('Finding', () {
      final findingJson = <String, dynamic>{
        'id': 'f-1',
        'jobId': 'job-1',
        'agentType': 'SECURITY',
        'severity': 'HIGH',
        'title': 'SQL Injection Risk',
        'description': 'User input not sanitized',
        'filePath': 'src/main/java/Service.java',
        'lineNumber': 42,
        'recommendation': 'Use parameterized queries',
        'evidence': 'db.query(userInput)',
        'effortEstimate': 'M',
        'debtCategory': 'CODE',
        'status': 'OPEN',
        'statusChangedBy': 'user-1',
        'statusChangedAt': '2025-01-15T12:00:00.000Z',
        'createdAt': '2025-01-15T10:30:00.000Z',
      };

      test('fromJson deserializes all fields correctly', () {
        final finding = Finding.fromJson(findingJson);

        expect(finding.id, 'f-1');
        expect(finding.jobId, 'job-1');
        expect(finding.agentType, AgentType.security);
        expect(finding.severity, Severity.high);
        expect(finding.title, 'SQL Injection Risk');
        expect(finding.description, 'User input not sanitized');
        expect(finding.filePath, 'src/main/java/Service.java');
        expect(finding.lineNumber, 42);
        expect(finding.recommendation, 'Use parameterized queries');
        expect(finding.evidence, 'db.query(userInput)');
        expect(finding.effortEstimate, Effort.m);
        expect(finding.debtCategory, DebtCategory.code);
        expect(finding.status, FindingStatus.open);
        expect(finding.statusChangedBy, 'user-1');
        expect(finding.statusChangedAt, isNotNull);
      });

      test('toJson produces correct field names', () {
        final finding = Finding.fromJson(findingJson);
        final json = finding.toJson();

        expect(json['agentType'], 'SECURITY');
        expect(json['severity'], 'HIGH');
        expect(json['status'], 'OPEN');
        expect(json['statusChangedBy'], 'user-1');
        expect(json.containsKey('statusChangedAt'), isTrue);
        expect(json.containsKey('effortEstimate'), isTrue);
        expect(json.containsKey('debtCategory'), isTrue);
      });

      test('handles null optional fields', () {
        final minimalJson = <String, dynamic>{
          'id': 'f-2',
          'jobId': 'job-1',
          'agentType': 'CODE_QUALITY',
          'severity': 'LOW',
          'title': 'Unused import',
          'status': 'OPEN',
        };

        final finding = Finding.fromJson(minimalJson);

        expect(finding.description, isNull);
        expect(finding.filePath, isNull);
        expect(finding.lineNumber, isNull);
        expect(finding.statusChangedBy, isNull);
        expect(finding.statusChangedAt, isNull);
      });
    });

    group('HealthSnapshot', () {
      final snapshotJson = <String, dynamic>{
        'id': 'snap-1',
        'projectId': 'proj-1',
        'jobId': 'job-1',
        'healthScore': 78,
        'findingsBySeverity': '{"CRITICAL":1,"HIGH":3,"MEDIUM":5,"LOW":10}',
        'techDebtScore': 65,
        'dependencyScore': 90,
        'testCoveragePercent': 72.5,
        'capturedAt': '2025-01-15T12:00:00.000Z',
      };

      test('fromJson deserializes all fields correctly', () {
        final snapshot = HealthSnapshot.fromJson(snapshotJson);

        expect(snapshot.id, 'snap-1');
        expect(snapshot.projectId, 'proj-1');
        expect(snapshot.jobId, 'job-1');
        expect(snapshot.healthScore, 78);
        expect(snapshot.findingsBySeverity, isNotNull);
        expect(snapshot.techDebtScore, 65);
        expect(snapshot.dependencyScore, 90);
        expect(snapshot.testCoveragePercent, 72.5);
        expect(snapshot.capturedAt, isNotNull);
      });

      test('uses capturedAt not createdAt', () {
        final snapshot = HealthSnapshot.fromJson(snapshotJson);
        final json = snapshot.toJson();

        expect(json.containsKey('capturedAt'), isTrue);
      });

      test('handles null optional fields', () {
        final minimalJson = <String, dynamic>{
          'id': 'snap-2',
          'projectId': 'proj-1',
          'healthScore': 50,
        };

        final snapshot = HealthSnapshot.fromJson(minimalJson);

        expect(snapshot.jobId, isNull);
        expect(snapshot.techDebtScore, isNull);
        expect(snapshot.capturedAt, isNull);
      });
    });
  });
}
