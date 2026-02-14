/// Drift table definitions for the local SQLite cache.
///
/// These tables mirror the server's PostgreSQL entities for offline access.
/// Enum fields are stored as text using the server's SCREAMING_SNAKE_CASE
/// representation. Conversion to Dart enums happens in the model layer.
library;

import 'package:drift/drift.dart';

/// Local cache of user profiles.
class Users extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// User email address.
  TextColumn get email => text()();

  /// Display name.
  TextColumn get displayName => text()();

  /// Avatar URL.
  TextColumn get avatarUrl => text().nullable()();

  /// Whether the account is active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Last login timestamp.
  DateTimeColumn get lastLoginAt => dateTime().nullable()();

  /// Account creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of teams.
class Teams extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Team name.
  TextColumn get name => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// Owner UUID.
  TextColumn get ownerId => text()();

  /// Owner display name.
  TextColumn get ownerName => text().nullable()();

  /// Microsoft Teams webhook URL.
  TextColumn get teamsWebhookUrl => text().nullable()();

  /// Member count.
  IntColumn get memberCount => integer().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of projects.
class Projects extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Team UUID.
  TextColumn get teamId => text()();

  /// Project name.
  TextColumn get name => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// GitHub connection UUID.
  TextColumn get githubConnectionId => text().nullable()();

  /// Repository clone URL.
  TextColumn get repoUrl => text().nullable()();

  /// Full repository name (owner/repo).
  TextColumn get repoFullName => text().nullable()();

  /// Default branch.
  TextColumn get defaultBranch => text().nullable()();

  /// Jira connection UUID.
  TextColumn get jiraConnectionId => text().nullable()();

  /// Jira project key.
  TextColumn get jiraProjectKey => text().nullable()();

  /// Tech stack description.
  TextColumn get techStack => text().nullable()();

  /// Health score (0-100).
  IntColumn get healthScore => integer().nullable()();

  /// Last audit timestamp.
  DateTimeColumn get lastAuditAt => dateTime().nullable()();

  /// Whether the project is archived.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of QA jobs.
class QaJobs extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Project UUID.
  TextColumn get projectId => text()();

  /// Project name.
  TextColumn get projectName => text().nullable()();

  /// Job mode (SCREAMING_SNAKE_CASE).
  TextColumn get mode => text()();

  /// Job status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// Job name.
  TextColumn get name => text().nullable()();

  /// Branch being analyzed.
  TextColumn get branch => text().nullable()();

  /// Markdown summary.
  TextColumn get summaryMd => text().nullable()();

  /// Overall result (SCREAMING_SNAKE_CASE).
  TextColumn get overallResult => text().nullable()();

  /// Health score.
  IntColumn get healthScore => integer().nullable()();

  /// Total findings count.
  IntColumn get totalFindings => integer().nullable()();

  /// Critical findings count.
  IntColumn get criticalCount => integer().nullable()();

  /// High findings count.
  IntColumn get highCount => integer().nullable()();

  /// Medium findings count.
  IntColumn get mediumCount => integer().nullable()();

  /// Low findings count.
  IntColumn get lowCount => integer().nullable()();

  /// Jira ticket key.
  TextColumn get jiraTicketKey => text().nullable()();

  /// Starter user UUID.
  TextColumn get startedBy => text().nullable()();

  /// Starter display name.
  TextColumn get startedByName => text().nullable()();

  /// Start timestamp.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// Completion timestamp.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of agent runs.
class AgentRuns extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent job UUID.
  TextColumn get jobId => text()();

  /// Agent type (SCREAMING_SNAKE_CASE).
  TextColumn get agentType => text()();

  /// Agent status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// Agent result (SCREAMING_SNAKE_CASE).
  TextColumn get result => text().nullable()();

  /// S3 key for the report.
  TextColumn get reportS3Key => text().nullable()();

  /// Score (0-100).
  IntColumn get score => integer().nullable()();

  /// Findings count.
  IntColumn get findingsCount => integer().nullable()();

  /// Critical findings count.
  IntColumn get criticalCount => integer().nullable()();

  /// High findings count.
  IntColumn get highCount => integer().nullable()();

  /// Start timestamp.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// Completion timestamp.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of findings.
class Findings extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent job UUID.
  TextColumn get jobId => text()();

  /// Agent type (SCREAMING_SNAKE_CASE).
  TextColumn get agentType => text()();

  /// Severity (SCREAMING_SNAKE_CASE).
  TextColumn get severity => text()();

  /// Finding title.
  TextColumn get title => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// Source file path.
  TextColumn get filePath => text().nullable()();

  /// Line number.
  IntColumn get lineNumber => integer().nullable()();

  /// Recommendation.
  TextColumn get recommendation => text().nullable()();

  /// Evidence.
  TextColumn get evidence => text().nullable()();

  /// Effort estimate (SCREAMING_SNAKE_CASE).
  TextColumn get effortEstimate => text().nullable()();

  /// Debt category (SCREAMING_SNAKE_CASE).
  TextColumn get debtCategory => text().nullable()();

  /// Finding status (SCREAMING_SNAKE_CASE).
  TextColumn get findingStatus => text()();

  /// Status changer UUID.
  TextColumn get statusChangedBy => text().nullable()();

  /// Status change timestamp.
  DateTimeColumn get statusChangedAt => dateTime().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of remediation tasks.
class RemediationTasks extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent job UUID.
  TextColumn get jobId => text()();

  /// Sequential task number.
  IntColumn get taskNumber => integer()();

  /// Task title.
  TextColumn get title => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// Prompt markdown.
  TextColumn get promptMd => text().nullable()();

  /// Priority (SCREAMING_SNAKE_CASE).
  TextColumn get priority => text().nullable()();

  /// Status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// Assignee UUID.
  TextColumn get assignedTo => text().nullable()();

  /// Assignee display name.
  TextColumn get assignedToName => text().nullable()();

  /// Jira ticket key.
  TextColumn get jiraKey => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of personas.
class Personas extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Persona name.
  TextColumn get name => text()();

  /// Agent type (SCREAMING_SNAKE_CASE).
  TextColumn get agentType => text().nullable()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// Content markdown.
  TextColumn get contentMd => text().nullable()();

  /// Scope (SCREAMING_SNAKE_CASE).
  TextColumn get scope => text()();

  /// Team UUID.
  TextColumn get teamId => text().nullable()();

  /// Creator UUID.
  TextColumn get createdBy => text().nullable()();

  /// Creator display name.
  TextColumn get createdByName => text().nullable()();

  /// Whether this is the default persona.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Version number.
  IntColumn get version => integer().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of directives.
class Directives extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Directive name.
  TextColumn get name => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// Content markdown.
  TextColumn get contentMd => text().nullable()();

  /// Category (SCREAMING_SNAKE_CASE).
  TextColumn get category => text().nullable()();

  /// Scope (SCREAMING_SNAKE_CASE).
  TextColumn get scope => text()();

  /// Team UUID.
  TextColumn get teamId => text().nullable()();

  /// Project UUID.
  TextColumn get projectId => text().nullable()();

  /// Creator UUID.
  TextColumn get createdBy => text().nullable()();

  /// Creator display name.
  TextColumn get createdByName => text().nullable()();

  /// Version number.
  IntColumn get version => integer().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of tech debt items.
class TechDebtItems extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Project UUID.
  TextColumn get projectId => text()();

  /// Category (SCREAMING_SNAKE_CASE).
  TextColumn get category => text()();

  /// Title.
  TextColumn get title => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// File path.
  TextColumn get filePath => text().nullable()();

  /// Effort estimate (SCREAMING_SNAKE_CASE).
  TextColumn get effortEstimate => text().nullable()();

  /// Business impact (SCREAMING_SNAKE_CASE).
  TextColumn get businessImpact => text().nullable()();

  /// Status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// First detection job UUID.
  TextColumn get firstDetectedJobId => text().nullable()();

  /// Resolution job UUID.
  TextColumn get resolvedJobId => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of dependency scans.
class DependencyScans extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Project UUID.
  TextColumn get projectId => text()();

  /// Job UUID.
  TextColumn get jobId => text().nullable()();

  /// Manifest file path.
  TextColumn get manifestFile => text().nullable()();

  /// Total dependencies count.
  IntColumn get totalDependencies => integer().nullable()();

  /// Outdated dependencies count.
  IntColumn get outdatedCount => integer().nullable()();

  /// Vulnerable dependencies count.
  IntColumn get vulnerableCount => integer().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of dependency vulnerabilities.
class DependencyVulnerabilities extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent scan UUID.
  TextColumn get scanId => text()();

  /// Dependency name.
  TextColumn get dependencyName => text()();

  /// Current version.
  TextColumn get currentVersion => text().nullable()();

  /// Fixed version.
  TextColumn get fixedVersion => text().nullable()();

  /// CVE identifier.
  TextColumn get cveId => text().nullable()();

  /// Severity (SCREAMING_SNAKE_CASE).
  TextColumn get severity => text()();

  /// Description.
  TextColumn get description => text().nullable()();

  /// Status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of health snapshots.
class HealthSnapshots extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Project UUID.
  TextColumn get projectId => text()();

  /// Job UUID.
  TextColumn get jobId => text().nullable()();

  /// Health score (0-100).
  IntColumn get healthScore => integer()();

  /// JSON mapping severity to count.
  TextColumn get findingsBySeverity => text().nullable()();

  /// Tech debt score.
  IntColumn get techDebtScore => integer().nullable()();

  /// Dependency health score.
  IntColumn get dependencyScore => integer().nullable()();

  /// Test coverage percentage.
  RealColumn get testCoveragePercent => real().nullable()();

  /// Capture timestamp.
  DateTimeColumn get capturedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of compliance items.
class ComplianceItems extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent job UUID.
  TextColumn get jobId => text()();

  /// Requirement text.
  TextColumn get requirement => text()();

  /// Spec UUID.
  TextColumn get specId => text().nullable()();

  /// Spec name.
  TextColumn get specName => text().nullable()();

  /// Status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// Evidence.
  TextColumn get evidence => text().nullable()();

  /// Agent type (SCREAMING_SNAKE_CASE).
  TextColumn get agentType => text().nullable()();

  /// Notes.
  TextColumn get notes => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of specifications.
class Specifications extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent job UUID.
  TextColumn get jobId => text()();

  /// Specification name.
  TextColumn get name => text()();

  /// Spec type (SCREAMING_SNAKE_CASE).
  TextColumn get specType => text().nullable()();

  /// S3 key.
  TextColumn get s3Key => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local registry of cloned git repositories.
class ClonedRepos extends Table {
  /// Full repository name (owner/repo) as primary key.
  TextColumn get repoFullName => text()();

  /// Absolute path on the local filesystem.
  TextColumn get localPath => text()();

  /// Optional associated project UUID.
  TextColumn get projectId => text().nullable()();

  /// Timestamp when the repo was cloned.
  DateTimeColumn get clonedAt => dateTime().nullable()();

  /// Timestamp of the last access.
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {repoFullName};
}

/// Tracks last sync time for each table.
class SyncMetadata extends Table {
  /// Synced table name as primary key.
  TextColumn get syncTableName => text()();

  /// Last synchronization timestamp.
  DateTimeColumn get lastSyncAt => dateTime()();

  /// Optional ETag for conditional requests.
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {syncTableName};
}
