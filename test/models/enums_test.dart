// Tests for all 23 CodeOps enums.
//
// Verifies toJson(), fromJson() round-trips, displayName, and invalid input
// handling for every enum value.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('AgentResult', () {
    test('toJson returns correct server strings', () {
      expect(AgentResult.pass.toJson(), 'PASS');
      expect(AgentResult.warn.toJson(), 'WARN');
      expect(AgentResult.fail.toJson(), 'FAIL');
    });

    test('fromJson round-trips all values', () {
      for (final v in AgentResult.values) {
        expect(AgentResult.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(AgentResult.pass.displayName, 'Pass');
      expect(AgentResult.warn.displayName, 'Warning');
      expect(AgentResult.fail.displayName, 'Fail');
    });

    test('fromJson throws on invalid input', () {
      expect(() => AgentResult.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('AgentStatus', () {
    test('toJson returns correct server strings', () {
      expect(AgentStatus.pending.toJson(), 'PENDING');
      expect(AgentStatus.running.toJson(), 'RUNNING');
      expect(AgentStatus.completed.toJson(), 'COMPLETED');
      expect(AgentStatus.failed.toJson(), 'FAILED');
    });

    test('fromJson round-trips all values', () {
      for (final v in AgentStatus.values) {
        expect(AgentStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(AgentStatus.pending.displayName, 'Pending');
      expect(AgentStatus.running.displayName, 'Running');
      expect(AgentStatus.completed.displayName, 'Completed');
      expect(AgentStatus.failed.displayName, 'Failed');
    });

    test('fromJson throws on invalid input', () {
      expect(() => AgentStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('AgentType', () {
    test('toJson returns correct server strings', () {
      expect(AgentType.security.toJson(), 'SECURITY');
      expect(AgentType.codeQuality.toJson(), 'CODE_QUALITY');
      expect(AgentType.buildHealth.toJson(), 'BUILD_HEALTH');
      expect(AgentType.completeness.toJson(), 'COMPLETENESS');
      expect(AgentType.apiContract.toJson(), 'API_CONTRACT');
      expect(AgentType.testCoverage.toJson(), 'TEST_COVERAGE');
      expect(AgentType.uiUx.toJson(), 'UI_UX');
      expect(AgentType.documentation.toJson(), 'DOCUMENTATION');
      expect(AgentType.database.toJson(), 'DATABASE');
      expect(AgentType.performance.toJson(), 'PERFORMANCE');
      expect(AgentType.dependency.toJson(), 'DEPENDENCY');
      expect(AgentType.architecture.toJson(), 'ARCHITECTURE');
      expect(AgentType.chaosMonkey.toJson(), 'CHAOS_MONKEY');
      expect(AgentType.hostileUser.toJson(), 'HOSTILE_USER');
      expect(AgentType.complianceAuditor.toJson(), 'COMPLIANCE_AUDITOR');
      expect(AgentType.loadSaboteur.toJson(), 'LOAD_SABOTEUR');
    });

    test('fromJson round-trips all values', () {
      for (final v in AgentType.values) {
        expect(AgentType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(AgentType.codeQuality.displayName, 'Code Quality');
      expect(AgentType.uiUx.displayName, 'UI/UX');
      expect(AgentType.apiContract.displayName, 'API Contract');
    });

    test('fromJson throws on invalid input', () {
      expect(() => AgentType.fromJson('INVALID'), throwsArgumentError);
    });

    test('has all 16 values', () {
      expect(AgentType.values.length, 16);
    });

    test('adversarial types have correct displayNames', () {
      expect(AgentType.chaosMonkey.displayName, 'Chaos Monkey');
      expect(AgentType.hostileUser.displayName, 'Hostile User');
      expect(AgentType.complianceAuditor.displayName, 'Compliance Auditor');
      expect(AgentType.loadSaboteur.displayName, 'Load Saboteur');
    });

    test('tier classification counts', () {
      final core = AgentType.values.where((t) => t.isCore).toList();
      final conditional =
          AgentType.values.where((t) => t.isConditional).toList();
      final adversarial =
          AgentType.values.where((t) => t.isAdversarial).toList();
      expect(core.length, 4);
      expect(conditional.length, 8);
      expect(adversarial.length, 4);
      expect(core.length + conditional.length + adversarial.length, 16);
    });

    test('old v1.0 values do not exist', () {
      final names = AgentType.values.map((v) => v.toJson()).toSet();
      expect(names.contains('BEST_PRACTICES'), isFalse);
      expect(names.contains('ERROR_HANDLING'), isFalse);
      expect(names.contains('TESTING'), isFalse);
      expect(names.contains('ACCESSIBILITY'), isFalse);
      expect(names.contains('TYPE_SAFETY'), isFalse);
      expect(names.contains('MAINTAINABILITY'), isFalse);
    });
  });

  group('BusinessImpact', () {
    test('toJson returns correct server strings', () {
      expect(BusinessImpact.low.toJson(), 'LOW');
      expect(BusinessImpact.medium.toJson(), 'MEDIUM');
      expect(BusinessImpact.high.toJson(), 'HIGH');
      expect(BusinessImpact.critical.toJson(), 'CRITICAL');
    });

    test('fromJson round-trips all values', () {
      for (final v in BusinessImpact.values) {
        expect(BusinessImpact.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(BusinessImpact.critical.displayName, 'Critical');
    });

    test('fromJson throws on invalid input', () {
      expect(() => BusinessImpact.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('ComplianceStatus', () {
    test('toJson returns correct server strings', () {
      expect(ComplianceStatus.met.toJson(), 'MET');
      expect(ComplianceStatus.partial.toJson(), 'PARTIAL');
      expect(ComplianceStatus.missing.toJson(), 'MISSING');
      expect(ComplianceStatus.notApplicable.toJson(), 'NOT_APPLICABLE');
    });

    test('fromJson round-trips all values', () {
      for (final v in ComplianceStatus.values) {
        expect(ComplianceStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(ComplianceStatus.notApplicable.displayName, 'Not Applicable');
    });

    test('fromJson throws on invalid input', () {
      expect(() => ComplianceStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('DebtCategory', () {
    test('toJson returns correct server strings', () {
      expect(DebtCategory.architecture.toJson(), 'ARCHITECTURE');
      expect(DebtCategory.code.toJson(), 'CODE');
      expect(DebtCategory.test.toJson(), 'TEST');
      expect(DebtCategory.dependency.toJson(), 'DEPENDENCY');
      expect(DebtCategory.documentation.toJson(), 'DOCUMENTATION');
    });

    test('fromJson round-trips all values', () {
      for (final v in DebtCategory.values) {
        expect(DebtCategory.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(DebtCategory.architecture.displayName, 'Architecture');
    });

    test('fromJson throws on invalid input', () {
      expect(() => DebtCategory.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('DebtStatus', () {
    test('toJson returns correct server strings', () {
      expect(DebtStatus.identified.toJson(), 'IDENTIFIED');
      expect(DebtStatus.planned.toJson(), 'PLANNED');
      expect(DebtStatus.inProgress.toJson(), 'IN_PROGRESS');
      expect(DebtStatus.resolved.toJson(), 'RESOLVED');
    });

    test('fromJson round-trips all values', () {
      for (final v in DebtStatus.values) {
        expect(DebtStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(DebtStatus.inProgress.displayName, 'In Progress');
    });

    test('fromJson throws on invalid input', () {
      expect(() => DebtStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('DirectiveCategory', () {
    test('toJson returns correct server strings', () {
      expect(DirectiveCategory.architecture.toJson(), 'ARCHITECTURE');
      expect(DirectiveCategory.standards.toJson(), 'STANDARDS');
      expect(DirectiveCategory.conventions.toJson(), 'CONVENTIONS');
      expect(DirectiveCategory.context.toJson(), 'CONTEXT');
      expect(DirectiveCategory.other.toJson(), 'OTHER');
    });

    test('fromJson round-trips all values', () {
      for (final v in DirectiveCategory.values) {
        expect(DirectiveCategory.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(DirectiveCategory.standards.displayName, 'Standards');
    });

    test('fromJson throws on invalid input', () {
      expect(
          () => DirectiveCategory.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('DirectiveScope', () {
    test('toJson returns correct server strings', () {
      expect(DirectiveScope.team.toJson(), 'TEAM');
      expect(DirectiveScope.project.toJson(), 'PROJECT');
      expect(DirectiveScope.user.toJson(), 'USER');
    });

    test('fromJson round-trips all values', () {
      for (final v in DirectiveScope.values) {
        expect(DirectiveScope.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(DirectiveScope.project.displayName, 'Project');
    });

    test('fromJson throws on invalid input', () {
      expect(() => DirectiveScope.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('Effort', () {
    test('toJson returns correct server strings', () {
      expect(Effort.s.toJson(), 'S');
      expect(Effort.m.toJson(), 'M');
      expect(Effort.l.toJson(), 'L');
      expect(Effort.xl.toJson(), 'XL');
    });

    test('fromJson round-trips all values', () {
      for (final v in Effort.values) {
        expect(Effort.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(Effort.s.displayName, 'Small');
      expect(Effort.xl.displayName, 'Extra Large');
    });

    test('fromJson throws on invalid input', () {
      expect(() => Effort.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('FindingStatus', () {
    test('toJson returns correct server strings', () {
      expect(FindingStatus.open.toJson(), 'OPEN');
      expect(FindingStatus.acknowledged.toJson(), 'ACKNOWLEDGED');
      expect(FindingStatus.falsePositive.toJson(), 'FALSE_POSITIVE');
      expect(FindingStatus.fixed.toJson(), 'FIXED');
      expect(FindingStatus.wontFix.toJson(), 'WONT_FIX');
    });

    test('fromJson round-trips all values', () {
      for (final v in FindingStatus.values) {
        expect(FindingStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(FindingStatus.falsePositive.displayName, 'False Positive');
      expect(FindingStatus.wontFix.displayName, "Won't Fix");
    });

    test('fromJson throws on invalid input', () {
      expect(() => FindingStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('GitHubAuthType', () {
    test('toJson returns correct server strings', () {
      expect(GitHubAuthType.pat.toJson(), 'PAT');
      expect(GitHubAuthType.oauth.toJson(), 'OAUTH');
      expect(GitHubAuthType.ssh.toJson(), 'SSH');
    });

    test('fromJson round-trips all values', () {
      for (final v in GitHubAuthType.values) {
        expect(GitHubAuthType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(GitHubAuthType.pat.displayName, 'Personal Access Token');
    });

    test('fromJson throws on invalid input', () {
      expect(() => GitHubAuthType.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('InvitationStatus', () {
    test('toJson returns correct server strings', () {
      expect(InvitationStatus.pending.toJson(), 'PENDING');
      expect(InvitationStatus.accepted.toJson(), 'ACCEPTED');
      expect(InvitationStatus.expired.toJson(), 'EXPIRED');
    });

    test('fromJson round-trips all values', () {
      for (final v in InvitationStatus.values) {
        expect(InvitationStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(InvitationStatus.accepted.displayName, 'Accepted');
    });

    test('fromJson throws on invalid input', () {
      expect(
          () => InvitationStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('JobMode', () {
    test('toJson returns correct server strings', () {
      expect(JobMode.audit.toJson(), 'AUDIT');
      expect(JobMode.compliance.toJson(), 'COMPLIANCE');
      expect(JobMode.bugInvestigate.toJson(), 'BUG_INVESTIGATE');
      expect(JobMode.remediate.toJson(), 'REMEDIATE');
      expect(JobMode.techDebt.toJson(), 'TECH_DEBT');
      expect(JobMode.dependency.toJson(), 'DEPENDENCY');
      expect(JobMode.healthMonitor.toJson(), 'HEALTH_MONITOR');
    });

    test('fromJson round-trips all values', () {
      for (final v in JobMode.values) {
        expect(JobMode.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(JobMode.bugInvestigate.displayName, 'Bug Investigation');
      expect(JobMode.healthMonitor.displayName, 'Health Monitor');
    });

    test('fromJson throws on invalid input', () {
      expect(() => JobMode.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('JobResult', () {
    test('toJson returns correct server strings', () {
      expect(JobResult.pass.toJson(), 'PASS');
      expect(JobResult.warn.toJson(), 'WARN');
      expect(JobResult.fail.toJson(), 'FAIL');
    });

    test('fromJson round-trips all values', () {
      for (final v in JobResult.values) {
        expect(JobResult.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(JobResult.warn.displayName, 'Warning');
    });

    test('fromJson throws on invalid input', () {
      expect(() => JobResult.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('JobStatus', () {
    test('toJson returns correct server strings', () {
      expect(JobStatus.pending.toJson(), 'PENDING');
      expect(JobStatus.running.toJson(), 'RUNNING');
      expect(JobStatus.completed.toJson(), 'COMPLETED');
      expect(JobStatus.failed.toJson(), 'FAILED');
      expect(JobStatus.cancelled.toJson(), 'CANCELLED');
    });

    test('fromJson round-trips all values', () {
      for (final v in JobStatus.values) {
        expect(JobStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(JobStatus.cancelled.displayName, 'Cancelled');
    });

    test('fromJson throws on invalid input', () {
      expect(() => JobStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('Priority', () {
    test('toJson returns correct server strings', () {
      expect(Priority.p0.toJson(), 'P0');
      expect(Priority.p1.toJson(), 'P1');
      expect(Priority.p2.toJson(), 'P2');
      expect(Priority.p3.toJson(), 'P3');
    });

    test('fromJson round-trips all values', () {
      for (final v in Priority.values) {
        expect(Priority.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(Priority.p0.displayName, contains('Critical'));
    });

    test('fromJson throws on invalid input', () {
      expect(() => Priority.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('ScheduleType', () {
    test('toJson returns correct server strings', () {
      expect(ScheduleType.daily.toJson(), 'DAILY');
      expect(ScheduleType.weekly.toJson(), 'WEEKLY');
      expect(ScheduleType.onCommit.toJson(), 'ON_COMMIT');
    });

    test('fromJson round-trips all values', () {
      for (final v in ScheduleType.values) {
        expect(ScheduleType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(ScheduleType.onCommit.displayName, 'On Commit');
    });

    test('fromJson throws on invalid input', () {
      expect(() => ScheduleType.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('Scope', () {
    test('toJson returns correct server strings', () {
      expect(Scope.system.toJson(), 'SYSTEM');
      expect(Scope.team.toJson(), 'TEAM');
      expect(Scope.user.toJson(), 'USER');
    });

    test('fromJson round-trips all values', () {
      for (final v in Scope.values) {
        expect(Scope.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(Scope.system.displayName, 'System');
    });

    test('fromJson throws on invalid input', () {
      expect(() => Scope.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('Severity', () {
    test('toJson returns correct server strings', () {
      expect(Severity.critical.toJson(), 'CRITICAL');
      expect(Severity.high.toJson(), 'HIGH');
      expect(Severity.medium.toJson(), 'MEDIUM');
      expect(Severity.low.toJson(), 'LOW');
    });

    test('fromJson round-trips all values', () {
      for (final v in Severity.values) {
        expect(Severity.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(Severity.critical.displayName, 'Critical');
    });

    test('fromJson throws on invalid input', () {
      expect(() => Severity.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('SpecType', () {
    test('toJson returns correct server strings', () {
      expect(SpecType.openapi.toJson(), 'OPENAPI');
      expect(SpecType.markdown.toJson(), 'MARKDOWN');
      expect(SpecType.screenshot.toJson(), 'SCREENSHOT');
      expect(SpecType.figma.toJson(), 'FIGMA');
    });

    test('fromJson round-trips all values', () {
      for (final v in SpecType.values) {
        expect(SpecType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(SpecType.openapi.displayName, 'OpenAPI');
    });

    test('fromJson throws on invalid input', () {
      expect(() => SpecType.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('TaskStatus', () {
    test('toJson returns correct server strings', () {
      expect(TaskStatus.pending.toJson(), 'PENDING');
      expect(TaskStatus.assigned.toJson(), 'ASSIGNED');
      expect(TaskStatus.exported.toJson(), 'EXPORTED');
      expect(TaskStatus.jiraCreated.toJson(), 'JIRA_CREATED');
      expect(TaskStatus.completed.toJson(), 'COMPLETED');
    });

    test('fromJson round-trips all values', () {
      for (final v in TaskStatus.values) {
        expect(TaskStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(TaskStatus.jiraCreated.displayName, 'Jira Created');
    });

    test('fromJson throws on invalid input', () {
      expect(() => TaskStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('TeamRole', () {
    test('toJson returns correct server strings', () {
      expect(TeamRole.owner.toJson(), 'OWNER');
      expect(TeamRole.admin.toJson(), 'ADMIN');
      expect(TeamRole.member.toJson(), 'MEMBER');
      expect(TeamRole.viewer.toJson(), 'VIEWER');
    });

    test('fromJson round-trips all values', () {
      for (final v in TeamRole.values) {
        expect(TeamRole.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(TeamRole.owner.displayName, 'Owner');
    });

    test('fromJson throws on invalid input', () {
      expect(() => TeamRole.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('VulnerabilityStatus', () {
    test('toJson returns correct server strings', () {
      expect(VulnerabilityStatus.open.toJson(), 'OPEN');
      expect(VulnerabilityStatus.updating.toJson(), 'UPDATING');
      expect(VulnerabilityStatus.suppressed.toJson(), 'SUPPRESSED');
      expect(VulnerabilityStatus.resolved.toJson(), 'RESOLVED');
    });

    test('fromJson round-trips all values', () {
      for (final v in VulnerabilityStatus.values) {
        expect(VulnerabilityStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(VulnerabilityStatus.suppressed.displayName, 'Suppressed');
    });

    test('fromJson throws on invalid input', () {
      expect(
          () => VulnerabilityStatus.fromJson('INVALID'), throwsArgumentError);
    });
  });

  group('Label maps', () {
    test('agentTypeLabels has all 16 entries', () {
      expect(agentTypeLabels.length, 16);
      for (final v in AgentType.values) {
        expect(agentTypeLabels.containsKey(v), isTrue);
      }
    });

    test('severityLabels has all 4 entries', () {
      expect(severityLabels.length, 4);
      for (final v in Severity.values) {
        expect(severityLabels.containsKey(v), isTrue);
      }
    });

    test('jobModeLabels has all 7 entries', () {
      expect(jobModeLabels.length, 7);
    });

    test('jobStatusLabels has all 5 entries', () {
      expect(jobStatusLabels.length, 5);
    });

    test('priorityLabels has all 4 entries', () {
      expect(priorityLabels.length, 4);
    });

    test('findingStatusLabels has all 5 entries', () {
      expect(findingStatusLabels.length, 5);
    });
  });

  group('JsonConverter classes', () {
    test('AgentResultConverter round-trips', () {
      const c = AgentResultConverter();
      expect(c.fromJson('PASS'), AgentResult.pass);
      expect(c.toJson(AgentResult.pass), 'PASS');
    });

    test('AgentStatusConverter round-trips', () {
      const c = AgentStatusConverter();
      expect(c.fromJson('RUNNING'), AgentStatus.running);
      expect(c.toJson(AgentStatus.running), 'RUNNING');
    });

    test('AgentTypeConverter round-trips', () {
      const c = AgentTypeConverter();
      expect(c.fromJson('CODE_QUALITY'), AgentType.codeQuality);
      expect(c.toJson(AgentType.codeQuality), 'CODE_QUALITY');
    });

    test('SeverityConverter round-trips', () {
      const c = SeverityConverter();
      expect(c.fromJson('HIGH'), Severity.high);
      expect(c.toJson(Severity.high), 'HIGH');
    });

    test('JobModeConverter round-trips', () {
      const c = JobModeConverter();
      expect(c.fromJson('AUDIT'), JobMode.audit);
      expect(c.toJson(JobMode.audit), 'AUDIT');
    });

    test('TeamRoleConverter round-trips', () {
      const c = TeamRoleConverter();
      expect(c.fromJson('ADMIN'), TeamRole.admin);
      expect(c.toJson(TeamRole.admin), 'ADMIN');
    });
  });
}
