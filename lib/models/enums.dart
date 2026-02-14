/// All CodeOps domain enumerations.
///
/// Every enum value matches the CodeOps-Server API string representation exactly.
/// Server stores all enums as `@Enumerated(EnumType.STRING)` in PostgreSQL.
///
/// Each enum provides:
/// - [toJson] returning the server's SCREAMING_SNAKE_CASE string
/// - [fromJson] factory parsing that string back
/// - [displayName] returning a human-friendly label
library;

import 'package:json_annotation/json_annotation.dart';

// ---------------------------------------------------------------------------
// AgentResult
// ---------------------------------------------------------------------------

/// Result of an individual agent run.
enum AgentResult {
  /// Agent found no issues.
  pass,

  /// Agent found non-critical issues.
  warn,

  /// Agent found critical issues.
  fail;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        AgentResult.pass => 'PASS',
        AgentResult.warn => 'WARN',
        AgentResult.fail => 'FAIL',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static AgentResult fromJson(String json) => switch (json) {
        'PASS' => AgentResult.pass,
        'WARN' => AgentResult.warn,
        'FAIL' => AgentResult.fail,
        _ => throw ArgumentError('Unknown AgentResult: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        AgentResult.pass => 'Pass',
        AgentResult.warn => 'Warning',
        AgentResult.fail => 'Fail',
      };
}

/// JSON converter for [AgentResult].
class AgentResultConverter extends JsonConverter<AgentResult, String> {
  /// Creates an [AgentResultConverter].
  const AgentResultConverter();

  @override
  AgentResult fromJson(String json) => AgentResult.fromJson(json);

  @override
  String toJson(AgentResult object) => object.toJson();
}

// ---------------------------------------------------------------------------
// AgentStatus
// ---------------------------------------------------------------------------

/// Lifecycle status of an agent run.
enum AgentStatus {
  /// Agent is queued and waiting to start.
  pending,

  /// Agent is actively executing.
  running,

  /// Agent finished successfully.
  completed,

  /// Agent encountered an error and stopped.
  failed;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        AgentStatus.pending => 'PENDING',
        AgentStatus.running => 'RUNNING',
        AgentStatus.completed => 'COMPLETED',
        AgentStatus.failed => 'FAILED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static AgentStatus fromJson(String json) => switch (json) {
        'PENDING' => AgentStatus.pending,
        'RUNNING' => AgentStatus.running,
        'COMPLETED' => AgentStatus.completed,
        'FAILED' => AgentStatus.failed,
        _ => throw ArgumentError('Unknown AgentStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        AgentStatus.pending => 'Pending',
        AgentStatus.running => 'Running',
        AgentStatus.completed => 'Completed',
        AgentStatus.failed => 'Failed',
      };
}

/// JSON converter for [AgentStatus].
class AgentStatusConverter extends JsonConverter<AgentStatus, String> {
  /// Creates an [AgentStatusConverter].
  const AgentStatusConverter();

  @override
  AgentStatus fromJson(String json) => AgentStatus.fromJson(json);

  @override
  String toJson(AgentStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// AgentType
// ---------------------------------------------------------------------------

/// The kind of QA agent that can be executed.
enum AgentType {
  /// Scans for security vulnerabilities.
  security,

  /// Analyzes code quality and style.
  codeQuality,

  /// Checks build configuration and health.
  buildHealth,

  /// Verifies feature completeness against specs.
  completeness,

  /// Validates API contracts.
  apiContract,

  /// Measures test coverage.
  testCoverage,

  /// Reviews UI/UX implementation.
  uiUx,

  /// Checks documentation quality.
  documentation,

  /// Analyzes database schema and queries.
  database,

  /// Profiles performance characteristics.
  performance,

  /// Scans dependencies for issues.
  dependency,

  /// Reviews architectural patterns.
  architecture;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        AgentType.security => 'SECURITY',
        AgentType.codeQuality => 'CODE_QUALITY',
        AgentType.buildHealth => 'BUILD_HEALTH',
        AgentType.completeness => 'COMPLETENESS',
        AgentType.apiContract => 'API_CONTRACT',
        AgentType.testCoverage => 'TEST_COVERAGE',
        AgentType.uiUx => 'UI_UX',
        AgentType.documentation => 'DOCUMENTATION',
        AgentType.database => 'DATABASE',
        AgentType.performance => 'PERFORMANCE',
        AgentType.dependency => 'DEPENDENCY',
        AgentType.architecture => 'ARCHITECTURE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static AgentType fromJson(String json) => switch (json) {
        'SECURITY' => AgentType.security,
        'CODE_QUALITY' => AgentType.codeQuality,
        'BUILD_HEALTH' => AgentType.buildHealth,
        'COMPLETENESS' => AgentType.completeness,
        'API_CONTRACT' => AgentType.apiContract,
        'TEST_COVERAGE' => AgentType.testCoverage,
        'UI_UX' => AgentType.uiUx,
        'DOCUMENTATION' => AgentType.documentation,
        'DATABASE' => AgentType.database,
        'PERFORMANCE' => AgentType.performance,
        'DEPENDENCY' => AgentType.dependency,
        'ARCHITECTURE' => AgentType.architecture,
        _ => throw ArgumentError('Unknown AgentType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        AgentType.security => 'Security',
        AgentType.codeQuality => 'Code Quality',
        AgentType.buildHealth => 'Build Health',
        AgentType.completeness => 'Completeness',
        AgentType.apiContract => 'API Contract',
        AgentType.testCoverage => 'Test Coverage',
        AgentType.uiUx => 'UI/UX',
        AgentType.documentation => 'Documentation',
        AgentType.database => 'Database',
        AgentType.performance => 'Performance',
        AgentType.dependency => 'Dependency',
        AgentType.architecture => 'Architecture',
      };
}

/// JSON converter for [AgentType].
class AgentTypeConverter extends JsonConverter<AgentType, String> {
  /// Creates an [AgentTypeConverter].
  const AgentTypeConverter();

  @override
  AgentType fromJson(String json) => AgentType.fromJson(json);

  @override
  String toJson(AgentType object) => object.toJson();
}

// ---------------------------------------------------------------------------
// BusinessImpact
// ---------------------------------------------------------------------------

/// Business impact level of a tech debt item.
enum BusinessImpact {
  /// Minimal business impact.
  low,

  /// Moderate business impact.
  medium,

  /// Significant business impact.
  high,

  /// Severe business impact requiring immediate attention.
  critical;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        BusinessImpact.low => 'LOW',
        BusinessImpact.medium => 'MEDIUM',
        BusinessImpact.high => 'HIGH',
        BusinessImpact.critical => 'CRITICAL',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static BusinessImpact fromJson(String json) => switch (json) {
        'LOW' => BusinessImpact.low,
        'MEDIUM' => BusinessImpact.medium,
        'HIGH' => BusinessImpact.high,
        'CRITICAL' => BusinessImpact.critical,
        _ => throw ArgumentError('Unknown BusinessImpact: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        BusinessImpact.low => 'Low',
        BusinessImpact.medium => 'Medium',
        BusinessImpact.high => 'High',
        BusinessImpact.critical => 'Critical',
      };
}

/// JSON converter for [BusinessImpact].
class BusinessImpactConverter extends JsonConverter<BusinessImpact, String> {
  /// Creates a [BusinessImpactConverter].
  const BusinessImpactConverter();

  @override
  BusinessImpact fromJson(String json) => BusinessImpact.fromJson(json);

  @override
  String toJson(BusinessImpact object) => object.toJson();
}

// ---------------------------------------------------------------------------
// ComplianceStatus
// ---------------------------------------------------------------------------

/// Status of a compliance requirement check.
enum ComplianceStatus {
  /// Requirement is fully met.
  met,

  /// Requirement is partially met.
  partial,

  /// Requirement is not met.
  missing,

  /// Requirement does not apply.
  notApplicable;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ComplianceStatus.met => 'MET',
        ComplianceStatus.partial => 'PARTIAL',
        ComplianceStatus.missing => 'MISSING',
        ComplianceStatus.notApplicable => 'NOT_APPLICABLE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static ComplianceStatus fromJson(String json) => switch (json) {
        'MET' => ComplianceStatus.met,
        'PARTIAL' => ComplianceStatus.partial,
        'MISSING' => ComplianceStatus.missing,
        'NOT_APPLICABLE' => ComplianceStatus.notApplicable,
        _ => throw ArgumentError('Unknown ComplianceStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ComplianceStatus.met => 'Met',
        ComplianceStatus.partial => 'Partial',
        ComplianceStatus.missing => 'Missing',
        ComplianceStatus.notApplicable => 'Not Applicable',
      };
}

/// JSON converter for [ComplianceStatus].
class ComplianceStatusConverter
    extends JsonConverter<ComplianceStatus, String> {
  /// Creates a [ComplianceStatusConverter].
  const ComplianceStatusConverter();

  @override
  ComplianceStatus fromJson(String json) => ComplianceStatus.fromJson(json);

  @override
  String toJson(ComplianceStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// DebtCategory
// ---------------------------------------------------------------------------

/// Category of technical debt.
enum DebtCategory {
  /// Architectural tech debt.
  architecture,

  /// Code-level tech debt.
  code,

  /// Testing tech debt.
  test,

  /// Dependency-related tech debt.
  dependency,

  /// Documentation tech debt.
  documentation;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        DebtCategory.architecture => 'ARCHITECTURE',
        DebtCategory.code => 'CODE',
        DebtCategory.test => 'TEST',
        DebtCategory.dependency => 'DEPENDENCY',
        DebtCategory.documentation => 'DOCUMENTATION',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static DebtCategory fromJson(String json) => switch (json) {
        'ARCHITECTURE' => DebtCategory.architecture,
        'CODE' => DebtCategory.code,
        'TEST' => DebtCategory.test,
        'DEPENDENCY' => DebtCategory.dependency,
        'DOCUMENTATION' => DebtCategory.documentation,
        _ => throw ArgumentError('Unknown DebtCategory: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        DebtCategory.architecture => 'Architecture',
        DebtCategory.code => 'Code',
        DebtCategory.test => 'Test',
        DebtCategory.dependency => 'Dependency',
        DebtCategory.documentation => 'Documentation',
      };
}

/// JSON converter for [DebtCategory].
class DebtCategoryConverter extends JsonConverter<DebtCategory, String> {
  /// Creates a [DebtCategoryConverter].
  const DebtCategoryConverter();

  @override
  DebtCategory fromJson(String json) => DebtCategory.fromJson(json);

  @override
  String toJson(DebtCategory object) => object.toJson();
}

// ---------------------------------------------------------------------------
// DebtStatus
// ---------------------------------------------------------------------------

/// Lifecycle status of a tech debt item.
enum DebtStatus {
  /// Debt has been identified but not yet planned.
  identified,

  /// Debt resolution is planned.
  planned,

  /// Debt resolution is in progress.
  inProgress,

  /// Debt has been resolved.
  resolved;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        DebtStatus.identified => 'IDENTIFIED',
        DebtStatus.planned => 'PLANNED',
        DebtStatus.inProgress => 'IN_PROGRESS',
        DebtStatus.resolved => 'RESOLVED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static DebtStatus fromJson(String json) => switch (json) {
        'IDENTIFIED' => DebtStatus.identified,
        'PLANNED' => DebtStatus.planned,
        'IN_PROGRESS' => DebtStatus.inProgress,
        'RESOLVED' => DebtStatus.resolved,
        _ => throw ArgumentError('Unknown DebtStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        DebtStatus.identified => 'Identified',
        DebtStatus.planned => 'Planned',
        DebtStatus.inProgress => 'In Progress',
        DebtStatus.resolved => 'Resolved',
      };
}

/// JSON converter for [DebtStatus].
class DebtStatusConverter extends JsonConverter<DebtStatus, String> {
  /// Creates a [DebtStatusConverter].
  const DebtStatusConverter();

  @override
  DebtStatus fromJson(String json) => DebtStatus.fromJson(json);

  @override
  String toJson(DebtStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// DirectiveCategory
// ---------------------------------------------------------------------------

/// Category of a directive.
enum DirectiveCategory {
  /// Architecture-related directive.
  architecture,

  /// Coding standards directive.
  standards,

  /// Team conventions directive.
  conventions,

  /// Contextual information directive.
  context,

  /// Uncategorized directive.
  other;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        DirectiveCategory.architecture => 'ARCHITECTURE',
        DirectiveCategory.standards => 'STANDARDS',
        DirectiveCategory.conventions => 'CONVENTIONS',
        DirectiveCategory.context => 'CONTEXT',
        DirectiveCategory.other => 'OTHER',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static DirectiveCategory fromJson(String json) => switch (json) {
        'ARCHITECTURE' => DirectiveCategory.architecture,
        'STANDARDS' => DirectiveCategory.standards,
        'CONVENTIONS' => DirectiveCategory.conventions,
        'CONTEXT' => DirectiveCategory.context,
        'OTHER' => DirectiveCategory.other,
        _ => throw ArgumentError('Unknown DirectiveCategory: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        DirectiveCategory.architecture => 'Architecture',
        DirectiveCategory.standards => 'Standards',
        DirectiveCategory.conventions => 'Conventions',
        DirectiveCategory.context => 'Context',
        DirectiveCategory.other => 'Other',
      };
}

/// JSON converter for [DirectiveCategory].
class DirectiveCategoryConverter
    extends JsonConverter<DirectiveCategory, String> {
  /// Creates a [DirectiveCategoryConverter].
  const DirectiveCategoryConverter();

  @override
  DirectiveCategory fromJson(String json) => DirectiveCategory.fromJson(json);

  @override
  String toJson(DirectiveCategory object) => object.toJson();
}

// ---------------------------------------------------------------------------
// DirectiveScope
// ---------------------------------------------------------------------------

/// Scope at which a directive applies.
enum DirectiveScope {
  /// Applies to the entire team.
  team,

  /// Applies to a specific project.
  project,

  /// Applies to an individual user.
  user;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        DirectiveScope.team => 'TEAM',
        DirectiveScope.project => 'PROJECT',
        DirectiveScope.user => 'USER',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static DirectiveScope fromJson(String json) => switch (json) {
        'TEAM' => DirectiveScope.team,
        'PROJECT' => DirectiveScope.project,
        'USER' => DirectiveScope.user,
        _ => throw ArgumentError('Unknown DirectiveScope: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        DirectiveScope.team => 'Team',
        DirectiveScope.project => 'Project',
        DirectiveScope.user => 'User',
      };
}

/// JSON converter for [DirectiveScope].
class DirectiveScopeConverter extends JsonConverter<DirectiveScope, String> {
  /// Creates a [DirectiveScopeConverter].
  const DirectiveScopeConverter();

  @override
  DirectiveScope fromJson(String json) => DirectiveScope.fromJson(json);

  @override
  String toJson(DirectiveScope object) => object.toJson();
}

// ---------------------------------------------------------------------------
// Effort
// ---------------------------------------------------------------------------

/// T-shirt size estimate of effort required.
enum Effort {
  /// Small effort (~1-2 hours).
  s,

  /// Medium effort (~half day).
  m,

  /// Large effort (~1-2 days).
  l,

  /// Extra-large effort (~3+ days).
  xl;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        Effort.s => 'S',
        Effort.m => 'M',
        Effort.l => 'L',
        Effort.xl => 'XL',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static Effort fromJson(String json) => switch (json) {
        'S' => Effort.s,
        'M' => Effort.m,
        'L' => Effort.l,
        'XL' => Effort.xl,
        _ => throw ArgumentError('Unknown Effort: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        Effort.s => 'Small',
        Effort.m => 'Medium',
        Effort.l => 'Large',
        Effort.xl => 'Extra Large',
      };
}

/// JSON converter for [Effort].
class EffortConverter extends JsonConverter<Effort, String> {
  /// Creates an [EffortConverter].
  const EffortConverter();

  @override
  Effort fromJson(String json) => Effort.fromJson(json);

  @override
  String toJson(Effort object) => object.toJson();
}

// ---------------------------------------------------------------------------
// FindingStatus
// ---------------------------------------------------------------------------

/// Status of an audit finding.
enum FindingStatus {
  /// Finding is open and unaddressed.
  open,

  /// Finding has been acknowledged.
  acknowledged,

  /// Finding has been marked as a false positive.
  falsePositive,

  /// Finding has been fixed.
  fixed,

  /// Finding will not be fixed.
  wontFix;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        FindingStatus.open => 'OPEN',
        FindingStatus.acknowledged => 'ACKNOWLEDGED',
        FindingStatus.falsePositive => 'FALSE_POSITIVE',
        FindingStatus.fixed => 'FIXED',
        FindingStatus.wontFix => 'WONT_FIX',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static FindingStatus fromJson(String json) => switch (json) {
        'OPEN' => FindingStatus.open,
        'ACKNOWLEDGED' => FindingStatus.acknowledged,
        'FALSE_POSITIVE' => FindingStatus.falsePositive,
        'FIXED' => FindingStatus.fixed,
        'WONT_FIX' => FindingStatus.wontFix,
        _ => throw ArgumentError('Unknown FindingStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        FindingStatus.open => 'Open',
        FindingStatus.acknowledged => 'Acknowledged',
        FindingStatus.falsePositive => 'False Positive',
        FindingStatus.fixed => 'Fixed',
        FindingStatus.wontFix => "Won't Fix",
      };
}

/// JSON converter for [FindingStatus].
class FindingStatusConverter extends JsonConverter<FindingStatus, String> {
  /// Creates a [FindingStatusConverter].
  const FindingStatusConverter();

  @override
  FindingStatus fromJson(String json) => FindingStatus.fromJson(json);

  @override
  String toJson(FindingStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// GitHubAuthType
// ---------------------------------------------------------------------------

/// Authentication method for GitHub connections.
enum GitHubAuthType {
  /// Personal access token.
  pat,

  /// OAuth authentication.
  oauth,

  /// SSH key authentication.
  ssh;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        GitHubAuthType.pat => 'PAT',
        GitHubAuthType.oauth => 'OAUTH',
        GitHubAuthType.ssh => 'SSH',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static GitHubAuthType fromJson(String json) => switch (json) {
        'PAT' => GitHubAuthType.pat,
        'OAUTH' => GitHubAuthType.oauth,
        'SSH' => GitHubAuthType.ssh,
        _ => throw ArgumentError('Unknown GitHubAuthType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        GitHubAuthType.pat => 'Personal Access Token',
        GitHubAuthType.oauth => 'OAuth',
        GitHubAuthType.ssh => 'SSH',
      };
}

/// JSON converter for [GitHubAuthType].
class GitHubAuthTypeConverter extends JsonConverter<GitHubAuthType, String> {
  /// Creates a [GitHubAuthTypeConverter].
  const GitHubAuthTypeConverter();

  @override
  GitHubAuthType fromJson(String json) => GitHubAuthType.fromJson(json);

  @override
  String toJson(GitHubAuthType object) => object.toJson();
}

// ---------------------------------------------------------------------------
// InvitationStatus
// ---------------------------------------------------------------------------

/// Status of a team invitation.
enum InvitationStatus {
  /// Invitation is pending acceptance.
  pending,

  /// Invitation has been accepted.
  accepted,

  /// Invitation has expired.
  expired;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        InvitationStatus.pending => 'PENDING',
        InvitationStatus.accepted => 'ACCEPTED',
        InvitationStatus.expired => 'EXPIRED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static InvitationStatus fromJson(String json) => switch (json) {
        'PENDING' => InvitationStatus.pending,
        'ACCEPTED' => InvitationStatus.accepted,
        'EXPIRED' => InvitationStatus.expired,
        _ => throw ArgumentError('Unknown InvitationStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        InvitationStatus.pending => 'Pending',
        InvitationStatus.accepted => 'Accepted',
        InvitationStatus.expired => 'Expired',
      };
}

/// JSON converter for [InvitationStatus].
class InvitationStatusConverter
    extends JsonConverter<InvitationStatus, String> {
  /// Creates an [InvitationStatusConverter].
  const InvitationStatusConverter();

  @override
  InvitationStatus fromJson(String json) => InvitationStatus.fromJson(json);

  @override
  String toJson(InvitationStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// JobMode
// ---------------------------------------------------------------------------

/// The mode of a QA job determining which agents run.
enum JobMode {
  /// Full audit of the project.
  audit,

  /// Compliance check against specifications.
  compliance,

  /// Bug investigation from a Jira ticket.
  bugInvestigate,

  /// Remediation of findings.
  remediate,

  /// Tech debt analysis.
  techDebt,

  /// Dependency scanning.
  dependency,

  /// Health monitoring check.
  healthMonitor;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        JobMode.audit => 'AUDIT',
        JobMode.compliance => 'COMPLIANCE',
        JobMode.bugInvestigate => 'BUG_INVESTIGATE',
        JobMode.remediate => 'REMEDIATE',
        JobMode.techDebt => 'TECH_DEBT',
        JobMode.dependency => 'DEPENDENCY',
        JobMode.healthMonitor => 'HEALTH_MONITOR',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static JobMode fromJson(String json) => switch (json) {
        'AUDIT' => JobMode.audit,
        'COMPLIANCE' => JobMode.compliance,
        'BUG_INVESTIGATE' => JobMode.bugInvestigate,
        'REMEDIATE' => JobMode.remediate,
        'TECH_DEBT' => JobMode.techDebt,
        'DEPENDENCY' => JobMode.dependency,
        'HEALTH_MONITOR' => JobMode.healthMonitor,
        _ => throw ArgumentError('Unknown JobMode: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        JobMode.audit => 'Audit',
        JobMode.compliance => 'Compliance',
        JobMode.bugInvestigate => 'Bug Investigation',
        JobMode.remediate => 'Remediation',
        JobMode.techDebt => 'Tech Debt',
        JobMode.dependency => 'Dependency Scan',
        JobMode.healthMonitor => 'Health Monitor',
      };
}

/// JSON converter for [JobMode].
class JobModeConverter extends JsonConverter<JobMode, String> {
  /// Creates a [JobModeConverter].
  const JobModeConverter();

  @override
  JobMode fromJson(String json) => JobMode.fromJson(json);

  @override
  String toJson(JobMode object) => object.toJson();
}

// ---------------------------------------------------------------------------
// JobResult
// ---------------------------------------------------------------------------

/// Overall result of a QA job.
enum JobResult {
  /// Job passed with no critical issues.
  pass,

  /// Job completed with warnings.
  warn,

  /// Job failed with critical issues.
  fail;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        JobResult.pass => 'PASS',
        JobResult.warn => 'WARN',
        JobResult.fail => 'FAIL',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static JobResult fromJson(String json) => switch (json) {
        'PASS' => JobResult.pass,
        'WARN' => JobResult.warn,
        'FAIL' => JobResult.fail,
        _ => throw ArgumentError('Unknown JobResult: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        JobResult.pass => 'Pass',
        JobResult.warn => 'Warning',
        JobResult.fail => 'Fail',
      };
}

/// JSON converter for [JobResult].
class JobResultConverter extends JsonConverter<JobResult, String> {
  /// Creates a [JobResultConverter].
  const JobResultConverter();

  @override
  JobResult fromJson(String json) => JobResult.fromJson(json);

  @override
  String toJson(JobResult object) => object.toJson();
}

// ---------------------------------------------------------------------------
// JobStatus
// ---------------------------------------------------------------------------

/// Lifecycle status of a QA job.
enum JobStatus {
  /// Job is queued and waiting to start.
  pending,

  /// Job is actively running.
  running,

  /// Job finished successfully.
  completed,

  /// Job encountered an error.
  failed,

  /// Job was cancelled by the user.
  cancelled;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        JobStatus.pending => 'PENDING',
        JobStatus.running => 'RUNNING',
        JobStatus.completed => 'COMPLETED',
        JobStatus.failed => 'FAILED',
        JobStatus.cancelled => 'CANCELLED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static JobStatus fromJson(String json) => switch (json) {
        'PENDING' => JobStatus.pending,
        'RUNNING' => JobStatus.running,
        'COMPLETED' => JobStatus.completed,
        'FAILED' => JobStatus.failed,
        'CANCELLED' => JobStatus.cancelled,
        _ => throw ArgumentError('Unknown JobStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        JobStatus.pending => 'Pending',
        JobStatus.running => 'Running',
        JobStatus.completed => 'Completed',
        JobStatus.failed => 'Failed',
        JobStatus.cancelled => 'Cancelled',
      };
}

/// JSON converter for [JobStatus].
class JobStatusConverter extends JsonConverter<JobStatus, String> {
  /// Creates a [JobStatusConverter].
  const JobStatusConverter();

  @override
  JobStatus fromJson(String json) => JobStatus.fromJson(json);

  @override
  String toJson(JobStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// Priority
// ---------------------------------------------------------------------------

/// Priority level of a remediation task.
enum Priority {
  /// Highest priority — must fix immediately.
  p0,

  /// High priority — fix within current sprint.
  p1,

  /// Normal priority — fix soon.
  p2,

  /// Low priority — fix when convenient.
  p3;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        Priority.p0 => 'P0',
        Priority.p1 => 'P1',
        Priority.p2 => 'P2',
        Priority.p3 => 'P3',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static Priority fromJson(String json) => switch (json) {
        'P0' => Priority.p0,
        'P1' => Priority.p1,
        'P2' => Priority.p2,
        'P3' => Priority.p3,
        _ => throw ArgumentError('Unknown Priority: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        Priority.p0 => 'P0 — Critical',
        Priority.p1 => 'P1 — High',
        Priority.p2 => 'P2 — Normal',
        Priority.p3 => 'P3 — Low',
      };
}

/// JSON converter for [Priority].
class PriorityConverter extends JsonConverter<Priority, String> {
  /// Creates a [PriorityConverter].
  const PriorityConverter();

  @override
  Priority fromJson(String json) => Priority.fromJson(json);

  @override
  String toJson(Priority object) => object.toJson();
}

// ---------------------------------------------------------------------------
// ScheduleType
// ---------------------------------------------------------------------------

/// Schedule frequency for health monitoring.
enum ScheduleType {
  /// Run daily.
  daily,

  /// Run weekly.
  weekly,

  /// Run on every commit.
  onCommit;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ScheduleType.daily => 'DAILY',
        ScheduleType.weekly => 'WEEKLY',
        ScheduleType.onCommit => 'ON_COMMIT',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static ScheduleType fromJson(String json) => switch (json) {
        'DAILY' => ScheduleType.daily,
        'WEEKLY' => ScheduleType.weekly,
        'ON_COMMIT' => ScheduleType.onCommit,
        _ => throw ArgumentError('Unknown ScheduleType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ScheduleType.daily => 'Daily',
        ScheduleType.weekly => 'Weekly',
        ScheduleType.onCommit => 'On Commit',
      };
}

/// JSON converter for [ScheduleType].
class ScheduleTypeConverter extends JsonConverter<ScheduleType, String> {
  /// Creates a [ScheduleTypeConverter].
  const ScheduleTypeConverter();

  @override
  ScheduleType fromJson(String json) => ScheduleType.fromJson(json);

  @override
  String toJson(ScheduleType object) => object.toJson();
}

// ---------------------------------------------------------------------------
// Scope
// ---------------------------------------------------------------------------

/// Scope at which a persona is defined.
enum Scope {
  /// Built-in system persona (read-only).
  system,

  /// Shared team persona.
  team,

  /// Personal user persona.
  user;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        Scope.system => 'SYSTEM',
        Scope.team => 'TEAM',
        Scope.user => 'USER',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static Scope fromJson(String json) => switch (json) {
        'SYSTEM' => Scope.system,
        'TEAM' => Scope.team,
        'USER' => Scope.user,
        _ => throw ArgumentError('Unknown Scope: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        Scope.system => 'System',
        Scope.team => 'Team',
        Scope.user => 'User',
      };
}

/// JSON converter for [Scope].
class ScopeConverter extends JsonConverter<Scope, String> {
  /// Creates a [ScopeConverter].
  const ScopeConverter();

  @override
  Scope fromJson(String json) => Scope.fromJson(json);

  @override
  String toJson(Scope object) => object.toJson();
}

// ---------------------------------------------------------------------------
// Severity
// ---------------------------------------------------------------------------

/// Severity level of a finding or vulnerability.
enum Severity {
  /// Critical severity — exploitable or data-loss risk.
  critical,

  /// High severity — significant issue.
  high,

  /// Medium severity — moderate issue.
  medium,

  /// Low severity — minor issue.
  low;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        Severity.critical => 'CRITICAL',
        Severity.high => 'HIGH',
        Severity.medium => 'MEDIUM',
        Severity.low => 'LOW',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static Severity fromJson(String json) => switch (json) {
        'CRITICAL' => Severity.critical,
        'HIGH' => Severity.high,
        'MEDIUM' => Severity.medium,
        'LOW' => Severity.low,
        _ => throw ArgumentError('Unknown Severity: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        Severity.critical => 'Critical',
        Severity.high => 'High',
        Severity.medium => 'Medium',
        Severity.low => 'Low',
      };
}

/// JSON converter for [Severity].
class SeverityConverter extends JsonConverter<Severity, String> {
  /// Creates a [SeverityConverter].
  const SeverityConverter();

  @override
  Severity fromJson(String json) => Severity.fromJson(json);

  @override
  String toJson(Severity object) => object.toJson();
}

// ---------------------------------------------------------------------------
// SpecType
// ---------------------------------------------------------------------------

/// Type of specification file.
enum SpecType {
  /// OpenAPI / Swagger specification.
  openapi,

  /// Markdown document.
  markdown,

  /// Screenshot image.
  screenshot,

  /// Figma design link.
  figma;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        SpecType.openapi => 'OPENAPI',
        SpecType.markdown => 'MARKDOWN',
        SpecType.screenshot => 'SCREENSHOT',
        SpecType.figma => 'FIGMA',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static SpecType fromJson(String json) => switch (json) {
        'OPENAPI' => SpecType.openapi,
        'MARKDOWN' => SpecType.markdown,
        'SCREENSHOT' => SpecType.screenshot,
        'FIGMA' => SpecType.figma,
        _ => throw ArgumentError('Unknown SpecType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        SpecType.openapi => 'OpenAPI',
        SpecType.markdown => 'Markdown',
        SpecType.screenshot => 'Screenshot',
        SpecType.figma => 'Figma',
      };
}

/// JSON converter for [SpecType].
class SpecTypeConverter extends JsonConverter<SpecType, String> {
  /// Creates a [SpecTypeConverter].
  const SpecTypeConverter();

  @override
  SpecType fromJson(String json) => SpecType.fromJson(json);

  @override
  String toJson(SpecType object) => object.toJson();
}

// ---------------------------------------------------------------------------
// TaskStatus
// ---------------------------------------------------------------------------

/// Lifecycle status of a remediation task.
enum TaskStatus {
  /// Task is pending assignment.
  pending,

  /// Task has been assigned to someone.
  assigned,

  /// Task has been exported.
  exported,

  /// Task has been created as a Jira ticket.
  jiraCreated,

  /// Task has been completed.
  completed;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        TaskStatus.pending => 'PENDING',
        TaskStatus.assigned => 'ASSIGNED',
        TaskStatus.exported => 'EXPORTED',
        TaskStatus.jiraCreated => 'JIRA_CREATED',
        TaskStatus.completed => 'COMPLETED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static TaskStatus fromJson(String json) => switch (json) {
        'PENDING' => TaskStatus.pending,
        'ASSIGNED' => TaskStatus.assigned,
        'EXPORTED' => TaskStatus.exported,
        'JIRA_CREATED' => TaskStatus.jiraCreated,
        'COMPLETED' => TaskStatus.completed,
        _ => throw ArgumentError('Unknown TaskStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        TaskStatus.pending => 'Pending',
        TaskStatus.assigned => 'Assigned',
        TaskStatus.exported => 'Exported',
        TaskStatus.jiraCreated => 'Jira Created',
        TaskStatus.completed => 'Completed',
      };
}

/// JSON converter for [TaskStatus].
class TaskStatusConverter extends JsonConverter<TaskStatus, String> {
  /// Creates a [TaskStatusConverter].
  const TaskStatusConverter();

  @override
  TaskStatus fromJson(String json) => TaskStatus.fromJson(json);

  @override
  String toJson(TaskStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// TeamRole
// ---------------------------------------------------------------------------

/// Role of a team member.
enum TeamRole {
  /// Team owner with full permissions.
  owner,

  /// Administrator with management permissions.
  admin,

  /// Regular team member.
  member,

  /// Read-only viewer.
  viewer;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        TeamRole.owner => 'OWNER',
        TeamRole.admin => 'ADMIN',
        TeamRole.member => 'MEMBER',
        TeamRole.viewer => 'VIEWER',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static TeamRole fromJson(String json) => switch (json) {
        'OWNER' => TeamRole.owner,
        'ADMIN' => TeamRole.admin,
        'MEMBER' => TeamRole.member,
        'VIEWER' => TeamRole.viewer,
        _ => throw ArgumentError('Unknown TeamRole: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        TeamRole.owner => 'Owner',
        TeamRole.admin => 'Admin',
        TeamRole.member => 'Member',
        TeamRole.viewer => 'Viewer',
      };
}

/// JSON converter for [TeamRole].
class TeamRoleConverter extends JsonConverter<TeamRole, String> {
  /// Creates a [TeamRoleConverter].
  const TeamRoleConverter();

  @override
  TeamRole fromJson(String json) => TeamRole.fromJson(json);

  @override
  String toJson(TeamRole object) => object.toJson();
}

// ---------------------------------------------------------------------------
// VulnerabilityStatus
// ---------------------------------------------------------------------------

/// Status of a dependency vulnerability.
enum VulnerabilityStatus {
  /// Vulnerability is open and unaddressed.
  open,

  /// Dependency is being updated.
  updating,

  /// Vulnerability has been suppressed.
  suppressed,

  /// Vulnerability has been resolved.
  resolved;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        VulnerabilityStatus.open => 'OPEN',
        VulnerabilityStatus.updating => 'UPDATING',
        VulnerabilityStatus.suppressed => 'SUPPRESSED',
        VulnerabilityStatus.resolved => 'RESOLVED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static VulnerabilityStatus fromJson(String json) => switch (json) {
        'OPEN' => VulnerabilityStatus.open,
        'UPDATING' => VulnerabilityStatus.updating,
        'SUPPRESSED' => VulnerabilityStatus.suppressed,
        'RESOLVED' => VulnerabilityStatus.resolved,
        _ => throw ArgumentError('Unknown VulnerabilityStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        VulnerabilityStatus.open => 'Open',
        VulnerabilityStatus.updating => 'Updating',
        VulnerabilityStatus.suppressed => 'Suppressed',
        VulnerabilityStatus.resolved => 'Resolved',
      };
}

/// JSON converter for [VulnerabilityStatus].
class VulnerabilityStatusConverter
    extends JsonConverter<VulnerabilityStatus, String> {
  /// Creates a [VulnerabilityStatusConverter].
  const VulnerabilityStatusConverter();

  @override
  VulnerabilityStatus fromJson(String json) =>
      VulnerabilityStatus.fromJson(json);

  @override
  String toJson(VulnerabilityStatus object) => object.toJson();
}

// ---------------------------------------------------------------------------
// UI display label maps
// ---------------------------------------------------------------------------

/// Human-friendly labels for each [AgentType].
const Map<AgentType, String> agentTypeLabels = {
  AgentType.security: 'Security',
  AgentType.codeQuality: 'Code Quality',
  AgentType.buildHealth: 'Build Health',
  AgentType.completeness: 'Completeness',
  AgentType.apiContract: 'API Contract',
  AgentType.testCoverage: 'Test Coverage',
  AgentType.uiUx: 'UI/UX',
  AgentType.documentation: 'Documentation',
  AgentType.database: 'Database',
  AgentType.performance: 'Performance',
  AgentType.dependency: 'Dependency',
  AgentType.architecture: 'Architecture',
};

/// Human-friendly labels for each [Severity].
const Map<Severity, String> severityLabels = {
  Severity.critical: 'Critical',
  Severity.high: 'High',
  Severity.medium: 'Medium',
  Severity.low: 'Low',
};

/// Human-friendly labels for each [JobMode].
const Map<JobMode, String> jobModeLabels = {
  JobMode.audit: 'Audit',
  JobMode.compliance: 'Compliance',
  JobMode.bugInvestigate: 'Bug Investigation',
  JobMode.remediate: 'Remediation',
  JobMode.techDebt: 'Tech Debt',
  JobMode.dependency: 'Dependency Scan',
  JobMode.healthMonitor: 'Health Monitor',
};

/// Human-friendly labels for each [JobStatus].
const Map<JobStatus, String> jobStatusLabels = {
  JobStatus.pending: 'Pending',
  JobStatus.running: 'Running',
  JobStatus.completed: 'Completed',
  JobStatus.failed: 'Failed',
  JobStatus.cancelled: 'Cancelled',
};

/// Human-friendly labels for each [Priority].
const Map<Priority, String> priorityLabels = {
  Priority.p0: 'P0 — Critical',
  Priority.p1: 'P1 — High',
  Priority.p2: 'P2 — Normal',
  Priority.p3: 'P3 — Low',
};

/// Human-friendly labels for each [FindingStatus].
const Map<FindingStatus, String> findingStatusLabels = {
  FindingStatus.open: 'Open',
  FindingStatus.acknowledged: 'Acknowledged',
  FindingStatus.falsePositive: 'False Positive',
  FindingStatus.fixed: 'Fixed',
  FindingStatus.wontFix: "Won't Fix",
};
