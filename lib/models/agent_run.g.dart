// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentRun _$AgentRunFromJson(Map<String, dynamic> json) => AgentRun(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      agentType:
          const AgentTypeConverter().fromJson(json['agentType'] as String),
      status: const AgentStatusConverter().fromJson(json['status'] as String),
      result: _$JsonConverterFromJson<String, AgentResult>(
          json['result'], const AgentResultConverter().fromJson),
      reportS3Key: json['reportS3Key'] as String?,
      score: (json['score'] as num?)?.toInt(),
      findingsCount: (json['findingsCount'] as num?)?.toInt(),
      criticalCount: (json['criticalCount'] as num?)?.toInt(),
      highCount: (json['highCount'] as num?)?.toInt(),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$AgentRunToJson(AgentRun instance) => <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'agentType': const AgentTypeConverter().toJson(instance.agentType),
      'status': const AgentStatusConverter().toJson(instance.status),
      'result': _$JsonConverterToJson<String, AgentResult>(
          instance.result, const AgentResultConverter().toJson),
      'reportS3Key': instance.reportS3Key,
      'score': instance.score,
      'findingsCount': instance.findingsCount,
      'criticalCount': instance.criticalCount,
      'highCount': instance.highCount,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
