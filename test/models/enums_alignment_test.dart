// Tests that every enum in enums.dart is aligned with the server OpenAPI spec.
//
// Verifies value count, toJson/fromJson round-trip, displayName non-empty,
// and SCREAMING_SNAKE_CASE JSON values for all 24 enums.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';

void main() {
  group('Enum alignment', () {
    group('AgentResult', () {
      const values = AgentResult.values;
      const jsonValues = ['PASS', 'WARN', 'FAIL'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(AgentResult.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => AgentResult.fromJson(json), returnsNormally);
        }
      });
    });

    group('AgentStatus', () {
      const values = AgentStatus.values;
      const jsonValues = ['PENDING', 'RUNNING', 'COMPLETED', 'FAILED'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(AgentStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => AgentStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('AgentType', () {
      const values = AgentType.values;
      const jsonValues = [
        'SECURITY',
        'CODE_QUALITY',
        'BUILD_HEALTH',
        'COMPLETENESS',
        'API_CONTRACT',
        'TEST_COVERAGE',
        'UI_UX',
        'DOCUMENTATION',
        'DATABASE',
        'PERFORMANCE',
        'DEPENDENCY',
        'ARCHITECTURE',
      ];

      test('has expected value count', () {
        expect(values, hasLength(12));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(AgentType.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => AgentType.fromJson(json), returnsNormally);
        }
      });
    });

    group('BusinessImpact', () {
      const values = BusinessImpact.values;
      const jsonValues = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(BusinessImpact.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => BusinessImpact.fromJson(json), returnsNormally);
        }
      });
    });

    group('ComplianceStatus', () {
      const values = ComplianceStatus.values;
      const jsonValues = ['MET', 'PARTIAL', 'MISSING', 'NOT_APPLICABLE'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(ComplianceStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => ComplianceStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('DebtCategory', () {
      const values = DebtCategory.values;
      const jsonValues = [
        'ARCHITECTURE',
        'CODE',
        'TEST',
        'DEPENDENCY',
        'DOCUMENTATION',
      ];

      test('has expected value count', () {
        expect(values, hasLength(5));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(DebtCategory.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => DebtCategory.fromJson(json), returnsNormally);
        }
      });
    });

    group('DebtStatus', () {
      const values = DebtStatus.values;
      const jsonValues = ['IDENTIFIED', 'PLANNED', 'IN_PROGRESS', 'RESOLVED'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(DebtStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => DebtStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('DirectiveCategory', () {
      const values = DirectiveCategory.values;
      const jsonValues = [
        'ARCHITECTURE',
        'STANDARDS',
        'CONVENTIONS',
        'CONTEXT',
        'OTHER',
      ];

      test('has expected value count', () {
        expect(values, hasLength(5));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(DirectiveCategory.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => DirectiveCategory.fromJson(json), returnsNormally);
        }
      });
    });

    group('DirectiveScope', () {
      const values = DirectiveScope.values;
      const jsonValues = ['TEAM', 'PROJECT', 'USER'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(DirectiveScope.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => DirectiveScope.fromJson(json), returnsNormally);
        }
      });
    });

    group('Effort', () {
      const values = Effort.values;
      const jsonValues = ['S', 'M', 'L', 'XL'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(Effort.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => Effort.fromJson(json), returnsNormally);
        }
      });
    });

    group('FindingStatus', () {
      const values = FindingStatus.values;
      const jsonValues = [
        'OPEN',
        'ACKNOWLEDGED',
        'FALSE_POSITIVE',
        'FIXED',
        'WONT_FIX',
      ];

      test('has expected value count', () {
        expect(values, hasLength(5));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(FindingStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => FindingStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('GitHubAuthType', () {
      const values = GitHubAuthType.values;
      const jsonValues = ['PAT', 'OAUTH', 'SSH'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(GitHubAuthType.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => GitHubAuthType.fromJson(json), returnsNormally);
        }
      });
    });

    group('InvitationStatus', () {
      const values = InvitationStatus.values;
      const jsonValues = ['PENDING', 'ACCEPTED', 'EXPIRED'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(InvitationStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => InvitationStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('JobMode', () {
      const values = JobMode.values;
      const jsonValues = [
        'AUDIT',
        'COMPLIANCE',
        'BUG_INVESTIGATE',
        'REMEDIATE',
        'TECH_DEBT',
        'DEPENDENCY',
        'HEALTH_MONITOR',
      ];

      test('has expected value count', () {
        expect(values, hasLength(7));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(JobMode.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => JobMode.fromJson(json), returnsNormally);
        }
      });
    });

    group('JobResult', () {
      const values = JobResult.values;
      const jsonValues = ['PASS', 'WARN', 'FAIL'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(JobResult.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => JobResult.fromJson(json), returnsNormally);
        }
      });
    });

    group('JobStatus', () {
      const values = JobStatus.values;
      const jsonValues = [
        'PENDING',
        'RUNNING',
        'COMPLETED',
        'FAILED',
        'CANCELLED',
      ];

      test('has expected value count', () {
        expect(values, hasLength(5));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(JobStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => JobStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('Priority', () {
      const values = Priority.values;
      const jsonValues = ['P0', 'P1', 'P2', 'P3'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(Priority.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => Priority.fromJson(json), returnsNormally);
        }
      });
    });

    group('ScheduleType', () {
      const values = ScheduleType.values;
      const jsonValues = ['DAILY', 'WEEKLY', 'ON_COMMIT'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(ScheduleType.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => ScheduleType.fromJson(json), returnsNormally);
        }
      });
    });

    group('Scope', () {
      const values = Scope.values;
      const jsonValues = ['SYSTEM', 'TEAM', 'USER'];

      test('has expected value count', () {
        expect(values, hasLength(3));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(Scope.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => Scope.fromJson(json), returnsNormally);
        }
      });
    });

    group('Severity', () {
      const values = Severity.values;
      const jsonValues = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(Severity.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => Severity.fromJson(json), returnsNormally);
        }
      });
    });

    group('SpecType', () {
      const values = SpecType.values;
      const jsonValues = ['OPENAPI', 'MARKDOWN', 'SCREENSHOT', 'FIGMA'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(SpecType.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => SpecType.fromJson(json), returnsNormally);
        }
      });
    });

    group('TaskStatus', () {
      const values = TaskStatus.values;
      const jsonValues = [
        'PENDING',
        'ASSIGNED',
        'EXPORTED',
        'JIRA_CREATED',
        'COMPLETED',
      ];

      test('has expected value count', () {
        expect(values, hasLength(5));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(TaskStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => TaskStatus.fromJson(json), returnsNormally);
        }
      });
    });

    group('TeamRole', () {
      const values = TeamRole.values;
      const jsonValues = ['OWNER', 'ADMIN', 'MEMBER', 'VIEWER'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(TeamRole.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => TeamRole.fromJson(json), returnsNormally);
        }
      });
    });

    group('VulnerabilityStatus', () {
      const values = VulnerabilityStatus.values;
      const jsonValues = ['OPEN', 'UPDATING', 'SUPPRESSED', 'RESOLVED'];

      test('has expected value count', () {
        expect(values, hasLength(4));
      });

      test('round-trips through toJson/fromJson', () {
        for (final v in values) {
          expect(VulnerabilityStatus.fromJson(v.toJson()), v);
        }
      });

      test('displayName is non-empty', () {
        for (final v in values) {
          expect(v.displayName, isNotEmpty);
        }
      });

      test('fromJson handles all server values', () {
        for (final json in jsonValues) {
          expect(() => VulnerabilityStatus.fromJson(json), returnsNormally);
        }
      });
    });
  });
}
