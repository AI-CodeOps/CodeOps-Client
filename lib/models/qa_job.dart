/// QA Job and job summary domain models.
///
/// Maps to the server's `JobResponse` and `JobSummaryResponse` DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'qa_job.g.dart';

/// A QA job — the primary unit of work executed by agents.
@JsonSerializable()
class QaJob {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the project being analyzed.
  final String projectId;

  /// Name of the project (denormalized for display).
  final String? projectName;

  /// The job mode determining which agents run.
  @JobModeConverter()
  final JobMode mode;

  /// Current lifecycle status of the job.
  @JobStatusConverter()
  final JobStatus status;

  /// Optional human-readable name for the job.
  final String? name;

  /// Git branch being analyzed.
  final String? branch;

  /// Job configuration as a JSON string.
  final String? configJson;

  /// Markdown summary of the job results.
  final String? summaryMd;

  /// Overall result of the job.
  @JobResultConverter()
  final JobResult? overallResult;

  /// Computed health score (0-100).
  final int? healthScore;

  /// Total number of findings across all agents.
  final int? totalFindings;

  /// Count of critical-severity findings.
  final int? criticalCount;

  /// Count of high-severity findings.
  final int? highCount;

  /// Count of medium-severity findings.
  final int? mediumCount;

  /// Count of low-severity findings.
  final int? lowCount;

  /// Jira ticket key if the job was created from a ticket.
  final String? jiraTicketKey;

  /// UUID of the user who started the job.
  final String? startedBy;

  /// Display name of the user who started the job.
  final String? startedByName;

  /// Timestamp when the job started executing.
  final DateTime? startedAt;

  /// Timestamp when the job completed.
  final DateTime? completedAt;

  /// Timestamp when the job record was created.
  final DateTime? createdAt;

  /// Creates a [QaJob] instance.
  const QaJob({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.mode,
    required this.status,
    this.name,
    this.branch,
    this.configJson,
    this.summaryMd,
    this.overallResult,
    this.healthScore,
    this.totalFindings,
    this.criticalCount,
    this.highCount,
    this.mediumCount,
    this.lowCount,
    this.jiraTicketKey,
    this.startedBy,
    this.startedByName,
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  /// Deserializes a [QaJob] from a JSON map.
  factory QaJob.fromJson(Map<String, dynamic> json) => _$QaJobFromJson(json);

  /// Serializes this [QaJob] to a JSON map.
  Map<String, dynamic> toJson() => _$QaJobToJson(this);
}

/// A lightweight summary of a QA job for list views.
@JsonSerializable()
class JobSummary {
  /// Unique identifier (UUID).
  final String id;

  /// Name of the project (denormalized for display).
  final String? projectName;

  /// The job mode.
  @JobModeConverter()
  final JobMode mode;

  /// Current lifecycle status.
  @JobStatusConverter()
  final JobStatus status;

  /// Optional human-readable name.
  final String? name;

  /// Overall result.
  @JobResultConverter()
  final JobResult? overallResult;

  /// Computed health score (0-100).
  final int? healthScore;

  /// Total number of findings.
  final int? totalFindings;

  /// Count of critical-severity findings.
  final int? criticalCount;

  /// Timestamp when the job completed.
  final DateTime? completedAt;

  /// Timestamp when the job was created.
  final DateTime? createdAt;

  /// Creates a [JobSummary] instance.
  const JobSummary({
    required this.id,
    this.projectName,
    required this.mode,
    required this.status,
    this.name,
    this.overallResult,
    this.healthScore,
    this.totalFindings,
    this.criticalCount,
    this.completedAt,
    this.createdAt,
  });

  /// Deserializes a [JobSummary] from a JSON map.
  factory JobSummary.fromJson(Map<String, dynamic> json) =>
      _$JobSummaryFromJson(json);

  /// Serializes this [JobSummary] to a JSON map.
  Map<String, dynamic> toJson() => _$JobSummaryToJson(this);
}
