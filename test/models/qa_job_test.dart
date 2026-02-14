// Tests for QaJob and JobSummary model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('QaJob', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'job-1',
        'projectId': 'proj-1',
        'projectName': 'MyProject',
        'mode': 'AUDIT',
        'status': 'COMPLETED',
        'name': 'Audit Run 1',
        'branch': 'main',
        'overallResult': 'PASS',
        'healthScore': 85,
        'totalFindings': 10,
        'criticalCount': 0,
        'highCount': 2,
        'mediumCount': 3,
        'lowCount': 5,
        'createdAt': '2025-01-15T00:00:00.000Z',
      };
      final job = QaJob.fromJson(json);
      expect(job.mode, JobMode.audit);
      expect(job.status, JobStatus.completed);
      expect(job.overallResult, JobResult.pass);
      expect(job.healthScore, 85);
      expect(job.totalFindings, 10);
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'job-1',
        'projectId': 'proj-1',
        'mode': 'TECH_DEBT',
        'status': 'PENDING',
      };
      final job = QaJob.fromJson(json);
      expect(job.overallResult, isNull);
      expect(job.healthScore, isNull);
    });

    test('toJson round-trip preserves enums', () {
      final job = QaJob(
        id: 'j1',
        projectId: 'p1',
        mode: JobMode.bugInvestigate,
        status: JobStatus.running,
      );
      final json = job.toJson();
      expect(json['mode'], 'BUG_INVESTIGATE');
      expect(json['status'], 'RUNNING');
    });
  });

  group('JobSummary', () {
    test('fromJson with enums', () {
      final json = {
        'id': 'js-1',
        'mode': 'COMPLIANCE',
        'status': 'FAILED',
        'overallResult': 'FAIL',
        'healthScore': 30,
        'totalFindings': 25,
        'criticalCount': 5,
      };
      final summary = JobSummary.fromJson(json);
      expect(summary.mode, JobMode.compliance);
      expect(summary.status, JobStatus.failed);
      expect(summary.overallResult, JobResult.fail);
    });

    test('toJson round-trip', () {
      final summary = JobSummary(
        id: 's1',
        mode: JobMode.healthMonitor,
        status: JobStatus.completed,
      );
      final restored = JobSummary.fromJson(summary.toJson());
      expect(restored.mode, JobMode.healthMonitor);
    });
  });
}
