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

  /// Job configuration JSON.
  TextColumn get configJson => text().nullable()();

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

/// Cached Anthropic model metadata fetched from the API.
class AnthropicModels extends Table {
  /// Model identifier (e.g. "claude-sonnet-4-20250514").
  TextColumn get id => text()();

  /// Human-readable display name.
  TextColumn get displayName => text()();

  /// Model family grouping (e.g. "claude-4").
  TextColumn get modelFamily => text().nullable()();

  /// Maximum input context window in tokens.
  IntColumn get contextWindow => integer().nullable()();

  /// Maximum output tokens the model can generate.
  IntColumn get maxOutputTokens => integer().nullable()();

  /// Timestamp when this model was fetched from the API.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local agent definitions for per-agent configuration.
class AgentDefinitions extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Agent display name.
  TextColumn get name => text()();

  /// Agent type enum value (SCREAMING_SNAKE_CASE).
  TextColumn get agentType => text().nullable()();

  /// Whether this agent serves as the QA manager (Vera).
  BoolColumn get isQaManager => boolean().withDefault(const Constant(false))();

  /// Whether this is a built-in agent (cannot be deleted).
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(true))();

  /// Whether this agent is enabled for dispatch.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// Override model ID for this agent (null = use system default).
  TextColumn get modelId => text().nullable()();

  /// Temperature setting for this agent (0.0–1.0).
  RealColumn get temperature => real().withDefault(const Constant(0.0))();

  /// Maximum retry attempts on failure.
  IntColumn get maxRetries => integer().withDefault(const Constant(1))();

  /// Timeout override in minutes (null = use system default).
  IntColumn get timeoutMinutes => integer().nullable()();

  /// Maximum agentic turns allowed.
  IntColumn get maxTurns => integer().withDefault(const Constant(50))();

  /// Optional system prompt override markdown.
  TextColumn get systemPromptOverride => text().nullable()();

  /// Human-readable description of the agent.
  TextColumn get description => text().nullable()();

  /// Display sort order.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local configuration for projects stored only on this machine.
///
/// Holds per-project settings like the local working directory path
/// that differ between developer machines and are never sent to the server.
class ProjectLocalConfig extends Table {
  /// Project UUID primary key (references [Projects.id]).
  TextColumn get projectId => text()();

  /// Absolute path to the project source code on this machine.
  TextColumn get localWorkingDir => text().nullable()();

  @override
  Set<Column> get primaryKey => {projectId};
}

/// Persisted Scribe editor tabs for session restoration.
///
/// Each row represents an open tab with its content, language,
/// cursor position, and display order. Loaded on app start to
/// restore the previous editing session.
class ScribeTabs extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Display name (file name or "Untitled-N").
  TextColumn get title => text()();

  /// Full file path on disk, or null if new/unsaved.
  TextColumn get filePath => text().nullable()();

  /// Editor content.
  TextColumn get content => text()();

  /// Language identifier for syntax highlighting.
  TextColumn get language => text()();

  /// Whether content has been modified since last save.
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  /// Cursor line position (0-based).
  IntColumn get cursorLine => integer().withDefault(const Constant(0))();

  /// Cursor column position (0-based).
  IntColumn get cursorColumn => integer().withDefault(const Constant(0))();

  /// Scroll offset for restoring position on tab switch.
  RealColumn get scrollOffset => real().withDefault(const Constant(0.0))();

  /// Tab display order (0-based).
  IntColumn get displayOrder => integer()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last modification timestamp.
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persisted Scribe editor settings (key-value store).
///
/// Stores editor configuration as a single JSON blob so that
/// settings survive app restarts.
class ScribeSettings extends Table {
  /// Setting key (e.g., 'editor_settings').
  TextColumn get key => text()();

  /// Setting value (JSON string).
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'scribe_settings';
}

// ─────────────────────────────────────────────────────────────────────────────
// DataLens Tables
// ─────────────────────────────────────────────────────────────────────────────

/// Saved database connections for DataLens.
class DatalensConnections extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Display name (e.g., "CodeOps Dev").
  TextColumn get name => text()();

  /// Database driver type (SCREAMING_SNAKE_CASE).
  TextColumn get driver =>
      text().withDefault(const Constant('POSTGRESQL'))();

  /// Database host address.
  TextColumn get host => text()();

  /// Database port number.
  IntColumn get port => integer().withDefault(const Constant(5432))();

  /// Database name.
  TextColumn get database => text()();

  /// Default schema (e.g., "public").
  TextColumn get schema => text().nullable()();

  /// Database username.
  TextColumn get username => text()();

  /// Database password (stored locally).
  TextColumn get password => text().nullable()();

  /// Whether to use SSL for the connection.
  BoolColumn get useSsl =>
      boolean().withDefault(const Constant(false))();

  /// SSL mode (disable, require, verify-ca, verify-full).
  TextColumn get sslMode => text().nullable()();

  /// Hex color for visual identification.
  TextColumn get color => text().nullable()();

  /// Connection timeout in seconds.
  IntColumn get connectionTimeout =>
      integer().withDefault(const Constant(10))();

  /// Timestamp of last successful connection.
  DateTimeColumn get lastConnectedAt => dateTime().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Query execution history for DataLens.
class DatalensQueryHistory extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Connection UUID this query was run against.
  TextColumn get connectionId => text()();

  /// SQL that was executed.
  TextColumn get sql => text()();

  /// Query execution status (SCREAMING_SNAKE_CASE).
  TextColumn get status => text()();

  /// Number of rows returned.
  IntColumn get rowCount => integer().nullable()();

  /// Execution time in milliseconds.
  IntColumn get executionTimeMs => integer()();

  /// Error message if the query failed.
  TextColumn get error => text().nullable()();

  /// Timestamp when the query was executed.
  DateTimeColumn get executedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-saved queries for DataLens.
class DatalensSavedQueries extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Connection UUID this query is associated with.
  TextColumn get connectionId => text()();

  /// Display name for the saved query.
  TextColumn get name => text()();

  /// Optional description.
  TextColumn get description => text().nullable()();

  /// SQL content.
  TextColumn get sql => text()();

  /// Optional grouping folder.
  TextColumn get folder => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Files attached to an agent definition (personas, prompts, etc.).
class AgentFiles extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Parent agent definition UUID.
  TextColumn get agentDefinitionId => text()();

  /// Display file name.
  TextColumn get fileName => text()();

  /// File type (e.g. "persona", "prompt", "context").
  TextColumn get fileType => text()();

  /// Markdown content of the file.
  TextColumn get contentMd => text().nullable()();

  /// Optional filesystem path reference.
  TextColumn get filePath => text().nullable()();

  /// Display sort order within the agent.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
