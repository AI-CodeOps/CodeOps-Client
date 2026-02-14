// Tests for RemediationTask model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/remediation_task.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('RemediationTask', () {
    test('fromJson with all fields including list', () {
      final json = {
        'id': 'rt-1',
        'jobId': 'j-1',
        'taskNumber': 1,
        'title': 'Fix SQL injection',
        'description': 'Parameterize all queries',
        'findingIds': ['f-1', 'f-2'],
        'priority': 'P0',
        'status': 'PENDING',
        'assignedTo': 'u-1',
        'assignedToName': 'Alice',
      };
      final task = RemediationTask.fromJson(json);
      expect(task.priority, Priority.p0);
      expect(task.status, TaskStatus.pending);
      expect(task.findingIds, ['f-1', 'f-2']);
      expect(task.taskNumber, 1);
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'rt-2',
        'jobId': 'j-1',
        'taskNumber': 2,
        'title': 'Update docs',
        'status': 'COMPLETED',
      };
      final task = RemediationTask.fromJson(json);
      expect(task.priority, isNull);
      expect(task.findingIds, isNull);
    });

    test('toJson round-trip preserves enums', () {
      final task = RemediationTask(
        id: 't1',
        jobId: 'j1',
        taskNumber: 1,
        title: 'Fix it',
        priority: Priority.p2,
        status: TaskStatus.jiraCreated,
      );
      final json = task.toJson();
      expect(json['priority'], 'P2');
      expect(json['status'], 'JIRA_CREATED');
    });
  });
}
