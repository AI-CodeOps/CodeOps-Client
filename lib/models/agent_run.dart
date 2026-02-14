/// Agent run domain model.
///
/// Maps to the server's `AgentRunResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'agent_run.g.dart';

/// A single agent execution within a QA job.
@JsonSerializable()
class AgentRun {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent QA job.
  final String jobId;

  /// The type of agent that was executed.
  @AgentTypeConverter()
  final AgentType agentType;

  /// Current lifecycle status of the agent run.
  @AgentStatusConverter()
  final AgentStatus status;

  /// Result of the agent run.
  @AgentResultConverter()
  final AgentResult? result;

  /// S3 key for the full agent report.
  final String? reportS3Key;

  /// Numeric score produced by the agent (0-100).
  final int? score;

  /// Number of findings produced.
  final int? findingsCount;

  /// Count of critical-severity findings.
  final int? criticalCount;

  /// Count of high-severity findings.
  final int? highCount;

  /// Timestamp when the agent started executing.
  final DateTime? startedAt;

  /// Timestamp when the agent completed.
  final DateTime? completedAt;

  /// Creates an [AgentRun] instance.
  const AgentRun({
    required this.id,
    required this.jobId,
    required this.agentType,
    required this.status,
    this.result,
    this.reportS3Key,
    this.score,
    this.findingsCount,
    this.criticalCount,
    this.highCount,
    this.startedAt,
    this.completedAt,
  });

  /// Deserializes an [AgentRun] from a JSON map.
  factory AgentRun.fromJson(Map<String, dynamic> json) =>
      _$AgentRunFromJson(json);

  /// Serializes this [AgentRun] to a JSON map.
  Map<String, dynamic> toJson() => _$AgentRunToJson(this);
}
