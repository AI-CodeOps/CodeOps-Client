/// Health snapshot, health schedule, page response, auth response,
/// metrics, connections, bug investigation, system settings,
/// audit log, and notification preference domain models.
///
/// Maps to multiple server response DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';
import 'user.dart';

part 'health_snapshot.g.dart';

/// A point-in-time health score snapshot for a project.
@JsonSerializable()
class HealthSnapshot {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the project.
  final String projectId;

  /// UUID of the job that produced this snapshot.
  final String? jobId;

  /// Overall health score (0-100).
  final int healthScore;

  /// JSON string mapping severity to finding count.
  final String? findingsBySeverity;

  /// Tech debt score component.
  final int? techDebtScore;

  /// Dependency health score component.
  final int? dependencyScore;

  /// Test coverage as a percentage.
  final double? testCoveragePercent;

  /// Timestamp when the snapshot was captured.
  final DateTime? capturedAt;

  /// Creates a [HealthSnapshot] instance.
  const HealthSnapshot({
    required this.id,
    required this.projectId,
    this.jobId,
    required this.healthScore,
    this.findingsBySeverity,
    this.techDebtScore,
    this.dependencyScore,
    this.testCoveragePercent,
    this.capturedAt,
  });

  /// Deserializes a [HealthSnapshot] from a JSON map.
  factory HealthSnapshot.fromJson(Map<String, dynamic> json) =>
      _$HealthSnapshotFromJson(json);

  /// Serializes this [HealthSnapshot] to a JSON map.
  Map<String, dynamic> toJson() => _$HealthSnapshotToJson(this);
}

/// A scheduled health monitoring configuration for a project.
@JsonSerializable()
class HealthSchedule {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the project.
  final String projectId;

  /// Schedule frequency type.
  @ScheduleTypeConverter()
  final ScheduleType scheduleType;

  /// Cron expression for custom scheduling.
  final String? cronExpression;

  /// Agent types to include in scheduled runs.
  @AgentTypeConverter()
  final List<AgentType>? agentTypes;

  /// Whether this schedule is active.
  final bool? isActive;

  /// Timestamp of the last scheduled run.
  final DateTime? lastRunAt;

  /// Timestamp of the next scheduled run.
  final DateTime? nextRunAt;

  /// Timestamp when the schedule was created.
  final DateTime? createdAt;

  /// Creates a [HealthSchedule] instance.
  const HealthSchedule({
    required this.id,
    required this.projectId,
    required this.scheduleType,
    this.cronExpression,
    this.agentTypes,
    this.isActive,
    this.lastRunAt,
    this.nextRunAt,
    this.createdAt,
  });

  /// Deserializes a [HealthSchedule] from a JSON map.
  factory HealthSchedule.fromJson(Map<String, dynamic> json) =>
      _$HealthScheduleFromJson(json);

  /// Serializes this [HealthSchedule] to a JSON map.
  Map<String, dynamic> toJson() => _$HealthScheduleToJson(this);
}

/// Generic paginated response wrapper.
@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  /// List of items in the current page.
  final List<T> content;

  /// Current page number (0-indexed).
  final int page;

  /// Page size.
  final int size;

  /// Total number of elements across all pages.
  final int totalElements;

  /// Total number of pages.
  final int totalPages;

  /// Whether this is the last page.
  final bool isLast;

  /// Creates a [PageResponse] instance.
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  /// Creates an empty [PageResponse] with no content.
  factory PageResponse.empty() => PageResponse(
        content: [],
        page: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        isLast: true,
      );

  /// Deserializes a [PageResponse] from a JSON map.
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageResponseFromJson(json, fromJsonT);

  /// Serializes this [PageResponse] to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}

/// Authentication response containing tokens and user data.
@JsonSerializable(explicitToJson: true)
class AuthResponse {
  /// JWT access token.
  final String token;

  /// JWT refresh token.
  final String refreshToken;

  /// The authenticated user's profile.
  final User user;

  /// Creates an [AuthResponse] instance.
  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  /// Deserializes an [AuthResponse] from a JSON map.
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  /// Serializes this [AuthResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

/// Aggregated metrics for a team.
@JsonSerializable()
class TeamMetrics {
  /// UUID of the team.
  final String teamId;

  /// Total number of projects in the team.
  final int? totalProjects;

  /// Total number of jobs across all projects.
  final int? totalJobs;

  /// Total number of findings across all projects.
  final int? totalFindings;

  /// Average health score across all projects.
  final double? averageHealthScore;

  /// Number of projects below the health threshold.
  final int? projectsBelowThreshold;

  /// Number of open critical findings.
  final int? openCriticalFindings;

  /// Creates a [TeamMetrics] instance.
  const TeamMetrics({
    required this.teamId,
    this.totalProjects,
    this.totalJobs,
    this.totalFindings,
    this.averageHealthScore,
    this.projectsBelowThreshold,
    this.openCriticalFindings,
  });

  /// Deserializes a [TeamMetrics] from a JSON map.
  factory TeamMetrics.fromJson(Map<String, dynamic> json) =>
      _$TeamMetricsFromJson(json);

  /// Serializes this [TeamMetrics] to a JSON map.
  Map<String, dynamic> toJson() => _$TeamMetricsToJson(this);
}

/// Aggregated metrics for a project.
@JsonSerializable()
class ProjectMetrics {
  /// UUID of the project.
  final String projectId;

  /// Name of the project.
  final String? projectName;

  /// Current health score (0-100).
  final int? currentHealthScore;

  /// Previous health score for comparison.
  final int? previousHealthScore;

  /// Total number of jobs run.
  final int? totalJobs;

  /// Total number of findings.
  final int? totalFindings;

  /// Number of open critical findings.
  final int? openCritical;

  /// Number of open high findings.
  final int? openHigh;

  /// Number of tracked tech debt items.
  final int? techDebtItemCount;

  /// Number of open vulnerabilities.
  final int? openVulnerabilities;

  /// Timestamp of the last audit.
  final DateTime? lastAuditAt;

  /// Creates a [ProjectMetrics] instance.
  const ProjectMetrics({
    required this.projectId,
    this.projectName,
    this.currentHealthScore,
    this.previousHealthScore,
    this.totalJobs,
    this.totalFindings,
    this.openCritical,
    this.openHigh,
    this.techDebtItemCount,
    this.openVulnerabilities,
    this.lastAuditAt,
  });

  /// Deserializes a [ProjectMetrics] from a JSON map.
  factory ProjectMetrics.fromJson(Map<String, dynamic> json) =>
      _$ProjectMetricsFromJson(json);

  /// Serializes this [ProjectMetrics] to a JSON map.
  Map<String, dynamic> toJson() => _$ProjectMetricsToJson(this);
}

/// A GitHub connection for a team.
@JsonSerializable()
class GitHubConnection {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning team.
  final String teamId;

  /// Connection name.
  final String name;

  /// Authentication type.
  @GitHubAuthTypeConverter()
  final GitHubAuthType authType;

  /// GitHub username.
  final String? githubUsername;

  /// Whether the connection is active.
  final bool? isActive;

  /// Timestamp when the connection was created.
  final DateTime? createdAt;

  /// Creates a [GitHubConnection] instance.
  const GitHubConnection({
    required this.id,
    required this.teamId,
    required this.name,
    required this.authType,
    this.githubUsername,
    this.isActive,
    this.createdAt,
  });

  /// Deserializes a [GitHubConnection] from a JSON map.
  factory GitHubConnection.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionFromJson(json);

  /// Serializes this [GitHubConnection] to a JSON map.
  Map<String, dynamic> toJson() => _$GitHubConnectionToJson(this);
}

/// A Jira connection for a team.
@JsonSerializable()
class JiraConnection {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning team.
  final String teamId;

  /// Connection name.
  final String name;

  /// Jira instance URL.
  final String instanceUrl;

  /// Email associated with the Jira API token.
  final String email;

  /// Whether the connection is active.
  final bool? isActive;

  /// Timestamp when the connection was created.
  final DateTime? createdAt;

  /// Creates a [JiraConnection] instance.
  const JiraConnection({
    required this.id,
    required this.teamId,
    required this.name,
    required this.instanceUrl,
    required this.email,
    this.isActive,
    this.createdAt,
  });

  /// Deserializes a [JiraConnection] from a JSON map.
  factory JiraConnection.fromJson(Map<String, dynamic> json) =>
      _$JiraConnectionFromJson(json);

  /// Serializes this [JiraConnection] to a JSON map.
  Map<String, dynamic> toJson() => _$JiraConnectionToJson(this);
}

/// A bug investigation linked to a Jira ticket.
@JsonSerializable()
class BugInvestigation {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent QA job.
  final String jobId;

  /// Jira ticket key (e.g. 'PROJ-123').
  final String? jiraKey;

  /// Jira ticket summary.
  final String? jiraSummary;

  /// Jira ticket description.
  final String? jiraDescription;

  /// Additional context provided by the user.
  final String? additionalContext;

  /// Root cause analysis in Markdown.
  final String? rcaMd;

  /// Impact assessment in Markdown.
  final String? impactAssessmentMd;

  /// S3 key for the RCA report.
  final String? rcaS3Key;

  /// Whether the RCA was posted to Jira.
  final bool? rcaPostedToJira;

  /// Whether fix tasks were created in Jira.
  final bool? fixTasksCreatedInJira;

  /// Timestamp when the investigation was created.
  final DateTime? createdAt;

  /// Creates a [BugInvestigation] instance.
  const BugInvestigation({
    required this.id,
    required this.jobId,
    this.jiraKey,
    this.jiraSummary,
    this.jiraDescription,
    this.additionalContext,
    this.rcaMd,
    this.impactAssessmentMd,
    this.rcaS3Key,
    this.rcaPostedToJira,
    this.fixTasksCreatedInJira,
    this.createdAt,
  });

  /// Deserializes a [BugInvestigation] from a JSON map.
  factory BugInvestigation.fromJson(Map<String, dynamic> json) =>
      _$BugInvestigationFromJson(json);

  /// Serializes this [BugInvestigation] to a JSON map.
  Map<String, dynamic> toJson() => _$BugInvestigationToJson(this);
}

/// A system-level key-value setting.
@JsonSerializable()
class SystemSetting {
  /// Setting key.
  final String key;

  /// Setting value.
  final String value;

  /// UUID of the user who last updated the setting.
  final String? updatedBy;

  /// Timestamp when the setting was last updated.
  final DateTime? updatedAt;

  /// Creates a [SystemSetting] instance.
  const SystemSetting({
    required this.key,
    required this.value,
    this.updatedBy,
    this.updatedAt,
  });

  /// Deserializes a [SystemSetting] from a JSON map.
  factory SystemSetting.fromJson(Map<String, dynamic> json) =>
      _$SystemSettingFromJson(json);

  /// Serializes this [SystemSetting] to a JSON map.
  Map<String, dynamic> toJson() => _$SystemSettingToJson(this);
}

/// An entry in the audit log.
@JsonSerializable()
class AuditLogEntry {
  /// Sequential identifier.
  final int id;

  /// UUID of the user who performed the action.
  final String? userId;

  /// Display name of the user.
  final String? userName;

  /// UUID of the team context.
  final String? teamId;

  /// The action that was performed.
  final String action;

  /// Type of entity affected.
  final String? entityType;

  /// UUID of the entity affected.
  final String? entityId;

  /// Additional details about the action.
  final String? details;

  /// IP address from which the action was performed.
  final String? ipAddress;

  /// Timestamp when the action occurred.
  final DateTime? createdAt;

  /// Creates an [AuditLogEntry] instance.
  const AuditLogEntry({
    required this.id,
    this.userId,
    this.userName,
    this.teamId,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    this.ipAddress,
    this.createdAt,
  });

  /// Deserializes an [AuditLogEntry] from a JSON map.
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditLogEntryFromJson(json);

  /// Serializes this [AuditLogEntry] to a JSON map.
  Map<String, dynamic> toJson() => _$AuditLogEntryToJson(this);
}

/// A user's notification preference for an event type.
@JsonSerializable()
class NotificationPreference {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the user.
  final String userId;

  /// Event type identifier.
  final String eventType;

  /// Whether in-app notifications are enabled.
  final bool inApp;

  /// Whether email notifications are enabled.
  final bool email;

  /// Creates a [NotificationPreference] instance.
  const NotificationPreference({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.inApp,
    required this.email,
  });

  /// Deserializes a [NotificationPreference] from a JSON map.
  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceFromJson(json);

  /// Serializes this [NotificationPreference] to a JSON map.
  Map<String, dynamic> toJson() => _$NotificationPreferenceToJson(this);
}
