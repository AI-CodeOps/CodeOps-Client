// Tests for HealthSnapshot, HealthSchedule, and other models in
// health_snapshot.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('HealthSnapshot', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'hs-1',
        'projectId': 'p-1',
        'jobId': 'j-1',
        'healthScore': 85,
        'findingsBySeverity': '{"CRITICAL":0,"HIGH":2}',
        'techDebtScore': 70,
        'dependencyScore': 90,
        'testCoveragePercent': 78.5,
        'capturedAt': '2025-01-15T00:00:00.000Z',
      };
      final snap = HealthSnapshot.fromJson(json);
      expect(snap.healthScore, 85);
      expect(snap.testCoveragePercent, 78.5);
    });

    test('toJson round-trip', () {
      final snap = HealthSnapshot(
        id: 'h1',
        projectId: 'p1',
        healthScore: 92,
      );
      final restored = HealthSnapshot.fromJson(snap.toJson());
      expect(restored.healthScore, 92);
    });
  });

  group('HealthSchedule', () {
    test('fromJson with agent types list', () {
      final json = {
        'id': 'sched-1',
        'projectId': 'p-1',
        'scheduleType': 'WEEKLY',
        'agentTypes': ['SECURITY', 'CODE_QUALITY'],
        'isActive': true,
        'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final schedule = HealthSchedule.fromJson(json);
      expect(schedule.scheduleType, ScheduleType.weekly);
      expect(schedule.agentTypes, [AgentType.security, AgentType.codeQuality]);
      expect(schedule.isActive, true);
    });

    test('toJson round-trip', () {
      final schedule = HealthSchedule(
        id: 's1',
        projectId: 'p1',
        scheduleType: ScheduleType.onCommit,
        agentTypes: [AgentType.architecture],
      );
      final json = schedule.toJson();
      expect(json['scheduleType'], 'ON_COMMIT');
      expect(json['agentTypes'], ['ARCHITECTURE']);
    });
  });

  group('PageResponse', () {
    test('fromJson with generic type', () {
      final json = {
        'content': [
          {'id': 'hs-1', 'projectId': 'p-1', 'healthScore': 85},
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'isLast': true,
      };
      final page = PageResponse.fromJson(
        json,
        (obj) => HealthSnapshot.fromJson(obj as Map<String, dynamic>),
      );
      expect(page.content.length, 1);
      expect(page.totalElements, 1);
      expect(page.isLast, true);
    });
  });

  group('AuthResponse', () {
    test('fromJson with nested user', () {
      final json = {
        'token': 'jwt-token',
        'refreshToken': 'refresh-token',
        'user': {
          'id': 'u-1',
          'email': 'test@test.com',
          'displayName': 'Test',
        },
      };
      final auth = AuthResponse.fromJson(json);
      expect(auth.token, 'jwt-token');
      expect(auth.user.email, 'test@test.com');
    });

    test('toJson round-trip', () {
      final auth = AuthResponse(
        token: 't',
        refreshToken: 'r',
        user: User(id: 'u1', email: 'a@b.com', displayName: 'A'),
      );
      final restored = AuthResponse.fromJson(auth.toJson());
      expect(restored.token, 't');
      expect(restored.user.id, 'u1');
    });
  });

  group('TeamMetrics', () {
    test('fromJson', () {
      final json = {
        'teamId': 't-1',
        'totalProjects': 10,
        'totalJobs': 50,
        'totalFindings': 200,
        'averageHealthScore': 75.5,
        'projectsBelowThreshold': 2,
        'openCriticalFindings': 5,
      };
      final metrics = TeamMetrics.fromJson(json);
      expect(metrics.totalProjects, 10);
      expect(metrics.averageHealthScore, 75.5);
    });
  });

  group('ProjectMetrics', () {
    test('fromJson', () {
      final json = {
        'projectId': 'p-1',
        'projectName': 'MyProject',
        'currentHealthScore': 80,
        'previousHealthScore': 75,
        'totalJobs': 20,
        'totalFindings': 50,
        'openCritical': 1,
        'openHigh': 3,
        'techDebtItemCount': 8,
        'openVulnerabilities': 2,
      };
      final metrics = ProjectMetrics.fromJson(json);
      expect(metrics.currentHealthScore, 80);
      expect(metrics.openVulnerabilities, 2);
    });
  });

  group('GitHubConnection', () {
    test('fromJson', () {
      final json = {
        'id': 'gh-1',
        'teamId': 't-1',
        'name': 'My PAT',
        'authType': 'PAT',
        'githubUsername': 'octocat',
        'isActive': true,
      };
      final conn = GitHubConnection.fromJson(json);
      expect(conn.authType, GitHubAuthType.pat);
      expect(conn.isActive, true);
    });
  });

  group('JiraConnection', () {
    test('fromJson', () {
      final json = {
        'id': 'jc-1',
        'teamId': 't-1',
        'name': 'Jira Cloud',
        'instanceUrl': 'https://myorg.atlassian.net',
        'email': 'jira@test.com',
        'isActive': true,
      };
      final conn = JiraConnection.fromJson(json);
      expect(conn.instanceUrl, 'https://myorg.atlassian.net');
    });
  });

  group('BugInvestigation', () {
    test('fromJson', () {
      final json = {
        'id': 'bi-1',
        'jobId': 'j-1',
        'jiraKey': 'PROJ-123',
        'jiraSummary': 'Login fails',
        'rcaMd': '# Root Cause\nNull pointer.',
        'rcaPostedToJira': true,
        'fixTasksCreatedInJira': false,
      };
      final bug = BugInvestigation.fromJson(json);
      expect(bug.jiraKey, 'PROJ-123');
      expect(bug.rcaPostedToJira, true);
    });
  });

  group('SystemSetting', () {
    test('fromJson', () {
      final json = {
        'key': 'claude_model',
        'value': 'claude-sonnet-4-20250514',
      };
      final setting = SystemSetting.fromJson(json);
      expect(setting.key, 'claude_model');
    });
  });

  group('AuditLogEntry', () {
    test('fromJson', () {
      final json = {
        'id': 42,
        'userId': 'u-1',
        'userName': 'Alice',
        'action': 'CREATE_PROJECT',
        'entityType': 'Project',
        'entityId': 'p-1',
      };
      final entry = AuditLogEntry.fromJson(json);
      expect(entry.id, 42);
      expect(entry.action, 'CREATE_PROJECT');
    });
  });

  group('NotificationPreference', () {
    test('fromJson', () {
      final json = {
        'id': 'np-1',
        'userId': 'u-1',
        'eventType': 'JOB_COMPLETED',
        'inApp': true,
        'email': false,
      };
      final pref = NotificationPreference.fromJson(json);
      expect(pref.inApp, true);
      expect(pref.email, false);
    });

    test('toJson round-trip', () {
      final pref = NotificationPreference(
        id: 'np1',
        userId: 'u1',
        eventType: 'FINDING_CREATED',
        inApp: false,
        email: true,
      );
      final restored = NotificationPreference.fromJson(pref.toJson());
      expect(restored.eventType, 'FINDING_CREATED');
      expect(restored.email, true);
    });
  });
}
